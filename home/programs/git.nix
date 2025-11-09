_: {
  programs.git = {
    enable = true;
    ignores = [
      ".direnv/"
      ".go/"
    ];
    settings = {
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
      user = {
        name = "matthewtapps";
        email = "mail@matthewtapps.com";
      };
    };
  };
}
