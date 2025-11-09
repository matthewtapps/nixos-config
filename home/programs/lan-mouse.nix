{ inputs, device, ... }:
let
  config = {
    "karsa" = {
      left = {
        hostname = "kruppe";
        ips = [ "192.168.0.181" ];
        activate_on_startup = true;
      };
      right = {
        hostname = "mappo";
        ips = [ "192.168.0.111" ];
        activate_on_startup = true;
      };
    };

    "kruppe" = {
      authorized_fingerprints = {
        "44:ba:df:4c:82:5b:93:84:38:9f:32:e4:e8:e8:09:0c:4e:97:4f:ac:29:42:93:38:14:c1:f5:34:da:22:88:3a" =
          "karsa";
      };
    };

    "mappo" = {
      authorized_fingerprints = {
        "44:ba:df:4c:82:5b:93:84:38:9f:32:e4:e8:e8:09:0c:4e:97:4f:ac:29:42:93:38:14:c1:f5:34:da:22:88:3a" =
          "karsa";
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
