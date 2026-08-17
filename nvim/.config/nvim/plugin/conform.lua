vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/zapling/mason-conform.nvim",
})

require("mason").setup()

require("conform").setup({
  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    bash = { "shfmt" },
    json = { "prettier" },
    jsonc = { "prettier" },
    lua = { "stylua" },
    markdown = { "prettier" },
    python = { "black" },
    sh = { "shfmt" },
    yaml = { "prettier" },
    zsh = { "shfmt" },
  },
})

require("mason-conform").setup()

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
