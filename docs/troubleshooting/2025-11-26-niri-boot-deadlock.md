# Niri 启动卡死问题排查记录

**日期**: 2025-11-26
**影响版本**: nixpkgs commit `117cc7f` (2025-11-20)
**状态**: 已解决（更新 flake 即可）

## 问题描述

### 现象
- NixOS 启动后自动进入 Niri 桌面环境时卡在黑屏
- 终端显示警告: `Calling import-environment without a list of variable names is deprecated.`
- 需要切换到其他 TTY，手动 `kill` 掉 `niri --session` 进程后才能进入桌面
- `ps aux | grep niri` 显示:
  - `systemctl --user --wait start niri.service`
  - `/nix/store/xxx/bin/niri --session`

### 触发条件
- 最后一次 `nix flake update` 之后出现
- 启用了 `hardware.nvidia-container-toolkit.enable = true`（通过 `custom.nvidia.enableCDI = true`）

## 排查过程

### 1. 初步分析

最初怀疑是 `niri-session` 脚本中的 `systemctl --user import-environment` 导致的问题（systemd 258+ 废弃了不带变量名的调用）。

查看 niri-session 脚本 (`/nix/store/.../bin/niri-session`):
```bash
# 第 36 行
systemctl --user import-environment  # deprecated warning 来源
```

但这个警告本身不应该导致卡死。

### 2. 深入日志分析

检查 systemd 日志发现真正的问题:

```bash
journalctl --user -u niri.service -b
```

关键日志:
```
niri::backend::tty: error doing early import: Error::DeviceMissing
niri::backend::tty: pausing session
Failed to initialize EGL. Err: EGL is not initialized
```

Niri 在启动时 GPU 设备不可用，导致 EGL 初始化失败。

### 3. 检查 NVIDIA 服务状态

```bash
systemctl list-units --type=service | grep nvidia
```

发现 `nvidia-container-toolkit-cdi-generator.service` 处于 **failed** 状态。

查看详细日志:
```bash
journalctl -u nvidia-container-toolkit-cdi-generator.service -b
```

输出:
```
wait-for-nvidia-devices: expecting 1 /dev/nvidiaN device node(s).
wait-for-nvidia-devices: timed out after 60 seconds; expected 1 node(s) but found 0.
```

### 4. 发现死锁

检查系统启动日志:
```bash
sudo journalctl -b | grep -iE "nvidia|drm"
```

关键发现:
```
22:01:10 - wait-for-nvidia-devices: expecting 1 /dev/nvidiaN device node(s).
22:02:09 - udev-worker: nvidia: Spawned process 'systemctl restart nvidia-container-toolkit-cdi-generator.service' is taking longer than 59s
22:02:10 - mknod -m 666 /dev/nvidiactl c 195 255 failed with exit code 1
22:02:10 - mknod -m 666 /dev/nvidia${i} c 195 ${i} failed with exit code 1
```

### 5. 分析 udev 规则

查看 `/run/current-system/etc/udev/rules.d/99-local.rules`:

```
# 第1条：同步重启 CDI 服务（阻塞等待设备）
KERNEL=="nvidia", RUN+="systemctl restart nvidia-container-toolkit-cdi-generator.service"

# 第2条：创建 /dev/nvidiactl（被阻塞，无法执行）
KERNEL=="nvidia", RUN+="mknod -m 666 /dev/nvidiactl c 195 255"

# 第3条：创建 /dev/nvidia0（被阻塞，无法执行）
KERNEL=="nvidia", RUN+="mknod ... /dev/nvidia${i} ..."
```

## 根本原因

### 死锁流程

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. 内核加载 nvidia 模块，触发 udev 规则                              │
├─────────────────────────────────────────────────────────────────────┤
│ 2. 第一条规则：同步执行                                              │
│    systemctl restart nvidia-container-toolkit-cdi-generator.service │
├─────────────────────────────────────────────────────────────────────┤
│ 3. 该服务的 ExecStartPre 运行 wait-for-nvidia-devices               │
│    等待 /dev/nvidia0 存在（最多 60 秒）                              │
├─────────────────────────────────────────────────────────────────────┤
│ 4. 但 /dev/nvidia0 需要由第三条 udev 规则创建                        │
│    而第三条规则在等第一条完成                                        │
├─────────────────────────────────────────────────────────────────────┤
│ 5. 死锁 60 秒，设备节点无法创建                                      │
├─────────────────────────────────────────────────────────────────────┤
│ 6. greetd 启动 niri-session 时 GPU 设备不可用                        │
│    → EGL 初始化失败 → 黑屏卡死                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### NixOS Bug 追踪

这是 NixOS nixpkgs 的已知 bug：

| 日期 | 事件 | 链接 |
|------|------|------|
| 2025-10-15 | PR #452645 添加 `wait-for-nvidia-devices` | [PR #452645](https://github.com/NixOS/nixpkgs/pull/452645) |
| 2025-11-21 | PR #463702 Revert，因导致 boot deadlock | [PR #463702](https://github.com/NixOS/nixpkgs/pull/463702) |

相关 Issue:
- [#463645 - Boot deadlock with udev and wait-for-nvidia-devices](https://github.com/NixOS/nixpkgs/issues/463645)
- [#463525 - Recent changes broke user systems](https://github.com/NixOS/nixpkgs/issues/463525)

### 版本对比

| 项目 | 值 |
|------|-----|
| 我的 nixpkgs 版本 | `117cc7f` (2025-11-20) |
| Bug 修复版本 | PR #463702 merge (2025-11-21) |
| 结论 | 我的版本在修复之前，包含有问题的代码 |

## 解决方案

### 方法 1: 更新 flake（推荐）

```bash
nix flake update nixpkgs
sudo nixos-rebuild switch --flake .#rog
```

### 方法 2: 临时禁用 CDI

如果无法立即更新，可以临时禁用 nvidia-container-toolkit CDI:

```nix
# hosts/rog/default.nix
custom.nvidia.enableCDI = false;  # 临时禁用
```

### 方法 3: 添加 greetd 启动延迟

作为 workaround，让 greetd 等待 nvidia 设备就绪:

```nix
# modules/desktop/displaymanager/greetd.nix
systemd.services.greetd.after = [ "dev-nvidia0.device" ];
systemd.services.greetd.wants = [ "dev-nvidia0.device" ];
```

## 相关配置文件

- `modules/nvidia/plain.nix` - NVIDIA 驱动配置
- `modules/desktop/displaymanager/greetd.nix` - Display Manager 配置
- `hosts/rog/default.nix` - 主机配置，启用了 `custom.nvidia.enableCDI = true`

## 环境信息

- **系统**: NixOS 25.11 (nixos-unstable)
- **内核**: Linux 6.17.8
- **GPU**: NVIDIA GeForce RTX 4090
- **驱动版本**: 580.105.08
- **systemd 版本**: 258.1
- **Display Manager**: greetd
- **Compositor**: Niri (unstable)

## 经验总结

1. `import-environment` 的 deprecated 警告是误导，真正的问题是 NVIDIA 设备节点创建死锁
2. 当遇到启动卡死问题时，应优先检查 `journalctl -b` 中的设备初始化日志
3. udev 规则中的同步命令可能导致意外的死锁
4. 关注 nixpkgs 的 unstable 分支更新，可能包含尚未完全测试的改动
