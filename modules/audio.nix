{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  # rtkit for PipeWire realtime scheduling
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };
}
