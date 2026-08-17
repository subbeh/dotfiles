vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/rshkarin/mason-nvim-lint",
})

require("mason").setup()

--- Call `fn` at most once per `ms`, restarting the delay on each call.
local function debounce(ms, fn)
  local timer = assert(vim.uv.new_timer())
  return function()
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(fn)
    end)
  end
end

local lint = require("lint")

lint.linters_by_ft = {
  lua = { "selene" },
  systemd = { "systemd-analyze" },
  zsh = { "zsh" },
}

table.insert(lint.linters.selene.args, function()
  local root = vim.fs.root(0, "selene.toml")
  if root then
    return string.format("--config=%s", vim.fs.joinpath(root, "selene.toml"))
  end
  local fname = vim.api.nvim_buf_get_name(0)
  local use_default = vim.fs.basename(fname) == ".nvim.lua" or vim.iter(vim.api.nvim_list_runtime_paths()):any(function(path)
    return vim.fs.relpath(path, fname) ~= nil
  end)

  if use_default then
    return string.format("--config=%s", vim.fs.joinpath(vim.fn.stdpath("config"), "selene.toml"))
  end
end)

local augroup = vim.api.nvim_create_augroup("user.lint", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = vim.tbl_keys(lint.linters_by_ft),
  callback = function(args)
    vim.api.nvim_clear_autocmds({ buffer = args.buf, group = augroup })
    local debounced_lint = debounce(100, lint.try_lint)
    debounced_lint()
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = augroup,
      buffer = args.buf,
      callback = function()
        debounced_lint()
      end,
      desc = "lint",
    })
  end,
  desc = "setup nvim-lint",
})

require("mason-nvim-lint").setup({
  ignore_install = { "systemd-analyze", "zsh" },
})
