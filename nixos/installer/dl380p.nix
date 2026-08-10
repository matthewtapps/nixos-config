{ modulesPath, pkgs, ... }:

{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  # DL380p Gen8 is legacy BIOS with no usable video once the kernel takes over,
  # so the install is driven over iLO's Virtual Serial Port (RBSU maps it to COM2).
  # The last console= wins for /dev/console, hence serial last.
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS1,115200n8"
  ];

  # Without hpsa the P420i array never appears as /dev/sd*.
  boot.initrd.availableKernelModules = [ "hpsa" ];
  boot.kernelModules = [ "hpsa" ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPm051kBWmtEh3hM2ajmxTTd6wd/70GdspJMSlfBC5DT matt@Matt-DESKTOP-NIXOS"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgseOkSq6JIlNi5appmg5CAmZ7KVpms+o0EOo5PIhWM matt@tehol"
  ];

  networking.hostName = "nixos-installer";

  environment.systemPackages = with pkgs; [
    gptfdisk
    parted
    smartmontools
    tmux
    pciutils
    ethtool
    rsync
    git
  ];
}
