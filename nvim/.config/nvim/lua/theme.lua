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
set(0, "Added",              { fg = colors.green.base })
set(0, "DiagnosticError",    { fg = colors.red.base })
set(0, "DiagnosticInfo",     { fg = colors.blue.base })
set(0, "DiagnosticWarn",     { fg = colors.yellow.bright })
set(0, "Error",              { fg = colors.red.base })
set(0, "FloatBorder",        { bg = colors.bg.default, fg = colors.blue.base })
set(0, "Function",           { fg = colors.magenta.bright })
set(0, "LineNr",             { fg = colors.fg.darkest })
set(0, "LspReferenceRead",   { underline = true,       bold = true })
set(0, "LspReferenceTarget", { underline = true,       bold = true })
set(0, "LspReferenceText",   { underline = true,       bold = true })
set(0, "LspReferenceWrite",  { underline = true,       bold = true })
set(0, "MoreMsg",            { fg = colors.blue.base, bold = true, cterm = { bold = true} })
set(0, "Visual",             { bg = colors.bg.lightest })
set(0, "WinSeparator",       { fg = colors.bg.lightest })
-- Cursor (mode groups referenced by 'guicursor' in options.lua)
set(0, "Cursor",             { fg = colors.bg.default, bg = colors.fg.default })
set(0, "CursorInsert",       { fg = colors.bg.default, bg = colors.green.bright })
set(0, "CursorVisual",       { fg = colors.bg.default, bg = colors.yellow.bright })
-- Pmenu
set(0, "Pmenu",              { bg = colors.bg.light })
set(0, "PmenuSel",           { bg = colors.bg.lightest })
set(0, "PmenuThumb",         { bg = colors.blue.base })
set(0, "PmenuSelSbar",       { bg = colors.bg.light })
set(0, "NormalFloat",        { bg = colors.bg.light })
-- stylua: ignore end

-- Active/inactive shading, mirroring window-style in tmux/.config/tmux/theme.conf.
-- nvim paints its own background, so tmux cannot shade this pane; the focused
-- window is one shade darker, and both drop back to the default while the pane is
-- unfocused. The global statusline follows the focused window. WinBar is left
-- without a bg (plugin/navic.lua) so it falls back to Normal: breadcrumbs.nvim
-- hardcodes %#WinBar# into every window's winbar, which an explicit bg would
-- paint dark in unfocused windows too.
local function shade(normal, inactive)
  set(0, "Normal", { bg = normal, fg = colors.fg.default })
  set(0, "NormalNC", { bg = inactive })
  set(0, "StatusLine", { bg = normal, fg = colors.fg.default })
  set(0, "WinBarNC", { bg = inactive, fg = colors.fg.default, bold = true })
end

shade(colors.bg.dark, colors.bg.default)

vim.api.nvim_create_autocmd("FocusLost", {
  group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
  callback = function()
    shade(colors.bg.default, colors.bg.default)
  end,
  desc = "Lighten background while the tmux pane is unfocused",
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = "user_theme",
  callback = function()
    shade(colors.bg.dark, colors.bg.default)
  end,
  desc = "Darken background when the tmux pane regains focus",
})
