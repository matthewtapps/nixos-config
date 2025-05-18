{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    coc.enable = false;
    withNodeJs = true;
    extraLuaPackages = ps: [
      ps.lua
      ps.luarocks-nix
      ps.magick
    ];
    extraPackages = with pkgs; [
      # Binaries
      ripgrep
      fd
      lazygit
      fzf

      # Language servers
      lua-language-server
      nixd
      nil

      # Formatters
      nixfmt-rfc-style
      shfmt
      black
      stylua
      nodePackages_latest.prettier # Used for so many things
    ];

  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}
