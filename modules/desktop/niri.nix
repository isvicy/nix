{
  config,
  pkgs,
  ...
}: {
  services.displayManager.ly.enable = true;
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    fastfetch

    mako
    swaybg
    swayidle
    swaylock
    xwayland-satellite

    pavucontrol
    fuzzel
    clipse
    wl-clipboard
    xclip

    adwaita-icon-theme
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    # Enable Wayland for Chrome/Electron apps
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # fallback default
      xdg-desktop-portal-gnome # brings PipeWire screencast
      xdg-desktop-portal-wlr
    ];
    # wlroots compositor helpers
    wlr.enable = true; # pulls xdg-desktop-portal-wlr
  };

  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.xwayland = {
    serviceConfig = {
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
      Restart = "on-failure";
      Environment = "DISPLAY=:0";
    };
    wantedBy = ["niri.service"];
  };

  security.polkit.enable = true;
}
