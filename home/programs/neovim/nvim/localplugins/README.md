# localplugins

Neovim plugins written for this setup, vendored here so every machine built from
this flake gets them. They used to live in `~/dev/*.nvim`, which meant only this
laptop had them.

Runtime files plus `tests/` are kept; screenshots and release docs stay in the
upstream checkouts. Run the markdown-table-wrap suite from its directory with:

```
nvim --headless -u NONE --cmd "set rtp+=$PWD" -l tests/run.lua
```

`lazy.nvim` loads each one from `vim.fn.stdpath("config") .. "/localplugins/<name>"`
(see `../lua/plugins/`). This directory is deliberately *not* on the runtimepath
itself — `nvim/lua/` and `nvim/plugin/` are auto-sourced, and a plugin sitting
there would load twice.

Editing: this copy is authoritative, but `~/.config/nvim` is a read-only symlink
tree out of the Nix store, so changes need a `home-manager switch` (or
`nixos-rebuild switch`) before nvim picks them up.

- `markdown-table-wrap.nvim` — fork of `ice345/markdown-table-wrap.nvim` adding
  focus-mode table editing. Mirror at `github.com/matthewtapps/markdown-table-wrap.nvim`;
  `~/dev/markdown-table-wrap.nvim` is the git checkout used to publish, and must
  be re-synced by hand from here before pushing.
- `transclude.nvim` — renders Obsidian `![[note]]` embeds as virtual lines. Never
  published anywhere; this is the only copy.
