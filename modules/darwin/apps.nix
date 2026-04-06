{...}: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };

    masApps = {};

    taps = [
      "morantron/tmux-fingers"
      "tonisives/tap"
      "tw93/tap"
      "productdevbook/tap"
      "anomalyco/tap"
    ];

    # Only mac-specific or broken-in-nixpkgs CLI tools.
    # All cross-platform CLI tools are in home-manager common.nix.
    brews = [
      "curl" # nixpkgs curl is broken on macOS
      "iproute2mac" # macOS-only
      "carthage" # iOS/macOS build tool
      "pngpaste" # macOS pasteboard utility
      "tw93/tap/mole"
      "morantron/tmux-fingers/tmux-fingers"
      "anomalyco/tap/opencode"
    ];

    casks = [
      # browsers
      "google-chrome"
      "arc"

      # terminals & editors
      "ghostty"
      "wezterm"
      "zed"

      # dev tools
      "orbstack"

      # communication & productivity
      "discord"
      "wechat"
      "raycast"
      "anki"
      "obsidian"
      "chatwise"
      "feishu"

      # media & reference
      "iina"
      "bilibili"

      # system utilities
      "jordanbaird-ice"
      "squirrel-app"
      "tonisives/tap/ovim"

      # fonts
      "font-maple-mono-nf-cn"
      "font-maple-mono-nf"
    ];
  };
}
