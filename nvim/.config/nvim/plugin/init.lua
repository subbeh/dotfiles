vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
})

require("oil").setup({
  default_file_explorer = true,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  view_options = {
    show_hidden = true,
    natural_order = "fast",
    is_always_hidden = function(name, _) return name == ".." or name == ".git" end,
  },
  float = {
    padding = 2,
    max_width = 90,
    max_height = 0,
  },
  win_options = {
    wrap = true,
    winblend = 0,
  },
  keymaps = {
    ["<C-c>"] = false,
    ["q"] = "actions.close",
  },
})

-- keymaps --
vim.keymap.set("n", "_", require("oil").toggle_float, { desc = "Oil" })
