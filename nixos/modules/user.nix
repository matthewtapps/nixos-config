{ pkgs, host, ... }:

let
  users = builtins.attrNames host.users;
  userConfigs = builtins.listToAttrs (
    map (user: {
      name = user;
      value = {
        isNormalUser = true;
        description = user;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
        shell = pkgs.zsh; # Or use another shell based on your config
      };
    }) users
  );

in
{
  users.users = userConfigs;
}
