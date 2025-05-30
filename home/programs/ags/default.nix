{ inputs, pkgs, ... }:
{
  # add the home manager module
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;

    configDir = ../ags;

    extraPackages = with pkgs; [
      inputs.ags.packages.${pkgs.system}.battery
      inputs.ags.packages.${pkgs.system}.hyprland
      inputs.ags.packages.${pkgs.system}.apps
      inputs.ags.packages.${pkgs.system}.auth
      inputs.ags.packages.${pkgs.system}.bluetooth
      inputs.ags.packages.${pkgs.system}.cava
      inputs.ags.packages.${pkgs.system}.io
      inputs.ags.packages.${pkgs.system}.network
      inputs.ags.packages.${pkgs.system}.powerprofiles
      inputs.ags.packages.${pkgs.system}.wireplumber
      inputs.ags.packages.${pkgs.system}.notifd
      inputs.ags.packages.${pkgs.system}.mpris
      fzf
    ];

  };
  home.packages = [
    inputs.ags.packages.${pkgs.system}.battery
    inputs.ags.packages.${pkgs.system}.hyprland
    inputs.ags.packages.${pkgs.system}.apps
    inputs.ags.packages.${pkgs.system}.auth
    inputs.ags.packages.${pkgs.system}.bluetooth
    inputs.ags.packages.${pkgs.system}.cava
    inputs.ags.packages.${pkgs.system}.io
    inputs.ags.packages.${pkgs.system}.network
    inputs.ags.packages.${pkgs.system}.powerprofiles
    inputs.ags.packages.${pkgs.system}.wireplumber
    inputs.ags.packages.${pkgs.system}.notifd
    inputs.ags.packages.${pkgs.system}.mpris
  ];
}
