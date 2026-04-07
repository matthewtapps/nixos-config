{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    thunderbird
    aerc
    teams-for-linux
  ];
}
