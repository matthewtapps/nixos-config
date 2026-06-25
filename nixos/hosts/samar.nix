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

  # 9192 existing. ahvi dev-instances (see ahvi justfile `dev-instance`):
  #   work (default): api 8420, otlp-ingest 8421, vite UI 5173
  #   personal:       api 8430, otlp-ingest 8431, vite UI 5174
  # The vite UI ports (5173/5174) must be open for the browser to reach the
  # frontend over the LAN; 8421/8431 for LAN OTLP ingest; 8420/8430 for direct
  # query-API hits (the browser doesn't need these — vite proxies /api itself).
  networking.firewall.allowedTCPPorts = [
    9192
    8420
    8421
    8430
    8431
    5173
    5174
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
