{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ../../programs/gcs-sheets.nix ];

  home.packages = with pkgs; [
    gimp
    darktable
    qdirstat
    geeqie
    (writeShellScriptBin "geeqie-show-in-thunar" ''exec thunar "$(dirname "$1")"'')
    # Geeqie's own recursive search follows symlinks and loops on Windows
    # junctions. fd skips symlinks, so build a collection with it instead.
    # Usage: geeqie-scan DIR [-E PATTERN ...]
    (writeShellScriptBin "geeqie-scan" ''
      set -eu
      dir=$1
      shift
      out=''${XDG_CONFIG_HOME:-$HOME/.config}/geeqie/collections/scan.gqv
      mkdir -p "$(dirname "$out")"
      {
        echo "#Geeqie collection"
        ${fd}/bin/fd -H -I -a -t f \
          -e jpg -e jpeg -e png -e gif -e webp -e bmp -e tif -e tiff \
          "$@" . "$dir" | sed 's/.*/"&"/'
        echo "#end"
      } > "$out"
      exec ${geeqie}/bin/geeqie "$out"
    '')
    gcs
    spotify
    discord
    calibre
    qbittorrent
    runelite
    bolt-launcher
  ];

  # Geeqie plugin: right-click a search result to open its folder in Thunar.
  xdg.configFile."geeqie/applications/show-in-thunar.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Show in Thunar
    Exec=geeqie-show-in-thunar %f
    Categories=X-Geeqie;Graphics;
    OnlyShowIn=X-Geeqie;
  '';

  xdg.desktopEntries.gcs = {
    name = "GCS";
    genericName = "Character Sheet Editor";
    comment = "Generic Character Sheet for GURPS";
    exec = "gcs --settings /home/matt/GCS/settings.json %F";
    icon = "gcs";
    terminal = false;
    categories = [
      "Utility"
      "RolePlaying"
    ];
    mimeType = [ "application/x-gcs" ];
  };

  programs.gcsSheets = {
    enable = true;
    sheets = {
      nahla = "User Library/salt-heavy/player-characters/Nahla.gcs";
      nimrod = "User Library/salt-heavy/player-characters/Nimrod.gcs";
      raven = "User Library/salt-heavy/player-characters/Raven.gcs";
      rhysand = "User Library/salt-heavy/player-characters/Rhysand.gcs";
      varani = "User Library/salt-heavy/player-characters/Varani-dae Mbau Dasami.gcs";
    };
  };

  home.activation.createGcsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/GCS
  '';
}
