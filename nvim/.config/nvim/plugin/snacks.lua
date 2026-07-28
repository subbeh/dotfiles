vim.pack.add({ "https://github.com/folke/snacks.nvim" })

local icons = require("icons")
local snacks = require("snacks")
local colors = require("colors")

require("snacks").setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      keys = {
        -- { icon = icons.ui.FindFile, key = "f", desc = "Find File", action = "<cmd>lua require('telescope').extensions.smart_open.smart_open({ cwd_only = true })<cr>" }, -- TODO
        { icon = icons.ui.NewFile, key = "n", desc = "New File", action = ":ene | startinsert" },
        -- { icon = icons.ui.FindText, key = "g", desc = "Find Text", action = ":Telescope live_grep" }, -- TODO
        -- { icon = icons.ui.Files, key = "r", desc = "Recent Files", action = ":Telescope oldfiles" }, -- TODO
        { icon = icons.ui.Config, key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = icons.ui.Refresh, key = "s", desc = "Restore Session", section = "session" },
        { icon = icons.ui.Exit, key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { icon = icons.ui.Keyboard, title = "Keymaps", section = "keys", indent = 2, padding = 1 },
      { icon = icons.ui.Files, title = "Recent Files", section = "recent_files", indent = 2, padding = 1, cwd = true },
      { icon = icons.ui.FolderOpen, title = "Projects", section = "projects", indent = 2, padding = 1 },
      {
        pane = 2,
        icon = " ",
        desc = "Browse Repo",
        padding = 1,
        key = "b",
        action = function()
          snacks.gitbrowse()
        end,
      },
      function()
        local in_git = snacks.git.get_root() ~= nil
        local cmds = {
          {
            icon = icons.git.Branch,
            title = "Git Status",
            cmd = "git --no-pager diff --stat -B -M -C",
            height = 10,
          },
          {
            icon = icons.git.PR,
            title = "Open PRs",
            cmd = "gh pr list -L 3",
            key = "p",
            action = function()
              vim.fn.jobstart("gh pr list --web", { detach = true })
            end,
            height = 7,
          },
        }
        return vim.tbl_map(function(cmd)
          return vim.tbl_extend("force", {
            pane = 2,
            section = "terminal",
            enabled = in_git,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          }, cmd)
        end, cmds)
      end,
    },
  },
  picker = {
    hidden = true,
    ignored = false,
    exclude = { ".git" },
    sources = {
      -- Must explicitly set hidden=true per source to override source defaults
      files = {
        hidden = true,
      },
      grep = {
        hidden = true,
      },
      grep_buffers = {
        hidden = true,
      },
      explorer = {
        hidden = true,
      },
      buffers = {
        current = false,
        sort_lastused = true,
        win = {
          list = {
            keys = {
              ["<Tab>"] = function(picker)
                picker:close()
              end,
              ["dd"] = "bufdelete",
            },
          },
        },
      },
    },
    formatters = {
      file = {
        filename_first = true,
        truncate = 250,
      },
    },
  },
})

-- stylua: ignore start

-- Keymaps
vim.keymap.set("n", "<leader><leader>", function() snacks.picker.smart({ filter = { cwd = true }}) end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg",       function() snacks.picker.grep() end,                            { desc = "Grep" })
vim.keymap.set("n", "<tab>",            function() snacks.picker.buffers({ focus = "list" }) end,       { desc = "Buffers" })
-- vim.keymap.set("n",   "<leader>ff",       function() snacks.picker.files() end,       { desc = "Files" })
-- vim.keymap.set("n",   "<leader>fo",       function() snacks.picker.recent() end,      { desc = "Recent files" })
-- vim.keymap.set("n",   "<leader>fh",       function() snacks.picker.help() end,        { desc = "Help" })
-- vim.keymap.set("n",   "<leader>sk",       function() snacks.picker.keymaps() end,     { desc = "Keymaps" })
-- vim.keymap.set("n",   "<leader>sc",       function() snacks.picker.commands() end,    { desc = "Commands" })
-- vim.keymap.set("n",   "<leader>sR",       function() snacks.picker.registers() end,   { desc = "Registers" })
-- vim.keymap.set("n",   "<leader>cS",       function() snacks.picker.lsp_symbols() end, { desc = "LSP symbols" })
-- vim.keymap.set("n",   "<leader>/",        function() snacks.picker.lines() end,       { desc = "Buffer lines" })
-- vim.keymap.set({ "n", "v" }, "<leader>gB",function() snacks.gitbrowse() end,          { desc = "Git browse" })

-- Highlighting -- TODO
local set = vim.api.nvim_set_hl
set(0, "MiniIndentscopeSymbol",   { fg = colors.fg3 })
-- set(0, "SnacksDashboardDesc",   { fg = colors.fg1 }) -- item description text
-- set(0, "SnacksDashboardKey",    { fg = colors.blue.base }) -- keybind letter
-- set(0, "SnacksDashboardIcon",   { fg = colors.fg1 }) -- item icons
-- set(0, "SnacksDashboardTitle",  { fg = colors.blue.base, bold = true }) -- section titles
-- set(0, "SnacksDashboardHeader", { fg = colors.blue.bright }) -- ASCII header
-- set(0, "SnacksDashboardFooter", { fg = colors.bg1 }) -- footer / startup line (dim)
-- set(0, "SnacksDashboardDir",    { fg = colors.bg1 }) -- dir portion of paths (dim)
-- set(0, "SnacksDashboardFile",   { fg = colors.magenta.base }) -- filenames
