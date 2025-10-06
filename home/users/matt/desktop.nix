{ pkgs, ... }:
{
  imports = [
    ./common.nix
    ./theme.nix
    ../../programs/ags/default.nix
    ../../programs/hypr/default.nix
    ../../programs/lan-mouse.nix
    ../../programs/wezterm/default.nix
    ../../programs/rofi.nix
    ../../programs/azure-vpn.nix
    ../../programs/orcaslicer.nix
    ../../programs/mangohud.nix
    ../../programs/freecad.nix
  ];
}
