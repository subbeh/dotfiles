local mp = require("mp")
local utils = require("mp.utils")
local input = require("mp.input")

-- Absolute path of the currently playing file (nil for streams/URLs).
local function current_file()
	local path = mp.get_property_native("path")
	if not path or path:find("://") then
		return nil
	end
	if utils.join_path("/", path) == path then
		return path -- already absolute
	end
	return utils.join_path(mp.get_property_native("working-directory"), path)
end

local function trash()
	local path = current_file()
	if not path then
		mp.osd_message("Can't trash: not a local file")
		return
	end

	-- Removing the current entry advances to the next, or ends playback if last.
	mp.commandv("playlist-remove", "current")

	local res = mp.command_native({
		name = "subprocess",
		args = { "gio", "trash", "--", path },
		playback_only = false,
	})

	if res.status == 0 then
		mp.osd_message("Trashed: " .. path)
	else
		mp.osd_message("Trash failed: " .. path)
	end
end

local function rename()
	local path = current_file()
	if not path then
		mp.osd_message("Can't rename: not a local file")
		return
	end

	local dir, name = utils.split_path(path)

	input.get({
		prompt = "Rename to:",
		default_text = name,
		cursor_position = #name,
		submit = function(new_name)
			input.terminate()
			if new_name == "" or new_name == name then
				return
			end

			local new_path = utils.join_path(dir, new_name)
			local ok, err = os.rename(path, new_path)
			if ok then
				mp.osd_message("Renamed to: " .. new_name)
			else
				mp.osd_message("Rename failed: " .. tostring(err))
			end
		end,
	})
end

mp.add_key_binding(nil, "trash-file", trash)
mp.add_key_binding(nil, "rename-file", rename)
