{ config, ... }:

let
  iface = "wlan0";
  ifaceMac = "54:c9:ff:00:07:bf";

  ssid = "the gang gets wifi";
  # Sits below the router's DHCP pool, which starts at .100.
  address = "192.168.0.10";
  prefixLength = 24;
  gateway = "192.168.0.1";
in

{
  # Mutually exclusive with networking.networkmanager, so any host importing this
  # must not import ./networkmanager.nix.
  networking.wireless = {
    enable = true;
    secretsFile = config.sops.secrets.wireless-conf.path;
    networks.${ssid}.pskRaw = "ext:psk_home";
  };

  sops.secrets.wireless-conf = {
    sopsFile = ../../secrets/baruk.yaml;
    # networking.wireless.enableHardening runs wpa_supplicant as its own user,
    # which cannot read a root-owned secret.
    owner = "wpa_supplicant";
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
