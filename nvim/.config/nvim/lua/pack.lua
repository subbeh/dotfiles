local hooks = {
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

vim.pack.clean = function(names, opts)
  opts = opts or {}
  local inactive = {}
  names = vim
    .iter(vim.pack.get(names, { info = false }))
    :map(function(plug)
      if not plug.active then
        table.insert(inactive, plug.spec.name)
      end
      return plug.spec.name
    end)
    :totable()

  if opts.inactive and not vim.tbl_isempty(inactive) then
    vim.pack.del(inactive)
  end

  local plug_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
  for name, type in vim.fs.dir(plug_dir) do
    if type == "directory" and not vim.tbl_contains(names, name) then
      vim.fs.rm(vim.fs.joinpath(plug_dir, name), { recursive = true, force = true })
      vim.notify(("vim.pack: Cleaned plugin '%s'"):format(name), vim.log.levels.INFO)
    end
  end
end

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
vim.keymap.set("n", "<leader>ps", function() vim.pack.update(nil,   { offline = true }) end,      { desc = "Package status" })
vim.keymap.set("n", "<leader>pr", function() vim.pack.update(nil,   { target = 'lockfile' }) end, { desc = "Reset from Lockfile" })
