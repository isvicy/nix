{
  pkgs,
  lib,
  ...
}: {
  nix.package = pkgs.nix;
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
}
