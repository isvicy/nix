{...}: {
  imports = [
    ../../modules/shared/nix.nix
    ../../modules/shared/common.nix
    ../../modules/darwin/nix.nix
    ../../modules/darwin/system.nix
    ../../modules/darwin/apps.nix
    ../../modules/darwin/host-users.nix
  ];
}
