vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

local colors = require("colors")
local icons = require("icons")

require("mini.align").setup()
require("mini.bracketed").setup()
require("mini.git").setup()
require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.sessions").setup()
require("mini.surround").setup()
require("mini.comment").setup()

-- With cmdheight=0 the interactive status/hints mini.align echoes flash and get
-- wiped on the next redraw. align_user() runs the interactive loop synchronously,
-- so temporarily give the command line a row while it runs, then restore.
local align_user = MiniAlign.align_user
MiniAlign.align_user = function(mode)
  local saved = vim.o.cmdheight
  if saved == 0 then
    vim.o.cmdheight = 1
  end
  local ok, err = pcall(align_user, mode)
  vim.o.cmdheight = saved
  if not ok then
    error(err)
  end
end

-- autocmds --
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  callback = function()
    vim.schedule(function()
      local disabled = {
        help = true,
        snacks_picker_input = true,
        snacks_input = true,
      }
      if disabled[vim.bo.filetype] then
        vim.b.miniindentscope_disable = true
        vim.b.minicompletion_disable = true
      end
    end)
  end,
})

-- animate --
require("mini.animate").setup({
  cursor = {
    timing = require("mini.animate").gen_timing.linear({ duration = 100, unit = 'total' }),
  },
  scroll = {
    timing = require("mini.animate").gen_timing.linear({ duration = 150, unit = 'total' }),
  },
  resize = {
    enable = false
  },
})

-- cmdline -- 
require("mini.cmdline").setup({
  autocorrect = {
    enable = false,
  }
})

-- completion --
require("mini.completion").setup({
  delay = { completion = 100, info = 100, signature = 50 },
  window = {
    info = { border = "single" },
    signature = { border = "single" },
  },
})

-- diff --
require("mini.diff").setup({
  view = {
    style = "sign",
    signs = {
      add = icons.ui.BoldLineMiddle,
      change = icons.ui.BoldLineDashedMiddle,
      delete = icons.ui.BoldLineMiddle,
    },
  },
})

-- motion --
require("mini.jump").setup()
require("mini.jump2d").setup({
  mappings = { start_jumping = "<CR>" },
})

-- textobjects --
require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    a = require("mini.ai").gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
  },
})

local hipatterns = require('mini.hipatterns')

-- Resolve a dotted palette path ("yellow.base") against the generated colors
-- module (which mirrors .mate/theme.yaml). Returns a "#rrggbb" string or nil.
local function palette_hex(path)
  local node = colors
  for key in path:gmatch('[^.]+') do
    if type(node) ~= 'table' then return nil end
    node = node[key]
  end
  return type(node) == 'string' and node or nil
end

hipatterns.setup({
  highlighters = {
    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
    todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
    note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = hipatterns.gen_highlighter.hex_color(),

    -- Highlight statemate template refs like `{{ .Vars.color.yellow.base }}`
    -- with the colour they resolve to via .mate/theme.yaml (looked up in the
    -- generated `colors` module, which shares the same keys).
    template_color = {
      pattern = '{{%s*%.Vars%.color%.[%w.]+%s*}}',
      group = function(_, _, data)
        local hex = palette_hex(data.full_match:match('%.color%.([%w.]+)'))
        return hex and hipatterns.compute_hex_color_group(hex, 'bg') or nil
      end,
    },
  },
})

-- statusline --
-- stylua: ignore start
local mode_names = {
  n = "NOR", v = "VIS", V = "V-L", ["\22"] = "V-B",
  s = "SEL", S = "S-L", ["\19"] = "S-B",
  i = "INS", R = "REP", c = "CMD", r = "PRM", ["!"] = "SHL", t = "TRM",
}
-- stylua: ignore end

-- Color an icon separately from its section text: switch to "<hl>Icon", draw the
-- icon, then switch back so the rest of the section keeps the section highlight.
local function with_icon(icon, text, hl)
  return "%#" .. hl .. "Icon#" .. icon .. "%#" .. hl .. "#" .. text
end

-- mini.icons highlight groups define only `fg`, so using one directly would leave
-- the icon on the default background. Derive a cached group per icon color that
-- pairs it with the section background.
local ft_icon_hls = {}
local function ft_icon_hl(icon_hl)
  local hl = ft_icon_hls[icon_hl]
  if hl == nil then
    hl = "MiniStatuslineFileinfo" .. icon_hl:gsub("MiniIcons", "")
    local fg = vim.api.nvim_get_hl(0, { name = icon_hl, link = false }).fg
    vim.api.nvim_set_hl(0, hl, { bg = colors.bg.default, fg = fg or colors.fg.default })
    ft_icon_hls[icon_hl] = hl
  end
  return hl
end

require("mini.statusline").setup({
  content = {
    active = function()
      local status = require("mini.statusline")
      local _, mode_hl = status.section_mode({ trunc_width = 9999 })
      local mode = mode_names[vim.fn.mode()] or "MISC"
      local git = status.section_git({ trunc_width = 40, icon = with_icon(vim.trim(icons.git.Branch), "", "MiniStatuslineDevinfo") })
      local summary = vim.b.minigit_summary
      if git ~= "" and summary ~= nil and summary.root ~= nil then
        git = with_icon(icons.git.Repo, vim.fn.fnamemodify(summary.root, ":t"), "MiniStatuslineDevinfo") .. " " .. git
      end
      -- section_lsp() only renders one "+" per client; name them instead.
      local lsp = ""
      if not status.is_truncated(60) then
        local names = vim.tbl_map(function(client)
          return client.name
        end, vim.lsp.get_clients({ bufnr = 0 }))
        if #names > 0 then
          lsp = with_icon(icons.ui.Flash, table.concat(names, ","), "MiniStatuslineDevinfo")
        end
      end
      local cwd = with_icon(icons.ui.Folder, vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), "MiniStatuslineDirinfo")
      local filename = vim.fn.expand("%:.")
      filename = filename ~= "" and with_icon(icons.ui.File, filename, "MiniStatuslineFileinfo") or ""
      local filetype = vim.bo.filetype
      if filetype ~= "" then
        local ft_icon, ft_hl = require("mini.icons").get("filetype", filetype)
        filetype = "%#" .. ft_icon_hl(ft_hl) .. "#" .. ft_icon .. "%#MiniStatuslineFileinfo# " .. filetype
      end

      return status.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, lsp } },
        "%#StatusLine#%=",
        { hl = "MiniStatuslineFilename", strings = {} },
        "%#StatusLine#%=",
        { hl = "MiniStatuslineDirinfo", strings = { cwd } },
        { hl = "MiniStatuslineFileinfo", strings = { filename } },
        { hl = "MiniStatuslineFileinfo", strings = { filetype } },
      })
    end,
  },
  use_icons = true,
})

-- keymap hints --
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

-- indent scope
require("mini.indentscope").setup({
  symbol = icons.ui.LineMiddle,
  options = { try_as_border = true },
})

-- stylua: ignore start
-- highlighting --
local set = vim.api.nvim_set_hl
set(0, "MiniDiffSignAdd",            { fg = colors.green.bright })
set(0, "MiniDiffSignChange",         { fg = colors.yellow.bright })
set(0, "MiniDiffSignDelete",         { fg = colors.red.bright })

set(0, "MiniIndentscopeSymbol",      { fg = colors.bg.lightest })

set(0, "MiniClueNextKey",            { fg = colors.fg.default })
set(0, "MiniClueDescSingle",         { fg = colors.red.base })
set(0, "MiniClueDescGroup",          { fg = colors.yellow.base })

set(0, "MiniStatuslineModeNormal",   { bg = colors.blue.bright,    fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeInsert",   { bg = colors.green.bright,   fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeVisual",   { bg = colors.yellow.bright,  fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeReplace",  { bg = colors.red.bright,     fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeCommand",  { bg = colors.magenta.bright, fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineModeOther",    { bg = colors.fg.default,     fg = colors.bg.default, bold = true, cterm = { bold = true } })
set(0, "MiniStatuslineDevinfo",      { bg = colors.bg.lighter,     fg = colors.fg.default })
set(0, "MiniStatuslineDirinfo",      { bg = colors.bg.default,     fg = colors.fg.darkest })
set(0, "MiniStatuslineFileinfo",     { bg = colors.bg.default,     fg = colors.fg.default })
set(0, "MiniStatuslineDevinfoIcon",  { bg = colors.bg.lighter,     fg = colors.red.base })
set(0, "MiniStatuslineDirinfoIcon",  { bg = colors.bg.default,     fg = colors.blue.base })
set(0, "MiniStatuslineFileinfoIcon", { bg = colors.bg.default,     fg = colors.blue.base })

set(0, "MiniIconsRed",               { fg = colors.red.bright })
set(0, "MiniIconsBlue",              { fg = colors.blue.bright })
set(0, "MiniIconsCyan",              { fg = colors.cyan.bright })
set(0, "MiniIconsGrey",              { fg = colors.white.base })
set(0, "MiniIconsAzure",             { fg = colors.blue.base })
set(0, "MiniIconsGreen",             { fg = colors.green.bright })
set(0, "MiniIconsOrange",            { fg = colors.yellow.base })
set(0, "MiniIconsPurple",            { fg = colors.magenta.bright })
set(0, "MiniIconsYellow",            { fg = colors.yellow.bright })
