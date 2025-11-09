_: {
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts."mattys.cloud" = {
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
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@mattys.cloud";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    logRefusedConnections = true;
    logRefusedPackets = false;
  };

  users.users.nginx.extraGroups = [ "acme" ];
}
