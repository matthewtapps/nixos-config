{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    gtk3 = {
      bookmarks = [
        "file:///home/matt/documents Documents"
        "file:///home/matt/downloads Downloads"
        "file:///home/matt/music Music"
        "file:///home/matt/pictures Pictures"
        "file:///home/matt/templates Templates"
        "file:///home/matt/videos Videos"
        "file:///home/matt/screenshots Screenshots"
      ];
    };
  };
  qt = {
    enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
