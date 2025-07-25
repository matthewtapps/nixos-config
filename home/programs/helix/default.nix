{ pkgs, ... }:
{
  home.packages = with pkgs; [
    evil-helix
  ];

  home.file."./.config/helix/" = {
    source = ./helix;
    recursive = true;
  };
}
