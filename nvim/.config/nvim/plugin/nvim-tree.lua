vim.pack.add({ "https://github.com/nvim-tree/nvim-tree.lua" })

local icons = require("icons")
local colors = require("colors")

require("nvim-tree").setup({
  sync_root_with_cwd = true,
  respect_buf_cwd = true,

  on_attach = function(bufnr)
    require("nvim-tree.api").config.mappings.default_on_attach(bufnr)
    -- Default binds <C-k> to toggle_file_info, which shadows tmux pane
    -- navigation inside the tree.
    vim.keymap.del("n", "<C-k>", { buffer = bufnr })
  end,

  actions = {
    change_dir = {
      enable = true,
      global = true, -- This makes the directory change global (changes vim.loop.cwd())
    },
  },

  renderer = {
    root_folder_label = ":t",
    indent_markers = {
      enable = true,
    },
    icons = {
      glyphs = {
        default = icons.ui.Text,
        symlink = icons.ui.FileSymlink,
        bookmark = icons.ui.BookMark,
        folder = {
          arrow_closed = icons.ui.ChevronRight,
          arrow_open = icons.ui.ChevronShortDown,
          default = icons.ui.Folder,
          open = icons.ui.FolderOpen,
          empty = icons.ui.EmptyFolder,
          empty_open = icons.ui.EmptyFolderOpen,
          symlink = icons.ui.FolderSymlink,
          symlink_open = icons.ui.FolderOpen,
        },
        git = {
          unstaged = icons.git.FileUnstaged,
          staged = icons.git.FileStaged,
          unmerged = icons.git.FileUnmerged,
          renamed = icons.git.FileRenamed,
          untracked = icons.git.FileUntracked,
          deleted = icons.git.FileDeleted,
          ignored = icons.git.FileIgnored,
        },
      },
    },
  },

  filters = {
    git_ignored = false,
    custom = {
      "^.git$",
      "^.stfolder$",
      "^.trash$",
    },
  },

  update_focused_file = {
    enable = true,
  },

  diagnostics = {
    enable = true,
    show_on_dirs = false,
    show_on_open_dirs = true,
    severity = {
      min = vim.diagnostic.severity.HINT,
      max = vim.diagnostic.severity.ERROR,
    },
    icons = {
      hint = icons.diagnostics.BoldHint,
      info = icons.diagnostics.BoldInformation,
      warning = icons.diagnostics.BoldWarning,
      error = icons.diagnostics.BoldError,
    },
  },
})

-- Show the tree alongside the dashboard on a bare `nvim`. The tree has to open
-- second: snacks refuses to draw the dashboard while more than one non-floating
-- window exists, which is why `nvim -c NvimTreeOpen` loses the dashboard.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("nvim_tree_dashboard", { clear = true }),
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end
    vim.schedule(function()
      if vim.bo.filetype == "snacks_dashboard" then
        require("nvim-tree.api").tree.toggle({ focus = false })
      end
    end)
  end,
})

-- Keymaps
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })

-- Highlighting
local set = vim.api.nvim_set_hl
set(0, "NvimTreeGitNew", { fg = colors.green.base })
set(0, "NvimTreeGitDirty", { fg = colors.orange.base })
set(0, "NvimTreeGitDeleted", { fg = colors.red.base })
set(0, "NvimTreeGitRenamed", { fg = colors.magenta.base })
