{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./theme.nix
    ../../programs/ags/default.nix
    ../../programs/hypr/default.nix
    ../../programs/lan-mouse.nix
    ../../programs/rofi/default.nix
    ../../programs/wezterm/default.nix
    ../../programs/azure-vpn.nix
    ../../programs/orcaslicer.nix
    ../../programs/mangohud.nix
  ];

  home.packages = with pkgs; [
    freecad
  ];
}
