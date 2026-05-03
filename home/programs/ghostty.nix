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
    };
  };
}
