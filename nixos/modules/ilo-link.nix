# Point-to-point link between an onboard NIC and the iLO4 dedicated management
# port. iLO4 has unauthenticated RCE history (CVE-2017-12542) and HPE gates the
# firmware fixes behind a support contract, so it is kept off the LAN.
{ ... }:

let
  # FILL from `ip -br link` on baruk; the 331FLR enumerates as eno1..eno4.
  iface = "eno1";

  # Overlapping the LAN subnet here would make iLO routable from it.
  baruk = "10.99.0.1";
  ilo = "10.99.0.2";
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

  # Addresses to enter when configuring iLO through RBSU at POST.
  environment.etc."ilo-link.info".text = ''
    baruk ${iface}: ${baruk}/24
    ilo dedicated port: ${ilo}/24
  '';
}
