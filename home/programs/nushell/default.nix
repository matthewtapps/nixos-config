{ device, pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      style = "compact";
      show_preview = true;
      filter_mode_shell_up_key_behavior = "session";
    };
  };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # single line: all info left, lang versions + time on right
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

  programs.nushell = {
    enable = true;
    extraEnv = ''
      $env.EDITOR = "nvim"
      $env.VISUAL = "nvim"
      $env.LANG = "en_AU.UTF-8"
      $env.MANPAGER = "nvim +Man!"
      $env.FZF_DEFAULT_COMMAND = 'ag --hidden -g""'
      $env.NH_NOM = "1"
      $env.PATH = ($env.PATH | append [
          ($env.HOME + "/.local/scripts")
          ($env.HOME + "/.local/bin")
          ($env.HOME + "/bin")
          "/opt/nvim-linux64/bin"
          ($env.HOME + "/google-cloud-sdk/bin")
          "/opt/lua-language-server/bin"
          ($env.HOME + "/.cargo/bin")
      ])
    '';
    extraConfig = ''
      ${builtins.readFile ./config.nu}

      source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu

      def nixos-config-hash [] {
          let repo = $"($env.HOME)/nixos-config"
          let commit = (git -C $repo rev-parse HEAD | str trim)
          let diff = (git -C $repo diff HEAD | hash sha256)
          $"($commit)/($diff)"
      }

      def nixswitch [] {
          let stamp = ($env.HOME | path join ".local/share/nixos-switch-stamp")
          let hash = (nixos-config-hash)
          if ($stamp | path exists) and ((open $stamp | str trim) == $hash) {
              print "karsa up to date, skipping"
              return
          }
          sudo -v
          nh os switch ~/nixos-config
          mkdir ($stamp | path dirname)
          $hash | save --force $stamp
      }

      alias hmswitch = nh home switch ~/nixos-config

      def fleetswitch [] {
          cd ~/nixos-config
          nixswitch
          nh home switch ~/nixos-config
          deploy ~/nixos-config
      }
    '';
  };
}
