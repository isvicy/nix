{
  username,
  pkgs,
  ...
}: {
  # greetd display manager
  services.greetd = let
    session = {
      command = "${pkgs.niri-unstable}/bin/niri-session";
      user = username;
    };
  in {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = session;
      initial_session = session;
    };
  };
}
