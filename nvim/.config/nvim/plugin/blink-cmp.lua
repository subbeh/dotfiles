vim.pack.add({
  "https://github.com/saghen/blink.lib",
  "https://github.com/saghen/blink.cmp",
  "https://github.com/nvim-mini/mini.nvim",
})

local function get_mini_icon(ctx)
  if ctx.source_name == "Path" then
    local is_unknown_type = vim.tbl_contains({ "link", "socket", "fifo", "char", "block", "unknown" }, ctx.item.data.type)
    local mini_icon, mini_hl, _ = require("mini.icons").get(is_unknown_type and "os" or ctx.item.data.type, is_unknown_type and "" or ctx.label)
    if mini_icon then
      return mini_icon, mini_hl
    end
  end
  local mini_icon, mini_hl, _ = require("mini.icons").get("lsp", ctx.kind)
  return mini_icon, mini_hl
end

local cmp = require("blink.cmp")

cmp.build():pwait()
cmp.setup({
  keymap = {
    preset = "default",
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<Tab>"] = { "select_and_accept", "fallback" },
  },

  completion = {
    menu = {
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind", gap = 1 },
        },
        components = {
          kind_icon = {
            text = function(ctx)
              local kind_icon, _ = get_mini_icon(ctx)
              return kind_icon
            end,
            highlight = function(ctx)
              local _, hl = get_mini_icon(ctx)
              return hl
            end,
          },
          kind = {
            highlight = function(ctx)
              local _, hl = get_mini_icon(ctx)
              return hl
            end,
          },
        },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    },
    ghost_text = {
      enabled = true,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  signature = {
    enabled = true,
  },

  cmdline = {
    keymap = {
      preset = "inherit",
    },
    completion = {
      menu = {
        auto_show = function(ctx)
          return vim.fn.getcmdtype() == ":"
        end,
      },
    },
  },

  enabled = function()
    -- Allow completion in cmdline
    if vim.fn.getcmdtype() ~= "" then
      return true
    end

    return not vim.tbl_contains({
      "markdown",
    }, vim.bo.filetype) and vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
  end,
})
