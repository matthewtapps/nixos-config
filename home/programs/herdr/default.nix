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
    close_tab        = ["prefix+shift+x", "prefix+d"]
    settings         = "prefix+shift+s"               # freed from prefix+s

    # Worktree open/remove are unbound by default; bind so kanata's shift+o /
    # shift+b reach them. new_worktree keeps its default (shift+g).
    open_worktree    = "prefix+shift+o"
    remove_worktree  = "prefix+shift+b"

    # Cycle spaces on [ / ] (unbound by default; freed by moving copy_mode to y).
    previous_workspace = "prefix+["
    next_workspace     = "prefix+]"
  '';
in
{
  home.packages = [ herdr ];

  # Herdr keybinds. Herdr has no hold-vs-tap; the home-row-mod feel comes from
  # kanata (nixos/modules/kanata.nix), which turns hold-f/j into a layer emitting
  # Herdr's `ctrl+b <key>` prefix sequence. Key->action here must match kanata.
  # Herdr's defaults are mnemonic; only the entries below differ.
  #
  #   hold f/j + key: h/j/k/l focus pane · v/s split · x close pane · d close tab
  #     z zoom · r resize · e scrollback · y copy · c new tab · n/p tab · q detach
  #     w workspaces · g goto · o notification · b sidebar · [ ] cycle workspace
  #   + shift: h/j/k/l swap pane · p rename pane · t rename tab · n/w/d
  #     new/rename/close workspace · g/o/b new/open/remove worktree · r reload
  #     · s settings · / (?) full list.  Press f/j BEFORE shift.
  #
  #   Worktrees: a repo workspace is the base checkout; Shift+g forks a linked
  #   worktree (own branch + workspace, nested under the repo in the sidebar).
  #   new/open must run from the base, not inside a worktree; Shift+b removes the
  #   current worktree (confirms). Switch base<->worktree with w or [ / ].
  xdg.configFile."herdr/config.toml".text = mkConfig "~/.herdr";
  xdg.configFile."herdr/config-cs.toml".text = mkConfig "~/cs";
}
