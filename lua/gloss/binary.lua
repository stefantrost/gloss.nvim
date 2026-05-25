local M = {}

local install_path = vim.fn.stdpath("data") .. "/gloss/gloss"

function M.find()
  if vim.fn.executable("gloss") == 1 then return "gloss" end
  if vim.fn.executable(install_path) == 1 then return install_path end
  return nil
end

function M.ensure(callback)
  local bin = M.find()
  if bin then
    callback(bin)
    return
  end

  local uname = vim.uv.os_uname()
  local os_map   = { Linux = "linux", Darwin = "darwin" }
  local arch_map = { x86_64 = "amd64", arm64 = "arm64", aarch64 = "arm64" }
  local os_name  = os_map[uname.sysname]
  local arch     = arch_map[uname.machine]

  if not os_name or not arch then
    vim.notify("gloss: unsupported platform " .. uname.sysname .. "/" .. uname.machine, vim.log.levels.ERROR)
    return
  end

  local url = string.format(
    "https://github.com/techscene/gloss/releases/latest/download/gloss_%s_%s",
    os_name, arch
  )
  vim.fn.mkdir(vim.fn.fnamemodify(install_path, ":h"), "p")
  vim.notify("gloss: downloading binary from " .. url .. " …", vim.log.levels.INFO)

  vim.fn.jobstart({ "curl", "-fsSL", "-o", install_path, url }, {
    on_exit = function(_, code)
      if code == 0 then
        vim.fn.system({ "chmod", "+x", install_path })
        vim.notify("gloss: binary installed at " .. install_path, vim.log.levels.INFO)
        callback(install_path)
      else
        vim.notify("gloss: download failed (exit " .. code .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

return M
