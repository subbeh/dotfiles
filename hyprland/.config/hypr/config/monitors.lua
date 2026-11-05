local M = {}

local function is_connected(monitor, live)
  for _, mon in ipairs(live) do
    if mon.description == MONITORS[monitor].desc then
      return true
    end
  end
  return false
end

local function match_profile(profile, live)
  for monitor in pairs(profile.monitors) do
    if not is_connected(monitor, live) then
      return false
    end
  end
  return true
end

local function get_profile(live)
  for _, profile in ipairs(PROFILES) do
    if match_profile(profile, live) then
      return profile.name
    end
  end
end

local function get_monitor(desc)
  for name, item in pairs(MONITORS) do
    if item.desc == desc then
      return name
    end
  end
end

local function logical_width(cat)
  local px = tonumber(cat.mode:match("(%d+)x"))
  return math.floor(px / (cat.scale or 1) + 0.5)
end

local function apply_profile(profile, live)
  for _, p in ipairs(PROFILES) do
    if p.name == profile then
      local active = {}
      for _, mon in ipairs(live) do
        local name = get_monitor(mon.description)
        local role = name and p.monitors[name]
        if role then
          table.insert(active, { mon = mon, name = name, role = role })
        else
          hl.monitor({
            output = "desc:" .. mon.description,
            disabled = true,
          })
        end
      end
      table.sort(active, function(a, b)
        return (a.role.pos or 0) < (b.role.pos or 0)
      end)
      local x = 0
      for _, item in ipairs(active) do
        local mon = item.mon
        local role = item.role
        local cat = MONITORS[item.name]
        local scale = cat.scale or 1
        hl.monitor({
          output = "desc:" .. mon.description,
          mode = cat.mode,
          position = x .. "x0",
          scale = tostring(scale),
        })
        if role.ws then
          for _, n in ipairs(role.ws) do
            hl.workspace_rule({
              workspace = tostring(n),
              monitor = "desc:" .. mon.description,
              persistent = true,
            })
          end
        end
        if role.waybar then
          StartWaybar(mon.description)
        end
        x = x + logical_width(cat)
      end
    end
  end
end

local function lid_closed()
  local f = io.open("/proc/acpi/button/lid/LID/state")
  if not f then
    return false
  end
  local closed = f:read("*a"):find("closed") ~= nil
  f:close()
  return closed
end

local function reload_layout()
  -- all = true: a panel disabled on lid close must still be listed to re-enable it
  local live = hl.get_monitors({ all = true })
  local candidates = live
  if lid_closed() then
    candidates = {}
    for _, mon in ipairs(live) do
      if not mon.name:match("^eDP") then
        table.insert(candidates, mon)
      end
    end
  end
  if #candidates > 0 then
    local profile = get_profile(candidates)
    if profile then
      apply_profile(profile, live)
    end
  end
end

-- a full reload re-runs M.init, which applies the layout again
local function reload()
  hl.dispatch(hl.dsp.reload_config())
end

-- the panel is toggled by the lid binds; reloading on it loops while the lid is closed
local function on_monitor_change(mon)
  if not mon.name:match("^eDP") then
    reload()
  end
end

M.init = function()
  hl.timer(function()
    reload_layout()
    hl.on("monitor.added", on_monitor_change)
    hl.on("monitor.removed", on_monitor_change)
    hl.bind("switch:on:Lid Switch", reload_layout, { locked = true })
    hl.bind("switch:off:Lid Switch", reload, { locked = true })
  end, { timeout = 500, type = "oneshot" })
end

return M
