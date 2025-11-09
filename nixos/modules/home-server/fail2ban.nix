_: {
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "192.168.0.0/24"
    ];

    jails = {
      nginx-http-auth = {
        settings = {
          enabled = true;
          filter = "nginx-http-auth";
          logpath = "/var/log/nginx/error.log";
          backend = "auto";
        };
      };
      
      nginx-limit-req = {
        settings = {
          enabled = true;
          filter = "nginx-limit-req";
          logpath = "/var/log/nginx/error.log";
          backend = "auto";
        };
      };
      
      nginx-botsearch = {
        settings = {
          enabled = true;
          filter = "nginx-botsearch";
          logpath = "/var/log/nginx/access.log";
          backend = "auto";
        };
      };

      home-assistant = {
        settings = {
          enabled = true;
          filter = "home-assistant";
          logpath = "/var/lib/hass/home-assistant.log";
          backend = "auto";
        };
      };
      
      sshd = {
        settings = {
          enabled = true;
          filter = "sshd";
          maxretry = 3;
        };
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

  systemd.services.fail2ban.after = [ "network.target" ];
}
