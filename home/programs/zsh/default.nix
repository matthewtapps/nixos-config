_:
{
  # home.file.".zshrc" = {
  #   source = ./.zshrc;
  # };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    plugins = [
      { name = "z-shell/F-Sy-H"; src = ./plugins/F-Sy-H; file = "F-Sy-H.plugin.zsh"; }
      { name = "romkatv/powerlevel10k"; src = ./plugins/powerlevel10k; file = "powerlevel10k.zsh-theme"; }
      { name = "marlonrichert/zsh-autocomplete"; src = ./plugins/zsh-autocomplete; file = "zsh-autocomplete.plugin.zsh"; }
      { name = "zsh-users/zsh-autosuggestions"; src = ./plugins/zsh-autosuggestions; file = "zsh-autosuggestions.zsh"; }
      { name = "chisui/zsh-nix-shell"; src = ./plugins/zsh-nix-shell; file = "nix-shell.plugin.zsh"; }
      { name = "jeffreytse/zsh-vi-mode"; src = ./plugins/zsh-vi-mode; file = "zsh-vi-mode.plugin.zsh"; }
    ];
    initExtra = ''
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

source $ZSHPLUGINS/romkatv/powerlevel10k/.p10k.zsh

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

if [ "$SSH_AUTH_SOCK" = "" -a -x /usr/bin/ssh-agent ]; then
                eval `/usr/bin/ssh-agent`
fi

export MANPAGER="nvim +Man!"

alias v="nvim"                                                                                       # v         = nvim
alias nixc="; cd /etc/nixos; sudo -E -s"                                                             # nixc      = NixOS system config
alias nixswitch="sudo nixos-rebuild switch --flake /etc/nixos#desktop"                               # nixswitch = NixOS system switch
alias ns="nix-shell"                                                                                 # ns        = nix shell
alias nsc="v shell.nix"                                                                              # nsc       = nix shell config
alias la="ls -a --color=auto"                                                                        # la        = list all
alias ls="ls --color=auto"                                                                           # ls        = list
alias zshstyle="v $HOME/.config/zsh/plugins/powerlevel10k/.p10k.zsh"                                 # zshstyle  = zsh style
alias quicktest="pnpm run test --testPathIgnorePatterns '(?<!mocked-)integration|agnostic|manual'"   # quicktest = run quick tests in autograb vehicle-matcher repo
alias aliases="cat ~/.zshrc | grep ^alias"                                                           # aliases

export PATH=$PATH:$HOME/.local/scripts
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/bin
export PATH=$PATH:/opt/nvim-linux64/bin
export PATH=$PATH:$HOME/google-cloud-sdk/bin
export PATH=$PATH:/opt/lua-language-server/bin
export PATH=$PATH:$HOME/.cargo/bin

export FZF_DEFAULT_COMMAND='ag --hidden -g""'

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      '';
  };

  # environment.pathsToLink = [ "/share/zsh" ];

  # home.file.".config/zsh/plugins" = {
  #   source = ./plugins;
  #   recursive = true;
  # };
}