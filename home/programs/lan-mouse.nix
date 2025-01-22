{ inputs, device, ... }:
let
  config = {
    "desktop" = {
      right = {
        hostname = "NUC-NIXOS";
        ips = [ "192.168.0.181" ];
      };
      left = {
        hostname = "Matt-THINKPAD-NIXOS";
        ips = [ "192.168.0.111" ];
      };
      systemd = true;
    };

    "nuc" = {
      systemd = true;
      authorized_fingerprints = {
        "44:ba:df:4c:82:5b:93:84:38:9f:32:e4:e8:e8:09:0c:4e:97:4f:ac:29:42:93:38:14:c1:f5:34:da:22:88:3a" =
          "Matt-DESKTOP-NIXOS";
      };
    };

    "thinkpad" = {
      systemd = true;
      authorized_fingerprints = {
        "44:ba:df:4c:82:5b:93:84:38:9f:32:e4:e8:e8:09:0c:4e:97:4f:ac:29:42:93:38:14:c1:f5:34:da:22:88:3a" =
          "Matt-DESKTOP-NIXOS";
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
