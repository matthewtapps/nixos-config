# transclude.nvim

Obsidian-style transclusion for Neovim. Renders `![[note]]`, `![[note#Heading]]`
and `![[note#^block]]` embeds as styled virtual lines directly below the embed,
approximating Obsidian's live preview.

## What it does

- Whole-file, `#Heading` section, and `#^block` paragraph embeds, with
  `|alias` display names.
- Nested embeds recurse (default depth 3) with cycle detection.
- Content is styled to match render-markdown.nvim: its highlight groups are
  used when present, with treesitter fallbacks (`@markup.*`) otherwise.
  Headings, bullets, checkboxes, quotes, code fences, inline
  bold/italic/code/links are approximated.
- The raw `![[...]]` line is covered by a `󰈔 name › anchor` header overlay,
  except when the cursor is on it — move onto the line to see/edit the source,
  and follow the link from there (e.g. obsidian.nvim's smart action).
- Embeds track live buffer content for open notes and re-render on write.
- Image/attachment embeds (`.png`, `.pdf`, …) are ignored — those belong to
  snacks.image / obsidian.nvim.

## Why virtual lines

Neovim extmark `virt_lines` are not real buffer text: treesitter never parses
them, so render-markdown.nvim can't style them and the cursor can't enter them.
That's the fundamental reason no plugin had this feature — the styling here is a
hand-rolled approximation, and embedded content is read-only (as in Obsidian's
preview).

## Setup

```lua
{
  dir = "~/dev/transclude.nvim",
  ft = "markdown",
  opts = {
    enabled = true,
    max_lines = 40,   -- cap per embed
    max_depth = 3,    -- nested embed recursion
    hide_raw = true,  -- overlay header on the raw line
    border = "▏",
    exclude = { "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "pdf", "mp4", "mp3", "wav" },
  },
}
```

Commands: `:Transclude [toggle|refresh|enable|disable]`.

Vault root resolution: obsidian.nvim's active workspace if loaded, else the
nearest ancestor containing `.obsidian`, else the buffer's directory. Link
resolution mirrors Obsidian's basename matching (case-insensitive, first match
wins).
