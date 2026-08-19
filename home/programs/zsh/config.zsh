# Interactive zsh setup.

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
# ctrl+left / ctrl+right: move backward/forward one word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
# ctrl+space: accept the autosuggestion (ghost text)
bindkey '^ ' autosuggest-accept
# ctrl+r fuzzy history search is provided by the atuin zsh integration.

# --- completion behaviour (case-insensitive + menu + colours) ---
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- functions ---

# config-<root>.toml puts new worktrees at ~/<root>/<repo>/<branch>, beside the
# other worktrees of the bare repo. A server reads the config once at startup and
# then serves every pane that attaches to it, so keying HERDR_SESSION by the same
# root stops a server started elsewhere from handing those panes ~/.herdr.
herdr() {
    local -a envv
    local root common dir=${PWD:A}
    # Herdr builds every worktree path as <worktrees.directory>/<repo>/<branch>,
    # so under a plain checkout config-<root>.toml (directory = ~/<root>) would
    # put new worktrees inside that working tree.
    common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [[ -z "$common" || "$common" == */.bare ]]; then
        for root in cs dev; do
            if [[ "$dir" == "$HOME/$root" || "$dir" == "$HOME/$root/"* ]]; then
                [[ -z "$HERDR_CONFIG_PATH" ]] &&
                    envv+=("HERDR_CONFIG_PATH=$HOME/.config/herdr/config-$root.toml")
                [[ -z "$HERDR_SESSION" ]] && envv+=("HERDR_SESSION=$root")
                break
            fi
        done
    fi
    if (( ${#envv} )); then
        env "${envv[@]}" herdr "$@"
    else
        command herdr "$@"
    fi
}

# lazygit can't run in a bare-repo parent (the "worktrees level 2" layout used by
# ~/cs and ~/dev repos: <root>/<repo>/.bare + a .git pointer file). It needs a work tree, so
# `git rev-parse --show-toplevel` fails at the parent with "must be run in a work
# tree". When cwd is such a parent, launch lazygit inside one of its worktrees
# instead, preferring a sibling named `main`, else the first sibling worktree, else
# any worktree. Runs in a subshell so the shell cwd doesn't move.
lg() {
    emulate -L zsh
    if [[ $(git rev-parse --is-bare-repository 2>/dev/null) == true ]]; then
        local -a wts
        wts=(${(f)"$(git worktree list --porcelain | sed -n 's/^worktree //p')"})
        local w target
        for w in $wts; do [[ $w == $PWD/main ]] && target=$w && break; done
        [[ -z $target ]] && for w in $wts; do
            [[ $w == $PWD/* && $w != $PWD/*/* && $w != */.bare ]] && target=$w && break
        done
        [[ -z $target ]] && for w in $wts; do [[ $w != */.bare ]] && target=$w && break; done
        if [[ -n $target ]]; then
            ( cd $target && command lazygit "$@" )
            return
        fi
    fi
    command lazygit "$@"
}

nixswitch() {
    sudo -v
    nh os switch ~/nixos-config
}

# `nh home` only accepts homeConfigurations attrs, and home-manager is part of
# the system config here.
hmswitch() {
    local out
    out=$(nom build --no-link --print-out-paths \
        "$HOME/nixos-config#nixosConfigurations.@DEVICE@.config.home-manager.users.$USER.home.activationPackage") || return
    "$out/activate"
}

fleetstatus() {
    local nodes host dir
    nodes=$(nix eval --raw "$HOME/nixos-config#deploy.nodes" \
        --apply 'ns: builtins.concatStringsSep " " (builtins.attrNames ns)') || return
    dir=$(mktemp -d) || return

    for host in ${=nodes}; do
        ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" '
            gen=$(readlink /nix/var/nix/profiles/system); gen=${gen#system-}
            # Every switch repoints /run/current-system, so only the boot pieces
            # say whether a reboot is actually owed.
            reboot=-
            for part in kernel initrd kernel-modules; do
                [ "$(readlink -f /run/booted-system/$part 2>/dev/null)" \
                    = "$(readlink -f /run/current-system/$part 2>/dev/null)" ] || reboot=reboot
            done
            printf "%s\t%s\t%s\n" "${gen%-link}" \
                "$(stat -c %y /run/current-system | cut -d. -f1)" "$reboot"
        ' > "$dir/$host" 2>/dev/null &
    done
    wait

    local gen stamp reboot
    printf '%-8s %-6s %-21s %s\n' HOST GEN ACTIVATED PENDING
    for host in ${=nodes}; do
        if IFS=$'\t' read -r gen stamp reboot < "$dir/$host" 2>/dev/null && [[ -n $gen ]]; then
            printf '%-8s %-6s %-21s %s\n' "$host" "$gen" "$stamp" "$reboot"
        else
            printf '%-8s %s\n' "$host" "unreachable"
        fi
    done
    rm -rf "$dir"
}

fleetswitch() {
    cd ~/nixos-config || return
    nixswitch

    local nodes targets=() host
    nodes=$(nix eval --raw "$HOME/nixos-config#deploy.nodes" \
        --apply 'ns: builtins.concatStringsSep " " (builtins.attrNames ns)') || return

    for host in ${=nodes}; do
        if ssh -o ConnectTimeout=3 -o BatchMode=yes "root@$host" true 2>/dev/null; then
            targets+=("$HOME/nixos-config#$host")
        else
            print -u2 "fleetswitch: skipping $host, unreachable"
        fi
    done

    (( $#targets )) || { print -u2 "fleetswitch: no hosts reachable"; return 1 }

    # deploy-rs repeats its pre-build check once per node, so --skip-checks
    # below leaves this as the only thing validating the flake.
    nix build --no-link \
        "$HOME/nixos-config#checks.x86_64-linux."{deploy-schema,deploy-activate} \
        || return

    # deploy-rs revokes already-succeeded profiles when any node in a multi-node
    # run fails. Its spinner swallows nix output whenever more than one host
    # builds, which is why nom needs --no-progress to have anything to render.
    deploy --no-progress --skip-checks --rollback-succeeded false \
        --targets "${targets[@]}" -- --log-format internal-json -v |& nom --json
    return ${pipestatus[1]}
}

nixc() {
    local prev="$PWD"
    cd ~/nixos-config || return
    nvim
    cd "$prev" || return
}

# nix wrapper: auto-append `--command zsh` to `nix shell`/`nix develop`
# so subshells drop back into zsh.
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
