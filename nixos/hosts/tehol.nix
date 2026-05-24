{ pkgs, ... }:

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
    ../modules/deploy-target.nix
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

  boot.kernelParams = [
    "i915.enable_psr=0"
  ];

  # Turn lockups into clean panic+reboot+EFI-pstore-saved oops instead of a
  # half-frozen state. Full magic SysRq lets us dump task stacks (Alt+SysRq+L/T/W)
  # before forcing a reboot via Alt+SysRq+B if needed.
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.softlockup_panic" = 1;
    "kernel.hardlockup_panic" = 1;
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 10;
  };

  networking = {
    hostName = "tehol";
  };

  networking.firewall.allowedTCPPorts = [ 9192 ];

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
      libraries = with pkgs; [
        stdenv.cc.cc
      ];
    };

  };

  environment = {
    systemPackages = with pkgs; [
      openssl
      thunar
      bun
      gcc
      colmena
    ];
  };

  hardware.rasdaemon.enable = true;

  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
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
