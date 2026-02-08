{pkgs, ...}: {
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Grayscale AA for XWayland apps to match Wayland native behavior.
  # Wayland compositors force grayscale AA for native apps, so we align
  # XWayland apps to get consistent rendering everywhere.
  xresources.properties = {
    "Xft.antialias" = 1;
    "Xft.hinting" = 1;
    "Xft.hintstyle" = "hintfull";
    "Xft.rgba" = "none";
    "Xft.lcdfilter" = "none";
  };
}
