{ pkgs, ... }:

{
  imports = [
    ../hardware/baruk.nix
    ../modules/common.nix
    ../modules/stylix.nix
    ../modules/wireless.nix
    ../modules/ilo-link.nix
    ../modules/home-server/dns.nix
    ../modules/avahi.nix
    ../modules/deploy-target.nix
  ];

  # DL380p Gen8 is legacy BIOS only. GRUB goes in the protective MBR gap of the
  # GPT-labelled array, so /dev/sda needs a bios_grub partition.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    extraConfig = ''
      serial --unit=1 --speed=115200
      terminal_input serial console
      terminal_output serial console
    '';
  };

  # RBSU maps iLO's Virtual Serial Port to COM2. Serial is listed last so it
  # owns /dev/console.
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS1,115200n8"
  ];

  networking = {
    hostName = "baruk";

    interfaces.eno2.useDHCP = true;
  };

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
      libraries = with pkgs; [ stdenv.cc.cc ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      openssl
      gcc
      htop
      iotop
      nmap
      tcpdump
      smartmontools
      pciutils
      usbutils
      ethtool
    ];
  };

  system.stateVersion = "26.11";
}
