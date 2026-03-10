# nvidia 模块 refcnt 导致 GPU 直通失败排查记录

**日期**: 2026-03-10
**影响版本**: nvidia 580.119.02, kernel 6.12.74, NixOS 25.11
**状态**: 已解决

## 问题描述

### 现象

单 GPU（RTX 4090）直通到 Windows 11 虚拟机时，libvirt hook 脚本无法卸载 nvidia 内核模块。`modprobe -r nvidia` 报错 `Module nvidia is in use`，即使：

- 所有使用 GPU 的用户态进程已被 kill（通过 `fuser -k /dev/nvidia*` 确认）
- nvidia_drm、nvidia_modeset、nvidia_uvm 子模块全部卸载成功
- `/sys/module/nvidia/holders/` 为空（无模块依赖）
- `lsof /dev/nvidia*` 无输出（无进程持有文件描述符）

`cat /sys/module/nvidia/refcnt` 始终为 **7**。

### 后果

由于 nvidia 模块无法卸载，后续所有尝试都会 hang：
- `virsh nodedev-detach`（在 hook 内调用会和 libvirtd 死锁）
- sysfs PCI unbind（`echo $dev > .../driver/unbind`）hang 在 `i2c_del_adapter`
- `rmmod -f nvidia` 也 hang

每次 hang 后只能硬重启恢复。

## 排查过程

### 1. 错误方向：fbdev 和 powerManagement

首先怀疑是 NixOS 自动添加的内核参数导致：
- `nvidia-drm.fbdev=1`（`modesetting.enable = true` + driver 545+ 时自动添加）
- `nvidia.NVreg_PreserveVideoMemoryAllocations=1`（`powerManagement.enable = true` 时添加）

尝试设置 `nvidia-drm.fbdev=0`（通过 `lib.mkAfter` 确保覆盖自动值）和 `powerManagement.enable = false`。

**结果：refcnt 仍然为 7。** 这两个参数不是根因。

### 2. 错误方向：virsh nodedev-detach 死锁

在 hook 脚本中调用 `virsh nodedev-detach` 会 hang。根因是 libvirt hook 与 virsh 之间的死锁——hook 由 libvirtd 调用，virsh 又连接 libvirtd。

改用 sysfs `driver_override` + PCI unbind/bind 绕过 virsh。但 sysfs unbind 同样 hang，通过 `cat /proc/<pid>/wchan` 发现阻塞在 `i2c_del_adapter`。

### 3. 错误方向：用户态文件描述符泄漏

发现多个隐藏的 nvidia 设备消费者：
- `systemctl isolate multi-user.target` 不会 kill 用户 session 内的 DRI 进程（niri、Xwayland 等通过 `/dev/dri/*` 而非 `/dev/nvidia*` 使用 GPU）
- `nvidia-smi`（之前在 hook 中用于查找 GPU 进程）本身会打开 nvidia 设备
- NixOS 的 `nvidia-container-toolkit-cdi-generator` 服务会打开 nvidia 设备

修复了这些问题（使用 `fuser -k /dev/nvidia* /dev/dri/*`，提前停止 CDI generator），确认所有用户态 fd 已关闭。

**结果：refcnt 仍然为 7。** 不是用户态泄漏。

### 4. 错误方向：nvidia RM blob 内部引用

深入研究社区和 nvidia 开源代码，认为 7 个引用来自 nvidia 专有 RM blob 中的 `try_module_get(THIS_MODULE)` 调用。多个社区帖子报告了相同问题且无解。**这个结论是错误的。**

### 5. 关键突破：i2c_del_adapter 和 I2C 适配器

突破口来自 sysfs unbind hang 时的 wchan 信息：

```bash
$ cat /proc/<stuck_pid>/wchan
i2c_del_adapter
```

nvidia 的 PCI remove 回调在尝试删除 I2C adapter 时阻塞。检查 nvidia 注册的 I2C adapter：

```bash
$ for d in /sys/bus/i2c/devices/i2c-*/name; do
    echo "$(basename $(dirname $d)): $(cat $d)"
  done | grep NVIDIA

i2c-5: NVIDIA i2c adapter 2 at 1:00.0
i2c-6: NVIDIA i2c adapter 3 at 1:00.0
i2c-7: NVIDIA i2c adapter 4 at 1:00.0
i2c-8: NVIDIA i2c adapter 5 at 1:00.0
i2c-9: NVIDIA i2c adapter 6 at 1:00.0
i2c-10: NVIDIA i2c adapter 7 at 1:00.0
```

**恰好 7 个 NVIDIA I2C adapter** — 和 refcnt 完全吻合！

### 6. 根因确认：i2c_dev 模块

`i2c_dev` 模块在 attach 到一个 I2C adapter 时，会调用 `try_module_get(adapter->owner)`，即增加 adapter 所属模块（nvidia）的引用计数。7 个 nvidia adapter = 7 个引用。

验证：

```bash
# 停止 i2c 设备消费者后干净卸载 i2c_dev
$ modprobe -r i2c_dev

# nvidia refcnt 从 274 降至 267（精确减少 7）
$ cat /proc/modules | grep '^nvidia '
```

这些引用不会出现在 `/sys/module/nvidia/holders/` 中（因为 `i2c_dev` 不是通过模块符号依赖 nvidia），也不会出现在 `lsof` 中（因为不是用户态文件描述符），所以通过常规手段完全不可见。

### 7. 额外发现：udev 重新加载已卸载的模块

在 hook 中成功卸载 nvidia 子模块后，`udev` 会检测到设备状态变化并重新触发模块加载规则，导致 `nvidia_uvm` 等模块被自动重新加载，使得 `modprobe -r nvidia` 再次失败。

解决方法：在卸载模块前暂停 udev 事件处理队列：

```bash
udevadm control --stop-exec-queue
# ... 卸载模块、绑定 vfio ...
udevadm control --start-exec-queue
```

### 8. VM 显示和输入

- 原 VM 配置包含 QXL 虚拟显卡 + SPICE 协议。QXL 作为 `primary='yes'` 导致 TianoCore/Windows 输出到虚拟显示器而非直通 GPU
- 移除 QXL 和 SPICE 后，直通 GPU 成为唯一显示设备，但失去了虚拟键鼠输入通道
- 最终方案：USB 直通物理键盘和鼠标到 VM

### 9. GPU 音频设备恢复

VM 关闭后 HDMI 音频不工作。`/sys/bus/pci/devices/0000:01:00.1/driver` 为空——GPU 音频设备没有绑定驱动。

原因：PCI `rescan` 不会为已存在但未绑定驱动的设备触发驱动绑定。vfio-pci unbind 后设备仍在 PCI 总线上，rescan 只发现"新"设备。

修复：在 revert hook 中先 PCI `remove` 再 `rescan`（强制完整重新枚举），并添加 `snd_hda_intel` bind 作为兜底。

## 根因

**`i2c_dev` 内核模块 attach 到 nvidia 注册的 7 个 I2C adapter 时，对每个 adapter 调用 `try_module_get(nvidia)`，导致 nvidia 模块的 refcnt 增加 7。** 卸载 nvidia 前必须先干净卸载 i2c_dev 以释放这些引用。

此外，hook 执行过程中需要处理两个竞争条件：
1. `fuser -k` 需要同时覆盖 `/dev/nvidia*` 和 `/dev/dri/*`（DRM 设备节点）
2. `udev` 会在模块卸载后自动重新加载它们，必须暂停 udev 队列

## 最终解决方案

### Hook 脚本关键步骤

```bash
# 1. 停止持有 GPU 设备的服务
systemctl stop nvidia-container-toolkit-cdi-generator.service

# 2. 切换到 multi-user.target（停止显示管理器）
systemctl isolate multi-user.target

# 3. 杀死所有持有 nvidia 和 DRI 设备的进程
fuser -k /dev/nvidia* /dev/dri/*

# 4. 解绑 vtconsole
echo 0 > /sys/class/vtconsole/vtcon*/bind

# 5. 暂停 udev（防止模块被重新加载）
udevadm control --stop-exec-queue

# 6. 按顺序卸载内核模块
modprobe -r nvidia_drm
modprobe -r nvidia_uvm
modprobe -r nvidia_modeset
modprobe -r i2c_dev    # 释放 7 个 I2C adapter 引用
modprobe -r nvidia     # 现在 refcnt=0，卸载成功

# 7. 加载 VFIO 并绑定 GPU（需先解绑当前驱动）
for dev in "${GPU_DEVS[@]}"; do
  echo "$dev" > /sys/bus/pci/devices/$dev/driver/unbind
  echo "vfio-pci" > /sys/bus/pci/devices/$dev/driver_override
  echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
done

# 8. 恢复 udev
udevadm control --start-exec-queue
```

### NixOS 配置变更

- 移除 OpenRGB（`modules/openrgb.nix`）— 它以 `Restart=always` 持续打开所有 `/dev/i2c-*`，阻止 `i2c_dev` 卸载
- 添加 `pkgs.psmisc`（提供 `fuser`）到 `environment.systemPackages`

### VM 配置变更

- 移除 QXL 虚拟显卡和 SPICE 协议
- 添加 USB 直通：键盘（Kinesis Advantage2 `29ea:0102`）和鼠标（Logitech G502 `046d:c08b`）
- GPU PCI 直通使用 `managed='no'`（hook 处理绑定/解绑）

## 教训

1. **`/sys/module/<mod>/holders/` 只显示模块符号依赖**，不显示通过 `try_module_get()` 创建的运行时引用
2. **`lsof /dev/nvidia*` 不够** — DRM 客户端通过 `/dev/dri/*` 使用 GPU，必须同时 `fuser -k /dev/dri/*`
3. **当 sysfs 操作 hang 时，`/proc/<pid>/wchan` 是关键线索** — `i2c_del_adapter` 直接指向了问题所在
4. **数字匹配是重要的调试信号** — refcnt 恰好为 7，nvidia I2C adapter 恰好为 7，这不是巧合
5. **`rmmod -f` 不等于干净卸载** — force 移除跳过 detach 回调，`module_put()` 不会被调用
6. **udev 会在模块卸载后自动重新加载** — 必须在关键操作期间暂停 udev 事件队列
7. **PCI rescan 不等于驱动重新绑定** — 对于已存在但未绑定驱动的设备，需要先 `remove` 再 `rescan` 才能触发驱动 probe
8. **Nix flakes 只能看到 git staged 的文件** — 修改 hook 后必须 `git add` 才能被 `nixos-rebuild` 看到
