vim.pack.add({ "https://github.com/folke/snacks.nvim" })

local icons = require("icons")
local snacks = require("snacks")
local colors = require("colors")

require("snacks").setup({
  -- misc
  bigfile = { enabled = true },
  toggle = { enabled = true },

  -- dashboard
  dashboard = {
    enabled = true,
    preset = {
      keys = {
        -- stylua: ignore start
        { icon = icons.ui.FindFile, key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.getcwd() })" },
        { icon = icons.ui.NewFile,  key = "n", desc = "New File",        action = ":ene | startinsert" },
        { icon = icons.ui.FindText, key = "g", desc = "Find Text",       action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = icons.ui.Files,    key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = icons.ui.Config,   key = "c", desc = "Config",          action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config' )})" },
        { icon = icons.ui.Refresh,  key = "s", desc = "Restore Session", action = ":lua require('persistence').load({ last = true })" },
        { icon = icons.ui.Exit,     key = "q", desc = "Quit",            action = ":qa" },
      },
    },
    sections = {
      -- stylua: ignore start
      { section = "header" },
      { icon = icons.ui.Keyboard,   title = "Keymaps",      section = "keys",         indent = 2, padding = 1 },
      { icon = icons.ui.Files,      title = "Recent Files", section = "recent_files", indent = 2, padding = 1, cwd = true },
      { icon = icons.ui.FolderOpen, title = "Projects",     section = "projects",     indent = 2, padding = 1 },
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

  -- picker
  picker = {
    hidden = true,
    ignored = false,
    layout = {
      layout = {
        backdrop = false,
      },
    },
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
      icons = {
        -- Append mini.icons entries to the built-in nerd font / emoji sources so
        -- glyphs are searchable by filetype, extension, OS and LSP kind names.
        finder = function(opts, ctx)
          local items = require("snacks.picker.source.icons").icons(opts, ctx)
          local mini_icons = require("mini.icons")
          local util = require("snacks.picker.util")
          for _, category in ipairs({ "filetype", "extension", "file", "directory", "lsp", "os" }) do
            for _, name in ipairs(mini_icons.list(category)) do
              local item = { icon = mini_icons.get(category, name), name = name, category = category, source = "mini.icons" }
              item.text = util.text(item, { "source", "category", "name" })
              item.data = item.icon
              items[#items + 1] = item
            end
          end
          return items
        end,
      },
      buffers = {
        current = false,
        sort_lastused = true,
        preset = "ivy",
        layout = {
          position = "bottom",
        },
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
local map = vim.keymap.set
map("n", "<leader><leader>", function() snacks.picker.smart({ filter = { cwd = true }}) end, { desc = "Find files" })
map("n", "<tab>",            function() snacks.picker.buffers({ focus = "list" }) end,       { desc = "Buffers" })
map("n", "<leader>bd",       function() snacks.bufdelete.delete() end,                       { desc = "Delete buffer" })
map("n", "<leader>bD",       function() snacks.bufdelete.other() end,                        { desc = "Delete buffers (other)" })
map("n", "<leader>fc",       function() snacks.picker.commands() end,                        { desc = "Commands" })
map("n", "<leader>fD",       function() snacks.picker.diagnostics_buffer() end,              { desc = "Diagnostics (buffer)" })
map("n", "<leader>fd",       function() snacks.picker.diagnostics() end,                     { desc = "Diagnostics" })
map("n", "<leader>ff",       function() snacks.picker.smart() end,                           { desc = "Find files (global)" })
map("n", "<leader>fg",       function() snacks.picker.grep() end,                            { desc = "Grep" })
map("n", "<leader>fh",       function() snacks.picker.help() end,                            { desc = "Help" })
map("n", "<leader>fh",       function() snacks.picker.highlights() end,                      { desc = "Highlights" })
map("n", "<leader>fi",       function() snacks.picker.icons() end,                           { desc = "Icons" })
map("n", "<leader>fj",       function() snacks.picker.jumps() end,                           { desc = "Jumps" })
map("n", "<leader>fk",       function() snacks.picker.keymaps() end,                         { desc = "Keymaps" })
map("n", "<leader>fl",       function() snacks.picker.lines() end,                           { desc = "Lines (buffer)" })
map("n", "<leader>fm",       function() snacks.picker.marks() end,                           { desc = "Marks" })
map("n", "<leader>fn",       function() snacks.picker.notifications() end,                   { desc = "Notifications" })
map("n", "<leader>fp",       function() snacks.picker.projects() end,                        { desc = "Projects" })
map("n", "<leader>fx",       function() snacks.picker.cliphist() end,                        { desc = "Clipboard" })
map("n", "<leader>gd",       function() snacks.picker.git_diff() end,                        { desc = "Git Diff" })
map("n", "<leader>gg",       function() snacks.picker.git_grep() end,                        { desc = "Git Grep" })
map("n", "<leader>gha",      function() snacks.picker.gh_actions() end,                      { desc = "GitHub Actions" })
map("n", "<leader>ghd",      function() snacks.picker.gh_diff() end,                         { desc = "GitHub Diff" })
map("n", "<leader>ghi",      function() snacks.picker.gh_issue() end,                        { desc = "GitHub Issue" })
map("n", "<leader>gho",      function() snacks.gitbrowse.open() end,                         { desc = "GitHub Open URL" })
map("n", "<leader>ghp",      function() snacks.picker.gh_pr() end,                           { desc = "GitHub PR" })
map("n", "<leader>gl",       function() snacks.picker.git_log_file() end,                    { desc = "Git Log (file)" })
map("n", "<leader>gL",       function() snacks.picker.git_log_line() end,                    { desc = "Git Log (line)" })
map("n", "<leader>gS",       function() snacks.picker.git_stash() end,                       { desc = "Git Stash" })
map("n", "<leader>lc",       function() snacks.picker.lsp_config() end,                      { desc = "List Servers" })
map("n", "<leader>ld",       function() snacks.picker.lsp_declarations() end,                { desc = "List Declarations" })
map("n", "<leader>lf",       function() snacks.picker.lsp_definitions() end,                 { desc = "List Definitions" })
map("n", "<leader>li",       function() snacks.picker.lsp_implementations() end,             { desc = "List Implementations" })
map("n", "<leader>lr",       function() snacks.picker.lsp_references() end,                  { desc = "List References" })
snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
snacks.toggle.inlay_hints():map("<leader>uh")
snacks.toggle.line_number():map("<leader>ul")
snacks.toggle.animate():map("<leader>ua")
snacks.toggle.diagnostics():map("<leader>cd")
snacks.toggle.indent():map("<leader>ci")
snacks.toggle.treesitter():map("<leader>ct")

-- Highlighting
local set = vim.api.nvim_set_hl
set(0, "SnacksPicker",          { bg = colors.bg.default })
set(0, "SnacksPickerBorder",    { fg = colors.fg.default })
set(0, "SnacksPickerDirectory", { fg = colors.fg.darker })
