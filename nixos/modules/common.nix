{ pkgs, ... }:
{
  imports = [
    ./base.nix
    ./user.nix
    ./notes.nix
    ./kanata.nix
  ];

  services.udev.packages = [ pkgs.openocd ];
  users.users.matt.extraGroups = [ "dialout" ];
}
