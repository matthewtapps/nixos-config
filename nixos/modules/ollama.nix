{ config, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";  # Listen on all interfaces
    port = 11434;
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
