{ device, pkgs, ... }:
{
  # PATH additions (shell-agnostic).
  home.sessionPath = [
    "$HOME/.local/scripts"
    "$HOME/.local/bin"
    "$HOME/bin"
    "/opt/nvim-linux64/bin"
    "$HOME/google-cloud-sdk/bin"
    "/opt/lua-language-server/bin"
    "$HOME/.cargo/bin"
  ];

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      style = "compact";
      show_preview = true;
      filter_mode_shell_up_key_behavior = "session";
    };
  };

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # fzf: Ctrl-T file picker, Alt-C cd. Ctrl-R is owned by atuin.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nix_shell$character";
      right_format = "$nodejs$python$rust$golang$cmd_duration$time";

      directory = {
        style = "bold white";
        truncation_length = 3;
        truncate_to_repo = false;
      };
      git_branch = {
        style = "bold yellow";
        symbol = " ";
        format = "[$symbol$branch]($style)";
      };
      git_status = {
        style = "bold yellow";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        stashed = "";
        modified = "*";
        staged = "+";
        untracked = "?";
        format = "[$all_status$ahead_behind]($style) ";
      };
      nix_shell = {
        symbol = "󱄅";
        style = "bold white";
        format = "[$symbol ]($style)";
        impure_msg = "";
        pure_msg = "";
      };
      nodejs = {
        style = "bold #a9b665";
        symbol = "󰎙 ";
      };
      python = {
        style = "bold #d8a657";
        symbol = "󰌠 ";
      };
      rust = {
        style = "bold #e78a4e";
        symbol = "󱘗 ";
      };
      golang = {
        style = "bold #89b482";
        symbol = "󰟓 ";
      };
      cmd_duration = {
        style = "bold #d8a657";
        min_time = 1;
        format = "[$duration]($style) ";
      };
      time = {
        disabled = false;
        style = "dimmed white";
        format = "[$time]($style)";
        time_format = "%H:%M:%S";
      };
      character = {
        success_symbol = "[»](bold white)";
        error_symbol = "[»](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # The only two plugins: fish-style ghost text + CLI syntax highlighting.
    # Both are the canonical zsh-users plugins, wired natively by home-manager
    # (no oh-my-zsh / zinit / antigen framework).
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 1000000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "en_AU.UTF-8";
      MANPAGER = "nvim +Man!";
      FZF_DEFAULT_COMMAND = ''ag --hidden -g""'';
      NH_NOM = "1";
    };

    shellAliases = {
      v = "nvim";
      la = "ls -a";
      lg = "lazygit";
      ldo = "lazydocker";
      aliases = "alias";
      hmswitch = "nh home switch ~/nixos-config";
    };

    # Interactive setup + functions. `@DEVICE@` is baked in for nixswitch.
    initContent = builtins.replaceStrings [ "@DEVICE@" ] [ device ] (
      builtins.readFile ./config.zsh
    );
  };
}
