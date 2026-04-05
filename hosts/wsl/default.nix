{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./wsl.nix

    ../../modules/shared/nix.nix
    ../../modules/shared/common.nix

    ../../modules/nixos/options.nix
    ../../modules/nixos/system.nix
    ../../modules/nixos/virtualization/docker.nix
    ../../modules/nixos/desktop/i3.nix
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

  system.stateVersion = lib.mkForce "24.05";
}
