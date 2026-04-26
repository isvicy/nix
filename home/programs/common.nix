{
  pkgs,
  lib,
  ...
}: let
  packages = with pkgs; [
    # ===================
    # System Utilities
    # ===================
    btop
    gh
    chafa
    glow
    graphviz
    openssl
    stow
    yt-dlp
    ffmpeg
    mpv
    skim
    sox
    gettext
    tree
    ncdu
    just
    cloc
    httpie
    nmap
    imagemagick
    resvg
    caddy

    # ===================
    # Shell & Terminal
    # ===================
    tmux
    bc
    fzf
    fzy
    vim
    unstable.neovim
    ripgrep
    yazi
    atuin
    sesh
    zoxide

    # ===================
    # Secrets Management
    # ===================
    age
    pass
    sops
    gitleaks
    gnupg
    pinentry-tty
    pre-commit

    # ===================
    # Network & Transfer
    # ===================
    curl
    wget
    aria2
    socat
    iperf3
    dnsutils
    proxychains-ng
    gost
    rclone

    # ===================
    # Development - General
    # ===================
    code2prompt
    fd
    ast-grep
    presenterm
    tree-sitter
    git
    git-lfs
    git-filter-repo
    tig
    lazygit
    tempo # provide tempo-cli
    grafana-loki # provide logcli
    mycli
    pgcli
    litecli
    pg-schema-diff # used when making ddl changes to postgres

    # ===================
    # Development - Build Tools
    # ===================
    gcc
    gnumake
    cmake
    pkg-config
    libtool
    autoconf
    automake

    # ===================
    # Development - Go
    # ===================
    go
    (lib.lowPrio gotools)
    golines
    gofumpt
    golangci-lint
    gopls
    grpcurl
    grpcui
    delve

    # ===================
    # Development - Rust
    # ===================
    rustup
    cargo-cache
    cargo-expand

    # ===================
    # Development - Python
    # ===================
    python3
    python3Packages.pipx
    python3Packages.black
    poetry
    uv
    ruff
    ty
    isort

    # ===================
    # Development - C/C++
    # ===================
    bear

    # ===================
    # Development - Node.js/Deno
    # ===================
    nodejs_22
    deno
    pnpm
    moon

    # ===================
    # Development - Lua
    # ===================
    lua5_1
    lua51Packages.luarocks

    # ===================
    # LSP Servers
    # ===================
    nil
    lua-language-server
    bash-language-server
    marksman
    terraform-ls
    harper
    golangci-lint-langserver
    basedpyright
    docker-language-server
    yaml-language-server
    vtsls

    # ===================
    # Code Formatters & Linters
    # ===================
    nixpkgs-fmt
    alejandra
    beautysh
    shfmt
    shellcheck
    stylua
    yq-go
    sqlfluff
    rubyPackages.htmlbeautifier
    tombi
    buf
    hadolint
    prettierd

    # ===================
    # Archives
    # ===================
    zip
    xz
    unzip
    p7zip
    zstd

    # ===================
    # GNU Replacements
    # ===================
    gnused
    gnutar
    gawk

    # ===================
    # Databases
    # ===================
    litecli
    postgresql
    sqlite
    tcl

    # ===================
    # Container & Cloud
    # ===================
    crane
    skopeo
    oras

    # ===================
    # Kubernetes
    # ===================
    kind
    kubernetes-helm
    kubectl
    k9s
    talosctl

    # ===================
    # Infrastructure
    # ===================
    terraform

    # ===================
    # gRPC & API
    # ===================
    jsonnet
  ];
in {
  home.packages =
    packages
    ++ [
    ];

  home.sessionVariables = {
    UV_PYTHON_DOWNLOADS = "never";
  };
}
