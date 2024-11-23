{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/desktop.nix
    # ./modules/impermanence/desktop.nix
    ./modules/common.nix
    ./modules/wayland.nix
    ./modules/virtualization.nix
    ./modules/nvidia.nix
    ./modules/audio.nix
    ./modules/thunar.nix
    ./modules/networkmanager.nix
    ./modules/cloudflare-warp.nix
    ./modules/steam.nix
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
    hostName = "Matt-DESKTOP-NIXOS";
    firewall.enable = false;
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
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      openssl
      xfce.thunar
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
