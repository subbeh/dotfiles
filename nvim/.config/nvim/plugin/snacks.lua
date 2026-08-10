vim.pack.add({ "https://github.com/folke/snacks.nvim" })

local icons = require("icons")
local snacks = require("snacks")
local colors = require("colors")

-- Explorer pane navigation.
--
-- The explorer's list and input are floating windows, so `wincmd h/j/k/l` does
-- not see them and nvim-tmux-navigation moves to the wrong window (or is
-- shadowed outright: <c-j>/<c-k> are list_down/list_up by default). The
-- explorer is docked on the left, so hand C-h/C-j/C-k straight to tmux and let
-- C-l focus the file window the picker was opened from.
local function explorer_nav_keys()
  local keys = {}
  for lhs, dir in pairs({ ["<c-h>"] = "h", ["<c-j>"] = "j", ["<c-k>"] = "k" }) do
    keys[lhs] = function()
      local tmux = require("nvim-tmux-navigation.tmux_util")
      -- Matches disable_when_zoomed in plugin/tmux.lua.
      if vim.env.TMUX and tmux.should_tmux_control(true, true) then
        tmux.tmux_change_pane(dir)
      end
    end
  end
  keys["<c-l>"] = function()
    -- A key handler receives the snacks.win, not the picker, so look the
    -- picker up to reach the window it was opened from.
    local picker = snacks.picker.get({ source = "explorer" })[1]
    if picker and picker.main and vim.api.nvim_win_is_valid(picker.main) then
      vim.api.nvim_set_current_win(picker.main)
    end
  end
  return keys
end

require("snacks").setup({
  -- misc
  bigfile = { enabled = true },

  -- dashboard
  dashboard = {
    enabled = true,
    preset = {
      keys = {
        { icon = icons.ui.FindFile, key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.getcwd() })" },
        { icon = icons.ui.NewFile, key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = icons.ui.FindText, key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = icons.ui.Files, key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = icons.ui.Config, key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config' )})" },
        { icon = icons.ui.Refresh, key = "s", desc = "Restore Session", action = ":lua require('persistence').load({ last = true })" },
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
      explorer = {
        hidden = true,
        trash = false,
        replace_netrw = true,
        layout = {
          layout = {
            width = 30,
          },
        },
        win = {
          list = {
            keys = vim.tbl_extend("error", explorer_nav_keys(), {
              ["-"] = "explorer_up",
              ["W"] = "explorer_close_all",
              ["<C-]>"] = "tcd",
            }),
          },
          input = {
            keys = explorer_nav_keys(),
          },
        },
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
vim.keymap.set("n", "<leader><leader>", function() snacks.picker.smart({ filter = { cwd = true }}) end, { desc = "Find files" })
vim.keymap.set("n", "<tab>",            function() snacks.picker.buffers({ focus = "list" }) end,       { desc = "Buffers" })
vim.keymap.set("n", "<leader>e",        function() snacks.picker.explorer() end,                        { desc = "Explorer" })
vim.keymap.set("n", "<leader>fc",       function() snacks.picker.commands() end,                        { desc = "Commands" })
vim.keymap.set("n", "<leader>fD",       function() snacks.picker.diagnostics_buffer() end,              { desc = "Diagnostics (buffer)" })
vim.keymap.set("n", "<leader>fd",       function() snacks.picker.diagnostics() end,                     { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>ff",       function() snacks.picker.smart() end,                           { desc = "Find files (global)" })
vim.keymap.set("n", "<leader>fg",       function() snacks.picker.grep() end,                            { desc = "Grep" })
vim.keymap.set("n", "<leader>fh",       function() snacks.picker.help() end,                            { desc = "Help" })
vim.keymap.set("n", "<leader>fh",       function() snacks.picker.highlights() end,                      { desc = "Highlights" })
vim.keymap.set("n", "<leader>fi",       function() snacks.picker.icons() end,                           { desc = "Icons" })
vim.keymap.set("n", "<leader>fj",       function() snacks.picker.jumps() end,                           { desc = "Jumps" })
vim.keymap.set("n", "<leader>fk",       function() snacks.picker.keymaps() end,                         { desc = "Keymaps" })
vim.keymap.set("n", "<leader>fm",       function() snacks.picker.marks() end,                           { desc = "Marks" })
vim.keymap.set("n", "<leader>fn",       function() snacks.picker.notifications() end,                   { desc = "Notifications" })
vim.keymap.set("n", "<leader>fp",       function() snacks.picker.projects() end,                        { desc = "Projects" })
vim.keymap.set("n", "<leader>fx",       function() snacks.picker.cliphist() end,                        { desc = "Clipboard" })
vim.keymap.set("n", "<leader>gg",       function() snacks.picker.git_grep() end,                        { desc = "Git Grep" })
vim.keymap.set("n", "<leader>gha",      function() snacks.picker.gh_actions() end,                      { desc = "GitHub Actions" })
vim.keymap.set("n", "<leader>ghd",      function() snacks.picker.gh_diff() end,                         { desc = "GitHub Diff" })
vim.keymap.set("n", "<leader>ghd",      function() snacks.picker.git_diff() end,                        { desc = "Git Diff" })
vim.keymap.set("n", "<leader>ghi",      function() snacks.picker.gh_issue() end,                        { desc = "GitHub Issue" })
vim.keymap.set("n", "<leader>ghp",      function() snacks.picker.gh_pr() end,                           { desc = "GitHub PR" })
vim.keymap.set("n", "<leader>gl",       function() snacks.picker.git_log_file() end,                    { desc = "Git Log (file)" })
vim.keymap.set("n", "<leader>gL",       function() snacks.picker.git_log_line() end,                    { desc = "Git Log (line)" })
vim.keymap.set("n", "<leader>gS",       function() snacks.picker.git_stash() end,                       { desc = "Git Stash" })
vim.keymap.set("n", "<leader>lc",       function() snacks.picker.lsp_config() end,                      { desc = "List Servers" })
vim.keymap.set("n", "<leader>ld",       function() snacks.picker.lsp_declarations() end,                { desc = "List Declarations" })
vim.keymap.set("n", "<leader>lf",       function() snacks.picker.lsp_definitions() end,                 { desc = "List Definitions" })
vim.keymap.set("n", "<leader>li",       function() snacks.picker.lsp_implementations() end,             { desc = "List Implementations" })
vim.keymap.set("n", "<leader>lr",       function() snacks.picker.lsp_references() end,                  { desc = "List References" })

-- Highlighting
local set = vim.api.nvim_set_hl
set(0, "SnacksPicker",       { bg = colors.bg.light })
set(0, "SnacksPickerBorder", { fg = colors.fg.default })
set(0, "SnacksPickerDirectory", { fg = colors.fg.darker })
