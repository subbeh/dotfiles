vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

local colors = require("colors")

-- Completion --
-- require("mini.completion").setup({
--   delay = { completion = 100, info = 100, signature = 50 },
--   window = {
--     info = { border = "single" },
--     signature = { border = "single" },
--   },
-- })

-- Motion --
require("mini.jump").setup()
require("mini.jump2d").setup({
  mappings = { start_jumping = "<CR>" },
})

-- Textobjects --
require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    a = require("mini.ai").gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
  },
})

-- Sessions --
require("mini.sessions").setup()

-- Surround --
require("mini.surround").setup()

-- Autopairs --
require("mini.pairs").setup()

-- Statusline --
require("mini.statusline").setup()

-- Keymap hints --
require("mini.clue").setup({
  triggers = {
    -- Leader triggers
    { mode = { "n", "x" }, keys = "<Leader>" },
    -- `[` and `]` keys
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    -- Built-in completion
    { mode = "i", keys = "<C-x>" },
    -- `g` key
    { mode = { "n", "x" }, keys = "g" },
    -- Marks
    { mode = { "n", "x" }, keys = "'" },
    { mode = { "n", "x" }, keys = "`" },
    -- Registers
    { mode = { "n", "x" }, keys = '"' },
    { mode = { "i", "c" }, keys = "<C-r>" },
    -- Window commands
    { mode = "n", keys = "<C-w>" },
    -- `z` key
    { mode = { "n", "x" }, keys = "z" },
  },
  clues = {
    require("mini.clue").gen_clues.square_brackets(),
    require("mini.clue").gen_clues.builtin_completion(),
    require("mini.clue").gen_clues.g(),
    require("mini.clue").gen_clues.marks(),
    require("mini.clue").gen_clues.registers(),
    require("mini.clue").gen_clues.windows(),
    require("mini.clue").gen_clues.z(),
    { mode = "n", keys = "<Leader>c", desc = "+Code" },
    { mode = "n", keys = "<Leader>f", desc = "+Find" },
    { mode = "n", keys = "<Leader>g", desc = "+Git" },
    { mode = "n", keys = "<Leader>gh", desc = "+GitHub" },
    { mode = "n", keys = "<Leader>l", desc = "+LSP" },
    { mode = "n", keys = "<Leader>p", desc = "+Pack" },
    { mode = "n", keys = "<Leader>s", desc = "+System" },
    { mode = "n", keys = "<Leader>u", desc = "+UI" },
    { mode = "n", keys = "<Leader>x", desc = "+Copy" },
  },
  window = {
    delay = 0,
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

-- Icons --
require("mini.icons").setup()

-- stylua: ignore start
-- Highlighting --
local set = vim.api.nvim_set_hl
set(0, "MiniIndentscopeSymbol",     { fg = colors.bg.lighter })

set(0, "MiniClueNextKey",           { fg = colors.fg.default })
set(0, "MiniClueDescSingle",        { fg = colors.red.base })
set(0, "MiniClueDescGroup",         { fg = colors.yellow.base })

set(0, "MiniStatuslineModeNormal",  { bg = colors.blue.bright,    fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeInsert",  { bg = colors.green.bright,   fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeVisual",  { bg = colors.yellow.bright,  fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeReplace", { bg = colors.red.bright,     fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeCommand", { bg = colors.magenta.bright, fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeOther",   { bg = colors.fg.default,     fg = colors.bg.default, bold = true, cterm = { bold = true } })
