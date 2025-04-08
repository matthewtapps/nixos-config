{ pkgs, ... }:
{
  services.tailscale.enable = true;

  services.tailscale.useRoutingFeatures = "both";

  networking.firewall.checkReversePath = "loose";

  environment = {
    systemPackages = with pkgs; [
      tailscale
      ktailctl
    ];
  };

  services.resolved = {
    enable = true;
  };
}
