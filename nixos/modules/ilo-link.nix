# Point-to-point link between an onboard NIC and the iLO4 dedicated management
# port. iLO grants full hardware control including power and console, so it is
# kept off the LAN and reachable only by jumping through baruk.
{ ... }:

let
  iface = "eno1";

  # Overlapping the LAN subnet here would make iLO routable from it.
  baruk = "10.42.0.1";
  ilo = "10.42.0.5";
in

{
  networking.interfaces.${iface} = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = baruk;
        prefixLength = 24;
      }
    ];
  };

  # Forwarding is off by default, and enabling libvirt turns it on globally,
  # which would expose this link to the LAN.
  networking.firewall.extraCommands = ''
    iptables -A FORWARD -o ${iface} -j DROP
    iptables -A FORWARD -i ${iface} -j DROP
  '';

  environment.etc."ilo-link.info".text = ''
    baruk ${iface}: ${baruk}/24
    ilo dedicated port: ${ilo}/24
  '';
}
