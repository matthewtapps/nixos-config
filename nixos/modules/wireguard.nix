{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.wireguard-tools ];

  # Split-DNS for the work WireGuard VPN. Without a split-capable resolver the
  # plain resolvconf backend concatenates every link's nameservers into one flat
  # /etc/resolv.conf, so the VPN's work DNS (172.20.20.2) ends up first and ALL
  # lookups — not just work ones — get routed over the tunnel.
  #
  # systemd-resolved turns the wg0 connection's `dns-search` (countersight.co)
  # into a routing domain: only *.countersight.co resolves via the work DNS,
  # everything else goes to the LAN/wifi link's resolver. NetworkManager
  # auto-switches to the resolved backend when this is enabled.
  services.resolved = {
    enable = true;
    dnssec = "false";
  };
}
