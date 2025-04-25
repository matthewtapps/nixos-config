{ inputs, pkgs, ... }:
{
  services.foundryvtt = {
    enable = true;
    hostName = "Matt-DESKTOP-NIXOS";
    minifyStaticFiles = true;
    package = inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_12;
    proxyPort = 443;
    proxySSL = true;
    upnp = false;
  };
}
