{
  config,
  pkgs,
  ...
}: let
  packages = with pkgs; [
    # misc
    glow
    btop
    ueberzugpp
    chafa

    # util
    sesh
    presenterm
    rclone # s3
    graphviz # for dot command
    openssl
    yt-dlp

    # kube
    kind # for kube test
    kubernetes-helm
    kubectl
    k9s
    fzy

    # programming
    code2prompt
    go
    gotools
    golines
    golangci-lint
    grpcurl
    rustup # remeber to run `rustup default stable` to set default toolchain version after installing
    # rust stuff
    cargo-cache
    cargo-expand
    postgresql
    # c stuff
    bear
    # neovim
    gofumpt
    tree-sitter
    fd
    ## deps
    lua51Packages.luarocks
    lua5_1
    # lsp
    nil
    lua-language-server
    gopls
    ruff
    delve
    stylua
    python3Packages.black
    marksman
    ty # python
    terraform-ls
    # formatter
    nixpkgs-fmt
    alejandra # nix
    beautysh
    yq-go # yaml, json, xml
    sqlfluff
    rubyPackages.htmlbeautifier
    shfmt
    shellcheck
    # frontend
    nodejs_22
    deno

    # container
    crane
    skopeo
    oras

    # python3
    python3
    python3Packages.pipx
    poetry
    uv

    # zsh
    atuin
    direnv
    zoxide
    stow

    # redis
    tcl

    # editor
    zed-editor

    scrcpy
    _1password-gui
    _1password-cli

    feishu
    pnpm
    moon

    telegram-desktop
    obsidian
    terraform
    talosctl

    chromium
  ];
in {
  home.packages =
    packages
    ++ [
    ];

  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: [ps.magick];
    extraPackages = [pkgs.imagemagick];
  };
}
