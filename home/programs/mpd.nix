{
  config,
  pkgs,
  ...
}: {
  services.mpd = {
    enable = true;
    musicDirectory = "/mnt/syno/music/";

    extraConfig = ''
      auto_update "yes"

      audio_output {
        type            "pipewire"
        name            "PipeWire Sound Server"
      }

      # for visualizerSupport
      audio_output {
        type    "fifo"
        name    "my_fifo"
        path    "/tmp/mpd.fifo"
        format  "44100:16:2"
      }
    '';
  };

  # mpd client
  programs.ncmpcpp = {
    enable = true;
    package = pkgs.ncmpcpp.override {visualizerSupport = true;};

    mpdMusicDir = config.services.mpd.musicDirectory;

    settings = {
      visualizer_data_source = "/tmp/mpd.fifo";
      visualizer_output_name = "my_fifo";
      visualizer_in_stereo = "yes";
      visualizer_type = "wave";
      visualizer_look = "+|";
    };
  };

  xdg.configFile."rmpc/config.toml".text = ''
    address = "127.0.0.1:6600"
    password = ""

    [theme]
    [theme.album_art]
    disabled = false
    method = "auto"
    max_size_px = 600
  '';

  home.packages = with pkgs; [
    mpc
    rmpc
    ymuse
    playerctl
  ];

  services.mpd-mpris = {
    enable = true;
    mpd.useLocal = true;
  };
}
