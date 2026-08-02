vim.pack.add({ "https://github.com/HiPhish/rainbow-delimiters.nvim" })

local colors = require("colors")
local rainbow_delimiters = require("rainbow-delimiters")

require("rainbow-delimiters.setup").setup({
  strategy = {
    [""] = rainbow_delimiters.strategy["global"],
    vim = rainbow_delimiters.strategy["local"],
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-blocks",
  },
  priority = {
    [""] = 110,
    lua = 210,
  },
  highlight = {
    "RainbowDelimiterRed",
    "RainbowDelimiterGreen",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterMagenta",
    "RainbowDelimiterCyan",
  },
})

-- stylua: ignore start
-- highlighting --
local set = vim.api.nvim_set_hl
set(0, "RainbowDelimiterRed",     { fg = colors.red.base })
set(0, "RainbowDelimiterGreen",   { fg = colors.green.base })
set(0, "RainbowDelimiterYellow",  { fg = colors.yellow.base })
set(0, "RainbowDelimiterBlue",    { fg = colors.blue.base })
set(0, "RainbowDelimiterMagenta", { fg = colors.magenta.base })
set(0, "RainbowDelimiterCyan",    { fg = colors.cyan.base })
