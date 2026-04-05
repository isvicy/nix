{lib, ...}: {
  options = {
    custom.nvidia.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable NVIDIA GPU support";
    };

    custom.nvidia.enableCDI = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable CDI (Container Device Interface) support for NVIDIA";
    };

    custom.virtualization.docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Docker virtualization";
    };
  };
}
