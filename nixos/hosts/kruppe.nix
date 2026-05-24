{ pkgs, ... }:

{
  imports = [
    ../hardware/kruppe.nix
    ../modules/common.nix
    ../modules/desktop.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/home-server/homeassistant.nix
    ../modules/home-server/reverse-proxy.nix
    ../modules/home-server/fail2ban.nix
    # ../modules/home-server/open-webui.nix  # open-webui-frontend-0.9.5 build broken in nixpkgs
    # ../modules/home-server/ssh-hardening.nix
    # ../modules/foundryvtt.nix
    ../modules/avahi.nix
    ../modules/deploy-target.nix
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
    hostName = "kruppe";
  };

  nix.settings.trusted-users = [
    "matt"
    "root"
    "@wheel"
  ];

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
      thunar
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
