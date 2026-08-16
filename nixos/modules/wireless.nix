{ config, ... }:

let
  iface = "wlan0";
  # FILL from `ip -br link` on baruk.
  ifaceMac = "aa:bb:cc:dd:ee:ff";

  # FILL: SSID, and an address outside the router's DHCP pool.
  ssid = "YOUR_SSID";
  address = "192.168.0.10";
  prefixLength = 24;
  gateway = "192.168.0.1";
in

{
  # Mutually exclusive with networking.networkmanager, so any host importing this
  # must not import ./networkmanager.nix.
  networking.wireless = {
    enable = true;

    # nixpkgs only installs the udev rule that restarts wpa_supplicant on wlan
    # hotplug while networking.wireless.interfaces is empty. Naming an interface
    # leaves a replugged USB adapter dead until reboot.
    secretsFile = config.sops.secrets.wireless-conf.path;
    networks.${ssid}.pskRaw = "ext:psk_home";
  };

  sops.secrets.wireless-conf = {
    sopsFile = ../../secrets/baruk.yaml;
    restartUnits = [ "wpa_supplicant.service" ];
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${ifaceMac}", NAME="${iface}"
  '';

  networking = {
    useDHCP = false;
    interfaces.${iface} = {
      useDHCP = false;
      ipv4.addresses = [ { inherit address prefixLength; } ];
    };
    defaultGateway = gateway;
    nameservers = [ gateway "1.1.1.1" ];
  };
}
