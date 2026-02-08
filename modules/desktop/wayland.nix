{...}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };
}
