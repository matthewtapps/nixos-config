# Publishes GCS character sheets as static HTML on the home server. `sheets` is
# the authoritative list: sync-sheets mirrors it with rsync --delete, so removing
# an entry unpublishes it.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.gcsSheets;

  slugs = lib.attrNames cfg.sheets;

  bashItems = f: lib.concatMapStringsSep "\n" (s: "  ${lib.escapeShellArg (f s)}") slugs;

  syncSheets = pkgs.writeShellApplication {
    name = "sync-sheets";
    runtimeInputs = [
      pkgs.gcs
      pkgs.rsync
    ];
    text = ''
      root=${lib.escapeShellArg cfg.libraryRoot}
      template="$root"/${lib.escapeShellArg cfg.template}
      remote=${lib.escapeShellArg cfg.remote}
      remotePath=${lib.escapeShellArg cfg.remotePath}

      slugs=(
      ${bashItems (s: s)}
      )
      paths=(
      ${bashItems (s: cfg.sheets.${s})}
      )

      [ -f "$template" ] || { echo "sync-sheets: template not found: $template" >&2; exit 1; }

      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      out="$work/out"
      mkdir -p "$out"

      index="$out/index.html"
      {
        echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8" />'
        echo '<meta name="viewport" content="width=device-width, initial-scale=1" />'
        echo '<title>Character Sheets</title>'
        echo '<style>body{font-family:sans-serif;max-width:40rem;margin:3rem auto;padding:0 1rem}'
        echo 'li{margin:.5rem 0;font-size:1.2rem}</style></head><body>'
        echo '<h1>Character Sheets</h1><ul>'
      } > "$index"

      for i in "''${!slugs[@]}"; do
        slug=''${slugs[$i]}
        src="$root/''${paths[$i]}"
        [ -f "$src" ] || { echo "sync-sheets: missing sheet: $src" >&2; exit 1; }

        # gcs writes the export beside its input, so export from a scratch copy
        # named for the slug rather than polluting the library.
        cp -- "$src" "$work/$slug.gcs"
        gcs -settings "$work/prefs.json" -log-file "$work/gcs.log" \
          -text "$template" "$work/$slug.gcs"
        mv -- "$work/$slug.html" "$out/$slug.html"
        rm -- "$work/$slug.gcs"

        name=$(basename -- "$src" .gcs)
        echo "<li><a href=\"$slug.html\">$name</a></li>" >> "$index"
        echo "exported $name -> $slug.html"
      done

      echo '</ul></body></html>' >> "$index"

      rsync -az --delete "$out"/ "$remote:$remotePath"/
      echo "published ''${#slugs[@]} sheet(s) to $remote:$remotePath"
    '';
  };
in
{
  options.programs.gcsSheets = {
    enable = lib.mkEnableOption "the sync-sheets GCS publishing script";

    libraryRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/GCS";
      description = "GCS data root that sheet and template paths are relative to.";
    };

    template = lib.mkOption {
      type = lib.types.str;
      default = "Master Library/Output Templates/HTML - PC.html";
      description = "Export template, relative to libraryRoot.";
    };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "kruppe";
      description = "ssh destination serving the sheets.";
    };

    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/gcs-sheets";
      description = "Directory on remote that nginx serves. Mirrored with --delete.";
    };

    sheets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        { nahla = "User Library/salt-heavy/player-characters/Nahla.gcs"; }
      '';
      description = ''
        URL slug -> .gcs path relative to libraryRoot. Each becomes
        https://sheets.mattys.cloud/<slug>.html.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ syncSheets ];
  };
}
