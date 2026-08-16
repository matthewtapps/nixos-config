{ config, ... }:

{
  sops.secrets.harmonia-signing-key.sopsFile = ../../secrets/karsa.yaml;

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets.harmonia-signing-key.path ];
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
