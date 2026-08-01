vim.pack.add({ "projekt0n/github-nvim-theme" })

local colors = require("colors")

require("github-theme").setup({
  specs = {
    all = colors,
  },
})

vim.cmd("colorscheme github_dark")

local set = vim.api.nvim_set_hl
set(0, "LineNr", { fg = colors.fg.dark })
set(0, "Visual", { bg = colors.bg.lighter })
set(0, "DiagnosticInfo", { fg = colors.blue.base })
set(0, "Error", { fg = colors.red.base })
set(0, "FloatBorder", { bg = colors.bg.default, fg = colors.blue.base })
