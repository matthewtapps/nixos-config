{ host, lib, ... }:
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

  users.users = lib.genAttrs (builtins.attrNames host.users) (_: {
    extraGroups = lib.mkAfter [ "docker" "podman" ];
  });
}
