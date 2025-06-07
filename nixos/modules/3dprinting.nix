{ pkgs, ... }:
{
  services.klipper = {
    enable = true;
    user = "matt";
    group = "users";
    configFile = "/home/matt/printing/klipper-config/printer.cfg";
  };

  services.moonraker = {
    enable = true;
    address = "0.0.0.0";
    allowSystemControl = true;
    user = "matt";
    group = "users";
    stateDir = "/home/matt/printing/moonraker"; # This creates /var/lib/moonraker owned by matt
    settings = {
      authorization = {
        trusted_clients = [
          "127.0.0.1"
          "::1"
          "localhost"
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "FE80::/10"
        ];
        cors_domains = [
          "http://localhost:*"
          "http://127.0.0.1:*"
        ];
      };
    };
  };

  systemd.services.fluidd-server = {
    description = "Fluidd Web Interface Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "matt";
      Group = "users";
      ExecStartPre = pkgs.writeShellScript "setup-fluidd" ''
        FLUIDD_DIR="/home/matt/printing/fluidd"
        if [ ! -f "$FLUIDD_DIR/index.html" ]; then
          mkdir -p "$FLUIDD_DIR"
          cd /tmp
          ${pkgs.wget}/bin/wget -O fluidd.zip https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip
          ${pkgs.unzip}/bin/unzip -o fluidd.zip -d "$FLUIDD_DIR"
          rm fluidd.zip
        fi
      '';
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /home/matt/printing/fluidd && ${pkgs.python3}/bin/python -m http.server 3000'";
      Restart = "always";
      RestartSec = "10";
    };
  };
}
