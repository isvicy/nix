{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };
}
