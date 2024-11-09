{ pkgs, theme, ... }: {
  programs.kitty = {
    enable = true;
    font.name = "CommitMono Nerd Font";
    shellIntegration.enableZshIntegration = true;
    themeFile = "everforest_dark_hard";
  };
}
