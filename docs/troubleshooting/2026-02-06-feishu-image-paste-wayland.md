# Feishu 无法粘贴 Niri 截图 & clipboard-sync 崩溃

**日期**: 2026-02-06
**影响环境**: Niri 25.11 (Wayland) + Feishu 7.50.14 + xwayland-satellite 0.8
**状态**: 已解决

## 问题描述

### 现象
- 使用 Niri 截图（Ctrl+Shift+A）后，无法在 Feishu 中粘贴图片
- `clipboard-sync` 服务持续崩溃重启

### 环境
- Compositor: Niri 25.11
- XWayland: xwayland-satellite 0.8
- 剪贴板同步: clipboard-sync 0.2.0
- 输入法: fcitx5 + Rime

## 根本原因

问题由三个因素叠加导致：

### 1. Feishu 运行在 XWayland 下

Feishu 是 Electron 应用，但其包装脚本未添加 `--ozone-platform=wayland` 标志。尽管环境变量 `NIXOS_OZONE_WL=1` 已设置，但 Feishu 的自定义包装脚本不读取此环境变量（它不使用 NixOS 标准的 Electron 包装器）。因此 Feishu 运行在 XWayland 下，通过 X11 剪贴板读取数据。

### 2. clipboard-sync 崩溃 + 竞态条件

clipboard-sync 0.2.0 使用过时的 `wayland-client 0.29.4`，与 Niri 的 Wayland 实现不兼容：
```
panicked at wayland-client-0.29.4/src/rust_imp/proxy.rs:211:39
WlcrsPaste(WaylandConnection(NoCompositorListening))
child process panicked too many times.
```

即使在未崩溃时，clipboard-sync 还存在竞态条件（[issue #46](https://github.com/dnut/clipboard-sync/issues/46)）：当 Wayland 剪贴板设为 `image/png` 时，clipboard-sync 会读取 X11 剪贴板中的旧文本数据并写回 Wayland，**覆盖掉图片数据**。

验证方式：
```bash
# 将图片放入 Wayland 剪贴板
wl-copy --type image/png < test.png
# 等待 3 秒后检查
wl-paste --list
# 结果：image/png 被替换为 text/plain（旧文本数据）
```

### 3. xwayland-satellite 0.8 不桥接剪贴板

测试发现 xwayland-satellite 0.8 不会将 Wayland 剪贴板内容桥接到 X11（甚至文本也不行）：
```bash
echo "test" | wl-copy
xclip -selection clipboard -o  # Error: target STRING not available
```

v0.8 之后有一次剪贴板重构（2025年2月），但尚未发布新版本。

### 数据流

```
Niri 截图 → image/png 进入 Wayland 剪贴板
  → clipboard-sync 检测到变化，从 X11 读取旧文本，写回 Wayland（覆盖图片）
  → xwayland-satellite 不桥接 Wayland→X11
  → Feishu（XWayland）看不到 image/png
```

## 解决方案

### 1. Feishu 使用原生 Wayland 运行

在 `flake.nix` 中添加 overlay，为 Feishu 添加 Wayland 标志：

```nix
(_final: prev: {
  feishu = prev.feishu.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram $out/opt/bytedance/feishu/feishu \
          --add-flags "--ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3"
      '';
  });
})
```

三个标志的作用：
| 标志 | 作用 |
|------|------|
| `--ozone-platform=wayland` | Electron 使用原生 Wayland 渲染，绕过 XWayland |
| `--enable-wayland-ime` | 启用 Wayland 输入法支持 |
| `--wayland-text-input-version=3` | 使用 text-input-v3 协议（Niri 支持的版本），解决 fcitx5/Rime 中文输入问题 |

### 2. 禁用 clipboard-sync

在 `hosts/rog/default.nix` 中：
```nix
services.clipboard-sync.enable = false;
```

clipboard-sync 在 Niri 环境下有三个问题：
- wayland-client 0.29.4 不兼容，持续崩溃
- 竞态条件覆盖图片剪贴板数据
- 图片支持本身不可靠（[issue #32](https://github.com/dnut/clipboard-sync/issues/32)）

## 调试命令

```bash
# 检查 Wayland 剪贴板内容和 MIME 类型
wl-paste --list

# 检查 X11 剪贴板目标类型
xclip -selection clipboard -o -t TARGETS

# 检查 Feishu 是否运行在 Wayland 模式
cat /proc/$(pgrep -f 'feishu' | head -1)/cmdline | tr '\0' '\n' | grep ozone

# 检查 clipboard-sync 状态和日志
systemctl --user status clipboard-sync
journalctl --user -u clipboard-sync --since "10 min ago"

# 检查 xwayland-satellite 版本
readlink /proc/$(pgrep xwayland-satellite)/exe
```

## 相关配置文件

- `flake.nix` - Feishu overlay（Wayland 标志）
- `hosts/rog/default.nix` - clipboard-sync 开关
- `modules/im/fcitx5.nix` - fcitx5 配置（`waylandFrontend = true`）
- `modules/desktop/niri.nix` - Niri 和 xwayland-satellite 配置

## 经验总结

1. **Electron 应用在 Niri 下优先使用原生 Wayland**：`NIXOS_OZONE_WL=1` 只对使用 NixOS 标准 Electron 包装器的应用有效，自定义包装的应用需要通过 overlay 手动添加 `--ozone-platform=wayland`
2. **Wayland IME 需要 text-input-v3**：Niri 使用 text-input-v3 协议，Electron 默认不启用，需要 `--wayland-text-input-version=3` 和 `--enable-wayland-ime` 两个标志配合 fcitx5
3. **clipboard-sync 与 Niri 不兼容**：使用过时的 wayland-client，且存在竞态条件会破坏非文本剪贴板数据
4. **xwayland-satellite 0.8 的剪贴板桥接不完整**：Wayland→X11 方向不工作，需等待后续版本（main 分支有相关修复但未发布）
5. **诊断剪贴板问题时**：分别检查 `wl-paste --list`（Wayland 侧）和 `xclip -selection clipboard -o -t TARGETS`（X11 侧），对比两侧 MIME 类型即可定位桥接断点
