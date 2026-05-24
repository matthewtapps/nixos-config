_: {
  security.sudo.extraRules = [
    {
      users = [ "matt" ];
      commands = [
        { command = "/nix/store/*/activate"; options = [ "NOPASSWD" ]; }
        { command = "/nix/store/*/bin/switch-to-configuration"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
