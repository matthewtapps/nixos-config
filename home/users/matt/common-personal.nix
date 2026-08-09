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
    gcs
    spotify
    discord
    calibre
    qbittorrent
    runelite
    bolt-launcher
  ];

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
