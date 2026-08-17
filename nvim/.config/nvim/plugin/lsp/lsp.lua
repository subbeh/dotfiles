-- Server definitions live in lsp/<name>.lua. Neovim merges every lsp/<name>.lua
-- found in 'runtimepath' (later entries win), then vim.lsp.config["*"], then any
-- vim.lsp.config("<name>", {...}) call -- which has the highest precedence.
vim.lsp.config["*"] = {
  root_markers = { ".git" },
}

vim.lsp.enable(require("servers"))

-- stylua: ignore start
vim.keymap.set("n", "<leader>lh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = "Toggle Inlay Hints" })
vim.keymap.set("n", "<leader>lI", "<cmd>checkhealth vim.lsp<cr>",                                                { desc = "LSP Info" })
