{ mypkgs, ... }:

{
  imports = [
    ../hardware/desktop.nix
    ../modules/common.nix
    ../modules/wayland.nix
    ../modules/virtualization.nix
    ../modules/nvidia.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/steam.nix
    ../modules/azure-vpn.nix
    ../modules/homeassistant.nix
    # ../modules/foundryvtt.nix
  ];

  nixpkgs.pkgs = mypkgs;

  programs.azure-vpn = {
    enable = true;
    users = [ "matt" ];
  };

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

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.home-assistant-ac = {
    enable = true;
    esp32Address = "192.168.0.206";  # Your ESP32's IP address
    port = 8123;
    openFirewall = true;
  };

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
