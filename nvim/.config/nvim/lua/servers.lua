-- Language servers to enable. Each name needs a matching lsp/<name>.lua defining
-- at least `cmd` and `filetypes`. plugin/mason.lua auto-installs anything here
-- whose executable is not already on PATH.
return {
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
}
