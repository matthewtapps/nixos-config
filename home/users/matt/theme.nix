{ pkgs, ... }:
let
  fontPackage = pkgs.geist-font;
  fontName = "Geist";
  fontSize = 12;

  cursorThemePackage = pkgs.simp1e-cursors;
  cursorThemeName = "Simp1e Cursors";
  cursorSize = 16;

  iconThemePackage = pkgs.everforest-gtk-theme;
  iconThemeName = "Everforest-Dark-BL-LB";

  themePackage = pkgs.everforest-gtk-theme;
  themeName = "Everforest-Dark-BL-LB";

  qtPlatformTheme = "gtk";
  qtStyleName = "Everforest-Dark-BL-LB";
in
{
  # home.pointerCursor = {
  #   package = cursorThemePackage;
  #   name = cursorThemeName;
  #   size = cursorSize;
  #   gtk.enable = true;
  #   x11 = {
  #     enable = true;
  #     defaultCursor = "left_ptr";
  #   };
  # };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;
    # font = {
    #   package = fontPackage;
    #   name = fontName;
    #   size = fontSize;
    # };
    # cursorTheme = {
    #   name = cursorThemeName;
    #   package = cursorThemePackage;
    #   size = cursorSize;
    # };
    # theme = {
    #   package = themePackage;
    #   name = themeName;
    # };
    # iconTheme = {
    #   package = iconThemePackage;
    #   name = iconThemeName;
    # };
    gtk3.bookmarks = [
      "file:///home/matt/documents Documents"
      "file:///home/matt/downloads Downloads"
      "file:///home/matt/music Music"
      "file:///home/matt/pictures Pictures"
      "file:///home/matt/templates Templates"
      "file:///home/matt/videos Videos"
      "file:///home/matt/screenshots Screenshots"
    ];
  };

  qt = {
    enable = true;
    # platformTheme.name = qtPlatformTheme;
    # style.name = qtStyleName;
  };
}
