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
      "x-systemd.mount-timeout=10"
      "x-systemd.unmount-timeout=5"  # 卸载超时 5 秒
      "_netdev"
      "soft"       # 软挂载，超时后返回错误而不是无限等待
      "timeo=50"   # CIFS 请求超时 5 秒 (单位 0.1 秒)
      "noauto"
      "nofail"
    ];
    neededForBoot = false;
  };
}
