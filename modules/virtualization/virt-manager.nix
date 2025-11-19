{
  config,
  pkgs,
  username,
  ...
}: {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };

  virtualisation.libvirtd.hooks.qemu = {
    "win11" = pkgs.writeShellScript "vm-win11-hook.sh" (builtins.readFile ./vm-win11-hook.sh);
  };

  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = [
    "libvirtd"
    "kvm"
  ];
}
