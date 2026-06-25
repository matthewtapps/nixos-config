# Reverse-proxies the ahvi WORK dev-instance (hot-reloading vite) onto a clean,
# port-less URL so colleagues can view it over the WireGuard VPN: they browse
# http://<publicHost>/ instead of <host>:5173. Plain http on :80 is fine here —
# the WireGuard tunnel already encrypts the traffic, so no TLS/certs needed — and
# the port is opened ONLY on the VPN interface, never on wifi/LAN.
#
# Pairs with the ahvi frontend: run the work dev-instance with AHVI_PUBLIC_HOST
# set so vite accepts the proxied Host header and routes HMR back through :80:
#   AHVI_PUBLIC_HOST=<publicHost> just dev-instance
{ lib, ... }:
let
  # ── FILL THESE IN once samar's WireGuard config is known (arriving tomorrow) ──
  # 1. Host colleagues type in the browser — samar's address/name ON the
  #    WireGuard network (an IP like "10.0.0.2", or a VPN DNS name). Becomes both
  #    nginx server_name and vite's allowedHosts entry.
  publicHost = "10.88.88.131";
  # 2. samar's WireGuard interface name. Find it on samar with `wg show` or
  #    `ip -br link` (e.g. "wg0", or a NetworkManager device name). Port 80 is
  #    opened ONLY on this interface.
  wgInterface = "wg0";
  # ─────────────────────────────────────────────────────────────────────────────

  # Work dev-instance vite port (the justfile `dev-instance` default).
  viteWorkPort = 5173;
in
{
  # Fail the build loudly if the placeholders weren't filled, rather than quietly
  # standing up a proxy on the wrong host/interface.
  assertions = [
    {
      assertion = publicHost != "REPLACE_ME" && wgInterface != "REPLACE_ME";
      message = "ahvi-dev-proxy: set publicHost and wgInterface in nixos/modules/ahvi-dev-proxy.nix before building.";
    }
  ];

  services.nginx = {
    enable = true;
    # Sets `proxy_set_header Host $host` (among others) so vite sees publicHost
    # and its allowedHosts check passes.
    recommendedProxySettings = true;
    virtualHosts.${publicHost} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString viteWorkPort}";
        # vite's HMR runs over a websocket — proxy it so hot-reload survives.
        proxyWebsockets = true;
      };
    };
  };

  # Expose the proxy on the VPN only.
  networking.firewall.interfaces.${wgInterface}.allowedTCPPorts = [ 80 ];
}
