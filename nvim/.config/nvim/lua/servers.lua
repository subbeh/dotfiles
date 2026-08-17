-- Language servers to enable. Each name needs a matching lsp/<name>.lua defining
-- at least `cmd` and `filetypes`. plugin/mason.lua auto-installs anything here
-- whose executable is not already on PATH.
return {
  "lua_ls",
}
