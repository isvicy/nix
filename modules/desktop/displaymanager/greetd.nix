{
  username,
  pkgs,
  lib,
  config,
  ...
}: let
  # 等待 GPU 设备就绪的脚本
  waitForGpu = pkgs.writeShellScript "wait-for-gpu" ''
    # 等待 /dev/dri/card* 设备出现，最多等待 30 秒
    # nvidia-drm 初始化时间不稳定，直接检查设备比依赖 systemd 服务更可靠
    timeout=30
    while [ $timeout -gt 0 ]; do
      if ls /dev/dri/card* >/dev/null 2>&1; then
        echo "GPU device ready"
        exit 0
      fi
      sleep 0.5
      timeout=$((timeout - 1))
    done
    echo "Warning: GPU device not found after 30s, proceeding anyway"
    exit 0
  '';
in {
  # greetd display manager
  services.greetd = let
    session = {
      command = "${pkgs.niri}/bin/niri-session";
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
  # 直接等待 /dev/dri/card* 设备出现，比依赖 systemd 服务更可靠
  systemd.services.greetd = lib.mkIf config.custom.nvidia.enable {
    serviceConfig.ExecStartPre = ["${waitForGpu}"];
  };
}
