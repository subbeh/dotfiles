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

local function delete()
	local path = current_file()
	if not path then
		mp.osd_message("Can't delete: not a local file")
		return
	end

	local _, name = utils.split_path(path)

	input.get({
		prompt = "Delete " .. name .. "? (y/N)",
		submit = function(answer)
			input.terminate()
			if answer:lower() ~= "y" then
				mp.osd_message("Delete canceled")
				return
			end

			local ok, err = os.remove(path)
			if ok then
				-- Removing the current entry advances to the next, or ends playback if last.
				mp.commandv("playlist-remove", "current")
				mp.osd_message("Deleted: " .. path)
			else
				mp.osd_message("Delete failed: " .. tostring(err))
			end
		end,
	})
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

mp.add_key_binding(nil, "delete-file", delete)
mp.add_key_binding(nil, "rename-file", rename)
