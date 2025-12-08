{pkgs, ...}: {
  # OpenRGB 服务
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "intel";  # Z790 是 Intel 平台
  };

  # SMBus 访问支持（ASUS Aura 通过 SMBus 控制）
  hardware.i2c.enable = true;
  boot.kernelModules = ["i2c-dev"];

  # 安装 CLI 工具
  environment.systemPackages = [pkgs.openrgb-with-all-plugins];
}
