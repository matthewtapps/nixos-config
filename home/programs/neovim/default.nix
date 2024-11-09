{ pkgs, ... }:
# let
#
#   # treesitterWithGrammars = (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
#   #   p.bash
#   #   p.comment
#   #   p.css
#   #   p.dockerfile
#   #   p.fish
#   #   p.gitattributes
#   #   p.gitignore
#   #   p.go
#   #   p.gomod
#   #   p.gowork
#   #   p.hcl
#   #   p.javascript
#   #   p.jq
#   #   p.json5
#   #   p.json
#   #   p.lua
#   #   p.make
#   #   p.markdown
#   #   p.nix
#   #   p.python
#   #   p.rust
#   #   p.toml
#   #   p.typescript
#   #   p.vue
#   #   p.yaml
#   # ]));
#   #
#   # treesitter-parsers = pkgs.symlinkJoin {
#   #   name = "treesitter-parsers";
#   #   paths = treesitterWithGrammars.dependencies;
#   # };
# in
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    coc.enable = false;
    withNodeJs = true;
    extraLuaPackages = ps: [ ps.lua ps.luarocks-nix ps.magick ];
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

      # Formatters
      nixfmt
      shfmt
      black

      # DAP
      vscode-js-debug

      # Testing
      vimPlugins.neotest-jest
    ];

    # plugins = [ treesitterWithGrammars ];
  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };

  # home.file."./.config/nvim/lua/matt/init.lua".text = ''
  #   require("matt.set")
  #   require("matt.keymaps")
  #   require("matt.lazy")
  # '';
  # vim.opt.runtimepath:append("${treesitter-parsers}")
  # part of the above??

  # Treesitter is configured as a locally developed module in lazy.nvim
  # we hardcode a symlink here so that we can refer to it in our lazy config
  # home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
  #   recursive = true;
  #   source = treesitterWithGrammars;
  # };
}
