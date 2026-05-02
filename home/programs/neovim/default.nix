{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    coc.enable = false;
    withNodeJs = true;
    withRuby = false;
    withPython3 = false;

    plugins = [
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (
        p: with p; [
          astro
          bash
          c_sharp
          css
          diff
          eex
          elixir
          erlang
          glimmer
          glsl
          hcl
          heex
          html
          hyprlang
          javascript
          json
          lua
          markdown
          markdown_inline
          nix
          python
          regex
          ruby
          rust
          sql
          svelte
          terraform
          toml
          typescript
          vim
          vimdoc
          yaml
        ]
      ))
    ];

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
      rubyPackages_3_3.ruby-lsp
      sqls
      glsl_analyzer

      # Formatters
      nixfmt
      shfmt
      black
      stylua
      prettier
      taplo
      pretty-php
    ];
  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}
