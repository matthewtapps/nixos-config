{
  pkgs,
  device,
  ...
}:
{
  # home.file.".zshrc" = {
  #   source = ./.zshrc;
  # };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    plugins = [
      {
        name = "F-Sy-H";
        src = pkgs.fetchFromGitHub {
          owner = "z-shell";
          repo = "F-Sy-H";
          rev = "v1.67";
          sha256 = "zhaXjrNL0amxexbZm4Kr5Y/feq1+2zW0O6eo9iZhmi0=";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "35833ea15f14b71dbcebc7e54c104d8d56ca5268";
          sha256 = "ES5vJXHjAKw/VHjWs8Au/3R+/aotSbY7PWnWAMzCR8E=";
        };
      }
      {
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "6d059a3634c4880e8c9bb30ae565465601fb5bd2";
          sha256 = "0NW0TI//qFpUA2Hdx6NaYdQIIUpRSd0Y4NhwBbdssCs=";

        };
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "a411ef3e0992d4839f0732ebeb9823024afaaaa8";
          sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        name = "zsh-nix-shell";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "8b86281cf9e9ef9f207433dd8b36d157dd48d50a";
          sha256 = "Z6EYQdasvpl1P78poj9efnnLj7QQg13Me8x1Ryyw+dM=";
        };
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "ea1f58ab9b1f3eac50e2cde3e3bc612049ef683b";
          sha256 = "xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
      }
    ];

    initContent = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      local lightgrey='#a89984'
      local grey='#928374'
      local red='#ea6962'
      local yellow='#d8a657'
      local blue='#7daea3'
      local magenta='#d3869b'
      local aqua='#89b482'
      local white='#ddc7a1'
      local green='#a9b665'
      local orange='#e78a4e'

      bindkey -v # Enables vi mode for zsh

      export TERM="xterm-256color"
      export EDITOR="nvim"
      export VISUAL="nvim"
      export LANG=en_AU.UTF-8
      export ZSHPLUGINS=$HOME/.zsh/plugins

      source $ZSHPLUGINS/powerlevel10k/powerlevel10k.zsh-theme
      source $ZSHPLUGINS/custom/.p10k.zsh
      source $ZSHPLUGINS/zsh-autocomplete/zsh-autocomplete.plugin.zsh
      source $ZSHPLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
      source $ZSHPLUGINS/F-Sy-H/F-Sy-H.plugin.zsh
      source $ZSHPLUGINS/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      source $ZSHPLUGINS/zsh-nix-shell/nix-shell.plugin.zsh

      zmodload zsh/complist
      autoload -U compinit; compinit -u

      _comp_options+=(globdots)

      zstyle ':completion:*' completer _extensions _complete _approximate 
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$HOME/zsh/.zcompcache"
      zstyle ':completion:*' menu select

      zstyle ':completion:*:*:*:*:descriptions' format "%F{green}-- %d --%f"
      zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
      zstyle ':completion:*:*:*:*:messages' format '%F{purple}-- %d --%f'
      zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- no matches found --%f'
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' keep-prefix
      zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':autocomplete:*' add_space '*'
      zstyle ':autocomplete:*' delay 0.5

      setopt AUTO_LIST
      setopt COMPLETE_IN_WORD
      setopt MENU_COMPLETE
      unsetopt PATH_DIRS

      bindkey -M menuselect 'h' vi-backward-char
      bindkey -M menuselect 'k' vi-up-line-or-history
      bindkey -M menuselect 'j' vi-down-line-or-history
      bindkey -M menuselect 'l' vi-forward-char
      bindkey '^I' menu-select
      bindkey "$terminfo[kcbt]" menu-select
      bindkey -M menuselect '^I' menu-complete
      bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
      bindkey -M menuselect '^[[D' .backward-char '^[OD' .backward-char
      bindkey -M menuselect '^[[C' .forward-char '^[OC' .forward-char
      bindkey -M menuselect '^M' .accept-line
      bindkey '^H' backward-delete-word
      bindkey -M menuselect '^?' backward-delete-line

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$lightgrey"
      bindkey '^ ' autosuggest-accept
      ZSH_AUTOSUGGEST_STRATEGY=(history)
      ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(menu-select menu-complete reverse-menu-complete backward-delete-word backward-delete-char vi-backward-char vi-forward-char vi-up-line-or-history vi-down-line-or-history)
      ZSH_AUTOSUGGEST_COMPLETION_IGNORE="cd *|la|la|v *"
      ZSH_AUTOSUGGEST_HISTORY_IGNORE="cd *|la|la|v *"
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZER=20

      ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
      ZVM_INIT_MODE=sourcing
      ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

      fpath=(~/.zsh $fpath)

      HISTFILE="$HOME/.zsh_history"
      HISTSIZE=10000000
      SAVEHIST=10000000
      HISTORY_IGNORE="(ls|cd|pwd|exit|cd|la|v)*"
      HIST_STAMPS="yyyy-mm-dd"
      setopt EXTENDED_HISTORY      # Write the history file in the ':start:elapsed;command' format.
      setopt INC_APPEND_HISTORY    # Write to the history file immediately, not when the shell exits.
      setopt SHARE_HISTORY         # Share history between all sessions.
      setopt HIST_IGNORE_DUPS      # Do not record an event that was just recorded again.
      setopt HIST_IGNORE_ALL_DUPS  # Delete an old recorded event if a new event is a duplicate.
      setopt HIST_IGNORE_SPACE     # Do not record an event starting with a space.
      setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file.
      setopt HIST_VERIFY           # Do not execute immediately upon history expansion.
      setopt APPEND_HISTORY        # append to history file (Default)
      setopt HIST_NO_STORE         # Don't store history commands
      setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history.
      setopt PUSHDSILENT

      if [ "$SSH_AUTH_SOCK" = "" -a -x /usr/bin/ssh-agent ]; then
                      eval `/usr/bin/ssh-agent`
      fi

      export MANPAGER="nvim +Man!"

      alias v="nvim"                                                                                       # v         = nvim
      alias nixc="pushd $HOME/nixos-config && nvim && popd"                                                # nixc      = NixOS system config
      alias nixswitch="sudo nixos-rebuild switch --flake $HOME/nixos-config#${device}"                     # nixswitch = NixOS system switch
      alias hmswitch="nix run $HOME/nixos-config#homeConfigurations.$USER@${device}.activationPackage"     # hmswitch  = User config switch
      alias la="ls -a --color=auto"                                                                        # la        = list all
      alias ls="ls --color=auto"                                                                           # ls        = list
      alias aliases="cat ~/.zshrc | grep ^alias"                                                           # aliases

      export PATH=$PATH:$HOME/.local/scripts
      export PATH=$PATH:$HOME/.local/bin
      export PATH=$PATH:$HOME/bin
      export PATH=$PATH:/opt/nvim-linux64/bin
      export PATH=$PATH:$HOME/google-cloud-sdk/bin
      export PATH=$PATH:/opt/lua-language-server/bin
      export PATH=$PATH:$HOME/.cargo/bin

      export FZF_DEFAULT_COMMAND='ag --hidden -g""'
    '';
  };

  # environment.pathsToLink = [ "/share/zsh" ];

  home.file.".zsh/plugins/custom/.p10k.zsh" = {
    source = ./plugins/custom/.p10k.zsh;
  };
}
