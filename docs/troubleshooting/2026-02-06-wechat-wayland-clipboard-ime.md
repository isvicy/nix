# WeChat 图片粘贴与中文输入在 Niri (Wayland) 下不工作

**日期**: 2026-02-06
**影响环境**: Niri 25.11 (Wayland) + WeChat 4.1.0.13 + xwayland-satellite 0.8
**状态**: 已解决

## 问题描述

### 现象
1. 使用 Niri 截图后，无法在 WeChat 中粘贴图片
2. 无法在 WeChat 中使用 fcitx5/Rime 输入中文

### 环境
- Compositor: Niri 25.11
- XWayland: xwayland-satellite 0.8
- 输入法: fcitx5 + Rime (`waylandFrontend = true`)
- WeChat: 4.1.0.13 (AppImage, 通过 nixpkgs `appimageTools.wrapAppImage` 打包)

## 根本原因

### WeChat 是 Qt5 应用，不是 Electron

WeChat Linux 是原生 **Qt 5** 应用（非 Electron），证据：
- 二进制包含 `QApplication`、`QGuiApplication`、`QPainter` 等 Qt 类引用
- 进程加载的全部是 `libxcb-*` 库，无 Wayland 库
- 有 `QT_PLUGIN_PATH`、`/platforminputcontexts` 等动态插件加载支持
- 内嵌 `RadiumWMPF/WeChatAppEx`（Chromium 内核，用于小程序）

因此 Feishu 的修复方式（`--ozone-platform=wayland`）对 WeChat 无效，因为那是 Chromium/Electron 专用参数。

### 问题一：图片剪贴板无法桥接

**原因**: xwayland-satellite v0.8 不支持 INCR（增量）选择传输协议。图片等大数据通过 X11 的 INCR 协议传输，v0.8 无法处理，导致 Wayland 剪贴板中的 `image/png` 无法桥接到 X11 侧。

验证方式：
```bash
# 将图片放入 Wayland 剪贴板
wl-copy --type image/png <<< "fake-png-data"
# 检查 Wayland 侧
wl-paste --list
# 结果：image/png ✓

# 检查 X11 侧
DISPLAY=:0 xclip -selection clipboard -o -t TARGETS
# 结果：仅 UTF8_STRING，无 image/png ✗
```

**修复**: commit [`94da1af`](https://github.com/Supreeeme/xwayland-satellite/commit/94da1af75326d89ecb12aba0cc9362e93ffdc766)（"Handle INCR selections properly"）于 2024-12-21 合并到 main 分支，在 v0.8（2024-12-01）发布 20 天之后。

### 问题二：fcitx5 中文输入不工作

**原因链**：

1. fcitx5 配置了 `waylandFrontend = true`，NixOS 25.11 下不再设置 `QT_IM_MODULE` 和 `GTK_IM_MODULE` 环境变量，依赖 Wayland text-input 协议
2. WeChat 的 Qt 使用 XCB 后端运行在 XWayland 上，无法使用 Wayland text-input 协议
3. `QT_IM_MODULE` 未设置时，Qt 默认使用 `QComposeInputContext`（简单组合键输入），而非 fcitx
4. `QT_PLUGIN_PATH` 仅指向 Qt 6 插件目录（`qt-6/plugins`），WeChat 是 Qt 5，无法加载 Qt 6 插件

`fcitx5-diagnose` 关键输出：
```
Group [x11::0] has 0 InputContext(s)    # 零个 X11 输入上下文
IM_MODULE_CLASSNAME=QComposeInputContext # 使用了 compose 而非 fcitx
QT_PLUGIN_PATH=.../lib/qt-6/plugins     # 指向 Qt 6，WeChat 是 Qt 5
```

## 解决方案

### 修复一：升级 xwayland-satellite 到 unstable

niri flake 提供 `xwayland-satellite-unstable`（`2026-02-04-0947c46`），包含 INCR 修复。

在 `modules/desktop/niri.nix` 和 `home/desktop/niri.nix` 中，将 `pkgs.xwayland-satellite` 替换为 `inputs.niri.packages.x86_64-linux.xwayland-satellite-unstable`。

### 修复二：为 WeChat 注入 fcitx5 Qt5 插件

在 `flake.nix` 中添加 overlay，使用 `symlinkJoin` + `makeWrapper` 包装 WeChat：

```nix
(_final: prev: let
  fcitx5-qt5 = prev.libsForQt5.fcitx5-qt;
  unwrapped = prev.wechat;
in {
  wechat = prev.symlinkJoin {
    name = "wechat-${unwrapped.version}";
    paths = [unwrapped];
    nativeBuildInputs = [prev.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/wechat \
        --set QT_IM_MODULE fcitx \
        --prefix QT_PLUGIN_PATH : "$(echo ${fcitx5-qt5}/lib/qt-*/plugins)"
    '';
  };
})
```

两个参数的作用：

| 参数 | 作用 |
|------|------|
| `QT_IM_MODULE=fcitx` | 告诉 Qt 加载 fcitx 平台输入上下文插件，通过 D-Bus 与 fcitx5 通信 |
| `QT_PLUGIN_PATH` 前缀 fcitx5-qt5 路径 | 提供 `libfcitx5platforminputcontextplugin.so`（Qt 5 版本），使 WeChat 的 Qt 可以找到并加载 |

### 为什么不能用 overrideAttrs

WeChat 通过 `appimageTools.wrapAppImage` 打包，底层使用 `buildFHSEnv`，最终由 `runCommandLocal` 生成输出。`runCommandLocal` 没有 `fixup` 阶段，因此 `overrideAttrs` 中的 `postFixup` 不会执行。必须使用 `symlinkJoin` + `makeWrapper` 在包构建完成后再包装。

## 调试命令

```bash
# 检查 WeChat 进程的环境变量
WECHAT_PID=$(pgrep -f '/usr/bin/wechat' | head -1)
tr '\0' '\n' < /proc/$WECHAT_PID/environ | rg -i 'QT_IM|QT_PLUGIN|XMOD|DISPLAY'

# 检查 WeChat 加载的共享库（是否包含 fcitx）
cat /proc/$WECHAT_PID/maps | awk '{print $NF}' | sort -u | rg -i 'fcitx'

# 检查 fcitx5 输入上下文
fcitx5-diagnose 2>&1 | rg -A2 'x11::'

# 测试 Wayland→X11 图片剪贴板桥接
wl-copy --type image/png <<< "test" && sleep 0.5 && DISPLAY=:0 xclip -selection clipboard -o -t TARGETS

# 检查 xwayland-satellite 版本
xwayland-satellite --version 2>&1 | head -1
```

## 相关配置文件

- `flake.nix` — WeChat overlay（fcitx5 Qt5 插件注入）
- `modules/desktop/niri.nix` — xwayland-satellite-unstable 系统包和 systemd 服务
- `home/desktop/niri.nix` — xwayland-satellite-unstable 用户包
- `modules/im/fcitx5.nix` — fcitx5 配置（`waylandFrontend = true`）

## 经验总结

1. **Qt 应用不等于 Electron 应用**：WeChat 是 Qt5 原生应用，不能用 `--ozone-platform=wayland` 修复
2. **`waylandFrontend = true` 不设置传统 IM 环境变量**：XWayland 应用仍需要 `QT_IM_MODULE` 和对应的 Qt 插件
3. **`QT_PLUGIN_PATH` 的 Qt 版本必须匹配**：Qt 5 应用不能加载 Qt 6 插件，需要 `fcitx5-qt5`（`libsForQt5.fcitx5-qt`）而非默认的 Qt 6 版本
4. **`buildFHSEnv` 包装的应用不能用 `overrideAttrs`**：必须用 `symlinkJoin` + `makeWrapper`
5. **xwayland-satellite v0.8 不支持 INCR 传输**：图片等大数据需要 unstable 版本（`>= 94da1af`）
6. **WeChat 的 Qt 支持动态插件加载**：虽然 Qt 是内嵌的，但 `QT_PLUGIN_PATH` 和 `platforminputcontexts` 机制仍然有效
