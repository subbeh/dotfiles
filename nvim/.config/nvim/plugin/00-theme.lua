vim.pack.add({ "projekt0n/github-nvim-theme" })

local colors = require("colors")
local hlgroups = {
  LineNr = { fg = colors.fg2 },
}

require("github-theme").setup({
  specs = {
    all = colors,
  },
  groups = {
    all = hlgroups,
  },
})

vim.cmd("colorscheme github_dark")
