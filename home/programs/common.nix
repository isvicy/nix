{
  config,
  pkgs,
  ...
}: let
  packages = with pkgs; [
    # ===================
    # System Utilities
    # ===================
    btop # System monitor
    chafa # Image to ASCII converter
    glow # Markdown renderer
    graphviz # Graph visualization (dot command)
    openssl # Cryptography toolkit
    scrcpy # Android screen mirroring
    stow # Symlink manager
    ueberzugpp # Image display in terminal
    yt-dlp # Video downloader

    # ===================
    # Shell & Terminal
    # ===================
    atuin # Shell history
    direnv # Directory-specific environment variables
    fzy # Fuzzy finder
    sesh # Session manager
    zoxide # Smart directory navigation

    # ===================
    # Development - General
    # ===================
    code2prompt # Convert code to LLM prompts
    fd # Fast find alternative
    presenterm # Terminal presentations
    rclone # Cloud storage sync
    tree-sitter # Parser generator

    # ===================
    # Development - Go
    # ===================
    go
    gotools
    golines
    gofumpt
    golangci-lint
    gopls # LSP
    grpcurl
    delve # Debugger

    # ===================
    # Development - Rust
    # ===================
    rustup # Remember to run `rustup default stable` after installing
    cargo-cache
    cargo-expand

    # ===================
    # Development - Python
    # ===================
    python3
    python3Packages.pipx
    python3Packages.black # Formatter
    poetry # Package manager
    uv # Fast Python package installer
    ruff # Linter & formatter
    ty # Type checker

    # ===================
    # Development - C/C++
    # ===================
    bear # Build EAR (compile_commands.json generator)

    # ===================
    # Development - Node.js/Deno
    # ===================
    nodejs_22
    deno
    pnpm
    moon # Monorepo build tool

    # ===================
    # Development - Lua
    # ===================
    lua5_1
    lua51Packages.luarocks

    # ===================
    # LSP Servers
    # ===================
    nil # Nix LSP
    lua-language-server
    bash-language-server
    marksman # Markdown LSP
    terraform-ls

    # ===================
    # Code Formatters & Linters
    # ===================
    nixpkgs-fmt # Nix
    alejandra # Nix
    beautysh # Bash
    shfmt # Shell
    shellcheck # Shell linter
    stylua # Lua
    yq-go # YAML, JSON, XML
    sqlfluff # SQL
    rubyPackages.htmlbeautifier

    # ===================
    # Databases
    # ===================
    litecli # SQLite CLI
    postgresql
    tcl # Required by Redis

    # ===================
    # Container & Cloud
    # ===================
    crane # Container image tool
    skopeo # Container image operations
    oras # OCI Registry As Storage

    # ===================
    # Kubernetes
    # ===================
    kind # Kubernetes in Docker
    kubernetes-helm
    kubectl
    k9s # Kubernetes TUI
    talosctl # Talos Linux CLI

    # ===================
    # Infrastructure
    # ===================
    terraform

    # ===================
    # Editors & IDEs
    # ===================
    zed-editor

    # ===================
    # Applications - Browsers
    # ===================
    chromium

    # ===================
    # Applications - Communication
    # ===================
    feishu # Lark/飞书
    telegram-desktop

    # ===================
    # Applications - Productivity
    # ===================
    _1password-gui
    _1password-cli
    anki # Flashcards
    obsidian # Note-taking

  ];
in {
  home.packages =
    packages
    ++ [
    ];

  home.sessionVariables = {
    UV_PYTHON_DOWNLOADS = "never";
  };

  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: [ps.magick];
    extraPackages = [pkgs.imagemagick];
  };
}
