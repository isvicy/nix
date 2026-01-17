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
    package = pkgs.niri;
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
        {command = ["sh" "-c" "cd /home/isvicy/github/ququ && pnpm run dev"];}
      ];
      layout = {
        shadow = {
          enable = false;
        };
        preset-column-widths = [
          {proportion = 0.33;}
          {proportion = 0.5;}
          {proportion = 0.66;}
          {proportion = 1.0;}
        ];
        default-column-width = {proportion = 0.5;};

        gaps = 6;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };

        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "left";
          corner-radius = 20.0;
          gap = -12.0;
          gaps-between-tabs = 10.0;
          width = 4.0;
          length.total-proportion = 0.1;
        };
      };
      window-rules = [
        {
          geometry-corner-radius = let
            radius = 12.0;
          in {
            bottom-left = radius;
            bottom-right = radius;
            top-left = radius;
            top-right = radius;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }
        {
          matches = [
            {app-id = "zen";}
            {app-id = "firefox";}
            {app-id = "chromium-browser";}
            {app-id = "edge";}
          ];
          open-maximized = true;
        }
        {
          matches = [
            {
              app-id = "firefox";
              title = "Picture-in-Picture";
            }
          ];
          open-floating = true;
          default-floating-position = {
            x = 32;
            y = 32;
            relative-to = "bottom-right";
          };
          default-column-width = {fixed = 480;};
          default-window-height = {fixed = 270;};
        }
        {
          matches = [
            {
              app-id = "zen";
              title = "Picture-in-Picture";
            }
          ];
          open-floating = true;
          default-floating-position = {
            x = 32;
            y = 32;
            relative-to = "bottom-right";
          };
          default-column-width = {fixed = 480;};
          default-window-height = {fixed = 270;};
        }
        {
          matches = [{title = "Picture in picture";}];
          open-floating = true;
          default-floating-position = {
            x = 32;
            y = 32;
            relative-to = "bottom-right";
          };
        }
        {
          matches = [{app-id = "pavucontrol";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "pavucontrol-qt";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "dialog";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "popup";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "file-roller";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "org.gnome.FileRoller";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "nm-connection-editor";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "blueman-manager";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "xdg-desktop-portal-gtk";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "org.kde.polkit-kde-authentication-agent-1";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "pinentry";}];
          open-floating = true;
        }
        {
          matches = [{title = "Progress";}];
          open-floating = true;
        }
        {
          matches = [{title = "File Operations";}];
          open-floating = true;
        }
        {
          matches = [{title = "Copying";}];
          open-floating = true;
        }
        {
          matches = [{title = "Moving";}];
          open-floating = true;
        }
        {
          matches = [{title = "Properties";}];
          open-floating = true;
        }
        {
          matches = [{title = "Downloads";}];
          open-floating = true;
        }
        {
          matches = [{title = "file progress";}];
          open-floating = true;
        }
        {
          matches = [{title = "Confirm";}];
          open-floating = true;
        }
        {
          matches = [{title = "Authentication Required";}];
          open-floating = true;
        }
        {
          matches = [{title = "Notice";}];
          open-floating = true;
        }
        {
          matches = [{title = "Warning";}];
          open-floating = true;
        }
        {
          matches = [{title = "Error";}];
          open-floating = true;
        }

        {
          matches = [
            {is-floating = true;}
          ];
          shadow.enable = true;
        }
        {
          matches = [{app-id = "clipse";}];
          default-column-width = {proportion = 0.25;};
        }
        {
          matches = [{app-id = "anki";}];
          open-floating = true;
          default-floating-position = {
            x = 512;
            y = 512;
            relative-to = "bottom-right";
          };
          default-column-width = {fixed = 1080;};
          default-window-height = {fixed = 1080;};
        }
        # ququ 录音状态指示器
        {
          matches = [{title = "录音指示器";}];
          open-floating = true;
          default-floating-position = {
            x = 0;
            y = 30;
            relative-to = "bottom";
          };
          default-column-width = {fixed = 80;};
          default-window-height = {fixed = 28;};
        }
      ];
      binds = with config.lib.niri.actions; {
        "Ctrl+Shift+H".action = spawn "kitty" "--class" "clipse" "-e" "clipse";
        "Mod+T".action = spawn "kitty";
        "Mod+D".action = spawn "fuzzel";
        "Mod+Shift+Space".action = spawn "/home/isvicy/github/ququ/ququ-ctl" "toggle";
        "Mod+Q".action = close-window;
        "Mod+S".action = switch-preset-column-width;
        "Mod+F".action = maximize-column;

        "Mod+1".action = set-column-width "33%";
        "Mod+2".action = set-column-width "50%";
        "Mod+3".action = set-column-width "66%";
        "Mod+4".action = set-column-width "100%";

        # "Mod+Space".action = toggle-window-floating;
        "Mod+W".action = toggle-column-tabbed-display;

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
