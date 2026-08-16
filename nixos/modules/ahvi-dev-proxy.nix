# Reverse-proxies the ahvi work dev-instance (hot-reloading vite) onto a clean,
# port-less URL so colleagues can view it over the WireGuard VPN: they browse
# http://<publicHost>/. Plain http on :80 is fine here because the WireGuard
# tunnel already encrypts the traffic, and the port is opened only on the VPN
# interface, never on wifi/LAN.
#
# Pairs with the ahvi frontend: run the work dev-instance with AHVI_PUBLIC_HOST
# set so vite accepts the proxied Host header and routes HMR back through :80:
#   AHVI_PUBLIC_HOST=<publicHost> just dev-instance
{ lib, ... }:
let
  # Host colleagues type in the browser: samar's address on the WireGuard
  # network. Becomes both the nginx server_name and vite's allowedHosts entry.
  publicHost = "10.88.88.131";
  # samar's WireGuard interface. Port 80 is opened only on this interface.
  wgInterface = "wg0";

  # Work dev-instance vite port (the justfile `dev-instance` default).
  viteWorkPort = 5173;
in
{
  # Fail the build loudly if the placeholders were not filled, so a proxy never
  # stands up on the wrong host or interface.
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
        # vite HMR runs over a websocket, so proxy it to keep hot-reload working.
        proxyWebsockets = true;
      };
    };
  };

  # Expose the proxy on the VPN only.
  networking.firewall.interfaces.${wgInterface}.allowedTCPPorts = [ 80 ];
}
