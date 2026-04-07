{ pkgs, ... }:
{
  home.packages = [ pkgs.teams-for-linux ];

  imports = [
    ./common.nix
    ./theme.nix
    ../../programs/hypr/default.nix
    ../../programs/wezterm/default.nix
    ../../programs/stylix.nix
    ../../programs/noctalia/samar.nix
  ];
}
