{ pkgs, ... }:
{
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];

  # Enables preferences to be saved
  programs.xfconf.enable = true;

  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
