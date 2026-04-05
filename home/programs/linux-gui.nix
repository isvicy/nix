{pkgs, ...}: {
  home.packages = with pkgs; [
    # Communication
    feishu
    telegram-desktop
    wechat

    # File Management
    nautilus

    # Productivity
    _1password-gui
    anki
    obsidian

    # Browsers
    chromium

    # Editors (GUI)
    zed-editor

    # Input automation (X11/Wayland)
    xdotool
    wtype
    dotool

    # Terminal image support
    ueberzugpp

    # Android
    scrcpy

    # AI tools
    confirmo
  ];
}
