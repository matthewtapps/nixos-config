{ host, lib, ... }:
let
  users = builtins.attrNames host.users;

  userModules = map (user: {
    users.users.${user} = {
      extraGroups = lib.mkAfter [
        "docker"
      ];
    };
  }) users;
in

{
  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;

  imports = userModules;
}
