---@type vim.lsp.Config
return {
  cmd = { "ansible-language-server", "--stdio" },
  filetypes = { "yaml.ansible" },
  root_markers = { "ansible.cfg", ".ansible-lint" },
  settings = {
    ansible = {
      -- nvim-lint runs ansible-lint (plugin/lint.lua); linting here too doubles every diagnostic.
      validation = { lint = { enabled = false } },
    },
  },
}
