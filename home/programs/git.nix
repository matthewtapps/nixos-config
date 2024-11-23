_: {
  programs.git = {
    enable = true;
    userName = "matthewtapps";
    userEmail = "mail@matthewtapps.com";
    ignores = [
      ".direnv/"
      ".go/"
    ];
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
      push = {
        autoSetupRemote = true;
      };
      merge = {
        conflictstyle = "diff3";
      };
      core.sshCommand = "ssh -i ~/.ssh/id_ed25519";
    };
  };
}
