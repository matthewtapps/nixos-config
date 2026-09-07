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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPm051kBWmtEh3hM2ajmxTTd6wd/70GdspJMSlfBC5DT matt@Matt-DESKTOP-NIXOS"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH6L78sNDUwYIeeubGuD5bSYStc3Z/Tt4d4wvfNxRp0 matt@Matt-THINKPAD-NIXOS"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgseOkSq6JIlNi5appmg5CAmZ7KVpms+o0EOo5PIhWM matt@tehol"
        ];
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
