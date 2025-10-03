--[[
About his module:
- It contains 2 module functions.
  - apply_to_config(config, options)
    - initialize wezterm.GLOBAL.system table with default value for theme,
      color, shades, tints, triadic, complementary and analogous. Serves as
      fallback values.
    - these fields are then updated based on Ubuntu's theme and color via a 
      custom python script that works only for Ubuntu >=24.04 and functions in
      sb.func_c.lua.
    - configure wezterm color_scheme
    - configure wezterm colors for:
      - window fg & bg
      - cursor
      - selection
      - scroll_bar thumb
      - split
      - launcher
  - change_starship_colors(toml)
    - if the starship.toml exist, it will amend it colors.
    - USE THIS FUNCTION WITH CARE as the customization is unique to my
      starship.toml file and can corrupt your starship.toml file. 
--]]
local wezterm = require("wezterm")
local func_c = require("sb.func_c")

local M = {}

-- Local Function to update wezterm.GLOBAL.system table with Ubuntu >=24.04
-- theme, color, shades, tints, triadic, complementary and analogous colors
local function update_GLOBAL_system_theme_color()
	-- Default state of wezterm.GLOBAL.system table
	if not wezterm.GLOBAL.system then
		wezterm.GLOBAL.system = {
			theme = "Yaru-purple-dark",
			color = "#7764d8",
			shades = func_c.get_shades_of("#7764d8", 10),
			tints = func_c.get_tints_of("#7764d8", 10),
			triadic = func_c.get_triadic_colors_of("#7764d8"),
			complementary = func_c.get_complementary_color_of("#7764d8"),
			analogous = func_c.get_analogous_colors_of("#7764d8", 3),
		}
	end

	-- Use custom python script to get Ubuntu >=24.04 theme and color
	local pyscript = wezterm.config_dir .. "/sb/get_ubuntu_24.04_theme_color.py"
	-- wezterm.log_info("pyscript = " .. pyscript)
	local success, stdout, stderr = wezterm.run_child_process({ "python3", pyscript })

	-- What to do when python script fails
	if not success then
		wezterm.log_error("Failed to run Python script: " .. tostring(stderr))
	end

	-- Split stdout into individual lines, removes leading and trailing
	-- whitespace from each line, filter out empty lines and store data
	-- as an array
	local lines = {}
	for line in stdout:gmatch("[^\r\n]+") do
		line = line:match("^%s*(.-)%s*$")
		if line ~= "" then
			table.insert(lines, line)
		end
	end

	-- Update GLOBAL.system table with Ubuntu's theme, color, shades, tints,
	-- triadic, complementary and analogius colors
	if #lines == 2 then
		wezterm.GLOBAL.system.theme = lines[1]
		wezterm.GLOBAL.system.color = string.lower(lines[2])
		local ucolor = wezterm.GLOBAL.system.color
		wezterm.GLOBAL.system.shades = func_c.get_shades_of(ucolor, 10)
		wezterm.GLOBAL.system.tints = func_c.get_tints_of(ucolor, 10)
		wezterm.GLOBAL.system.triadic = func_c.get_triadic_colors_of(ucolor)
		wezterm.GLOBAL.system.complementary = func_c.get_complementary_color_of(ucolor)
		wezterm.GLOBAL.system.analogous = func_c.get_analogous_colors_of(ucolor, 3)
	else
		wezterm.log_error("Expected exactly 2 lines from Python script, got " .. #lines)
	end

	-- Debug: Print all values
	wezterm.log_info("System:- theme=" .. wezterm.GLOBAL.system.theme .. ", color=" .. wezterm.GLOBAL.system.color)
end

-- Local Function returns a color scheme for a given system theme
local function get_color_scheme_for(theme)
	if string.lower(theme):find("dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

-- Module Function to apply to config
function M.apply_to_config(config)
	update_GLOBAL_system_theme_color()
	config.color_scheme = get_color_scheme_for(wezterm.GLOBAL.system.theme)
	config.colors = {
		foreground = wezterm.GLOBAL.system.tints[5], -- The default text color
		background = wezterm.GLOBAL.system.shades[10], -- The default background color
		cursor_bg = wezterm.GLOBAL.system.color,
		cursor_fg = wezterm.GLOBAL.system.triadic[3],
		cursor_border = wezterm.GLOBAL.system.shades[8],
		compose_cursor = "gold",
		selection_fg = wezterm.GLOBAL.system.complementary[2],
		selection_bg = wezterm.GLOBAL.system.shades[9],
		scrollbar_thumb = wezterm.GLOBAL.system.color,
		split = wezterm.GLOBAL.system.shades[6],
		launcher_label_bg = { AnsiColor = "Black" }, -- (*Since: Nightly Builds Only*)
		launcher_label_fg = { Color = wezterm.GLOBAL.system.triadic[2] }, -- (*Since: Nightly Builds Only*)
	}
	config.integrated_title_button_color = wezterm.GLOBAL.system.color
end

local function file_exists(filename)
	local file = io.open(filename, "r")
	if file then
		file:close()
		return true
	else
		return false
	end
end

function M.change_starship_colors(toml)
	local sfile = toml or wezterm.home_dir .. "/.config/starship.toml"
	if file_exists(sfile) then
		require("sb.change_starship_colors")
	end
end

return M
