local CLASS = "dropterm"
local WIN = "class:^" .. CLASS .. "$"
local HIDDEN = "special:" .. CLASS
local SPAWN = "kitty --class " .. CLASS .. " -o font_size=9 -o window_padding_width='20 10 10 10'" .. " -e zsh -c 'tmux new-session -A -s " .. CLASS .. "'"

hl.window_rule({
  match = { class = "^" .. CLASS .. "$" },
  opacity = "0.8",
  float = true,
  no_blur = true,
  no_dim = true,
  size = { "monitor_w*0.8", "monitor_h*0.5" },
  move = { "monitor_w*0.1", "0" },
  animation = "slidefadevert -15%",
})

local hiding = false
local opened_over = nil

-- Sizes dropterm and moves it to the top of the active monitor, or just above it when raised.
local function place_dropterm(raised)
  local monitor = hl.get_active_monitor()
  if not monitor then
    return
  end
  local scale = monitor.scale or 1
  local mw = monitor.width / scale
  local mh = monitor.height / scale
  local w = math.floor(mw * 0.8)
  local h = math.floor(mh * 0.5)
  local x = monitor.x + math.floor(mw * 0.1)
  -- raised clears the border and shadow too, which draw outside the window
  local y = raised and monitor.y - h - 10 or monitor.y
  hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = WIN }))
  hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = WIN }))
end

-- general.no_focus_fallback leaves nothing focused once dropterm leaves, so refocus the window it was opened over,
-- or else the most recently focused window still on screen.
local function refocus()
  local ws = hl.get_active_workspace().name
  local special = hl.get_active_special_workspace()
  special = special and special.name
  local function on_screen(w)
    return w and w.class ~= CLASS and w.workspace and (w.workspace.name == ws or w.workspace.name == special)
  end
  local target = opened_over and hl.get_window("address:" .. opened_over)
  if not on_screen(target) then
    target = nil
    for _, w in ipairs(hl.get_windows()) do
      if on_screen(w) and (not target or w.focus_history_id < target.focus_history_id) then
        target = w
      end
    end
  end
  if target then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
  end
end

-- Shown: pinned on the active workspace, so it follows workspace switches. Hidden: parked on HIDDEN,
-- raised above the monitor so the next show slides it down (windowsMove animation).
function Dropterm()
  return function()
    if hiding then
      return
    end
    local win = hl.get_window(WIN)
    if not win then
      hl.exec_cmd(SPAWN, { pin = true })
    elseif win.workspace and win.workspace.name == HIDDEN then
      local active = hl.get_active_window()
      opened_over = active and active.address
      hl.dispatch(hl.dsp.window.move({ window = WIN, workspace = hl.get_active_workspace().name, follow = false }))
      hl.dispatch(hl.dsp.window.pin({ window = WIN, action = "enable" }))
      place_dropterm(false)
      hl.dispatch(hl.dsp.focus({ window = WIN }))
    else
      hiding = true
      place_dropterm(true)
      -- wait out the slide (windowsMove speed 2 = 200ms) before parking it
      hl.timer(function()
        hl.dispatch(hl.dsp.window.pin({ window = WIN, action = "disable" }))
        hl.dispatch(hl.dsp.window.move({ window = WIN, workspace = HIDDEN, follow = false }))
        refocus()
        hiding = false
      end, { timeout = 250, type = "oneshot" })
    end
  end
end
