{pkgs, ...}: {
  environment.pathsToLink = ["/libexec"]; # links /libexec from derivations to /run/current-system/sw

  services.displayManager.defaultSession = "none+i3";

  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    dpi = 192;
    xkb.options = "ctrl:nocaps";
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi # application launcher, the same as dmenu
        dunst # notification daemon
        i3blocks # status bar
        i3lock # default i3 screen locker

        i3status # provide information to i3bar
        i3-gaps # i3 with gaps
        feh # set wallpaper

        xbindkeys # bind keys to commands
        xorg.xdpyinfo # get screen information
        sysstat # get system information

        xorg.xauth
        xorg.xinit
      ];
    };
  };

  services.xrdp = {
    enable = true;
    port = 3390;
    defaultWindowManager = "i3";
    openFirewall = true;
  };
}
