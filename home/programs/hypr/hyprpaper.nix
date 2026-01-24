_:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = "~/.config/hypr/bg3.jpg";
      wallpaper = [
        {
          monitor = "DP-1";
          path = "~/.config/hypr/bg3.jpg";
        }
      ];
    };
  };
}
