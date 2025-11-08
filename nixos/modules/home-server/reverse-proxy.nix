# nixos/modules/reverse-proxy.nix
{ config, lib, ... }:

with lib;
let
  cfg = config.services.secure-reverse-proxy;
in
{
  options.services.secure-reverse-proxy = {
    enable = mkEnableOption "secure reverse proxy with SSL";
    
    domain = mkOption {
      type = types.str;
      example = "home.example.com";
      description = "Your domain name pointing to your static IP";
    };
    
    email = mkOption {
      type = types.str;
      example = "you@example.com";
      description = "Email for Let's Encrypt notifications";
    };
    
    homeAssistantPort = mkOption {
      type = types.port;
      default = 8123;
      description = "Port where Home Assistant is running";
    };
  };

  config = mkIf cfg.enable {
    # Nginx reverse proxy
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.${cfg.domain} = {
        forceSSL = true;
        enableACME = true;
        
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.homeAssistantPort}";
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
      defaults.email = cfg.email;
    };

    # Open firewall for HTTP and HTTPS only
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
      
      # Log dropped packets for monitoring
      logRefusedConnections = true;
      logRefusedPackets = false;  # Set to true for debugging
    };

    # Ensure nginx user can access certificates
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
