# nixos/hosts/nuc.nix
{ pkgs, ... }:

{
  imports = [
    ../hardware/nuc.nix
    ../modules/common.nix
    ../modules/wayland.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/home-server/homeassistant.nix
    ../modules/home-server/reverse-proxy.nix
    ../modules/home-server/fail2ban.nix
    ../modules/home-server/ssh-hardening.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };
  };

  networking = {
    hostName = "NUC-NIXOS";
    # Firewall is now enabled via reverse-proxy module
    # DON'T set firewall.enable = false anymore!
  };

  # Configure your domain and email for Let's Encrypt
  services.secure-reverse-proxy = {
    enable = true;
    domain = "matty.cloud"; # ⚠️ CHANGE THIS to your actual domain
    email = "me@matty.cloud"; # ⚠️ CHANGE THIS to your email
    homeAssistantPort = 8123;
  };

  # Enable fail2ban for intrusion prevention
  services.secure-fail2ban = {
    enable = true;
    bantime = "1h";
    maxretry = 5;
  };

  # Secure SSH configuration
  services.secure-ssh = {
    enable = true;
    port = 2222; # Non-standard port - more secure than 22
    allowPasswordAuth = false; # SSH keys only
    allowedUsers = [ "matt" ]; # Add other users if needed
  };

  # Enable Home Assistant
  services.home-assistant-ac = {
    esp32Address = "192.168.0.206";
    port = 8123;
    openFirewall = false; # Don't open directly - nginx proxies instead
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = false;
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ stdenv.cc.cc ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      openssl
      xfce.thunar
      bun
      gcc
      # Useful tools for monitoring
      htop
      iotop
      nmap
      tcpdump
    ];
  };

  hardware = {
    bluetooth.enable = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  system.stateVersion = "24.05";
}
