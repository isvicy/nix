{
  config,
  lib,
  pkgs,
  ...
}: {
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
  };
}

