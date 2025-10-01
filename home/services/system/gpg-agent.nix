{pkgs, ...}: {
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  home.sessionVariables.GPG_TTY = "$TTY";
}
