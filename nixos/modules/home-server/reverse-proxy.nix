_: {
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts = {
      "mattys.cloud" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:8123";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
          '';
        };
      };

      "foundry.mattys.cloud" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:30000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_pass_header Authorization;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            client_max_body_size 300M;
          '';
        };
      };

      "llm.mattys.cloud" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
      };

      # AC controller (ESP32 at 192.168.0.206) — HTTP-only device fronted by
      # nginx for TLS. Accessible from the home LAN and over Tailscale only;
      # ACME validates via the public record but the deny rule keeps the
      # outside world out, since the firmware has no auth of its own.
      "ac.mattys.cloud" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://192.168.0.206";
          extraConfig = ''
            allow 192.168.0.0/24;
            allow 100.64.0.0/10;
            deny all;
          '';
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@mattys.cloud";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
    logRefusedConnections = true;
    logRefusedPackets = false;
  };

  users.users.nginx.extraGroups = [ "acme" ];
}
