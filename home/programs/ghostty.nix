_: {
  programs.ghostty = {
    enable = true;
    settings = {
      window-decoration = false;
      scrollback-limit = 10000;
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
