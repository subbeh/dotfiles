-- Transparent editing of statemate-managed files.
--
-- Three things happen here:
--
--   1. Opening a deployed file redirects to its source. `nvim ~/.ssh/config`
--      edits ssh/.ssh/config#encrypted in the dotfiles repo instead, so you are
--      never editing a file that `mate apply` will overwrite.
--
--   2. Filetype detection is fixed for source files. Statemate keeps metadata in
--      the filename (settings.json#profile:work#encrypted), so nvim reads the
--      extension as "json#profile:work#encrypted" and loses highlighting and
--      LSP. The attrs are stripped and the filetype re-detected.
--
--   3. Files marked #encrypted are age ciphertext on disk. They are decrypted on
--      read and re-encrypted on write so they can be edited in place.
--
-- Requires the `mate` and `age` binaries. If either is missing the autocmds fall
-- back to normal editing rather than erroring.
--
-- Note for #template files: you edit the raw template source, so Go template
-- syntax ({{ ... }}) is intact and unrendered. That is correct -- the template is
-- what is version-controlled -- but it will not show interpolated values.

local augroup = vim.api.nvim_create_augroup("statemate", { clear = true })

local AGE_ATTR = "#encrypted"
local IDENTITY = vim.fn.expand("~/.config/statemate/key.txt")

---Strip statemate #attrs from a path, returning the logical filename.
---"a/settings.json#profile:work#encrypted" -> "a/settings.json"
---@param path string
---@return string
local function strip_attrs(path)
  local dir, base = path:match("^(.*/)([^/]*)$")
  if not base then
    dir, base = "", path
  end
  return dir .. (base:gsub("#.*$", ""))
end

---@param path string
---@return boolean
local function is_encrypted(path)
  -- Substring rather than suffix: #encrypted is not always the last attribute.
  return path:find(AGE_ATTR, 1, true) ~= nil
end

---Whether a path carries statemate attrs, i.e. looks like a source file.
---Only the basename is checked, so a '#' in a parent directory (etc#owner-r:root)
---does not count.
---@param path string
---@return boolean
local function has_attrs(path)
  local base = path:match("[^/]*$") or path
  return base:find("#", 1, true) ~= nil
end

---@return boolean
local function has_mate()
  return vim.fn.executable("mate") == 1
end

---Run mate and return its stdout lines, or nil on failure.
---@param args string[]
---@return string[]|nil
local function mate(args)
  if not has_mate() then
    return nil
  end
  local cmd = { "mate" }
  vim.list_extend(cmd, args)

  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.split(result.stdout or "", "\n", { plain = true, trimempty = true })
end

local source_dir_cache = nil

---The absolute path of the statemate repo, resolved once per session.
---@return string|nil
local function source_dir()
  if source_dir_cache ~= nil then
    return source_dir_cache ~= "" and source_dir_cache or nil
  end

  local out = mate({ "config", "source-dir" })
  source_dir_cache = (out and out[1]) and vim.trim(out[1]) or ""
  return source_dir_cache ~= "" and source_dir_cache or nil
end

---Resolve a deployed target path to its source file.
---
---Relies on `mate managed <abs-path>` matching exactly one entry when given a
---real path. Returns nil when the file is not managed, is not active for the
---current profile, or mate is unavailable.
---@param path string absolute target path
---@return string|nil source absolute path of the source file
---@return boolean is_template whether the source is a template
local function source_for_target(path)
  local out = mate({ "managed", path })
  -- Header only means no match.
  if not out or #out < 2 then
    return nil, false
  end

  local row = out[2]
  local target, rel = row:match("^%s*(%S+)%s+(%S+)")
  if not rel then
    return nil, false
  end

  -- Guard against a loose match returning some other file: the reported target
  -- must be the file we asked about. Compare in ~-shortened form, which is how
  -- mate prints paths under $HOME.
  local home = vim.fn.expand("~")
  local shortened = path:gsub("^" .. vim.pesc(home), "~")
  if target ~= path and target ~= shortened then
    return nil, false
  end

  -- Only redirect for files that apply would actually deploy. An inactive entry
  -- belongs to a profile that is not in play, so editing its source would be
  -- misleading. The marker is a standalone '*' column.
  if not row:match("%s%*%s") then
    return nil, false
  end

  local root = source_dir()
  if not root then
    return nil, false
  end

  return root .. "/" .. rel, rel:find("#template", 1, true) ~= nil
end

---Read age recipients from the repo's mate.yaml.
---
---Recipients are matched by their well-known "age1..." shape rather than by
---parsing YAML structure, which keeps this robust against formatting changes.
---@return string[]
local function recipients()
  local root = source_dir()
  if not root then
    return {}
  end

  local cfg = root .. "/mate.yaml"
  if vim.fn.filereadable(cfg) == 0 then
    cfg = root .. "/mate.yml"
    if vim.fn.filereadable(cfg) == 0 then
      return {}
    end
  end

  local found = {}
  for _, line in ipairs(vim.fn.readfile(cfg)) do
    -- Skip comments so a disabled key is not resurrected.
    if not line:match("^%s*#") then
      local key = line:match("(age1[%w]+)")
      if key then
        table.insert(found, key)
      end
    end
  end
  return found
end

---Set filetype from the attr-stripped filename so highlighting and LSP work.
---@param buf integer
---@param path string
local function apply_filetype(buf, path)
  local clean = strip_attrs(path)
  if clean == path then
    return
  end
  local ft = vim.filetype.match({ filename = clean, buf = buf })
  if ft then
    vim.bo[buf].filetype = ft
  end
end

---Keep plaintext off disk for the lifetime of this buffer.
---@param buf integer
local function harden_buffer(buf)
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.opt_local.backup = false
  vim.opt_local.writebackup = false
end

---Notify outside the current autocmd, so it renders as a message rather than a
---Vim error with a Lua traceback.
---@param msg string
---@param level integer
local function notify_later(msg, level)
  vim.schedule(function()
    vim.notify("statemate: " .. msg, level)
  end)
end

-- Redirect a deployed target to its source file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local path = vim.fn.fnamemodify(args.file, ":p")

    -- Source files already carry attrs; nothing to redirect.
    if path == "" or has_attrs(path) then
      return
    end
    -- Files inside the repo are sources, not targets.
    local root = source_dir()
    if not root or vim.startswith(path, root .. "/") then
      return
    end

    local src, is_template = source_for_target(path)
    if not src or vim.fn.filereadable(src) == 0 then
      return
    end

    local display = vim.fn.fnamemodify(src, ":t")
    vim.schedule(function()
      -- Replace the buffer rather than opening a split, so the target buffer
      -- does not linger and get written by accident.
      vim.cmd("keepalt edit " .. vim.fn.fnameescape(src))
      vim.bo.buflisted = true

      local msg = ("editing source %s"):format(display)
      if is_template then
        msg = msg .. " (template: {{ }} is unrendered)"
      end
      vim.notify("statemate: " .. msg, vim.log.levels.INFO)
    end)
  end,
  desc = "statemate: redirect a deployed file to its source",
})

-- Fix filetype for every mate-managed source file, encrypted or not.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup,
  pattern = "*#*",
  callback = function(args)
    if has_attrs(args.file) then
      apply_filetype(args.buf, args.file)
    end
  end,
  desc = "statemate: detect filetype from attr-stripped filename",
})

-- Decrypt on read.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = augroup,
  pattern = "*" .. AGE_ATTR .. "*",
  callback = function(args)
    local buf = args.buf
    local path = vim.fn.fnamemodify(args.file, ":p")

    vim.bo[buf].buftype = ""
    harden_buffer(buf)

    -- A file that does not exist yet is a new encrypted file: start empty and
    -- let the write path encrypt it.
    if vim.fn.filereadable(path) == 0 then
      apply_filetype(buf, path)
      vim.bo[buf].modified = false
      return
    end

    if vim.fn.executable("age") == 0 then
      notify_later("age not found; cannot decrypt " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.ERROR)
      vim.bo[buf].modifiable = false
      vim.bo[buf].readonly = true
      return
    end

    local result = vim.system({ "age", "--decrypt", "--identity", IDENTITY, path }, { text = true }):wait()

    if result.code ~= 0 then
      -- Non-modifiable matters: it stops a stray :w from replacing good
      -- ciphertext with an empty buffer.
      vim.bo[buf].modifiable = false
      vim.bo[buf].readonly = true
      notify_later(
        ("could not decrypt %s: %s"):format(vim.fn.fnamemodify(path, ":t"), vim.trim(result.stderr or "")),
        vim.log.levels.ERROR
      )
      return
    end

    local lines = vim.split(result.stdout or "", "\n", { plain = true })
    -- Drop the trailing empty element from a final newline, so saving does not
    -- accumulate blank lines.
    if lines[#lines] == "" then
      table.remove(lines)
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
    apply_filetype(buf, path)
  end,
  desc = "statemate: decrypt age-encrypted file on read",
})

-- Re-encrypt on write.
vim.api.nvim_create_autocmd("BufWriteCmd", {
  group = augroup,
  pattern = "*" .. AGE_ATTR .. "*",
  callback = function(args)
    local buf = args.buf
    local path = vim.fn.fnamemodify(args.file, ":p")

    -- On failure, return without clearing 'modified' so the buffer stays dirty
    -- and the failed save is obvious.
    local function abort(msg)
      notify_later(msg, vim.log.levels.ERROR)
    end

    if vim.fn.executable("age") == 0 then
      abort("age not found; file not written")
      return
    end

    local to = recipients()
    if #to == 0 then
      abort("no age recipients found in mate.yaml; refusing to write " .. vim.fn.fnamemodify(path, ":t"))
      return
    end

    -- Armored output matches how statemate stores these files, keeping git diffs
    -- consistent between mate and nvim writes.
    local cmd = { "age", "--armor", "--output", path }
    for _, r in ipairs(to) do
      table.insert(cmd, "--recipient")
      table.insert(cmd, r)
    end

    local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
    local result = vim.system(cmd, { stdin = content, text = true }):wait()

    if result.code ~= 0 then
      abort("encryption failed, file not written: " .. vim.trim(result.stderr or ""))
      return
    end

    vim.bo[buf].modified = false
    notify_later(
      ("encrypted %s (%d recipient%s)"):format(vim.fn.fnamemodify(path, ":t"), #to, #to == 1 and "" or "s"),
      vim.log.levels.INFO
    )
  end,
  desc = "statemate: re-encrypt age file on write",
})
