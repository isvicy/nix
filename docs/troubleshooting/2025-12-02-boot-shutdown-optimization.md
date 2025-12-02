# 启动/关机优化及 Z790 主板 B4 卡住问题

**日期**: 2025-12-02
**硬件**: ROG MAXIMUS Z790 HERO + NVIDIA RTX 4090
**状态**: 已解决

## 问题描述

### 1. 启动时间过长
- 原始启动时间：约 56 秒（用户空间 27.6 秒）
- 主要耗时：k3s.service (18.9s)、NetworkManager-wait-online.service (5.4s)

### 2. 关机卡住约 3 分钟
- `/mnt/syno` CIFS 网络挂载卸载超时
- 网络断开后 CIFS 挂载无法正常卸载，等待默认 90 秒超时

### 3. Niri 桌面启动失败/延迟
- greetd 启动时 NVIDIA GPU 设备节点尚未就绪
- 错误日志：`Error::DeviceMissing`、`software EGL renderers are skipped`

### 4. Z790 主板重启后卡 B4 POST 代码
- B4 是 USB 设备初始化阶段的 POST 代码
- 卡住后需要手动按关机键，重新开机才能正常启动
- Windows 下从未出现此问题

## 排查过程

### 启动时间分析

```bash
systemd-analyze
systemd-analyze blame | head -20
systemd-analyze critical-chain
```

发现 k3s.service 是关键路径上最慢的服务（18.9s），且依赖 network-online.target。

### 关机日志分析

```bash
journalctl -b -1 -o short-monotonic | grep -E "(timeout|Timed out|Failed)"
```

发现 `data.mount` 和 `mnt-syno.mount` 卸载超时。CIFS 挂载的 `x-systemd.mount-timeout` 只影响挂载操作，不影响卸载。

### Niri 启动失败分析

```bash
journalctl -b | grep -E "greetd|niri|nvidia0"
```

发现 greetd 等待 `dev-nvidia0.device` 超时（约 90 秒）。原因是 NVIDIA 设备节点通过 udev 的 `mknod` 创建，不会触发 systemd 的设备单元。

### Z790 B4 问题调研

通过 kernel.org Bugzilla 发现 Z790 芯片组存在多个活跃 bug，包括：
- xHCI 控制器警告和 URB 提交失败
- Linux 6.16+ 内核在 Z790 上启动失败

## 根本原因

### 关机卡住
CIFS 网络挂载在网络断开后无法正常卸载，默认等待 90 秒超时。

### Niri 启动延迟
greetd 配置了等待 `dev-nvidia0.device`，但该设备单元永远不会变成 active 状态（NVIDIA 设备节点通过 mknod 创建，不触发 systemd 设备单元）。

### Z790 B4 卡住
Linux 默认的重启方式（keyboard controller）不能正确重置 Z790 的 USB/xHCI 控制器状态，导致 UEFI 在 USB 初始化阶段卡住。

## 解决方案

### 1. 禁用 k3s 自动启动

```nix
# modules/k3s.nix
{lib, ...}: {
  services.k3s = {
    enable = true;
    clusterInit = true;
  };

  # 禁用自动启动，需要时手动: sudo systemctl start k3s
  systemd.services.k3s.wantedBy = lib.mkForce [];
}
```

### 2. 优化 CIFS 挂载选项

```nix
# modules/nfs.nix
fileSystems."/mnt/syno" = {
  # ...
  options = [
    # ... 原有选项
    "x-systemd.mount-timeout=10"
    "x-systemd.unmount-timeout=5"  # 卸载超时 5 秒
    "_netdev"
    "soft"       # 软挂载，超时后返回错误而不是无限等待
    "timeo=50"   # CIFS 请求超时 5 秒 (单位 0.1 秒)
  ];
};
```

### 3. 缩短 systemd 默认停止超时

```nix
# hosts/rog/default.nix
# 30s 是个平衡点，太短可能导致硬件状态不干净
systemd.settings.Manager.DefaultTimeoutStopSec = "30s";
```

### 4. greetd 等待 NVIDIA CDI generator 服务

```nix
# modules/desktop/displaymanager/greetd.nix
{username, pkgs, lib, config, ...}: {
  services.greetd = {
    # ... 原有配置
  };

  # 等待 NVIDIA GPU 就绪后再启动 greetd
  # 注意：dev-nvidia0.device 不会被触发（设备通过 mknod 创建）
  systemd.services.greetd = lib.mkIf config.custom.nvidia.enableCDI {
    after = ["nvidia-container-toolkit-cdi-generator.service"];
    wants = ["nvidia-container-toolkit-cdi-generator.service"];
  };
}
```

### 5. 使用 PCI 方式重启解决 B4 问题

```nix
# hosts/rog/default.nix
boot.kernelParams = [
  # ... 其他参数
  "reboot=pci"  # 使用 PCI 方式重启，解决 Z790 主板 B4 卡住问题
];
```

`reboot=pci` 通过 PCI 配置空间的 CF9 寄存器触发重启，会导致完整的硬件重置（类似冷启动），确保 USB/xHCI 控制器状态被完全清除。

## 效果

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| 启动时间（用户空间） | ~28s | ~8s |
| 关机时间 | ~3min | ~2s |
| Niri 启动 | 偶尔失败/延迟 90s | 正常 |
| Z790 B4 卡住 | 频繁 | 未再出现 |

## 相关配置文件

- `hosts/rog/default.nix` - 内核参数、systemd 超时
- `modules/k3s.nix` - K3s 服务配置
- `modules/nfs.nix` - CIFS 挂载配置
- `modules/desktop/displaymanager/greetd.nix` - Display Manager 配置

## 环境信息

- **系统**: NixOS 25.11 (nixos-unstable)
- **内核**: Linux 6.17.8
- **主板**: ROG MAXIMUS Z790 HERO
- **GPU**: NVIDIA GeForce RTX 4090
- **驱动版本**: 580.105.08
- **Display Manager**: greetd
- **Compositor**: Niri (unstable)

## 经验总结

1. `x-systemd.mount-timeout` 只影响挂载，需要 `x-systemd.unmount-timeout` 控制卸载超时
2. NVIDIA 设备节点通过 mknod 创建，不触发 systemd 设备单元，不能用 `dev-nvidia0.device` 作为依赖
3. Z790 等新主板可能需要 `reboot=pci` 参数来确保硬件正确重置
4. `DefaultTimeoutStopSec` 设置太短可能导致硬件状态不干净，30 秒是个合理的平衡点
