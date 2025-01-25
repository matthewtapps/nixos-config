{ inputs, pkgs, ... }:
{
  # add the home manager module
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;

    configDir = ../ags;

    extraPackages = with pkgs; [
      inputs.ags.packages.${pkgs.system}.battery
      fzf
    ];
  };
}
