{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      kitty
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      ghostty
    ];
}
