vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

local p = require("palette")

-- Map the named palette (from theme.yaml) onto the base16 slots.
-- base00-07 are the dark->light ramp; base08-0F are the accents.
require("mini.base16").setup({
  palette = {
    base00 = p.surface_bg, -- default background
    base01 = p.surface_bg1, -- lighter background (statusline, cursorline)
    base02 = p.sel_bg, -- selection background
    base03 = p.black_bright, -- comments, invisibles
    base04 = p.white, -- dark foreground (statusline)
    base05 = p.surface_fg, -- default foreground
    base06 = p.surface_fg, -- light foreground
    base07 = p.white_bright, -- light background
    base08 = p.surface_fg, -- variables, diff deleted
    base09 = p.magenta, -- numbers, booleans, constants
    base0A = p.blue_bright, -- classes, search highlight
    base0B = p.blue, -- strings, diff added
    base0C = p.yellow, -- support, regex, escapes
    base0D = p.magenta, -- functions, methods
    base0E = p.red_bright, -- keywords, storage
    base0F = p.red, -- deprecated, embedded tags
  },
  use_cterm = true,
  plugins = {
    default = true,
  },
})
