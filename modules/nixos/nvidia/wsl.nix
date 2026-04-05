{
  config,
  pkgs,
  ...
}: {
  hardware.nvidia = {
    modesetting.enable = true;
    # don't use gui setting from nvidia
    nvidiaSettings = false;
    open = false;
  };
  hardware.nvidia-container-toolkit = {
    enable = true;
    # see: https://github.com/nix-community/NixOS-WSL/issues/578#issuecomment-2464795408
    mount-nvidia-executables = false;
  };
  services.xserver.videoDrivers = ["nvidia"];
  systemd.services = {
    nvidia-cdi-generator = {
      description = "Generate nvidia cdi";
      wantedBy = ["docker.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.nvidia-docker}/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --nvidia-ctk-path=${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk";
      };
    };
  };
  environment.systemPackages = with pkgs; [
    vulkan-tools
    vulkan-loader
    mesa
  ];
  environment.sessionVariables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
    LD_LIBRARY_PATH = [
      "/usr/lib/wsl/lib"
      "${pkgs.linuxPackages.nvidia_x11}/lib"
      "${pkgs.ncurses5}/lib"
    ];
    MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
  };
  systemd.services."xrdp-sesman".environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
}
