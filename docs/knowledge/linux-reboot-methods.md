# Linux 内核 reboot 参数详解

本文档记录 Linux 内核 `reboot=` 参数的各种方式及其区别。

## 参数格式

```
reboot=b[ios] | t[riple] | k[bd] | a[cpi] | e[fi] | p[ci] [, [w]arm | [c]old]
```

## 重启方式对比

| 方式 | 参数 | 机制 | 特点 |
|------|------|------|------|
| **键盘控制器** | `kbd` | 通过 PS/2 键盘控制器 (i8042) 发送重置信号 | 默认方式，最传统 |
| **BIOS** | `bios` | 跳转到 BIOS 重启向量 | 仅 32 位系统，温重启 |
| **ACPI** | `acpi` | 使用 ACPI FADT 中的 RESET_REG | 标准化方式 |
| **EFI** | `efi` | 调用 EFI 运行时服务 `ResetSystem()` | UEFI 系统推荐 |
| **PCI (CF9)** | `pci` | 写入 PCI 配置空间 0xCF9 寄存器 | 强制硬件重置 |
| **三重故障** | `triple` | 触发 CPU 三重故障 | 最后手段 |

## 详细说明

### kbd (键盘控制器) - 默认

```c
// 内核实现
outb(0xfe, 0x64);  // 向键盘控制器发送重置命令
```

- 使用 Intel 8042 键盘控制器的 CPU 重置引脚
- 历史最悠久的方式，兼容性最好
- 触发**冷重启**（cold reset）

### efi (EFI 运行时服务)

```c
// 内核实现
efi_reboot(reboot_mode, NULL);
```

- 调用 UEFI 固件的 `ResetSystem()` 运行时服务
- 让固件自己决定如何重置硬件
- **UEFI 系统的标准方式**
- 失败时回退到键盘控制器

**优点**：
- 固件最了解自己的硬件
- 现代主板（如 Z790）可能需要此方式
- 可以正确处理复杂的硬件状态

### pci (CF9 寄存器)

```c
// 内核实现
u8 cf9 = inb(0xcf9) & ~6;
outb(cf9|2, 0xcf9);      // 请求硬重置
udelay(50);
outb(cf9|reboot_code, 0xcf9);  // 0x06=温重启, 0x0E=冷重启
```

- 写入 I/O 端口 0xCF9（PCI 重置寄存器）
- **非标准化**，但大多数 x86 芯片组支持
- 触发类似"按下机箱重启按钮"的硬件重置

**CF9 寄存器位定义**：
| 位 | 含义 |
|---|------|
| bit 1 | 系统重置（设为 1 触发） |
| bit 2 | 重置类型（0=温重启, 1=冷重启） |
| bit 3 | 全系统重置 |

**注意**：不同芯片组对 CF9 的实现可能不同，某些系统可能会卡住。

### acpi (ACPI RESET_REG)

```c
// 内核实现
acpi_reboot();  // 使用 FADT 表中定义的重置寄存器
```

- 使用 ACPI 固定描述表 (FADT) 中的 `RESET_REG`
- 大多数现代系统的 RESET_REG 实际上指向 0xCF9
- 标准化的方式，但依赖 BIOS 正确实现

### triple (三重故障)

- 故意触发 CPU 三重故障（Triple Fault）
- CPU 会自动重置
- 最后的手段，某些 hypervisor 中使用

## 温重启 vs 冷重启

| 类型 | 参数 | 特点 |
|------|------|------|
| **冷重启** | `cold` | 完整硬件初始化，包括内存检测 |
| **温重启** | `warm` | 跳过部分硬件初始化，更快 |

```bash
# 组合使用
reboot=efi,cold   # 使用 EFI 方式 + 冷重启
reboot=pci,warm   # 使用 PCI 方式 + 温重启
```

**温重启的风险**：
- 大内存系统更快（跳过内存检测）
- 但某些硬件状态可能未完全重置
- 可能导致启动问题

## 回退机制

内核在 `native_machine_emergency_restart()` 中实现了回退链：

```
ACPI → Keyboard → EFI → BIOS → PCI (CF9) → Triple Fault
```

如果指定的方式失败，会自动尝试下一种。

## 实际案例

### Z790 主板 B4 POST 卡住问题

| 方式 | 效果 |
|------|------|
| `reboot=pci` | 偶发卡住 |
| `reboot=efi` | 正常 |

**原因分析**：
- Z790 使用 Intel Raptor Lake 芯片组
- xHCI (USB 3.0) 控制器在关机时状态可能不干净
- `reboot=pci` 直接写 CF9 可能不能正确重置所有硬件
- `reboot=efi` 让 UEFI 固件处理，它知道如何正确重置自己的硬件

### 选择建议

| 系统类型 | 推荐方式 |
|----------|----------|
| 传统 BIOS 系统 | `kbd`（默认） |
| UEFI 系统 | `efi` |
| 虚拟机 | `acpi` 或 `triple` |
| 问题排查 | 依次尝试 `efi` → `acpi` → `pci` |

## 调试命令

```bash
# 查看当前使用的重启参数
cat /proc/cmdline | grep reboot

# 查看当前重启类型和模式
cat /sys/kernel/reboot/type
cat /sys/kernel/reboot/mode

# 查看上次关机日志
journalctl -b -1 | tail -50
```

## 参考资料

- [Linux Kernel Documentation: AMD64 Boot Options](https://docs.kernel.org/next/arch/x86/x86_64/boot-options.html)
- [Linux Kernel Source: arch/x86/kernel/reboot.c](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/reboot.c)
- [Ask Ubuntu: Why can't I restart/shutdown?](https://askubuntu.com/questions/7114/why-cant-i-restart-shutdown)
