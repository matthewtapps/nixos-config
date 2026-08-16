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

    # Taildrop refuses to send or receive as a non-root user without this.
    extraSetFlags = [ "--operator=matt" ];
  };

  # Tailscale SSH serves the deploy connection, so restarting tailscaled kills
  # the session running switch-to-configuration and leaves the switch half done.
  systemd.services.tailscaled.restartIfChanged = false;

  # Keeping enrollment out of multi-user.target stops a stale auth key from
  # failing a routine deploy. Run `systemctl start tailscaled-autoconnect` once
  # on a new host.
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ];

  # An unenrolled host has no profile to set the operator on, and without this
  # that failure fails the deploy.
  systemd.services.tailscaled-set.serviceConfig.SuccessExitStatus = "0 1";

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
