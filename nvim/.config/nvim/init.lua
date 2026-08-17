vim.g.start_time = vim.uv.hrtime()
vim.loader.enable()

require("options")
require("autocmds")
require("keymaps")
require("pack")
require("diagnostic")
