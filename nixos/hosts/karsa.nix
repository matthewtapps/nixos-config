{ mypkgs, ... }:

{
  imports = [
    ../hardware/karsa.nix
    ../modules/common.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/virtualization.nix
    ../modules/nvidia.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/steam.nix
    ../modules/azure-vpn.nix
    ../modules/avahi.nix
    ../modules/ollama.nix
  ];

  networking.hosts = {
    "127.0.0.1" = [
      "rosterfy2.localhost.com"
      "sub.rosterfy2.localhost.com"
      "localstack"
      "gcloud-emulator"
    ];
  };

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
    hostName = "karsa";
    firewall.enable = false;
  };

  nix.settings.trusted-users = [
    "matt"
    "root"
    "@wheel"
  ];

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
