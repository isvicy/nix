{lib, ...}: {
  services.k3s = {
    enable = true;
    clusterInit = true;
  };

  # 禁用自动启动，需要时手动: sudo systemctl start k3s
  systemd.services.k3s.wantedBy = lib.mkForce [];
}
