vim.pack.add({
  "https://github.com/SmiteshP/nvim-navic",
  "https://github.com/LunarVim/breadcrumbs.nvim",
})

local navic = require("nvim-navic")
local colors = require("colors")
local icons = require("icons")

require("breadcrumbs").setup()

navic.setup({
  icons = icons.kind,
  highlight = true,
  lsp = {
    auto_attach = true,
  },
  separator = " " .. icons.ui.ChevronRight .. " ",
})

-- stylua: ignore start
local set = vim.api.nvim_set_hl
set(0, "WinBar",         { bg = colors.bg.default, fg = colors.fg.dark, bold = true })
set(0, "NavicText",      { bg = colors.bg.default, fg = colors.fg.darker })
set(0, "NavicSeparator", { bg = colors.bg.default, fg = colors.fg.darker })
