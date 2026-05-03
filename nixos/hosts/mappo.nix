{ pkgs, ... }:

{
  imports = [
    ../hardware/mappo.nix
    ../modules/common.nix
    ../modules/wayland.nix
    ../modules/stylix.nix
    ../modules/virtualization.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/steam.nix
    # ../modules/azure-vpn.nix
    ../modules/avahi.nix
    ../modules/laptop.nix
  ];

  # programs.azure-vpn = {
  #   enable = true;
  #   users = [ "matt" ];
  # };

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub.enable = true;
    grub.device = "nodev";
    grub.efiSupport = true;
    grub.memtest86.enable = true;
  };

  networking = {
    hostName = "mappo";
    firewall.enable = false;
  };

  nix.settings.trusted-users = [
    "matt"
    "root"
    "@wheel"
  ];

  networking.hosts = {
    "127.0.0.1" = [
      "rosterfy2.localhost.com"
      "sub.rosterfy2.localhost.com"
      "localstack"
      "gcloud-emulator"
    ];
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
      thunar
      bun
      gcc
    ];
  };

  hardware = {
    bluetooth.enable = true;
  };

  boot.kernelParams = [
    "amd_pstate=active"
    "acpi_backlight=native"
  ];

  # NFC chip declared in ACPI but not physically present (or broken) — driver
  # spins in an interrupt loop causing ~80% load on one core at boot.
  boot.blacklistedKernelModules = [ "nxp-nci" "nxp-nci-i2c" ];
  hardware.sensor.iio.enable = false;

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Don't delete
  system.stateVersion = "24.05";
}
