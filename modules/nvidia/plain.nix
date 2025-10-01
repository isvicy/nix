{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../options.nix];

  config = lib.mkIf config.custom.nvidia.enable {
    boot.kernelParams = [
      "nvidia-drm.modeset=1"
    ];
    boot.blacklistedKernelModules = ["nouveau"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    hardware.graphics.enable = true;

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia-container-toolkit.enable = config.custom.nvidia.enableCDI && config.custom.virtualization.docker.enable;

    environment.systemPackages = with pkgs; [
      unigine-valley
    ];
  };
}

