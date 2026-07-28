_: {
  programs.git = {
    enable = true;
    signing.format = null;
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
      branch = {
        # Only inherit upstream when the new branch name matches the remote
        # branch name; avoids worktree branches created off origin/main
        # silently tracking origin/main.
        autoSetupMerge = "simple";
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
