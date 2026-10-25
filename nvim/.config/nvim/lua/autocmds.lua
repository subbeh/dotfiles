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

-- Publish this instance's server on its tmux pane, so `cda` can :cd it.
if vim.env.TMUX_PANE then
  vim.system({ "tmux", "set", "-p", "-t", vim.env.TMUX_PANE, "@nvim_server", vim.v.servername })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      vim.system({ "tmux", "set", "-p", "-u", "-t", vim.env.TMUX_PANE, "@nvim_server" }):wait()
    end,
    desc = "Unpublish nvim server from tmux pane",
  })
end
