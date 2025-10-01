{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    kitty
    ghostty
  ];
}
