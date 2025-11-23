{...}: {
  imports = [
    ../../home/core.nix

    ../../home/programs

    ../../home/desktop/niri.nix
  ];

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      settings.user = {
        name = "isvicy";
        email = "isregistermail@gmail.com";
      };
    };
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
    };
  };
}
