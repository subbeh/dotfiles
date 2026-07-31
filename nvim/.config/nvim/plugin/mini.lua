vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

local colors = require("colors")

-- Completion
-- require("mini.completion").setup({
--   delay = { completion = 100, info = 100, signature = 50 },
--   window = {
--     info = { border = "single" },
--     signature = { border = "single" },
--   },
-- })

-- Motion
require("mini.jump").setup()
require("mini.jump2d").setup({
  mappings = { start_jumping = "<CR>" },
})

-- Textobjects
require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    a = require("mini.ai").gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
  },
})

-- Surround
require("mini.surround").setup()

-- Autopairs
require("mini.pairs").setup()

-- Statusline
require("mini.statusline").setup({ use_icons = true })

-- Keymap hints
require("mini.clue").setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
  },
  clues = {
    require("mini.clue").gen_clues.builtin_completion(),
    require("mini.clue").gen_clues.g(),
    require("mini.clue").gen_clues.marks(),
    require("mini.clue").gen_clues.registers(),
    require("mini.clue").gen_clues.windows(),
    require("mini.clue").gen_clues.z(),
    { mode = "n", keys = "<Leader>c", desc = "+Code" },
    { mode = "n", keys = "<Leader>f", desc = "+Find" },
    { mode = "n", keys = "<Leader>g", desc = "+Git" },
    { mode = "n", keys = "<Leader>s", desc = "+System" },
    { mode = "n", keys = "<Leader>u", desc = "+UI" },
    { mode = "n", keys = "<Leader>x", desc = "+Copy" },
  },
  window = {
    delay = 300,
    config = { width = "auto" },
  },
})

-- Indent scope
require("mini.indentscope").setup({
  symbol = "│",
  options = { try_as_border = true },
})
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  callback = function()
    vim.schedule(function()
      local disabled = {
        help = true,
        snacks_dashboard = true,
      }
      if disabled[vim.bo.filetype] then
        vim.b.miniindentscope_disable = true
      end
    end)
  end,
})

-- Icons
require("mini.icons").setup()

-- stylua: ignore start

-- Highlighting -- TODO
local set = vim.api.nvim_set_hl
set(0, "MiniIndentscopeSymbol", { fg = colors.fg3 })
