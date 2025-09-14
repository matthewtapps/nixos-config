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
    nixd
    nil
    lua-language-server
    typescript-language-server
    bash-language-server
    astro-language-server
    docker-language-server
    gopls
    terraform-ls
    vscode-langservers-extracted
    markdown-oxide
    ruff
    yaml-language-server
    omnisharp-roslyn
    tailwindcss-language-server
    phpactor

      # Formatters
      nixfmt
      shfmt
      black
      stylua
      prettier
      taplo
    ];
  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}
