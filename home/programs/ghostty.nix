_: {
  programs.ghostty = {
    enable = true;
    settings = {
      # Launch the login shell via the stable system-profile path rather than
      # inheriting $SHELL. Ghostty reads $SHELL from its own env, captured at
      # compositor login — a stale value there (e.g. an old login shell whose
      # store path was GC'd) makes every new window fail to spawn. This path
      # always resolves to the current zsh and is never GC'd while it's the
      # active system, so it tracks the login shell without the staleness.
      command = "/run/current-system/sw/bin/zsh";
      window-decoration = false;
      scrollback-limit = 104857600;
      confirm-close-surface = false;
      mouse-hide-while-typing = true;
      copy-on-select = false;
      window-inherit-working-directory = false;
      cursor-click-to-move = true;
      notify-on-command-finish = "unfocused";
      notify-on-command-finish-after = "10s";
      keybind = [
        "shift+up=jump_to_prompt:-1"
        "shift+down=jump_to_prompt:1"
      ];
    };
  };
}
