_: {
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts."mattys.cloud" = {  # CHANGE THIS
      forceSSL = true;
      enableACME = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          
          # Security headers
          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Referrer-Policy "no-referrer-when-downgrade" always;
          
          # Increase timeouts for Home Assistant
          proxy_connect_timeout 3600s;
          proxy_send_timeout 3600s;
          proxy_read_timeout 3600s;
        '';
      };
    };
  };

  # ACME (Let's Encrypt) configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "me@mattys.cloud";  # CHANGE THIS
  };

  # Open firewall for HTTP and HTTPS only
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    logRefusedConnections = true;
    logRefusedPackets = false;
  };

  # Ensure nginx user can access certificates
  users.users.nginx.extraGroups = [ "acme" ];
}
