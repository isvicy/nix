{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../modules/shared/nix.nix
    ../../modules/shared/common.nix

    ../../modules/nixos/options.nix
    ../../modules/nixos/system.nix

    ../../modules/nixos/nvidia/plain.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/audio.nix

    ../../modules/nixos/nfs.nix
    ../../modules/nixos/virtualization/docker.nix
    ../../modules/nixos/virtualization/virt-manager.nix
    ../../modules/nixos/k3s.nix

    ../../modules/nixos/desktop/wayland.nix
    ../../modules/nixos/desktop/xdg.nix
    ../../modules/nixos/desktop/displaymanager/greetd.nix
    ../../modules/nixos/im/fcitx5.nix
  ];

  custom.nvidia.enable = true;
  custom.nvidia.enableCDI = true;
  custom.virtualization.docker.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
    "reboot=efi"  # 使用 EFI 运行时服务重启
    "xhci_hcd.quirks=270336"  # XHCI_SPURIOUS_REBOOT + XHCI_SPURIOUS_WAKEUP
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
    fstrim.enable = true;
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

  # clipboard-sync disabled: crashes with Niri (wayland-client 0.29.4 incompatible)
  services.clipboard-sync.enable = false;

  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-tty;

  system.stateVersion = "25.05";
}
