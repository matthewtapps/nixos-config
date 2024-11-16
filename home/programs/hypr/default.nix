{ system }:
let
  system = {
    "nuc" = [ (import ./nuc.nix) ];
    "desktop" = [ (import ./desktop.nix) ];
    
    };
    in
{
  imports = [
    ./hyprpaper.nix
    ./hyprlock.nix
  ] ++ (system.{system} or [ ]);

  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
  };
}
