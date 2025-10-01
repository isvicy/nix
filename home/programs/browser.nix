{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.twilight # or .beta
  ];

  programs.firefox.enable = true;
  programs.zen-browser = {
    enable = true;

    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
    };
  };
}
