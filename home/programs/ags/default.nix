{ pkgs, inputs, ... }: {

  imports = [ inputs.ags.homeManagerModules.default ];
  programs.ags = {
    enable = true;
    configDir = ./.;
    extraPackages = with pkgs; [ gtksourceview webkitgtk accountsservice ];
  };

  # home.file."./.config/ags" = {
  #   source = ./.;
  #   recursive = true;
  # };
}
