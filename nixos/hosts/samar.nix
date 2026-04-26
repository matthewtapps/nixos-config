{ mypkgs, ... }:

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
  ];

  nixpkgs.pkgs = mypkgs;

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

  networking.firewall.allowedTCPPorts = [ 9090 ];

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
      libraries = with mypkgs; [
        stdenv.cc.cc
      ];
    };

  };

  environment = {
    systemPackages = with mypkgs; [
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
