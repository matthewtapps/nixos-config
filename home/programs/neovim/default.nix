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
      nodejs_22
      cargo
      rustc
      lazygit
      fzf

      # Language servers
      lua-language-server
      rust-analyzer-unwrapped
      nixd
      nil
      typescript-language-server
      gopls

      # Formatters
      nixfmt-rfc-style
      shfmt
      black

      # DAP
      vscode-js-debug

      # Testing
      vimPlugins.neotest-jest
    ];

  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}
