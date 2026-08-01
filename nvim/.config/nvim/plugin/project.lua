vim.pack.add({ "https://github.com/ahmedkhalf/project.nvim" })

require("project_nvim").setup({
  manual_mode = true,
  detection_methods = { "pattern", "lsp" },
  patterns = { ">dotfiles", ">dotfiles_v2", ">dots", ">projects", ".git", "go.mod", "_darcs", "Makefile", "package.json", ".obsidian", "__pycache__" },
  exclude_dirs = { "~/.local/*", "/opt/*", "*/temp/*" },
  silent_chdir = false,
  scope_chdir = "tab",
})

vim.keymap.set("n", "<Leader>r", "<cmd>ProjectRoot<cr>", { desc = "Goto Root" })
