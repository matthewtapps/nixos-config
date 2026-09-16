# localplugins

Neovim plugins written for this setup, vendored here so every machine built from
this flake gets them. They used to live in `~/dev/*.nvim`, which meant only this
laptop had them.

`lazy.nvim` loads each one from `vim.fn.stdpath("config") .. "/localplugins/<name>"`
(see `../lua/plugins/`). This directory is deliberately *not* on the runtimepath
itself — `nvim/lua/` and `nvim/plugin/` are auto-sourced, and a plugin sitting
there would load twice.

Editing: this copy is authoritative, but `~/.config/nvim` is a read-only symlink
tree out of the Nix store, so changes need a `home-manager switch` (or
`nixos-rebuild switch`) before nvim picks them up.

- `transclude.nvim` — renders Obsidian `![[note]]` embeds as virtual lines. Never
  published anywhere; this is the only copy.
