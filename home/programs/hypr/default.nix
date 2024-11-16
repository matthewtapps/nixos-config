{ device, ... }:
let
  system = {
    "nuc" = [ (import ./nuc.nix) ];
    "desktop" = [ (import ./desktop.nix) ];

  };
in
{
  imports = [
    ./hyprpaper.nix
  ] ++ (system.${device} or [ ]);

  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
  };
}
