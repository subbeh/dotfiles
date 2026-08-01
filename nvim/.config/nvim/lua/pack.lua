local hooks = {
  ["telescope-fzf-native.nvim"] = {
    kind = { "install", "update" },
    build = { "make" },
  },
  ["nvim-texlabconfig"] = {
    kind = { "install", "update" },
    build = { "go", "build", "-o", vim.fs.joinpath(vim.env.HOME, ".local/bin/") },
  },
  ["mason.nvim"] = {
    kind = { "update" },
    build = "MasonUpdate",
  },
  ["nvim-treesitter"] = {
    kind = { "update" },
    build = function()
      local success, res = pcall(require("nvim-treesitter").update)
      if success and #vim.api.nvim_list_uis() == 0 then
        res:wait(300000)
      end
    end,
  },
}

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("build_system", { clear = true }),
  callback = function(args)
    local pkg = args.data
    local hook = hooks[pkg.spec.name]
    local success, res
    if not hook or not vim.list_contains(hook.kind, pkg.kind) then
      return
    elseif type(hook.build) == "table" then
      success, res = pcall(vim.system, hook.build, { cwd = pkg.path })
      if success and #vim.api.nvim_list_uis() == 0 then
        res:wait(300000)
      end
    else
      if not pkg.active then
        vim.cmd.packadd(pkg.spec.name)
      end

      if type(hook.build) == "string" then
        success, res = pcall(vim.cmd[hook.build])
      elseif type(hook.build) == "function" then
        success, res = pcall(hook.build, pkg)
      end
    end

    if success == false then
      vim.notify(("Failed to build - %s: %s"):format(pkg.spec.name, res), vim.log.levels.ERROR, { title = "vim.pack" })
    end
  end,
})

-- stylua: ignore start
-- Keymaps
vim.keymap.set("n", "<leader>pu", function() vim.pack.update() end, { desc = "Update Packages" })
vim.keymap.set("n", "<leader>ps", function() vim.pack.update(nil, { offline = true }) end, { desc = "Package status" })
vim.keymap.set("n", "<leader>pr", function() vim.pack.update(nil, { target = 'lockfile' }) end, { desc = "Reset from Lockfile" })
