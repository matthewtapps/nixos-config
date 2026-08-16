{
  config,
  lib,
  pkgs,
  ...
}:

{
  sops.secrets.tailscale-authkey.sopsFile = ../../secrets/tailscale.yaml;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    authKeyFile = config.sops.secrets.tailscale-authkey.path;

    # `up` runs only at enrollment, so --ssh is applied there. Access still needs
    # an ssh rule in the tailnet ACL to grant it.
    extraUpFlags = [ "--ssh" ];
  };

  # Keeping enrollment out of multi-user.target stops a stale auth key from
  # failing a routine deploy. Run `systemctl start tailscaled-autoconnect` once
  # on a new host.
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ];

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  environment.systemPackages = with pkgs; [
    tailscale
    ktailctl
  ];
}
