---@type vim.lsp.Config
return {
  cmd = { "bash-language-server", "start" },
  filetypes = { "bash", "sh" },
  settings = {
    bashIde = {
      -- Non-recursive by default: the upstream "**/*@(...)" pattern makes opening a
      -- script directly in $HOME scan the entire home directory.
      globPattern = "*@(.sh|.inc|.bash|.command)",
      shellcheckArguments = { ("--source-path=%s"):format(vim.uv.cwd()) },
    },
  },
}
