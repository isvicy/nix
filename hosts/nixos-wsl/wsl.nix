{
  config,
  username,
  ...
}: {
  wsl.enable = true;
  wsl.defaultUser = username;
  wsl.useWindowsDriver = true;
  wsl.startMenuLaunchers = true;
  wsl.interop.includePath = false;

  system.stateVersion = "24.05";
}
