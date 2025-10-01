{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./wsl.nix

    ../../modules/system.nix
    ../../modules/virtualization/docker.nix
    ../../modules/i3.nix
  ];

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
    pinentryPackage = pkgs.pinentry-curses;
  };

  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    EDITOR = "nvim"; # this is a must for zsh edit-command-line to use neovim as editor.
    VISUAL = "nvim";
    LIBSQLITE = "${pkgs.sqlite.out}/lib/libsqlite3.so";
  };
}
