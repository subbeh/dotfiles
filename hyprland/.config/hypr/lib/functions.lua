--- @class Func
local Func = {}

Func.toggle_special = function()
  if hl.get_active_special_workspace() then
    if hl.get_active_special_workspace().name == "special:term" then
      hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace().name }))
    end
  else
    hl.dispatch(hl.dsp.window.move({ workspace = "special:term" }))
  end
end

Func.bitwarden_float = function(window)
  if window.title == "Extension: (Bitwarden Password Manager) - Bitwarden — Mozilla Firefox" then
    hl.dispatch(hl.dsp.window.float(window))
    local x, y = Utils.percent_to_px(20, 50)
    hl.dispatch(hl.dsp.window.resize({ x = x, y = y, window = window }))
    hl.timer(function()
      hl.dispatch(hl.dsp.window.center({ window = window }))
    end, { timeout = 500, type = "oneshot" })
  end
end

Func.move_all_workspaces = function(monitor)
  for _, ws in ipairs(hl.get_workspaces()) do
    if not ws.special then
      hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = monitor }))
    end
  end
end

-- Focuses the first window of `class` outside special workspaces, or runs `cmd` when none is open.
Func.focus_or_launch = function(class, cmd)
  local target
  for _, w in ipairs(hl.get_windows()) do
    if w.class == class and not (w.workspace and w.workspace.special) then
      target = w
      break
    end
  end
  -- an open special workspace stays drawn over the target, so hide it
  local special = hl.get_active_special_workspace()
  if special then
    hl.dispatch(hl.dsp.workspace.toggle_special((special.name:gsub("^special:", ""))))
  end
  if target then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
  else
    hl.exec_cmd(cmd)
  end
end

return Func
