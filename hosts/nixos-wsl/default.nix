{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./wsl.nix

    ../../modules/options.nix
    ../../modules/system.nix
    ../../modules/virtualization/docker.nix
    ../../modules/desktop/i3.nix
  ];

  environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];

  networking.networkmanager.enable = lib.mkForce false;

  services.dnsmasq.enable = lib.mkForce false;

  programs.gnupg.agent = {
    enableSSHSupport = false;
    pinentryPackage = pkgs.pinentry-tty;
  };

  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    LIBSQLITE = "${pkgs.sqlite.out}/lib/libsqlite3.so";
  };
}
