{
  device,
  lib,
  pkgs,
  ...
}:
let
  # Public halves of secrets/lan-mouse/<host>.pem.
  fingerprints = {
    karsa = "25:d3:12:27:3f:18:03:40:6a:cc:de:4f:b6:90:b6:44:bf:73:1b:ec:4a:47:4a:ff:23:c0:f4:8f:5b:9a:37:25";
    kruppe = "b0:fb:72:97:5d:bf:18:0b:3b:a6:b3:f3:05:41:36:1f:f5:b0:d1:fb:4f:cf:54:b3:99:81:dd:92:b0:fd:63:34";
    samar = "ce:b7:4d:c0:34:dd:1c:78:19:38:48:b6:9a:4b:6a:26:94:0c:3c:bc:5e:f2:67:43:5f:88:50:62:28:58:c8:8b";
    mappo = "49:f1:c4:d3:42:f2:64:6f:ef:e8:0b:1a:51:f9:6e:6c:3e:7e:03:fa:4b:c8:12:09:69:c5:a2:68:4c:2b:a0:85";
    tehol = "a2:61:5e:4e:f5:09:f7:9c:35:f3:1e:63:0c:8c:94:86:1d:57:58:78:f0:e8:9f:cd:ee:28:ba:86:ad:df:70:e3";
  };

  syncd = pkgs.callPackage ../../nixos/packages/taildrop-syncd { };

  configFile = (pkgs.formats.toml { }).generate "lan-mouse.toml" {
    port = 4242;
    release_bind = [
      "KeyLeftAlt"
      "KeyU"
    ];
    capture_backend = "layer-shell";
    cert_path = "/run/secrets/lan-mouse-cert";
    authorized_fingerprints = lib.mapAttrs' (host: fingerprint: lib.nameValuePair fingerprint host) (
      removeAttrs fingerprints [ device ]
    );
  };
in
lib.mkIf (fingerprints ? ${device}) {
  home.packages = [ pkgs.lan-mouse ];

  # Lan Mouse rewrites this on every runtime change; the read-only link makes
  # that write fail harmlessly, so the plugin's changes last until a restart.
  xdg.configFile."lan-mouse/config.toml" = {
    source = configFile;
    force = true;
  };

  systemd.user.services.lan-mouse = {
    Unit = {
      Description = "Lan Mouse";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse daemon";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.lan-mouse-layoutd = {
    Unit = {
      Description = "Lan Mouse layout synced across the tailnet";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${syncd}/bin/taildrop-syncd";
      Environment = [ "TAILDROP_SYNCD_PORT=8472" ];
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
