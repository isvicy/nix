{username, ...}: {
  imports = [
    ./base.nix
    ./programs/common.nix
    ./programs/terminal.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
