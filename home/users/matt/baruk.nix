_: {
  imports = [
    ../../programs/zsh/version-check.nix
    ../../programs/zsh/default.nix
    ../../programs/neovim/default.nix
    ../../programs/git.nix
    ../../programs/direnv.nix
    ../../programs/claude-code.nix
  ];

  programs.home-manager.enable = true;

  # sd-switch can't find previous HM generation in NixOS module mode, restarts all user services (HM #7583)
  systemd.user.startServices = false;

  home = {
    username = "matt";
    homeDirectory = "/home/matt";
    stateVersion = "26.11";
    sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
    file.".hushlogin".text = "";
  };

  services.ssh-agent.enable = true;
}
