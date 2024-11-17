{ inputs, device, ... }:
let
  config = {
    "Matt-DESKTOP-NIXOS" = {
      right = {
        hostname = "NUC-NIXOS";
        ips = [ "192.168.0.181" ];
      };
      left = {
        hostname = "Matt-THINKPAD";
        ips = [ "192.168.0.111" ];
      };
    };
  };
in
{
  imports = [ inputs.lan-mouse.homeManagerModules.default ];
  programs.lan-mouse = {
    enable = true;
    settings = (config.${device} or { });
  };
}
