{...}: {
  imports = [
    ../../home/core.nix

    ../../home/programs
    ../../home/services

    ../../home/desktop/niri.nix
  ];

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
      userName = "isvicy";
      userEmail = "isregistermail@gmail.com";
    };
  };
}
