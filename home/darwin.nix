{username, pkgs, lib, ...}: {
  imports = [
    ./base.nix
    ./programs/common.nix
    ./programs/terminal.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.11";

    sessionVariables = {
      LIBRARY_PATH = "${lib.makeLibraryPath [pkgs.libiconv]}\${LIBRARY_PATH:+:$LIBRARY_PATH}";
    };
  };

  programs.home-manager.enable = true;
}
