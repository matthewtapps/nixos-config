{ lib, ... }:

let
  domain = "home.arpa";

  hosts = {
    router = "192.168.0.1";
    baruk = "192.168.0.10";
    mappo = "192.168.0.111";
    samar = "192.168.0.170";
    kruppe = "192.168.0.181";
    karsa = "192.168.0.194";
    esp32s3-008818 = "192.168.0.197";
    esp32-ac = "192.168.0.206";
    tehol = "192.168.0.213";
  };
in

{
  services.dnsmasq = {
    enable = true;

    # Left off so the nameserver below stays the single source of truth; the
    # option would otherwise append 127.0.0.1 and wire up resolvconf.
    resolveLocalQueries = false;

    settings = {
      # wlan0 gets its address well after dnsmasq starts, and bind-interfaces
      # would fail on a socket that does not exist yet.
      bind-dynamic = true;
      interface = [
        "wlan0"
        "lo"
      ];

      no-resolv = true;
      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];

      # Avahi already answers for .local across the fleet, so serving it here
      # would collide with mDNS.
      inherit domain;
      local = "/${domain}/";

      domain-needed = true;
      bogus-priv = true;
      cache-size = 1000;

      host-record = lib.mapAttrsToList (name: ip: "${name},${name}.${domain},${ip}") hosts;
    };
  };

  networking = {
    nameservers = lib.mkForce [ "127.0.0.1" ];
    firewall.interfaces.wlan0 = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
