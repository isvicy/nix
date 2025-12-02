{
  username,
  pkgs,
  lib,
  config,
  ...
}: {
  # greetd display manager
  services.greetd = let
    session = {
      command = "${pkgs.niri-unstable}/bin/niri-session";
      user = username;
    };
  in {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = session;
      initial_session = session;
    };
  };

  # 等待 NVIDIA GPU 就绪后再启动 greetd，避免 niri EGL 初始化失败
  # 注意：dev-nvidia0.device 不会被触发（设备通过 mknod 创建），改为依赖 CDI generator 服务
  systemd.services.greetd = lib.mkIf config.custom.nvidia.enableCDI {
    after = ["nvidia-container-toolkit-cdi-generator.service"];
    wants = ["nvidia-container-toolkit-cdi-generator.service"];
  };
}
