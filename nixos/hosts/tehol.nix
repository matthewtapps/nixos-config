{ mypkgs, ... }:

{
  imports = [
    ../hardware/tehol.nix
    ../modules/common.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/virtualization.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/wireguard.nix
    ../modules/laptop.nix
    ../modules/aic8800.nix
    ../modules/avahi.nix
  ];

  nixpkgs.pkgs = mypkgs;

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };
  };

  boot.kernelParams = [
    "i915.enable_psr=0"
  ];

  networking = {
    hostName = "tehol";
  };

  networking.firewall.allowedTCPPorts = [ 9090 ];

  nix.settings.trusted-users = [
    "matt"
    "root"
    "@wheel"
  ];

  programs = {
    wireshark.enable = true;
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

  hardware.rasdaemon.enable = true;

  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      extraPackages = with mypkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024;
    }
  ];

  # Don't delete
  system.stateVersion = "24.05";
}
