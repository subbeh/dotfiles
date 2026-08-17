local icons = require("icons")

vim.diagnostic.config({
  underline = true,
  virtual_text = {
    source = "if_many",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.BoldError,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.BoldWarning,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.BoldInformation,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.BoldHint,
    },
  },
  float = {
    scope = "cursor",
    source = true,
  },
  update_in_insert = true,
  severity_sort = true,
})
