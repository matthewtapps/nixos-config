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

  # Enrollment is a bootstrap step, and auth keys expire after 90 days. Leaving
  # this out of multi-user.target keeps a stale key from failing a routine
  # deploy. On a new host, run `systemctl start tailscaled-autoconnect` once.
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
