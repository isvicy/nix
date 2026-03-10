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
      swtpm.enable = true;
    };
  };

  virtualisation.libvirtd.hooks.qemu = {
    "win11" = pkgs.writeShellScript "vm-win11-hook.sh" (builtins.readFile ./vm-win11-hook.sh);
  };

  environment.systemPackages = [pkgs.psmisc];

  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = [
    "libvirtd"
    "kvm"
  ];
  security.pki.certificateFiles = [./rootCA.pem];
}
