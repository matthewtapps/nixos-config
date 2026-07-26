{ pkgs, lib, ... }:
let
  # Floating keybind cheatsheet: the Herdr home-row layer plus the live Hyprland
  # binds (read from the running config, so hypr stays authoritative and never
  # drifts). Bound in hypr to CTRL+ALT+(SHIFT+)slash, which kanata emits from
  # hold-f/j + `/` — see nixos/modules/kanata.nix and hypr common.conf.
  #
  # `toggle` opens a floating ghostty (class "cheatsheet", floated+centered by a
  # windowrule) running `view`; if one is already open it closes it. `view`
  # renders the sheet and pages it (q / Esc to dismiss).
  #
  # The Herdr block is hand-curated (mirrors home/programs/herdr) because a
  # cheatsheet reads better than dumped TOML — keep the two in sync when you
  # change bindings.
  cheatsheet = pkgs.writeShellScriptBin "keybind-cheatsheet" ''
    set -euo pipefail
    # Text utils pinned; hyprctl and ghostty come from the live session PATH.
    export PATH=${lib.makeBinPath (with pkgs; [ jq less gnugrep gawk gnused coreutils util-linux ])}:$PATH

    RULE='────────────────────────────────────────────────────────────────'

    # section TITLE BODY — BODY is tab-separated "keys<TAB>action" lines. Aligns
    # the two columns into a table under a titled rule. Skipped if BODY is empty.
    section() {
      local title="$1" body="$2"
      [ -n "$body" ] || return 0
      printf '\n  \033[1m%s\033[0m\n  %s\n' "$title" "$RULE"
      printf '%s\n' "$body" | column -t -s "$(printf '\t')" | sed 's/^/  /'
    }

    # All Hyprland binds as "MODS + KEY<TAB>action", $mainMod resolved, exec/
    # trailing-comma noise stripped. Read once, then split into categories.
    hypr_rows() {
      local f varmap
      # Build a sed program from the configs' own `$name = value` definitions so
      # $mainMod / $terminal / $menu / … show resolved, not as raw variables.
      varmap=$(grep -hE '^\$[A-Za-z_]+[[:space:]]*=' "$HOME"/.config/hypr/*.conf 2>/dev/null \
        | sed -E 's/^\$([A-Za-z_]+)[[:space:]]*=[[:space:]]*(.*)$/s@[$]\1@\2@g/')
      for f in "$HOME"/.config/hypr/*.conf; do
        [ -e "$f" ] || continue
        grep -hE '^bind[a-z]* *=' "$f" || true
      done | sed -E 's/^bind[a-z]* *= *//' \
        | if [ -n "$varmap" ]; then sed -E "$varmap"; else cat; fi \
        | awk -F',' '{
            mods=$1; key=$2; act=$3;
            for (i=4; i<=NF; i++) act=act "," $i;
            gsub(/^ +| +$/,"",mods); gsub(/^ +| +$/,"",key); gsub(/^ +| +$/,"",act);
            sub(/^exec, */,"",act); sub(/,+ *$/,"",act);
            lhs = (mods=="" ? key : mods " + " key);
            printf "%s\t%s\n", lhs, act;
          }'
    }

    render() {
      printf '  \033[1mKEYBINDS\033[0m   Herdr home-row: hold  f (left) or j (right), then key (opposite hand). Shift-family is on the Ctrl+b prefix.\n'

      section "HERDR · PANES  (hold f/j + key)" "$(printf '%b\n' \
        'h  j  k  l\tfocus pane  left / down / up / right' \
        'v  /  s\tsplit  vertical (right) / horizontal (below)' \
        'x\tclose pane' \
        'z\tzoom pane' \
        'r\tresize mode' \
        'e\tedit scrollback' \
        'y\tcopy / scrollback mode')"

      section "HERDR · TABS  (hold f/j + key)" "$(printf '%b\n' \
        'c\tnew tab' \
        'n  /  p\tnext / previous tab' \
        'd\tclose tab')"

      section "HERDR · SESSION  (hold f/j + key)" "$(printf '%b\n' \
        'q\tdetach client' \
        'w\tworkspace picker' \
        '[  /  ]\tprevious / next workspace' \
        'g\tgoto' \
        'o\topen notification target' \
        'b\ttoggle sidebar' \
        'hold + / (or ?)\tthis cheatsheet')"

      section "HERDR · VIA Ctrl+b PREFIX  (press Ctrl+b, then key)" "$(printf '%b\n' \
        'Shift + h/j/k/l\tswap pane in direction' \
        'Tab  /  Shift+Tab\tcycle pane  next / previous' \
        'Shift + p\trename pane' \
        'Shift + t\trename tab' \
        'Shift + n\tnew workspace' \
        'Shift + w\trename workspace' \
        'Shift + d\tclose workspace' \
        'Shift + g\tnew worktree (from base)' \
        'Shift + o\topen worktree picker' \
        'Shift + b\tremove worktree checkout' \
        'Shift + r\treload config' \
        'Shift + s\tsettings' \
        '?\tHerdr full binding list' \
        '<any layer key>\tprefix form works for every action too')"

      # Hyprland, categorised by dispatcher / target.
      local rows; rows="$(hypr_rows || true)"
      section "HYPRLAND · WINDOWS & FOCUS" \
        "$(printf '%s\n' "$rows" | grep -E 'movefocus|movewindow|swapwindow|killactive|fullscreen|togglefloating|pseudo|centerwindow' || true)"
      section "HYPRLAND · WORKSPACES" \
        "$(printf '%s\n' "$rows" | grep -Ei 'workspace' || true)"
      section "HYPRLAND · MEDIA & HARDWARE" \
        "$(printf '%s\n' "$rows" | grep -Ei 'pactl|playerctl|brightnessctl|xf86' || true)"
      section "HYPRLAND · LAUNCH & ACTIONS" \
        "$(printf '%s\n' "$rows" | grep -Eiv 'movefocus|movewindow|swapwindow|killactive|fullscreen|togglefloating|pseudo|centerwindow|workspace|pactl|playerctl|brightnessctl|xf86' || true)"

      printf '\n  Press q or Esc to close.\n'
    }

    case "''${1:-view}" in
      view)
        render | less -R
        ;;
      toggle)
        addr=$(hyprctl clients -j | jq -r 'first(.[] | select(.class == "cheatsheet") | .address) // empty')
        if [ -n "$addr" ]; then
          hyprctl dispatch closewindow "address:$addr"
        else
          ghostty --class=cheatsheet -e keybind-cheatsheet view &
        fi
        ;;
      *)
        echo "usage: keybind-cheatsheet [view|toggle]" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ cheatsheet ];
}
