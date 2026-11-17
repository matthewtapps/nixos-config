{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    ../modules/avahi.nix
    # nixos-anywhere reconnects as root once it sees an installer.
    ../modules/deploy-target.nix
  ];

  services.openssh.enable = true;

  users.users.matt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = import ../modules/authorized-keys.nix;
  };

  # Reachable as nixos-kexec.local if DHCP hands out a different address.
  networking.hostName = "nixos-kexec";
  system.stateVersion = config.system.nixos.release;
  networking.networkmanager.enable = lib.mkForce true;
  networking.firewall.enable = false;
  # Full linux-firmware makes kexec --load crawl; carry only this laptop's wifi and GPU blobs.
  hardware.firmware = [
    (pkgs.runCommand "crokus-firmware" { } ''
      mkdir -p $out/lib/firmware
      cp -rL ${pkgs.linux-firmware}/lib/firmware/{iwlwifi-7265*,i915} $out/lib/firmware/
    '')
  ];

  systemd.services.full-brightness = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig.Type = "oneshot";
    script = "for b in /sys/class/backlight/*; do [ -e $b ] && cat $b/max_brightness > $b/brightness; done; true";
  };

  # Kexec drops the old OS's wifi, so pick up any *.nmconnection left at the
  # root or /boot of a local partition before NetworkManager starts.
  systemd.services.import-wifi = {
    wantedBy = [ "NetworkManager.service" ];
    before = [ "NetworkManager.service" ];
    wants = [ "systemd-udev-settle.service" ];
    after = [ "systemd-udev-settle.service" ];
    path = with pkgs; [
      util-linux
      gawk
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      dst=/etc/NetworkManager/system-connections
      mkdir -p /run/wifi-src "$dst"
      for dev in $(lsblk -lnpo NAME,FSTYPE | awk '$2 ~ /^(vfat|ext4)$/ {print $1}'); do
        mount -o ro "$dev" /run/wifi-src || continue
        cp /run/wifi-src/*.nmconnection /run/wifi-src/boot/*.nmconnection "$dst"/ 2>/dev/null || true
        umount /run/wifi-src
      done
      chmod 600 "$dst"/* 2>/dev/null || true
    '';
  };

  environment.systemPackages = with pkgs; [
    gptfdisk
    parted
    rsync
    git
  ];

  # The kexec tree plus a static kexec, for hosts that cannot install kexec-tools.
  # kexec_file_load hands the EFI tables and framebuffer to the new kernel; the
  # stock script's kexec_load leaves UEFI laptops hung on a blank screen.
  system.build.kexecBundle =
    let
      boot = pkgs.writeScript "kexec-boot" ''
        #!/bin/sh
        set -e
        cd "$(dirname "$0")"
        ./kexec --load ./bzImage --kexec-syscall-auto --initrd=./initrd.gz \
          --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
        # A bare kexec -e leaves iwlwifi running and the next kernel's probe
        # times out (-110); a clean systemd shutdown quiesces it first.
        systemctl kexec
      '';
    in
    pkgs.runCommand "nixos-kexec.tar.gz" { } ''
      mkdir kexec
      cp -L ${config.system.build.kernel}/${config.system.boot.loader.kernelFile} kexec/bzImage
      cp -L ${config.system.build.netbootRamdisk}/initrd kexec/initrd.gz
      cp ${pkgs.pkgsStatic.kexec-tools}/bin/kexec kexec/
      cp ${boot} kexec/kexec-boot
      tar czf $out kexec
    '';
}
