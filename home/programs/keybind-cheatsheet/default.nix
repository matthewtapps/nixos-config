{ pkgs, lib, ... }:
let
  # Floating keybind cheatsheet: the Herdr home-row layer plus the live Hyprland
  # binds (read from the running compositor, so hypr stays authoritative and
  # never drifts). Bound in hypr to CTRL+ALT+(SHIFT+)slash, which kanata emits
  # from hold-f/j + `/` — see nixos/modules/kanata.nix and hypr common.lua.
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

    # All Hyprland binds as "CATEGORY<TAB>MODS + KEY<TAB>description", from the
    # running compositor. Lua dispatchers all surface as `__lua` in hyprctl, so
    # the description is the only readable action text and a bind without one is
    # dropped. Categories use first-match priority so each bind lands in exactly
    # one section ("window to workspace 3" is a workspace bind).
    hypr_rows() {
      hyprctl binds -j 2>/dev/null | jq -r '
        # Hyprland modmask bits, listed in conventional display order.
        def mods($m): [
          {b:64, n:"SUPER"}, {b:4, n:"CTRL"},
          {b:8,  n:"ALT"},   {b:1, n:"SHIFT"}
        ] | map(select($m / .b | floor % 2 == 1) | .n) | join(" + ");

        .[]
        | select(.description != "" and .description != null)
        | (if mods(.modmask) == "" then .key else mods(.modmask) + " + " + .key end) as $lhs
        | (.description | ascii_downcase) as $d
        | (if   $d | test("volume|mute|track|play|brightness|display")  then "media"
           elif $d | test("workspace|scratchpad|monitor")               then "workspace"
           elif $d | test("focus|window|float|fullscreen|pseudo|tile")  then "window"
           else "action" end) as $cat
        | [$cat, $lhs, .description] | @tsv
      '
    }

    # section_cat TITLE ROWS CATEGORY — render one hypr category as a table.
    section_cat() {
      section "$1" "$(printf '%s\n' "$2" | awk -F'\t' -v c="$3" '$1 == c { print $2 "\t" $3 }')"
    }

    render() {
      printf '  \033[1mKEYBINDS\033[0m   Herdr home-row: hold  f (left) or j (right), then key (opposite hand). Add Shift for the shift-family; either press order works.\n'

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

      section "HERDR · SHIFT-FAMILY  (hold f/j + Shift, then key)" "$(printf '%b\n' \
        'Shift + h/j/k/l\tswap pane in direction' \
        'Shift + p\trename pane' \
        'Shift + t\trename tab' \
        'Shift + x\tclose tab' \
        'Shift + n\tnew workspace' \
        'Shift + w\trename workspace' \
        'Shift + d\tclose workspace' \
        'Shift + g\tnew worktree (from base)' \
        'Shift + o\topen worktree picker' \
        'Shift + b\tremove worktree checkout' \
        'Shift + r\treload config' \
        'Shift + s\tsettings' \
        'Shift + / (?)\tthis cheatsheet')"

      section "HERDR · TYPING THESE BY HAND" "$(printf '%b\n' \
        'Ctrl+b then <key>\tworks for the plain family above' \
        'Ctrl+alt+<key>\tworks for the shift family above (no prefix)' \
        'Ctrl+b then Shift+<key>\tDOES NOT WORK -- shift exits prefix mode' \
        'Ctrl+b then Tab\tcycle pane next (no home-row equivalent)')"

      # Hyprland, categorised by hypr_rows.
      local rows; rows="$(hypr_rows || true)"
      section_cat "HYPRLAND · WINDOWS & FOCUS" "$rows" window
      section_cat "HYPRLAND · WORKSPACES"      "$rows" workspace
      section_cat "HYPRLAND · MEDIA & HARDWARE" "$rows" media
      section_cat "HYPRLAND · LAUNCH & ACTIONS" "$rows" action

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
