{ mypkgs, ... }:

{
  imports = [
    ../hardware/thinkpad.nix
    ../modules/common.nix
    ../modules/wayland.nix
    ../modules/stylix.nix
    ../modules/virtualization.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/steam.nix
    ../modules/azure-vpn.nix
  ];

  programs.azure-vpn = {
    enable = true;
    users = [ "matt" ];
  };

  nixpkgs.pkgs = mypkgs;

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
      libraries = with mypkgs; [ stdenv.cc.cc ];
    };

  };

  environment = {
    systemPackages = with mypkgs; [
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
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # Control cpu throttling and temps
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "schedutil";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

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
  security.pam.services.hyprlock.fprintAuth = true;

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
