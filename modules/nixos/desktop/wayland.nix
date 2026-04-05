{...}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    # Stem darkening: embolden font stems at small sizes to compensate for
    # the thinner appearance of grayscale AA (which Wayland forces).
    # Custom darkening-parameters ramp: full darkening at 500-2500 ppem, off at 4000+.
    FREETYPE_PROPERTIES = "autofitter:no-stem-darkening=0 autofitter:darkening-parameters=500,0,1000,500,2500,500,4000,0 cff:no-stem-darkening=0 type1:no-stem-darkening=0 t1cid:no-stem-darkening=0";
  };
}
