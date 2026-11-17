{ config, pkgs, ... }:

{
  imports = [
    ../hardware/crokus.nix
    ./crokus-disk.nix
    ../modules/base.nix
    ../modules/deploy-target.nix
    ../modules/networkmanager.nix
    ../modules/audio.nix
    ../modules/avahi.nix
  ];

  # disko fills in grub.devices from the EF02 partition.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  hardware.enableRedistributableFirmware = true;

  networking.hostName = "crokus";

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enabling flatpak also pulls in GNOME Software as the app store.
  services.flatpak.enable = true;
  systemd.services.flatpak-add-flathub = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig.Type = "oneshot";
    script = "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
  };

  hardware.bluetooth.enable = true;

  sops.secrets = {
    matt-password = {
      sopsFile = ../../secrets/users.yaml;
      neededForUsers = true;
    };
    brittany-password = {
      sopsFile = ../../secrets/users.yaml;
      neededForUsers = true;
    };
  };

  users.mutableUsers = false;
  users.users = {
    brittany = {
      isNormalUser = true;
      description = "Brittany";
      extraGroups = [ "networkmanager" ];
      hashedPasswordFile = config.sops.secrets.brittany-password.path;
    };
    matt = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.matt-password.path;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = import ../modules/authorized-keys.nix;
    };
  };

  services.openssh.settings.PasswordAuthentication = false;

  environment.systemPackages = [ pkgs.firefox ];

  system.stateVersion = "26.11";
}
