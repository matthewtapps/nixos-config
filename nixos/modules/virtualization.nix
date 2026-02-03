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
    };

    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  imports = userModules;
}
