{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.wireguard-tools ];

  # Split-DNS for the work WireGuard VPN. Without a split-capable resolver the
  # plain resolvconf backend concatenates every link's nameservers into one flat
  # /etc/resolv.conf, so the VPN's work DNS (172.20.20.2) ends up first and every
  # lookup gets routed over the tunnel.
  #
  # The wg0 NetworkManager profile must set `ipv4.dns-search` to
  # `~countersight.co`. Drop the `~` and it becomes a search domain too; the work
  # zone answers every name under it with NODATA, so bare hostnames like `samar`
  # stop resolving before the tailnet suffix is tried.
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = false;
  };
}
