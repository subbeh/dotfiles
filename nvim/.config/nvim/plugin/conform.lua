vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/zapling/mason-conform.nvim",
  "https://github.com/folke/snacks.nvim",
})

require("mason").setup()

local function has_frontmatter(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "---"
end

require("conform").setup({
  format_on_save = function()
    if vim.g.disable_autoformat then
      return
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
  formatters_by_ft = {
    bash = { "shfmt" },
    html = { "prettier", "injected" },
    json = { "prettier" },
    jsonc = { "prettier" },
    lua = { "stylua" },
    -- mdformat mangles YAML frontmatter and mason can't install mdformat-frontmatter,
    -- so frontmatter files go to prettier instead (see the conditions below).
    markdown = { "mdformat", "prettier", "injected" },
    python = { "black" },
    sh = { "shfmt" },
    toml = { "tombi" },
    yaml = { "prettier" },
    zsh = { "shfmt" },
  },
  formatters = {
    mdformat = {
      condition = function(_, ctx)
        return not has_frontmatter(ctx.buf)
      end,
    },
    prettier = {
      condition = function(_, ctx)
        return vim.bo[ctx.buf].filetype ~= "markdown" or has_frontmatter(ctx.buf)
      end,
      prepend_args = function(_, ctx)
        local wrap = vim.bo[ctx.buf].filetype == "markdown" and "preserve" or "always"
        return { "--prose-wrap", wrap }
      end,
    },
  },
})

require("mason-conform").setup()

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

require("snacks").toggle
  .new({
    name = "Format on Save",
    get = function()
      return not vim.g.disable_autoformat
    end,
    set = function(state)
      vim.g.disable_autoformat = not state
    end,
  })
  :map("<leader>uf")
