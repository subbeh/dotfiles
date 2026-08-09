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
set(0, "LineNr", { fg = colors.fg.darker })
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
-- Treesitter
set(0, "@field.yaml", { fg = colors.green.base })
set(0, "@property.yaml", { fg = colors.green.bright })
set(0, "@label.yaml", { fg = colors.magenta.base })
set(0, "@boolean.yaml", { fg = colors.blue.bright })
set(0, "@markup.list.unchecked", { fg = colors.fg.darker })
set(0, "@markup.list.checked", { fg = colors.green.bright })
set(0, "@tag", { fg = colors.green.bright })
