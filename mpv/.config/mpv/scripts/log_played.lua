local mp = require("mp")

local o = {
	log_file = "history.txt",
}

require("mp.options").read_options(o)

mp.register_event("file-loaded", function()
	local name = mp.get_property_native("filename")
	if not name then
		return
	end

	local file = io.open(o.log_file, "a")
	if file then
		file:write(name .. "\n")
		file:close()
	end
end)
