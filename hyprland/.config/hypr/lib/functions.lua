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

-- Focuses the first window of `class` (switching workspace), or runs `cmd` when none is open.
Func.focus_or_launch = function(class, cmd)
  local win = "class:^" .. class .. "$"
  if hl.get_window(win) then
    hl.dispatch(hl.dsp.focus({ window = win }))
  else
    hl.exec_cmd(cmd)
  end
end

return Func
