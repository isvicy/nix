{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "nixos.local";
in {
  imports = [../options.nix];

  config = lib.mkIf config.custom.virtualization.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      extraPackages = [
        pkgs.getent
      ];
      daemon.settings = lib.mkMerge [
        {}
        (lib.mkIf (config.custom.nvidia.enable && config.custom.nvidia.enableCDI) {
          features.cdi = true;
          cdi-spec-dirs = ["/etc/cdi"];
        })
      ];
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        address = "/${domain}/127.0.0.1";
      };
    };

    environment.systemPackages = [pkgs.mkcert];
  };
}
