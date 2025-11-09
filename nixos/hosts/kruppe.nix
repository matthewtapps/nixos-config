{ pkgs, lib, ... }:

{
  imports = [
    ../hardware/kruppe.nix
    ../modules/common.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/home-server/homeassistant.nix
    ../modules/home-server/reverse-proxy.nix
    ../modules/home-server/fail2ban.nix
    # ../modules/home-server/ssh-hardening.nix
    ../modules/avahi.nix
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
