{
  username,
  hostname,
  pkgs,
  inputs,
  ...
}: {
  nix.settings = {
    trusted-users = [username];
    experimental-features = "nix-command flakes";
  };
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
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZD8Fl36zcqyYut8vu2Vhcv8m+JcxNhiRDrtM3hxzrv matexpro"
    ];
  };
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

  time.timeZone = "Asia/Shanghai";
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
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];

    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = ["Noto Serif" "Noto Color Emoji"];
      sansSerif = ["Noto Sans" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
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
  ];

  programs.zsh.enable = true;

  environment.variables = {
    EDITOR = "nvim"; # this is a must for zsh edit-command-line to use neovim as editor.
    VISUAL = "nvim";
  };

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    tzdata # we need this to use asia timezone.
    btop
    tmux
    bc # for tmux conf patch
    curl
    wget
    iotop
    nethogs
    parted
    jq
    fzf
    vim
    ripgrep
    yazi
    alejandra
    proxychains-ng
    iperf3
    dnsutils # `dig` + `nslookup`
    aria2
    inetutils
    socat
    gost

    iotop
    iftop
    strace
    ltrace
    lsof
    pciutils # lspci

    # git && git plugin
    git
    git-lfs
    git-filter-repo
    tig
    lazygit
    delta

    # common dev stuff
    gcc
    gnumake
    cmake
    pkg-config
    libtool
    autoconf
    automake
    binutils
    sqlite

    # archives
    zip
    xz
    unzip
    p7zip
    zstd

    killall

    glibc.getent
  ];

  swapDevices = [];

  system.activationScripts.getentSymlink.text = ''
    mkdir -p /usr/bin
    ln -sf ${pkgs.glibc.getent}/bin/getent /usr/bin/getent
  '';

  system.stateVersion = "25.05";
}
