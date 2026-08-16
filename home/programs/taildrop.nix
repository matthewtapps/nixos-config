{ config, pkgs, ... }:

let
  # %h is the systemd specifier for the home directory; ExecStart gets no shell.
  downloadDir = "%h/Downloads/taildrop";
  queueFile = "\${XDG_RUNTIME_DIR:-/tmp}/taildrop-queue";

  syncd = pkgs.callPackage ../../nixos/packages/taildrop-syncd { };

  # Collects whatever is being sent into a NUL-separated queue, then hands the
  # panel over to Noctalia. NUL is what survives filenames containing newlines.
  taildrop-send = pkgs.writeShellApplication {
    name = "taildrop-send";
    runtimeInputs = [
      config.programs.noctalia.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnutar
      pkgs.gzip
      pkgs.wl-clipboard
    ];
    text = ''
      queue="${queueFile}"
      : > "$queue"

      # The send is asynchronous, so staged clipboard images and archives cannot
      # be deleted on the way out. /tmp here is disk-backed and not cleaned on
      # boot, so each run clears what earlier runs left behind.
      base="''${TMPDIR:-/tmp}"
      find "$base" -maxdepth 1 -name 'taildrop-*' -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true

      stage=$(mktemp -d -t taildrop-XXXXXX)
      stamp=$(date +%Y%m%d-%H%M%S)

      enqueue() { printf '%s\0' "$1" >> "$queue"; }

      from_clipboard() {
        local types
        types=$(wl-paste --list-types 2>/dev/null || true)
        case "$types" in
          *image/png*)
            wl-paste --type image/png > "$stage/clipboard-$stamp.png"
            enqueue "$stage/clipboard-$stamp.png"
            ;;
          *)
            wl-paste --no-newline > "$stage/clipboard-$stamp.txt" 2>/dev/null || true
            if [ -s "$stage/clipboard-$stamp.txt" ]; then
              enqueue "$stage/clipboard-$stamp.txt"
            fi
            ;;
        esac
      }

      case "''${1:-}" in
        --clipboard)
          from_clipboard
          ;;
        --text)
          shift
          printf '%s' "$*" > "$stage/note-$stamp.txt"
          enqueue "$stage/note-$stamp.txt"
          ;;
        *)
          for path in "$@"; do
            if [ -d "$path" ]; then
              # `tailscale file cp` refuses directories, so they travel as an archive.
              archive="$stage/$(basename "$path")-$stamp.tar.gz"
              tar -czf "$archive" -C "$(dirname "$path")" "$(basename "$path")"
              enqueue "$archive"
            elif [ -e "$path" ]; then
              enqueue "$(realpath "$path")"
            fi
          done
          ;;
      esac

      if [ ! -s "$queue" ]; then
        exit 0
      fi
      noctalia msg panel-open matt/taildrop:panel send
    '';
  };
in
{
  home.packages = [
    taildrop-send
    syncd
  ];

  systemd.user.services.taildrop-syncd = {
    Unit = {
      Description = "Shared text buffer synced across the tailnet";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${syncd}/bin/taildrop-syncd";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # `file get` blocks in a one-hour long poll against the local tailscaled and
  # wakes only when a file lands, so this idles at zero cost.
  systemd.user.services.taildrop-receive = {
    Unit = {
      Description = "Receive Taildrop files as they arrive";
      After = [ "network.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${downloadDir}";
      ExecStart = "${pkgs.tailscale}/bin/tailscale file get --loop --verbose --conflict=rename ${downloadDir}";
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Managing this file makes it a read-only symlink, so Thunar's "Configure
  # custom actions" dialog can no longer save. Edit it here.
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon>utilities-terminal</icon>
    	<name>Open Terminal Here</name>
    	<submenu></submenu>
    	<unique-id>1720478334460516-1</unique-id>
    	<command>exo-open --working-directory %f --launch TerminalEmulator</command>
    	<description>Example for a custom action</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    </action>
    <action>
    	<icon>document-send</icon>
    	<name>Send via Taildrop</name>
    	<submenu></submenu>
    	<unique-id>1755400000000000-1</unique-id>
    	<command>${taildrop-send}/bin/taildrop-send %F</command>
    	<description>Send the selection to another Tailscale device</description>
    	<range>*</range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    	<audio-files/>
    	<image-files/>
    	<other-files/>
    	<text-files/>
    	<video-files/>
    </action>
    </actions>
  '';
}
