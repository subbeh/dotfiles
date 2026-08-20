-- Server definitions live in lsp/<name>.lua. Neovim merges every lsp/<name>.lua
-- found in 'runtimepath' (later entries win), then vim.lsp.config["*"], then any
-- vim.lsp.config("<name>", {...}) call -- which has the highest precedence.
vim.lsp.config["*"] = {
  root_markers = { ".git" },
}

-- Enable every language server for which a lsp/<name>.lua config exists on
-- 'runtimepath'. plugin/mason.lua auto-installs anything here whose
-- executable is not already on PATH.
local servers = {}
for _, file in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  servers[#servers + 1] = vim.fn.fnamemodify(file, ":t:r")
end
vim.lsp.enable(servers)

-- stylua: ignore start
vim.keymap.set("n", "<leader>lh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = "Toggle Inlay Hints" })
vim.keymap.set("n", "<leader>lI", "<cmd>checkhealth vim.lsp<cr>",                                                { desc = "LSP Info" })
-- stylua: ignore end

local function set_lsp_enabled(state)
  local bufnr = vim.api.nvim_get_current_buf()
  if state then
    vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
  else
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end
end

require("snacks").toggle
  .new({
    name = "LSP",
    get = function()
      return #vim.lsp.get_clients({ bufnr = 0 }) > 0
    end,
    set = set_lsp_enabled,
  })
  :map("<leader>lt")
