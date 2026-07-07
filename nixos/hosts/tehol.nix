{ pkgs, ... }:

{
  imports = [
    ../hardware/tehol.nix
    ../modules/common.nix
    ../modules/stylix.nix
    ../modules/wayland.nix
    ../modules/virtualization.nix
    ../modules/demo-vm.nix
    ../modules/audio.nix
    ../modules/thunar.nix
    ../modules/networkmanager.nix
    ../modules/wireguard.nix
    ../modules/laptop.nix
    # ../modules/aic8800.nix
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
    "i915.enable_fbc=0"
    "i915.enable_dc=0"

    # The MT7925U USB WiFi wedges its firmware in monitor mode through the dock's
    # tunnelled USB hubs (but not on a direct port). Disabling USB3 LPM for the
    # adapter and USB autosuspend stops control transfers stalling on that path.
    "usbcore.quirks=0846:9072:k"
    "usbcore.autosuspend=-1"
  ];

  boot.initrd.kernelModules = [ "i915" ];

  # Turn lockups into clean panic+reboot+EFI-pstore-saved oops instead of a
  # half-frozen state. Full magic SysRq lets us dump task stacks (Alt+SysRq+L/T/W)
  # before forcing a reboot via Alt+SysRq+B if needed.
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.nmi_watchdog" = 1;
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

  # Auto-authorize the ThinkPad Thunderbolt 4 Dock so DP-alt-mode tunnels
  # come up on hot-plug (security level is "user" on this machine).
  services.hardware.bolt.enable = true;

  # Keep NetworkManager off USB WiFi dongles (the internal card is PCI) so the
  # sniffer can own them outright, with no managed->unmanaged handoff to bounce
  # the netdev mid-use.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="net", ENV{DEVTYPE}=="wlan", ENV{ID_BUS}=="usb", ENV{NM_UNMANAGED}="1"
  '';

  # Pin the shared wpa_supplicant to the internal card. Otherwise NixOS's
  # "restart wpa_supplicant on any wlan add/remove" udev rule fires every time a
  # USB dongle re-enumerates and drops the internal wifi with it.
  networking.wireless.interfaces = [ "wlp0s20f3" ];

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
