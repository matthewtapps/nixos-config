{
  pkgs,
  inputs,
  ...
}:
let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Config body shared by both variants; only worktrees.directory differs.
  # config.toml is the default; config-cs.toml keeps ~/cs repos' worktrees under
  # ~/cs so the shared ~/cs/flake.nix stays an ancestor. The zsh herdr() wrapper
  # (home/programs/zsh) selects config-cs via HERDR_CONFIG_PATH when launched
  # under ~/cs.
  #
  # ~/cs repos use the "worktrees level 2" bare layout (~/cs/<repo>/.bare + a
  # .git pointer file). Herdr places new worktrees at <directory>/<repo>/<branch>,
  # so directory = "~/cs" lands them at ~/cs/<repo>/<branch> — siblings of the
  # bare repo's other worktrees, right inside the repo dir. Forking must start
  # from the bare-parent workspace (cwd ~/cs/<repo>); Herdr rejects a linked
  # worktree as the source (error: linked_worktree_source).
  mkConfig = worktreeDir: ''
    # Herdr writes `onboarding = false` itself once the overlay is dismissed,
    # but this file is a read-only store symlink, so without it set here the
    # first-run overlay returns on every launch.
    onboarding = false

    [update]
    # herdr comes from the pinned flake input and `herdr update` cannot write to
    # the store. manifest_check stays on: those manifests are runtime data.
    version_check = false

    [theme]
    # Derive palette from the host terminal, so it matches ghostty/stylix.
    name = "terminal"

    [theme.custom]
    # everforest-dark-soft accents. panel_bg left unset (transparent) so panels
    # keep the terminal's grey; that also makes panel_contrast_fg fall back to
    # surface_dim, so dark surface_dim/surface0 give readable accent text and row
    # highlights darker than the background.
    accent      = "#a7c080"  # highlight background
    surface_dim = "#232a2e"  # accent-highlight text + active-row bg + dividers
    surface0    = "#2d353b"  # selected-row bg
    surface1    = "#4d5960"  # dragged-row / secondary bg
    mauve       = "#d699b6"  # branch label on highlighted rows

    [ui]
    # Sort agent sidebar by priority/activity, not by space.
    agent_panel_sort = "priority"

    [worktrees]
    directory = "${worktreeDir}"

    [keys]
    prefix = "ctrl+b"

    # Remap actions whose default prefix key isn't the mnemonic kanata drives.
    split_horizontal = ["prefix+minus", "prefix+s"]
    copy_mode        = "prefix+y"                     # y (yank)

    # Cycle spaces on [ / ] (unbound by default; freed by moving copy_mode to y).
    previous_workspace = "prefix+["
    next_workspace     = "prefix+]"

    # Shift-family: direct chords, overriding Herdr's `prefix+shift+<key>`
    # defaults, which cannot fire. Herdr enables REPORT_EVENT_TYPES, so Shift
    # arrives as its own key event; in prefix mode it matches nothing and falls
    # through to leave_command_mode() (app/input/navigate.rs), so the letter
    # types into the pane. Direct bindings take the Navigate path, which drops
    # modifier-only events (app/input/terminal.rs), and never enter prefix mode.
    #
    # kanata emits each as one chord (nixos/modules/kanata.nix); the letters
    # mirror the home-row mnemonics rather than being typed by hand.
    # ctrl+alt+<letter> is free: Hyprland binds only CTRL+ALT+(SHIFT+)slash.
    swap_pane_left   = "ctrl+alt+h"
    swap_pane_down   = "ctrl+alt+j"
    swap_pane_up     = "ctrl+alt+k"
    swap_pane_right  = "ctrl+alt+l"
    rename_pane      = "ctrl+alt+p"
    rename_tab       = "ctrl+alt+t"
    close_tab        = ["ctrl+alt+x", "prefix+d"]
    new_workspace    = "ctrl+alt+n"
    rename_workspace = "ctrl+alt+w"
    close_workspace  = "ctrl+alt+d"
    new_worktree     = "ctrl+alt+g"
    open_worktree    = "ctrl+alt+o"
    remove_worktree  = "ctrl+alt+b"
    reload_config    = "ctrl+alt+r"
    settings         = "ctrl+alt+s"
  '';
in
{
  home.packages = [ herdr ];

  # Herdr has no hold-vs-tap; the home-row-mod feel comes from kanata
  # (nixos/modules/kanata.nix), which drives these bindings from hold-f/j.
  # Key->action above must match kanata. Only non-default entries are listed.
  #
  #   hold f/j + key: h/j/k/l focus pane · v/s split · x close pane · d close tab
  #     z zoom · r resize · e scrollback · y copy · c new tab · n/p tab · q detach
  #     w workspaces · g goto · o notification · b sidebar · [ ] cycle workspace
  #   + shift: h/j/k/l swap pane · p rename pane · t rename tab · x close tab
  #     · n/w/d new/rename/close workspace · g/o/b new/open/remove worktree
  #     · r reload · s settings.  Either press order works.
  #
  #   Worktrees: a repo workspace is the base checkout; Shift+g forks a linked
  #   worktree (own branch + workspace, nested under the repo in the sidebar).
  #   new/open must run from the base, not inside a worktree; Shift+b removes the
  #   current worktree (confirms). Switch base<->worktree with w or [ / ].
  xdg.configFile."herdr/config.toml".text = mkConfig "~/.herdr";
  xdg.configFile."herdr/config-cs.toml".text = mkConfig "~/cs";
}
