{ pkgs, ... }:

let
  check-lang-versions = pkgs.writeShellApplication {
    name = "check-lang-versions";
    runtimeInputs = with pkgs; [ curl jq gnused gnugrep ];
    text = ''
      CACHE="$HOME/.cache/version-checks"
      mkdir -p "$CACHE"

      save() {
        local name=$1 val=$2
        [[ -n $val && $val != null ]] && printf '%s\n' "$val" > "$CACHE/''${name}.latest"
      }

      # Node.js: latest LTS release
      node=$(curl -sf 'https://nodejs.org/dist/index.json' \
        | jq -r '[.[] | select(.lts != false)][0].version[1:]' || true)
      save node "$node"

      # Python: latest stable from endoflife.date
      python=$(curl -sf 'https://endoflife.date/api/python.json' \
        | jq -r '.[0].latest' || true)
      save python "$python"

      # Rust: stable channel manifest
      rust=$(curl -sf 'https://static.rust-lang.org/dist/channel-rust-stable.toml' \
        | grep '^version = "' | head -1 \
        | sed 's/version = "\([^ ]*\).*/\1/' || true)
      save rust "$rust"

      # Go: latest stable release
      go=$(curl -sf 'https://go.dev/dl/?mode=json' \
        | jq -r '[.[] | select(.stable)][0].version[2:]' || true)
      save go "$go"
    '';
  };
in
{
  home.packages = [ check-lang-versions ];

  systemd.user.services.check-lang-versions = {
    Unit = {
      Description = "Check latest language runtime versions";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${check-lang-versions}/bin/check-lang-versions";
    };
  };

  systemd.user.timers.check-lang-versions = {
    Unit.Description = "Periodically check latest language runtime versions";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "6h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
