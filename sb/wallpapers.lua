--[[
About his module:
- It contains 2 module functions.
  - apply_to_config(config, options)
    - Access "directory" to get the paths of all image files and stores them in
      wezterm.GLOBAL.images
    - Default "directory" is $HOME/Pictures/Wallpapers/ and it can be changed.
    - Randomly chooses an image from wezterm.GLOBAL.images and displays it as
      a wallpaper by appyling it to config.background. 
    - The image index is stored in wezterm.GLOBAL.image_index.
    - The image brightness is stored in wezterm.GLOBAL.brightness.
  - get_keys(options)
    - contains the event handlers to toggle wallpaper change and brightness
      change.
    - return the keys arrary for:
        - toggling the wallpaper choice forward and backward using Super+b and
          Super+Shift+B, and updating wezterm.GLOBAL.image_index.
        - brightening and dimming the wallpaper using Super+Alt+b and Super+Alt+B and
          updating wezterm.GLOBAL.brightness.

-- Special thanks to @bew for advices/guidance during initial development.
]]

local wezterm = require("wezterm")

local M = {}

-- Function to define the fields of a single layer of config.background.
local function create_blayer(image, brightness)
	if image then
		return {
			source = { File = image },
			hsb = { hue = 1.0, saturation = 1.0, brightness = brightness },
			opacity = 1.0,
			height = "100%",
			width = "100%",
		}
	else
		print("Functon create_blayer parameter 'image' not defined.")
		return {}
	end
end

-- Function to get filepath of all image files and return them in a table
local function get_images(directory)
	-- Check if directory exists and is accessible
	local handle = io.popen('test -d "' .. directory .. '" && echo "exists" || echo "not found"', "r")
	if handle then
		local result = handle:read("*a")
		handle:close()
		if string.match(result, "not found") then
			return {}
		end
	else
		return {} -- Return empty table instead of erroring
	end
	-- Build the find command using your specified approach
	local find_cmd = 'find "'
		.. directory
		.. '" -type f -print0 2>/dev/null| xargs -0 file --mime-type | grep -F "image/" | cut -d: -f1 | sort'
	-- Execute the command and capture output
	local handle = io.popen(find_cmd, "r")
	if not handle then
		return {}
	end
	local results = handle:read("*a")
	handle:close()
	-- Parse the output
	local images = {}
	for line in string.gmatch(results, "[^\n]+") do
		if line ~= "" then -- Filter out empty lines
			table.insert(images, line)
		end
	end

	return images
end

-- Module funtion to apply to config
function M.apply_to_config(config, options)
	local directory = options.directory or wezterm.home_dir .. "/Pictures/Wallpapers"
	local brightness = options.brightness or 0.06

	-- Get images
	wezterm.GLOBAL.images = get_images(directory)
	wezterm.log_info("#wezterm.GLOBAL.images = " .. #wezterm.GLOBAL.images)

	-- Initial state
	if not wezterm.GLOBAL.image_index then
		wezterm.GLOBAL.image_index = math.random(1, #wezterm.GLOBAL.images)
	end
	if not wezterm.GLOBAL.brightness then
		wezterm.GLOBAL.brightness = brightness
	end

	-- Set initial wallpaper
	config.background = {
		create_blayer(wezterm.GLOBAL.images[wezterm.GLOBAL.image_index], brightness),
	}
end

function M.get_keys(options)
	local toggle_forward_key = options.toggle_forward_key or "b"
	local toggle_forward_mods = options.toggle_forward_mods or "SUPER"
	local toggle_backward_key = options.toggle_backward_key or "B"
	local toggle_backward_mods = options.toggle_backward_mods or "SUPER|SHIFT"
	local increase_brightness_key = options.increase_brightness_key or "b"
	local increase_brightness_mods = options.increase_brightness_mods or "SUPER|ALT"
	local decrease_brightness_key = options.decrease_brightness_key or "B"
	local decrease_brightness_mods = options.decrease_brightness_mods or "SUPER|ALT|SHIFT"

	-- Event handler for toggle-wallpaper
	wezterm.on("toggle-wallpaper", function(window, pane, direction)
		local old_index = wezterm.GLOBAL.image_index
		wezterm.log_info("direction = " .. direction)
		wezterm.log_info("old image index : " .. old_index)
		if direction == "forward" then
			wezterm.GLOBAL.image_index = (old_index % #wezterm.GLOBAL.images) + 1
		elseif direction == "backward" then
			wezterm.GLOBAL.image_index = old_index - 1
			if wezterm.GLOBAL.image_index < 1 then
				wezterm.GLOBAL.image_index = #wezterm.GLOBAL.images
			end
		else
			wezterm.error("arg: direction is not defined.")
		end
		local new_index = wezterm.GLOBAL.image_index
		local new_image = wezterm.GLOBAL.images[new_index]
		wezterm.log_info("Image changed to : " .. new_index .. " " .. new_image)
		local overrides = window:get_config_overrides() or {}
		overrides.background = {
			create_blayer(new_image, wezterm.GLOBAL.brightness),
		}
		window:set_config_overrides(overrides)
		wezterm.log_info("window:set_config_overrides(overrides) done.")
	end)

	-- Event handlers for toggle-brightness
	wezterm.on("toggle-brightness", function(window, pane, direction)
		local old_brightness = wezterm.GLOBAL.brightness
		wezterm.log_info("direction = " .. direction)
		wezterm.log_info("old brightness : " .. old_brightness)
		local delta = 0.02
		local brightness = wezterm.GLOBAL.brightness
		if direction == "increase" then
			wezterm.GLOBAL.brightness = brightness + delta
			if wezterm.GLOBAL.brightness > 1.0 then
				wezterm.GLOBAL.brightness = 1.0
			end
		elseif direction == "decrease" then
			wezterm.GLOBAL.brightness = brightness - delta
			if wezterm.GLOBAL.brightness < 0.0 then
				wezterm.GLOBAL.brightness = 0.0
			end
		end
		local new_brightness = wezterm.GLOBAL.brightness
		wezterm.log_info("new_brightness = " .. new_brightness)
		local image = wezterm.GLOBAL.images[wezterm.GLOBAL.image_index]
		local overrides = window:get_config_overrides() or {}
		overrides.background = { create_blayer(image, new_brightness) }
		window:set_config_overrides(overrides)
	end)

	-- Return key bindings so that wezterm can insert it to config.keys
	return {
		-- Toggle forward
		{
			key = toggle_forward_key,
			mods = toggle_forward_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("toggle-wallpaper", window, pane, "forward")
			end),
		},
		-- Toggle backwards
		{
			key = toggle_backward_key,
			mods = toggle_backward_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("toggle-wallpaper", window, pane, "backward")
			end),
		},
		-- Increase brightness
		{
			key = increase_brightness_key,
			mods = increase_brightness_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("toggle-brightness", window, pane, "increase")
			end),
		},
		-- Decrease brightness
		{
			key = decrease_brightness_key,
			mods = decrease_brightness_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("toggle-brightness", window, pane, "decrease")
			end),
		},
	}
end

return M
