vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/pwntester/octo.nvim",
})

require("octo").setup({
  picker = "snacks",
})
