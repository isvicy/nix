{pkgs, ...}: {
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Match fontconfig settings for XWayland apps (Qt5/GTK X11 apps like WeChat)
  # These read Xft.* from Xresources, not fontconfig
  xresources.properties = {
    "Xft.antialias" = 1;
    "Xft.hinting" = 1;
    "Xft.hintstyle" = "hintfull";
    "Xft.rgba" = "rgb";
    "Xft.lcdfilter" = "lcddefault";
  };
}
