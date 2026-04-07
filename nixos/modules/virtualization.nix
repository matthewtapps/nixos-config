{ host, lib, ... }:
let
  users = builtins.attrNames host.users;

  userModules = map (user: {
    users.users.${user} = {
      extraGroups = lib.mkAfter [
        "docker"
        "podman"
      ];
    };
  }) users;
in

{
  virtualisation = {
    docker = {
      enable = true;
      liveRestore = false;
      daemon.settings = {
        default-address-pools = [
          {
            base = "100.64.0.0/16";
            size = 24;
          }
        ];
      };
    };

    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  imports = userModules;
}
