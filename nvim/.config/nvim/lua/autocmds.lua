local augroup = vim.api.nvim_create_augroup("user", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
  desc = "Highlight text on yank",
})

-- Press q to close windows
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = {
    "checkhealth",
    "git",
    "help",
    "lspinfo",
    "man",
    "netrw",
    "qf",
    "",
  },
  callback = function()
    vim.cmd([[
      nnoremap <silent> <buffer> q :close!<CR>
      set nobuflisted
    ]])
  end,
  desc = "Press q to close window",
})
