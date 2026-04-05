{
  username,
  hostname,
  pkgs,
  ...
}: {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = ["04:45"];
  };

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "docker" "uinput"];
    packages = [pkgs.gnupg];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZD8Fl36zcqyYut8vu2Vhcv8m+JcxNhiRDrtM3hxzrv matexpro"
    ];
  };
  hardware.uinput.enable = true;
  programs.gnupg.agent.enable = true;
  security.sudo.extraRules = [
    {
      users = [username];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [
    "zh_CN.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  fonts = {
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "full";
      };
      subpixel = {
        rgba = "none";
        lcdfilter = "none";
      };
      defaultFonts = {
        serif = ["Noto Serif" "Noto Color Emoji"];
        sansSerif = ["Noto Sans" "Noto Color Emoji"];
        monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };

  services.openssh = {
    enable = true;
    ports = [10022];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  networking = {
    hostName = "${hostname}";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    glib
    ncurses

    nss
    nspr
    dbus
    atk
    pango
    cairo
    cups
    expat
    fontconfig
    freetype
    gdk-pixbuf
    gtk3
    libdrm
    libgbm
    libnotify
    libxcb
    libxkbcommon
    mesa
    libglvnd
    udev

    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver

    at-spi2-atk
    at-spi2-core
    alsa-lib
    libpulseaudio
  ];

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    tzdata
    parted
    iotop
    nethogs
    iftop
    strace
    lsof
    pciutils
    killall
    glibc.getent
    binutils
    inetutils
  ];

  swapDevices = [];

  system.activationScripts.getentSymlink.text = ''
    mkdir -p /usr/bin
    ln -sf ${pkgs.glibc.getent}/bin/getent /usr/bin/getent
  '';
}
