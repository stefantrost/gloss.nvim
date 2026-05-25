# gloss.nvim

Neovim plugin for annotating markdown files using the [gloss](https://github.com/stefantrost/gloss)
annotation format — the same format the gloss TUI produces.

Annotations are paired HTML comments that wrap the lines you're commenting on. They are
invisible in any rendered markdown view but fully readable by an LLM in raw form:

```markdown
<!-- ANNOTATION_START -->
- spin up postgres
- run migrations
<!-- ANNOTATION_END: migrations need a rollback strategy -->
```

See the [gloss repo](https://github.com/stefantrost/gloss) for the full annotation format spec
and the companion TUI.

---

## Features

- Annotate the current line or a visual selection
- Navigate between annotations with `]a` / `[a`
- Annotated regions highlighted with an amber background tint
- Annotation text shown as virtual text on the end marker line
- Auto-downloads the `gloss` binary on first use if not in `PATH`

---

## Requirements

- Neovim ≥ 0.10
- `curl` (for auto-download; if unavailable, install `gloss` manually — see below)
- Linux or macOS (Windows not currently supported)

---

## Installation

### lazy.nvim

```lua
{
  "stefantrost/gloss.nvim",
  ft = "markdown",
  config = function()
    require("gloss").setup()
  end,
}
```

The plugin downloads the `gloss` binary automatically on first use. If you prefer to install
it manually:

```sh
# requires Go 1.21+
go install github.com/stefantrost/gloss/cmd/gloss@latest
```

---

## Configuration

All options are optional — defaults shown:

```lua
require("gloss").setup({
  keymaps = {
    annotate   = "<leader>ca",  -- normal: annotate current line; visual: annotate selection
    next_annot = "]a",
    prev_annot = "[a",
  },
  auto_highlight = true,   -- refresh highlights on BufEnter and BufWritePost
  virtual_text   = true,   -- show annotation text as virtual text
})
```

To disable default keymaps, set them to `false`:

```lua
require("gloss").setup({
  keymaps = { annotate = false, next_annot = false, prev_annot = false },
})
```

---

## Highlight groups

Override after `setup()` to match your colorscheme:

| Group | Default | Used for |
|-------|---------|----------|
| `GlossAnnotated` | `bg = #2d1f00` | Annotated line background |
| `GlossVirtText` | `fg = #888888, italic` | Annotation virtual text |

```lua
vim.api.nvim_set_hl(0, "GlossAnnotated", { bg = "#1e2a1e" })
vim.api.nvim_set_hl(0, "GlossVirtText",  { fg = "#6a9955", italic = true })
```

---

## License

MIT
