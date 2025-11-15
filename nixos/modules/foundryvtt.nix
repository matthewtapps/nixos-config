{ inputs, pkgs, ... }:
{
  services.foundryvtt = {
    enable = true;
    hostName = "foundry.mattys.cloud";
    minifyStaticFiles = true;
    package = inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_13;
    proxyPort = 443;
    proxySSL = true;
    upnp = false;
  };
}
