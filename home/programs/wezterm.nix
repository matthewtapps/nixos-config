_: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      return {
        color-scheme = "Everforest Dark Soft (Gogh)",
        font = wezterm.font("GeistMono Nerd Font"),
        enable_tab_bar = false,
      }
    '';
  };
}
