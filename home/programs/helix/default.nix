{ pkgs, ... }:
let
  vim-hx = pkgs.callPackage ../../../nixos/packages/vim-hx.nix {};
in
{
  home.packages = with pkgs; [
    vim-hx
    
    # Language servers
    nixd
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

    # Formatters
    taplo
  ];
  
  home.file."./.config/helix/" = {
    source = ./helix;
    recursive = true;
  };
}
