vim.pack.add({ "https://github.com/projekt0n/github-nvim-theme" })

local colors = require("colors")

require("github-theme").setup({
  specs = {
    all = colors,
  },
})

vim.cmd("colorscheme github_dark")

local set = vim.api.nvim_set_hl
set(0, "LineNr", { fg = colors.fg.darker })
set(0, "Visual", { bg = colors.bg.lighter })
set(0, "DiagnosticInfo", { fg = colors.blue.base })
set(0, "DiagnosticWarn", { fg = colors.yellow.bright })
set(0, "DiagnosticError", { fg = colors.red.base })
set(0, "Error", { fg = colors.red.base })
set(0, "Added", { fg = colors.green.base })
set(0, "FloatBorder", { bg = colors.bg.default, fg = colors.blue.base })
set(0, "StatusLine", { bg = colors.bg.default, fg = colors.fg.default })
