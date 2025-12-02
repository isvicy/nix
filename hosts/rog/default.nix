{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../modules/options.nix

    ../../modules/nvidia/plain.nix
    ../../modules/bluetooth.nix
    ../../modules/audio.nix

    ../../modules/system.nix
    ../../modules/nfs.nix
    ../../modules/virtualization/docker.nix
    ../../modules/virtualization/virt-manager.nix
    ../../modules/k3s.nix

    ../../modules/desktop/wayland.nix
    ../../modules/desktop/xdg.nix
    ../../modules/desktop/displaymanager/greetd.nix
    ../../modules/im/fcitx5.nix
  ];

  custom.nvidia.enable = true;
  custom.nvidia.enableCDI = true;
  custom.virtualization.docker.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # 6.12.35 has issues with gpu card pass-through

  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
    "reboot=pci"  # 使用 PCI 方式重启，解决 Z790 主板 B4 卡住问题
  ];
  boot.initrd.availableKernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];
  boot.plymouth = {
    enable = true;
    font = "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf";
    themePackages = [pkgs.nixos-bgrt-plymouth];
    theme = "nixos-bgrt";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
  };

  services = {
    # for SSD/NVME
    fstrim.enable = true;
  };

  # 缩短关机超时时间，避免卡住（30s 是个平衡点，太短可能导致硬件状态不干净）
  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";
}
