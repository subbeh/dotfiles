vim.lsp.config["*"] = {
  root_markers = { ".git" },
}

vim.lsp.enable({
  "ansiblels",
  "bashls",
  "clangd",
  "cssls",
  "dockerls",
  "gopls",
  "html",
  "jsonls",
  "lua_ls",
  "pyright",
  "ruff",
  "terraformls",
  "yamlls",
})
