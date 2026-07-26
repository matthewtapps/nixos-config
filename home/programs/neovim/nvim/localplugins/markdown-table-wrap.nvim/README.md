# markdown-table-wrap.nvim (fork)

A fork of [ice345/markdown-table-wrap.nvim](https://github.com/ice345/markdown-table-wrap.nvim)
that grows the original wrapped-table *renderer* into a full **native-feeling
table editor** for Markdown pipe tables.

The upstream plugin renders pipe tables with wrapped cell content as a virtual
overlay — beautiful, but read-only, and the cursor lives in the concealed
source lines underneath, visually disconnected from the rendered rows. This
fork adds **focus mode**: moving onto a table seamlessly places your cursor
*inside* the rendered table, where all normal Vim motions, operators, text
objects, search, and scrolling work directly on the pretty view, while every
edit writes through to the Markdown source underneath.

## What the fork adds

### Focus mode (`auto_focus = true`)

- Moving the cursor onto a table (j/k, search jump, `G`, …) automatically
  enters a borderless float containing the rendered table as a real buffer.
  Adjacent-line entry lands on the top/bottom border; jumps land on the exact
  cell and column (a search match is under the cursor).
- `j`/`k`/`w`/`e`/`f`/`/`/counts — everything native, on the rendered rows.
- Motion through the edges exits seamlessly: `j` past the bottom border drops
  you on the line after the table; counts spill (`10k` five rows in exits and
  continues 5 lines above); `<C-d>`/`<C-u>`/`<C-f>`/`<C-b>` follow the same
  rule.
- **Lockstep scrolling**: the document scrolls with the focus cursor,
  respecting your `scrolloff`, by screen lines (virt_lines-aware). The float
  frame always covers exactly the visible slice of the table — partially
  scrolled tables (top or bottom clipped, taller than the viewport) stay
  pixel-aligned with the overlay behind.
- **Native relative numbers**: when the source window shows numbers, the float
  grows its own relative-number column aligned with rendered rows, and the
  document's numbers outside the table track your position for accurate `Nj`
  exit targets.

### Editing (all cell-scoped, all write-through)

| Keys | Action |
|---|---|
| `i` `a` `I` `A` | insert at cursor / after / cell start / cell end |
| `C` / `cc` `S` | change to end of cell / whole cell |
| `c{motion}` `ciw` `caw` `c$` … | change operator with any motion/text object |
| `d{motion}` `diw` `dd` `D` | delete (region / cell / to end), yanks to `"` |
| `v` + `c`/`d`/`x` | operate on the visual selection (clamped to one cell) |
| `r{char}` `x` `X` `~` | replace / delete / toggle case at the visual position |
| `yy` / `p` `P` | yank cell text / paste into cell |
| `o` `O` | new table row below / above |
| `go` `gO` | new column right / left |
| `dc` | delete column |
| `u` `<C-r>` | undo / redo the document, re-rendered in place |
| `<CR>` | open the cell editor in normal mode |
| `q` | escape hatch: drop to raw Markdown source until you leave the table |
| `:w` | write the document |

- Insert-style edits open an **in-place cell editor**: a borderless float over
  the exact cell rectangle, live write-through (the table reshapes as you
  type), leave insert mode to save and land back in focus mode.
- Undo parity: an insert session is one undo step (`undojoin`), every discrete
  operator is its own step, column/row operations are single steps.
- Pipes are escaped/unescaped automatically (code spans respected).
- Search (`/` `?` `n` `N` `*` `#`) forwards to the document and cycles
  seamlessly through and out of tables. [flash.nvim](https://github.com/folke/flash.nvim)'s
  `s` works natively on the rendered table.
- `:MarkdownTableCreate` inserts a one-column skeleton table below the cursor.

### Everything upstream, unchanged

The overlay renderer, wrapping engine, themes, float preview, and cell
navigation commands from upstream are intact — focus mode is layered on top
and entirely optional (`auto_focus` defaults to `false`).

## Install (lazy.nvim)

```lua
return {
  "matthewtapps/markdown-table-wrap.nvim",
  ft = { "markdown", "markdown.mdx" },
  opts = {
    highlight_preset = "render_markdown",
    auto_focus = true, -- enable seamless focus-mode editing
  },
}
```

If you use `render-markdown.nvim`, disable its table renderer so this plugin
owns pipe tables:

```lua
{ "MeanderingProgrammer/render-markdown.nvim", opts = { pipe_table = { enabled = false } } }
```

## New commands

| Command | Action |
|---|---|
| `:MarkdownTableFocus` | toggle focus mode on the table under the cursor |
| `:MarkdownTableEditCell` | edit the current cell in a floating editor |
| `:MarkdownTableCreate` | insert a new one-column table below the cursor |

## New configuration

| Option | Default | Meaning |
|---|---|---|
| `auto_focus` | `false` | auto-enter focus mode when the cursor lands on a table |

Focus mode temporarily zeroes the source window's `scrolloff` and enables
`smoothscroll` (both window-local, restored on exit) and enforces your
configured scrolloff margin itself, so scrolling matches your settings.

## Known limits

- `.` repeat does not replay cell operators.
- Registers: unnamed register only (`"a`-style named registers not wired).
- `y{motion}` yanks the rendered text natively; `yy` yanks the logical cell.
- Multi-cell (blockwise) editing is intentionally unsupported.
- Requires Neovim 0.10+.

## Credits

All rendering fundamentals are the work of [ice345](https://github.com/ice345/markdown-table-wrap.nvim).
This fork adds the focus-mode editing layer. The upstream README is preserved
in git history.

## License

MIT, same as upstream — see [LICENSE](LICENSE).
