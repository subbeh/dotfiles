local icons = require("icons")

vim.diagnostic.config({
  underline = true,
  virtual_text = {
    prefix = "●",
    source = "if_many",
    spacing = 4,
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

-- stylua: ignore start
vim.keymap.set("n"  , "gd"        , vim.lsp.buf.definition                            , { desc = "Go to definition" })
vim.keymap.set("n"  , "gD"        , vim.lsp.buf.declaration                           , { desc = "Go to declaration" })
vim.keymap.set("n"  , "gr"        , vim.lsp.buf.references                            , { desc = "References" })
vim.keymap.set("n"  , "gi"        , vim.lsp.buf.implementation                        , { desc = "Implementation" })
vim.keymap.set("n"  , "go"        , vim.lsp.buf.type_definition                       , { desc = "Type definition" })
vim.keymap.set("n"  , "K"         , vim.lsp.buf.hover                                 , { desc = "Hover" })
vim.keymap.set("i"  , "<C-h>"     , vim.lsp.buf.signature_help                        , { desc = "Signature help" })
vim.keymap.set({ "n", "v" }, "<leader>cc", vim.lsp.buf.code_action                    , { desc = "Code action" })
vim.keymap.set("n"  , "<leader>cR", vim.lsp.buf.rename                                , { desc = "Rename" })
vim.keymap.set("n"  , "<leader>cs", vim.lsp.buf.workspace_symbol                      , { desc = "Workspace symbols" })
vim.keymap.set("n"  , "[d"        , function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
vim.keymap.set("n"  , "]d"        , function() vim.diagnostic.jump({ count = 1 }) end , { desc = "Next diagnostic" })
