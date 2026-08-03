---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".stylua.toml",
    "stylua.toml",
    ".git",
  },
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt"),
        },
      },
      completion = {
        callSnippet = "Replace",
      },
      format = {
        enable = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
