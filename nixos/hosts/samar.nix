{ pkgs, ... }:

{
  imports = [
    ../hardware/samar.nix
    ../modules/common.nix
    ../modules/desktop.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/virtualization.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/wireguard.nix
    ../modules/avahi.nix
    ../modules/deploy-target.nix
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        enableCryptodisk = true;
      };
    };
  };

  networking = {
    hostName = "samar";
  };

  # 9192 existing; 8420/8421 personal ahvi (UI/ingest), 8430/8431 work ahvi.
  networking.firewall.allowedTCPPorts = [
    9192
    8420
    8421
    8430
    8431
  ];

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
      libraries = with pkgs; [
        stdenv.cc.cc
      ];
    };

  };

  environment = {
    systemPackages = with pkgs; [
      openssl
      thunar
      bun
      gcc
    ];
  };

  hardware = {
    bluetooth.enable = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  # Don't delete
  system.stateVersion = "24.05";
}
