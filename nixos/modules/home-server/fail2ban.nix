# nixos/modules/fail2ban.nix
{ config, lib, ... }:

with lib;
let
  cfg = config.services.secure-fail2ban;
in
{
  options.services.secure-fail2ban = {
    enable = mkEnableOption "fail2ban with Home Assistant and Nginx protection";
    
    bantime = mkOption {
      type = types.str;
      default = "1h";
      description = "Duration of ban";
    };
    
    maxretry = mkOption {
      type = types.int;
      default = 5;
      description = "Number of failures before ban";
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = cfg.maxretry;
      bantime = cfg.bantime;
      
      ignoreIP = [
        "127.0.0.1/8"
        "::1"
        # Add your local network range here if you want to exclude it
        # "192.168.0.0/24"
      ];

      jails = {
        # Nginx jail
        nginx-http-auth = {
          enabled = true;
          filter = "nginx-http-auth";
        };
        
        nginx-limit-req = {
          enabled = true;
          filter = "nginx-limit-req";
        };
        
        nginx-botsearch = {
          enabled = true;
          filter = "nginx-botsearch";
        };

        # Home Assistant specific jail
        home-assistant = {
          enabled = true;
          filter = "home-assistant";
          logpath = "/var/lib/home-assistant/home-assistant.log";
          maxretry = cfg.maxretry;
          bantime = cfg.bantime;
        };
      };
    };

    # Create custom filter for Home Assistant
    environment.etc."fail2ban/filter.d/home-assistant.conf".text = ''
      [Definition]
      failregex = ^%(__prefix_line)s.*Login attempt or request with invalid authentication from <HOST>.*$
                  ^%(__prefix_line)s.*\[homeassistant.components.http.ban\] Login attempt or request with invalid authentication from <HOST>.*$
                  ^%(__prefix_line)s.*Possible authentication attempt or login with invalid authentication from <HOST>.*$
      
      ignoreregex =
      
      datepattern = ^%%Y-%%m-%%d %%H:%%M:%%S
    '';

    # Allow fail2ban to modify iptables
    systemd.services.fail2ban.after = [ "network.target" ];
  };
}
