{pkgs, ...}: {
  services.displayManager.ly = {
    enable = true;
  };

  environment.etc."xdg/wayland-sessions/niri.desktop".text = ''
    [Desktop Entry]
    Name=Niri
    Comment=A scrollable-tiling Wayland compositor
    Exec=${pkgs.niri}/bin/niri-session
    Type=Application
    DesktopNames=niri
  '';
}
