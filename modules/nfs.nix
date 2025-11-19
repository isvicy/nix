{pkgs, ...}: {
  environment.systemPackages = with pkgs; [cifs-utils];

  fileSystems."/mnt/syno" = {
    device = "//192.168.50.177/downloads";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/creds-syno"
      "uid=1000"
      "gid=100"
      "file_mode=0664"
      "dir_mode=0775"
      "iocharset=utf8"
      "vers=3.0"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "noauto"
      "nofail"
    ];
    neededForBoot = false;
  };
}
