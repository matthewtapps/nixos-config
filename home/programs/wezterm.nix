_: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local config = {}
      config.color_scheme = "Everforest Dark Medium (Gogh)"
      config.font = wezterm.font("GeistMono Nerd Font")
      config.enable_tab_bar = false
      config.window_padding = {
        left = '0px',
        right = '0px',
        top = '0px',
        bottom = '0.25cell'
      }
      enable_scroll_bar = false

      return config
    '';
  };
}
