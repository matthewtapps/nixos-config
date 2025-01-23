{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/thinkpad.nix
    # ./modules/impermanence/desktop.nix
    ./modules/common.nix
    ./modules/wayland.nix
    ./modules/virtualization.nix
    ./modules/audio.nix
    ./modules/thunar.nix
    ./modules/networkmanager.nix
    ./modules/cloudflare-warp.nix
    ./modules/steam.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub.enable = true;
    grub.device = "nodev";
    grub.efiSupport = true;
  };

  networking = {
    hostName = "Matt-THINKPAD-NIXOS";
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

  powerManagement.enable = true;

  # Don't delete
  system.stateVersion = "24.05";
}
