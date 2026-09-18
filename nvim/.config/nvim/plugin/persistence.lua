vim.pack.add({ "https://github.com/folke/persistence.nvim" })

require("persistence").setup({
  dir = vim.fn.stdpath("data") .. "/sessions",
  options = { "buffers", "curdir", "tabpages", "winsize" },
})

-- stylua: ignore start
-- keymaps --
local map = vim.keymap.set
map("n", "<leader>Ss", function() require("persistence").select() end,             { desc = "Select Session" })
map("n", "<leader>Sl", function() require("persistence").load() end,               { desc = "Load Session" })
map("n", "<leader>SL", function() require("persistence").load({ last = true}) end, { desc = "Load Last Session" })
map("n", "<leader>Sx", function() require("persistence").stop() end,               { desc = "Discard Session" })
