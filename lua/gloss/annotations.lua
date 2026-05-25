local binary = require("gloss.binary")
local ns = vim.api.nvim_create_namespace("gloss")

local M = {}

local function parse_sync(bufnr)
  local bin = binary.find()
  if not bin then return {} end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, "\n")
  local output = vim.fn.system({ bin, "parse" }, input)
  if vim.v.shell_error ~= 0 then return {} end
  local ok, decoded = pcall(vim.json.decode, output)
  return (ok and decoded) or {}
end

-- Annotate lines [start_line, end_line] (0-indexed) in bufnr with text.
-- Replaces buffer contents with the result from `gloss annotate`.
function M.annotate(bufnr, start_line, end_line, text)
  binary.ensure(function(bin)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, "\n")
    local output = vim.fn.system({
      bin, "annotate",
      "--start=" .. start_line,
      "--end=" .. end_line,
      "--text=" .. text,
    }, input)
    if vim.v.shell_error ~= 0 then
      vim.notify("gloss: annotate failed", vim.log.levels.ERROR)
      return
    end
    -- strip trailing newline and split
    local new_lines = vim.split(output:gsub("\n$", ""), "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    M.refresh_highlights(bufnr)
  end)
end

-- Annotate the current line (normal mode).
function M.annotate_current()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
  vim.ui.input({ prompt = "Annotation: " }, function(text)
    if text and text ~= "" then
      M.annotate(bufnr, row, row, text)
    end
  end)
end

-- Annotate the visual selection (visual mode).
function M.annotate_visual()
  local bufnr = vim.api.nvim_get_current_buf()
  -- exit visual mode first so '< and '> marks are up to date
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  local start_line = vim.fn.line("'<") - 1  -- 0-indexed
  local end_line   = vim.fn.line("'>") - 1
  vim.ui.input({ prompt = "Annotation: " }, function(text)
    if text and text ~= "" then
      M.annotate(bufnr, start_line, end_line, text)
    end
  end)
end

-- Jump to the next (dir=1) or previous (dir=-1) annotation.
function M.jump(dir)
  local bufnr = vim.api.nvim_get_current_buf()
  local annotations = parse_sync(bufnr)
  if #annotations == 0 then
    vim.notify("gloss: no annotations", vim.log.levels.INFO)
    return
  end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed

  if dir > 0 then
    for _, a in ipairs(annotations) do
      if a.start > cursor_row then
        vim.api.nvim_win_set_cursor(0, { a.start + 1, 0 })
        return
      end
    end
    vim.notify("gloss: no next annotation", vim.log.levels.INFO)
  else
    for i = #annotations, 1, -1 do
      local a = annotations[i]
      if a.start < cursor_row then
        vim.api.nvim_win_set_cursor(0, { a.start + 1, 0 })
        return
      end
    end
    vim.notify("gloss: no previous annotation", vim.log.levels.INFO)
  end
end

-- Refresh extmark highlights and virtual text for all annotations in bufnr.
function M.refresh_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local annotations = parse_sync(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for _, a in ipairs(annotations) do
    -- highlight every line in the annotated region
    for lnum = a.start, a["end"] do
      if lnum < line_count then
        vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
          line_hl_group = "GlossAnnotated",
          priority = 50,
        })
      end
    end
    -- virtual text showing the annotation note on the END marker line
    if a["end"] < line_count and a.text ~= "" then
      vim.api.nvim_buf_set_extmark(bufnr, ns, a["end"], 0, {
        virt_text = { { "  » " .. a.text, "GlossVirtText" } },
        virt_text_pos = "eol",
        priority = 50,
      })
    end
  end
end

return M
