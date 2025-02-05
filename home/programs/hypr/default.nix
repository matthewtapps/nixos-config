{ device, ... }:
{
  imports = [
    ./hyprpaper.nix
  ];

  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
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
}
