{
  lib,
  username,
  ...
}: {
  wsl.enable = true;
  wsl.defaultUser = username;
  wsl.useWindowsDriver = true;
  wsl.startMenuLaunchers = true;
  wsl.interop.includePath = false;

  system.stateVersion = lib.mkForce "24.05";
}
