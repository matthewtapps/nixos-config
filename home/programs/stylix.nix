{ pkgs, ... }:
{
  stylix = {
    enable = true;

    # Set your theme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-soft.yaml";

    polarity = "dark";

    # Cursor configuration
    cursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e Cursors";
      size = 16;
    };

    # Fonts configuration
    fonts = {
      serif = {
        package = pkgs.geist-font;
        name = "Geist";
      };
      sansSerif = {
        package = pkgs.geist-font;
        name = "Geist";
      };
      monospace = {
        package = pkgs.nerd-fonts.geist-mono;
        name = "GeistMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        terminal = 12;
        desktop = 12;
        popups = 12;
      };
    };

    # Auto-enable for all supported applications
    targets = {
      gtk.enable = true;
      gnome.enable = true;
      hyprland.enable = true;
      kitty.enable = true;
      rofi.enable = true;
      wezterm.enable = true;
      lazygit.enable = true;
      zen-browser.profileNames = [ "Personal" ];
      qt.enable = true;
      spotify-player.enable = true;
      xfce.enable = true;
    };
  };
}
