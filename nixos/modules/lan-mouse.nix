{ config, ... }:
{
  sops.secrets.lan-mouse-cert = {
    sopsFile = ../../secrets/lan-mouse/${config.networking.hostName}.pem;
    format = "binary";
    owner = "matt";
    mode = "0400";
  };
}
