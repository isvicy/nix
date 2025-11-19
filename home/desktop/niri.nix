{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.niri.homeModules.niri

    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs.dankMaterialShell = {
    enable = true;
    niri.enableSpawn = true;
    niri.enableKeybinds = true;
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    settings = {
      outputs = {
        "HDMI-A-1" = {
          mode = {
            width = 3840;
            height = 2160;
            refresh = 119.880;
          };
          scale = 1;
          variable-refresh-rate = false;
        };
        "HDMI-A-2" = {
          background-color = "#ffffff";
          scale = 2.0;
        };
      };
      spawn-at-startup = [
        {command = ["clipse" "-listen"];}
        {command = ["fcitx5" "-d"];}
      ];
      window-rules = [
        {
          matches = [{app-id = "clipse";}];
          default-column-width = {proportion = 0.25;};
        }
      ];
      binds = with config.lib.niri.actions; {
        "Ctrl+Shift+H".action = spawn "kitty" "--class" "clipse" "-e" "clipse";
        "Mod+T".action = spawn "kitty";
        "Mod+D".action = spawn "fuzzel";
        "Mod+Q".action = close-window;

        "Mod+Left".action = focus-column-left;
        "Mod+Down".action = focus-window-down;
        "Mod+Up".action = focus-window-up;
        "Mod+Right".action = focus-column-right;
        "Mod+H".action = focus-column-left;
        "Mod+J".action = focus-window-down;
        "Mod+K".action = focus-window-up;
        "Mod+L".action = focus-column-right;
        "Mod+Ctrl+Left".action = move-column-left;
        "Mod+Ctrl+Down".action = move-window-down;
        "Mod+Ctrl+Up".action = move-window-up;
        "Mod+Ctrl+Right".action = move-column-right;
        "Mod+Ctrl+H".action = move-column-left;
        "Mod+Ctrl+J".action = move-window-down;
        "Mod+Ctrl+K".action = move-window-up;
        "Mod+Ctrl+L".action = move-column-right;

        "Mod+Shift+Left".action = focus-monitor-left;
        "Mod+Shift+Down".action = focus-monitor-down;
        "Mod+Shift+Up".action = focus-monitor-up;
        "Mod+Shift+Right".action = focus-monitor-right;
        "Mod+Shift+H".action = focus-monitor-left;
        "Mod+Shift+J".action = focus-monitor-down;
        "Mod+Shift+K".action = focus-monitor-up;
        "Mod+Shift+L".action = focus-monitor-right;
        "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
        "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;
        "Print".action.screenshot = [];
        "Ctrl+Print".action.screenshot-screen = [];
        "Alt+Print".action.screenshot-window = [];

        "Mod+F".action = maximize-column;

        "Mod+Shift+E".action = quit;
      };
    };
  };

  home.packages = with pkgs; [
    fastfetch

    mako
    swaybg
    swayidle
    swaylock
    xwayland-satellite

    pavucontrol
    fuzzel
    clipse
    wl-clipboard
    xclip

    adwaita-icon-theme
    seatd
    jaq
  ];
}
