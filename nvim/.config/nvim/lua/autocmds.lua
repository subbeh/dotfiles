-- Press q to close windows
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "git",
    "help",
    "lspinfo",
    "man",
    "netrw",
    "",
  },
  callback = function()
    vim.cmd([[
      nnoremap <silent> <buffer> q :close!<CR>
      set nobuflisted
    ]])
  end,
})
