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

  # Google Chrome Beta from browser-previews flake
  home.packages = with inputs.browser-previews.packages.${pkgs.system}; [
    google-chrome-beta
  ];
}
