_: {
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowTcpForwarding = "yes";
      GatewayPorts = "no";
      PermitTunnel = "no";
      PubkeyAuthentication = true;
      MaxAuthTries = 3;
      MaxSessions = 10;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      AllowUsers = [ "matt" ];  # Add users as needed
    };
    
    extraConfig = ''
      # Strong ciphers only
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      
      # Strong MACs only
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
      
      # Strong key exchange
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2222 ];
}
