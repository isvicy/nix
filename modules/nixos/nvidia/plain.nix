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
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };

    services.xserver.videoDrivers = ["nvidia"];

    # Required for nvidia-vaapi-driver
    environment.sessionVariables = {
      NVD_BACKEND = "direct";
      # Prevent NVIDIA FXAA post-processing from blurring text on Wayland
      __GL_ALLOW_FXAA_USAGE = "0";
    };

    hardware.nvidia-container-toolkit.enable = config.custom.nvidia.enableCDI && config.custom.virtualization.docker.enable;
  };
}
