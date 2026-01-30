{
  host,
  lib,
  pkgs-stable,
  ...
}:
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
      package = pkgs-stable.docker; # Pin to Docker 24.x from stable
    };
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  imports = userModules;
}
