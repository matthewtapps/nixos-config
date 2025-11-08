# nixos/modules/ssh-hardening.nix
{ config, lib, ... }:

with lib;
let
  cfg = config.services.secure-ssh;
in
{
  options.services.secure-ssh = {
    enable = mkEnableOption "hardened SSH configuration";
    
    port = mkOption {
      type = types.port;
      default = 22;
      description = "SSH port (consider using a non-standard port like 2222)";
    };
    
    allowPasswordAuth = mkOption {
      type = types.bool;
      default = false;
      description = "Allow password authentication (not recommended)";
    };
    
    allowedUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of users allowed to SSH";
      example = [ "matt" ];
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      
      settings = {
        # Disable password authentication - use SSH keys only
        PasswordAuthentication = cfg.allowPasswordAuth;
        PermitRootLogin = "no";
        
        # Security settings
        X11Forwarding = false;
        AllowTcpForwarding = "yes";
        GatewayPorts = "no";
        PermitTunnel = "no";
        
        # Key-based authentication only
        PubkeyAuthentication = true;
        
        # Additional hardening
        MaxAuthTries = 3;
        MaxSessions = 10;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        
        # Restrict to specific users if configured
        AllowUsers = mkIf (cfg.allowedUsers != []) cfg.allowedUsers;
      };
      
      # Use strong key exchange algorithms
      extraConfig = ''
        # Strong ciphers only
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        
        # Strong MACs only
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
        
        # Strong key exchange
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
      '';
    };

    # Firewall rule for SSH
    networking.firewall.allowedTCPPorts = mkIf cfg.enable [ cfg.port ];

    # Fail2ban jail for SSH
    services.fail2ban.jails.sshd = mkIf config.services.secure-fail2ban.enable {
      enabled = true;
      filter = "sshd";
      maxretry = 3;
    };
  };
}
