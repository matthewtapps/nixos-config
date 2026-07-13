# Interactive zsh setup — ported from the bash config.

# Allow `#` comments on the interactive command line, so pasted scripts with
# comments run as-is (bash allows this; zsh does not by default).
setopt interactive_comments

# --- vi mode ---
bindkey -v
export KEYTIMEOUT=1

# Cursor shape per mode: bar in insert, block in normal. Use add-zle-hook-widget
# so we append to (not clobber) the hooks autosuggestions/atuin also register.
autoload -Uz add-zle-hook-widget
_zsh_cursor_select() {
    case $KEYMAP in
        vicmd) printf '\e[2 q' ;;   # steady block
        *)     printf '\e[6 q' ;;   # steady bar
    esac
}
_zsh_cursor_init() { printf '\e[6 q'; }
add-zle-hook-widget keymap-select _zsh_cursor_select
add-zle-hook-widget line-init _zsh_cursor_init

# --- keybindings ---
# ctrl+p / ctrl+n: history navigation (matches the bash binds)
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
# ctrl+w / ctrl+h: delete word backward
bindkey '^W' backward-kill-word
bindkey '^H' backward-kill-word
# ctrl+space: accept the autosuggestion (ghost text)
bindkey '^ ' autosuggest-accept
# ctrl+r fuzzy history search is provided by the atuin zsh integration.

# --- completion behaviour (case-insensitive + menu + colours) ---
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- functions ---

nixswitch() {
    sudo -v
    nh os switch ~/nixos-config
}

fleetswitch() {
    cd ~/nixos-config || return
    nixswitch
    nh home switch ~/nixos-config
    deploy ~/nixos-config
}

nixc() {
    local prev="$PWD"
    cd ~/nixos-config || return
    nvim
    cd "$prev" || return
}

# nix wrapper: auto-append `--command zsh` to `nix shell`/`nix develop`
# so subshells drop back into zsh instead of the default shell.
nix() {
    local subcmd="$1" a has_command=0
    if [[ "$subcmd" == "shell" || "$subcmd" == "develop" ]]; then
        for a in "$@"; do
            if [[ "$a" == "--command" || "$a" == "-c" ]]; then
                has_command=1
                break
            fi
        done
        if [[ $has_command -eq 0 ]]; then
            command nix "$@" --command zsh
            return
        fi
    fi
    command nix "$@"
}

# Report language runtimes that are behind the cached latest version.
vup() {
    local cache="$HOME/.cache/version-checks" found=0 current latest
    if command -v node >/dev/null 2>&1 && [[ -f "$cache/node.latest" ]]; then
        current=$(node --version | tr -d 'v[:space:]')
        latest=$(< "$cache/node.latest")
        [[ "$current" != "$latest" ]] && { printf 'node     %s → %s\n' "$current" "$latest"; found=1; }
    fi
    if command -v python3 >/dev/null 2>&1 && [[ -f "$cache/python.latest" ]]; then
        current=$(python3 --version 2>&1 | awk '{print $NF}')
        latest=$(< "$cache/python.latest")
        [[ "$current" != "$latest" ]] && { printf 'python   %s → %s\n' "$current" "$latest"; found=1; }
    fi
    if command -v rustc >/dev/null 2>&1 && [[ -f "$cache/rust.latest" ]]; then
        current=$(rustc --version | awk '{print $2}')
        latest=$(< "$cache/rust.latest")
        [[ "$current" != "$latest" ]] && { printf 'rust     %s → %s\n' "$current" "$latest"; found=1; }
    fi
    if command -v go >/dev/null 2>&1 && [[ -f "$cache/go.latest" ]]; then
        current=$(go version | awk '{print $3}' | sed 's/^go//')
        latest=$(< "$cache/go.latest")
        [[ "$current" != "$latest" ]] && { printf 'go       %s → %s\n' "$current" "$latest"; found=1; }
    fi
    [[ $found -eq 0 ]] && echo "All language runtimes up to date."
}

# Git repo overview report (https://piechowski.io/post/git-commands-before-reading-code/)
git-overview() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not a git repository."
        return
    fi

    local repo sep bold cyan reset
    repo=$(basename "$(git rev-parse --show-toplevel)")
    sep="────────────────────────────────────────"
    bold=$(tput bold 2>/dev/null || printf '\033[1m')
    cyan=$(tput setaf 6 2>/dev/null || printf '\033[36m')
    reset=$(tput sgr0 2>/dev/null || printf '\033[0m')

    printf '\n%s%sGit Overview: %s%s\n' "$bold" "$cyan" "$repo" "$reset"

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sMost Modified Files (past year)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    git log --format=format: --name-only --since="1 year ago" \
        | grep -v '^$' | sort | uniq -c | sort -rn | head -20 \
        | awk '{printf "  %s %s\n", $1, $2}'

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sAll Contributors (by commits)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    git shortlog -sn --no-merges HEAD

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sRecent Contributors (past 6 months)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    git shortlog -sn --no-merges --since="6 months ago" HEAD

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sMost Bug-Fixed Files (past year)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    git log -i -E --grep="fix|bug|broken" --name-only --format="" \
        | grep -v '^$' | sort | uniq -c | sort -rn | head -20 \
        | awk '{printf "  %s %s\n", $1, $2}'

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sCommit Velocity (monthly)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    local monthly
    monthly=$(git log --format="%ad" --date=format:"%Y-%m" | sort | uniq -c)
    if [[ -z "$monthly" ]]; then
        echo "  No commits found"
    else
        local max
        max=$(echo "$monthly" | awk '{print $1}' | sort -rn | head -1)
        echo "$monthly" | awk -v max="$max" -v width=30 -v cyan="$cyan" -v reset="$reset" '{
            count=$1; month=$2;
            len=int(count*width/max + 0.5); if (len < 1) len=1;
            bar=""; for (i=0;i<len;i++) bar=bar "█";
            pad=""; for (i=0;i<width-len;i++) pad=pad " ";
            printf "  %s  %s%s%s%s %s\n", month, cyan, bar, reset, pad, count;
        }'
    fi

    printf '\n%s%s%s%s\n' "$bold" "$cyan" "$sep" "$reset"
    printf '%sEmergency Commits (past year)%s\n' "$bold" "$reset"
    printf '%s%s%s\n' "$cyan" "$sep" "$reset"
    local emergency
    emergency=$(git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback')
    if [[ -z "$emergency" ]]; then
        echo "  None found"
    else
        while IFS= read -r line; do printf '  %s\n' "$line"; done <<< "$emergency"
    fi

    echo
}
