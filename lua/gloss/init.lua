local M = {}

local defaults = {
  keymaps = {
    annotate   = "<leader>ca",
    next_annot = "]a",
    prev_annot = "[a",
  },
  auto_highlight = true,
  virtual_text   = true,
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  vim.api.nvim_set_hl(0, "GlossAnnotated", { bg = "#2d1f00", default = true })
  vim.api.nvim_set_hl(0, "GlossVirtText",  { fg = "#888888", italic = true, default = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("GlossKeymaps", { clear = true }),
    pattern = "markdown",
    callback = function(ev)
      local ann = require("gloss.annotations")
      local bufopts = { buffer = ev.buf, silent = true }
      vim.keymap.set("n", opts.keymaps.annotate,   ann.annotate_current, bufopts)
      vim.keymap.set("v", opts.keymaps.annotate,   ann.annotate_visual,  bufopts)
      vim.keymap.set("n", opts.keymaps.next_annot, function() ann.jump(1)  end, bufopts)
      vim.keymap.set("n", opts.keymaps.prev_annot, function() ann.jump(-1) end, bufopts)
    end,
  })

  if opts.auto_highlight then
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("GlossHighlight", { clear = true }),
      pattern = "*.md",
      callback = function(ev)
        require("gloss.annotations").refresh_highlights(ev.buf)
      end,
    })
  end
end

return M
