-- Installs language servers into ~/.local/share/nvim/mason/bin, which mason
-- prepends to vim.env.PATH so the bare `cmd` names in lsp/*.lua resolve.
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("*") },
})

local icons = require("icons")

require("mason").setup({
  ui = {
    icons = {
      package_installed = icons.ui.Check,
      package_pending = icons.ui.ChevronRight,
      package_uninstalled = icons.ui.Close,
    },
  },
})

vim.keymap.set("n", "<leader>sm", "<cmd>Mason<cr>", { desc = "Mason" })

--- Servers from lua/servers.lua whose `cmd` executable is not on PATH.
--- @return { server: string, exe: string }[]
local function missing_servers()
  local missing = {}
  for _, server in ipairs(require("servers")) do
    local config = vim.lsp.config[server]
    local cmd = config and config.cmd
    -- `cmd` may be a function (custom rpc launcher); those are not mason-managed.
    local exe = type(cmd) == "table" and cmd[1] or nil
    if exe and vim.fn.executable(exe) == 0 then
      missing[#missing + 1] = { server = server, exe = exe }
    end
  end
  return missing
end

--- Mason package names keyed by every executable they provide, so package names
--- are derived from lsp/*.lua rather than duplicated in a second list.
--- @return table<string, string>
local function index_by_executable()
  local index = {}
  for _, pkg in ipairs(require("mason-registry").get_all_packages()) do
    for exe in pairs(pkg.spec.bin or {}) do
      index[exe] = pkg.name
    end
  end
  return index
end

local function install_missing(missing)
  local registry = require("mason-registry")
  local index = index_by_executable()

  for _, entry in ipairs(missing) do
    local name = index[entry.exe]
    if not name then
      vim.notify(("No mason package provides %q (%s)"):format(entry.exe, entry.server), vim.log.levels.WARN, { title = "mason.nvim" })
    else
      local pkg = registry.get_package(name)
      if not pkg:is_installed() then
        vim.notify(("Installing %s"):format(name), vim.log.levels.INFO, { title = "mason.nvim" })
        -- Report failures: mason only surfaces them via :MasonInstall and the
        -- :Mason window, so a programmatic install fails silently and is retried
        -- on every startup.
        pkg:install(nil, function(success, err)
          if not success then
            vim.schedule(function()
              vim.notify(("Failed to install %s: %s"):format(name, err), vim.log.levels.ERROR, { title = "mason.nvim" })
            end)
          end
        end)
      end
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("user.mason", { clear = true }),
  once = true,
  callback = function()
    local missing = missing_servers()
    if #missing == 0 then
      return
    end
    -- Refresh first: the local registry is empty until it has been fetched once.
    require("mason-registry").refresh(vim.schedule_wrap(function()
      install_missing(missing)
    end))
  end,
  desc = "Install missing language servers",
})
