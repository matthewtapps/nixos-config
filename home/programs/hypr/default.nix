_:
{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
    ./hyprlock.nix
  ];

  home.file."./.config/hypr/bg3.jpg" = {
    source = ./bg3.jpg;
  };
}
