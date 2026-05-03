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
        shell = pkgs.nushell;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPm051kBWmtEh3hM2ajmxTTd6wd/70GdspJMSlfBC5DT matt@Matt-DESKTOP-NIXOS"
        ];
      };
    }) users
  );

in
{
  users.users = userConfigs;
}
