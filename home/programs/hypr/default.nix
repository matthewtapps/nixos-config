{ device, pkgs, ... }:
{
  imports = [
    ./hyprpaper.nix
  ];

  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
  };

  home.file."./.config/hypr/assets" = {
    source = ./assets/default_album.png;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ${builtins.readFile ./hyprland/${device}.conf}
      ${builtins.readFile ./hyprland/common.conf}
    '';
  };

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      ${builtins.readFile ./hyprlock/${device}.conf}
      ${builtins.readFile ./hyprlock/common.conf}
    '';
  };

  home.packages = with pkgs; [
    imagemagick
    (writeShellScriptBin "music-info" ''
      ${builtins.readFile ./scripts/music-info}
    '')
    (writeShellScriptBin "record-region-toggle" ''
      ${builtins.readFile ./scripts/record-region-toggle.sh}
    '')
  ];
}
