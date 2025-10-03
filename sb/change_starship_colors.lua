--[[
What does this module do?
 - Every time window-config-reloaded event is triggered, it updates the 
   ~/.config/starship.toml file with the system theme colors.
 - This script works only for my starship.toml. If you want to use it, you have
   to make the relevant amendments from lines 37 to 55
--]]
local wezterm = require("wezterm")

-- Function to update starship.toml using toml.lua
local function update_starship_toml()
	local starship_toml = wezterm.home_dir .. "/.config/starship.toml"

	-- Read the file
	local file = io.open(starship_toml, "r")
	if not file then
		wezterm.log_warn("Could not open starship.toml file at: " .. starship_toml)
		return
	end
	-- Read all lines
	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	-- Do nothing and return if starship.toml is empty
	if #lines == 0 then
		wezterm.log_warn("~/.config/starship.toml is empty. Starship can't be updated.")
		return
	end

	-- Define the new lines for starship.toml using wezterm.GLOBAL.system.shades
	local bg = wezterm.GLOBAL.system.shades[3]
	local fg = wezterm.GLOBAL.system.shades[10]
	local new_line2 = 'format = """[░▒▓]('
		.. bg
		.. ")[ ](bg:"
		.. bg
		.. " fg:"
		.. fg
		.. ")[](fg:"
		.. bg
		.. ')$directory$character"""'
	local new_line8 = 'success_symbol = "[❯](bold fg:' .. bg .. ')"'
	local new_line12 = 'style = "bold fg:' .. bg .. '"'
	wezterm.log_info("new_line2 = " .. new_line2)
	wezterm.log_info("new_line8 = " .. new_line8)
	wezterm.log_info("new_line12 = " .. new_line12)

	-- Replace the relevant lines
	lines[2] = new_line2
	lines[8] = new_line8
	lines[12] = new_line12

	-- Write back to file
	local outfile = io.open(starship_toml, "w")
	if not outfile then
		wezterm.log_warn("Could not write to: " .. starship_toml)
		return
	end

	for _, line in ipairs(lines) do
		outfile:write(line .. "\n")
	end
	outfile:close()

	wezterm.log_info("Successfully updated starship.toml with wezterm.GLOBAL.system.shades.")
end

-- Function to handle window config reload events
local function on_window_config_reload()
	wezterm.log_info("Window config reloaded, updating starship.toml...")
	update_starship_toml()
end

-- Register the event handler
wezterm.on("window-config-reloaded", function(window, pane)
	-- Use a small delay to ensure the configuration is fully loaded
	wezterm.sleep_ms(100)
	on_window_config_reload()
end)
