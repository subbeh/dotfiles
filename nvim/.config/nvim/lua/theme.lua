vim.pack.add({ "https://github.com/projekt0n/github-nvim-theme" })

local colors = require("colors")

require("github-theme").setup({
  specs = {
    all = colors,
  },
})

vim.cmd("colorscheme github_dark")

local set = vim.api.nvim_set_hl
-- stylua: ignore start
set(0, "LineNr", { fg = colors.fg.darkest })
set(0, "Visual", { bg = colors.bg.lighter })
set(0, "Function", { fg = colors.magenta.bright })
set(0, "DiagnosticInfo", { fg = colors.blue.base })
set(0, "DiagnosticWarn", { fg = colors.yellow.bright })
set(0, "DiagnosticError", { fg = colors.red.base })
set(0, "Error", { fg = colors.red.base })
set(0, "Added", { fg = colors.green.base })
set(0, "FloatBorder", { bg = colors.bg.default, fg = colors.blue.base })
set(0, "StatusLine", { bg = colors.bg.default, fg = colors.fg.default })
set(0, "LspReferenceRead", { underline = true, bold = true })
set(0, "LspReferenceText", { underline = true, bold = true })
set(0, "LspReferenceWrite", { underline = true, bold = true })
set(0, "LspReferenceTarget", { underline = true, bold = true })
-- Cursor (mode groups referenced by 'guicursor' in options.lua)
set(0, "Cursor", { fg = colors.bg.default, bg = colors.fg.default })
set(0, "CursorInsert", { fg = colors.bg.default, bg = colors.green.bright })
set(0, "CursorVisual", { fg = colors.bg.default, bg = colors.yellow.bright })
-- Pmenu
set(0, "Pmenu", { bg = colors.bg.light })
set(0, "PmenuSel", { bg = colors.bg.lightest })
set(0, "PmenuThumb", { bg = colors.blue.base })
set(0, "PmenuSelSbar", { bg = colors.bg.light })
