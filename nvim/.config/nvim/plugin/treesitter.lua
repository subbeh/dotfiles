vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  { src = "https://github.com/Wansmer/treesj" },
})

-- The `main` branch has no module system: setup() only configures install_dir, and
-- highlighting/indenting are driven by core vim.treesitter in the autocmd below.
-- Install hangs when the tree-sitter CLI is missing.
-- See: https://github.com/nvim-treesitter/nvim-treesitter/issues/8010
if vim.fn.executable("tree-sitter") == 1 then
  local install = require("nvim-treesitter").install({
    "bash",
    "comment",
    "css",
    "dockerfile",
    "gitignore",
    "go",
    "gomod",
    "gosum",
    "graphql",
    "html",
    "javascript",
    "json",
    "lua",
    "luadoc",
    "make",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "sql",
    "terraform",
    "vim",
    "vimdoc",
    "yaml",
  })

  if #vim.api.nvim_list_uis() == 0 then
    install:wait(300000)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user.treesitter", { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not vim.treesitter.language.add(lang or "") then
      return
    end

    vim.treesitter.start(args.buf, lang)

    if #vim.api.nvim_get_runtime_file(("queries/%s/indents.scm"):format(lang), false) > 0 then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
  desc = "Start treesitter highlighting and indenting",
})

require("treesj").setup({
  disable_when_zoomed = true,
})

require("nvim-treesitter-textobjects").setup()

-- Movement only. Selection textobjects (af/if, ac/ic, aa/ia) come from mini.ai,
-- which already backs them with treesitter -- see plugin/mini.lua.
local function move_map(lhs, fn, obj, desc)
  vim.keymap.set({ "n", "x", "o" }, lhs, function()
    require("nvim-treesitter-textobjects.move")[fn](obj, "textobjects")
  end, { desc = desc })
end

-- stylua: ignore start
move_map("]m", "goto_next_start",     "@function.outer", "Next function start")
move_map("]]", "goto_next_start",     "@class.outer",    "Next class start")
move_map("]M", "goto_next_end",       "@function.outer", "Next function end")
move_map("][", "goto_next_end",       "@class.outer",    "Next class end")
move_map("[m", "goto_previous_start", "@function.outer", "Prev function start")
move_map("[[", "goto_previous_start", "@class.outer",    "Prev class start")
move_map("[M", "goto_previous_end",   "@function.outer", "Prev function end")
move_map("[]", "goto_previous_end",   "@class.outer",    "Prev class end")
vim.keymap.set("n", "<leader>cj", require('treesj').toggle, { desc = "Toggle TreeJS" })

-- highlighting
local set = vim.api.nvim_set_hl
local colors = require("colors")
set(0, "@field.yaml",            { fg = colors.green.base })
set(0, "@property.yaml",         { fg = colors.green.bright })
set(0, "@label.yaml",            { fg = colors.magenta.base })
set(0, "@boolean.yaml",          { fg = colors.blue.bright })
set(0, "@markup.list.unchecked", { fg = colors.fg.darker })
set(0, "@markup.list.checked",   { fg = colors.green.bright })
set(0, "@tag",                   { fg = colors.green.bright })
