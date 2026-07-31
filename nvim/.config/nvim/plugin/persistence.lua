vim.pack.add({ "https://github.com/folke/persistence.nvim" })

require("persistence").setup({
  dir = vim.fn.stdpath("data") .. "/sessions", -- directory where session files are saved
  options = { "buffers", "curdir", "tabpages", "winsize" }, -- session options
})
