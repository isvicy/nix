# Chrome 文件选择器无法打开问题

**日期**: 2026-01-31
**影响环境**: Niri (Wayland compositor) + Google Chrome
**状态**: 已解决

## 问题描述

### 现象
- 在 Google Chrome 中点击任何网站的文件上传按钮，没有任何反应
- 文件选择对话框完全不弹出
- 其他浏览器（Firefox、Zen Browser）可能也受影响

### 环境
- Compositor: Niri (wlroots-based Wayland compositor)
- 浏览器: Google Chrome Beta
- Portal 配置: xdg-desktop-portal-gnome + xdg-desktop-portal-gtk

## 根本原因

在 Wayland 环境下，应用程序通过 `xdg-desktop-portal` 调用系统的文件选择器。问题出在 portal 配置上：

```nix
# modules/desktop/xdg.nix (修复前)
config = {
  common = {
    default = ["gnome" "gtk"];  # GNOME 优先
    # 没有显式配置 FileChooser
  };
};
```

`xdg-desktop-portal-gnome` 的 FileChooser 实现依赖完整的 GNOME 会话环境。在 Niri 这样的独立 Wayland compositor 中，GNOME portal 的文件选择器无法正常工作。

### Portal 接口说明

| Portal 接口 | 功能 | 推荐后端 |
|------------|------|---------|
| `org.freedesktop.impl.portal.FileChooser` | 文件选择对话框 | gtk (独立环境) |
| `org.freedesktop.impl.portal.ScreenCast` | 屏幕录制 | gnome (需要 PipeWire) |
| `org.freedesktop.impl.portal.Screenshot` | 截图 | gnome |

## 解决方案

修改 `modules/desktop/xdg.nix`，显式指定 FileChooser 使用 GTK 后端：

```nix
{pkgs, ...}: {
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common = {
        default = ["gtk"];  # 改为 GTK 优先
        "org.freedesktop.impl.portal.FileChooser" = "gtk";  # 显式指定
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
        "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
```

### 应用修复

```bash
sudo nixos-rebuild switch --flake .#rog
systemctl --user restart xdg-desktop-portal
```

## 调试命令

如果问题仍然存在，可以使用以下命令排查：

```bash
# 检查 portal 服务状态
systemctl --user status xdg-desktop-portal

# 查看 portal 日志
journalctl --user -u xdg-desktop-portal -f

# 检查当前 portal 配置
cat /run/user/$(id -u)/xdg-desktop-portal/portals.conf

# 测试文件选择器（需要安装 zenity 或使用 gdbus）
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.FileChooser.OpenFile \
  "" "Test" '{}'
```

## 相关配置文件

- `modules/desktop/xdg.nix` - XDG portal 配置
- `modules/desktop/wayland.nix` - Wayland 环境变量（包含 `NIXOS_OZONE_WL=1`）

## 经验总结

1. 在非 GNOME 的 Wayland 环境中，应优先使用 `xdg-desktop-portal-gtk` 作为默认后端
2. 某些 portal 接口（如 ScreenCast）仍需要 GNOME 后端以获得完整功能
3. 遇到 Wayland 应用功能异常时，优先检查 xdg-desktop-portal 配置和服务状态
