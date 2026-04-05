{
  pkgs,
  username,
  hostname,
  ...
}: {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
  system.primaryUser = username;

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
    shell = pkgs.zsh;
  };

  nix.settings.trusted-users = [username];
}
