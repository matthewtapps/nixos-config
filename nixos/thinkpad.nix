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

  # Laptop lid
  services.logind = {
    lidSwitch = "lock";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "lock";
  };

  # Control cpu throttling and temps
  services.auto-cpufreq.enable = true;
  services.thermald.enable = true;
  boot.kernelParams = [
    "amd_pstate=guided"
    "acpi_backlight=native"
  ];
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  # Battery power profiles
  services.upower = {
    enable = true;
    ignoreLid = true;
  };

  services.devmon.enable = true;
  services.udisks2.enable = true;

  hardware.sensor.iio.enable = false;

  # Fingerprint reader
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = false;

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  # Don't delete
  system.stateVersion = "24.05";
}
