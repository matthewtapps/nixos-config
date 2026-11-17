{
  config,
  pkgs,
  host,
  ...
}:

let
  users = builtins.attrNames host.users;
  userConfigs = builtins.listToAttrs (
    map (user: {
      name = user;
      value = {
        isNormalUser = true;
        description = user;
        hashedPasswordFile = config.sops.secrets."${user}-password".path;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = import ./authorized-keys.nix;
      };
    }) users
  );

  passwordSecrets = builtins.listToAttrs (
    map (user: {
      name = "${user}-password";
      value = {
        sopsFile = ../../secrets/users.yaml;
        # Decrypt before user creation so hashedPasswordFile can read it.
        neededForUsers = true;
      };
    }) users
  );

in
{
  users.users = userConfigs;

  # Passwords come only from the sops secrets above; passwd changes do not persist.
  users.mutableUsers = false;

  sops.secrets = passwordSecrets;

  # Enable zsh system-wide so it's a valid login shell (adds it to /etc/shells).
  programs.zsh.enable = true;
}
