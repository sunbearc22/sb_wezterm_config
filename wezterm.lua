--[[
My wezterm config for Ubuntu 24.04 system with dual monitors in 
landscape mode:
 - It includes base features that I want. Read sb.base.lua for details. 
 - Also, it includes shortcut keys to: 
   - Span window across all screens at start and has keys to resize window
     width to (1/4, 1/2, 3/4, 4/4, 1/4right) of all screens.
     Leader key(Super+k) -> 1, 2, 3, 4 or 5.
 - Shows theme and color that is consistent to Ubuntu 24.04 theme and
   color, and applies them to the Starship prompt.
 - Its tabs shapes are changable whenever config is reloaded and they have
   has suggested titles/labels & icons.
 - Shows wallpaper. It's change can be toggled forward and backward and it
   can be brightened or dimmed. Shows a different wallpaper on different
   windows. See wp_options for default shortcut keys.
--]]
local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Implement base features. Includes keys to resize the window.
local base_options = {}
-- base_options.screens_padx = 0
-- base_options.screens_pady = 0
-- base_options.leader_mods or "SUPER"
-- base_options.leader_key = "k"
-- base_options.window_span_quarter_screens_mods = "LEADER"
-- base_options.window_span_quarter_screens_key = "1"
-- base_options.window_span_half_screens_mods = "LEADER"
-- base_options.window_span_half_screens_key = "2"
-- base_options.window_span_three_quarter_screens_mods = "LEADER"
-- base_options.window_span_three_quarter_screens_key = "3"
-- base_options.window_span_all_screens_mods = "LEADER"
-- base_options.window_span_all_screens_key = "4"
-- base_options.window_span_quarter_right_screens_mods = "LEADER"
-- base_options.window_span_quarter_right_screens_key = "5"
local base = require("sb.base")
base.apply_to_config(config, base_options)
local base_keys = base.get_keys(base_options)

-- Configure theme and color of base features (and startship prompt) to be
-- consistent with system theme and color. YOU HAVE TO TWEAK
-- sb.change_starship_colors.lua TO MAKE IT WORK WITH YOUR starship.toml.
local colors = require("sb.colors")
colors.apply_to_config(config)
colors.change_starship_colors() -- enable this ONLY AFTER TWEAKING FILE

-- Configure tabs' shape, title and color and make title-bar transparent
local tabs = require("sb.tabs")
tabs.apply_to_config(config)

-- Show wallpaper in background. The wallpaper and its brightness can be
-- changed using shortcut keys. To use your own option values, you have to
-- amend and uncomment below option(s)
local wp_options = {}
-- wp_options.background = wezterm.home_dir .. "/Pictures/Wallpapers_wezterm"
-- wp_options.brightness = 0.06
-- wp_options.opacity = 0.0
-- wp_options.toggle_forward_mods = "SUPER"
-- wp_options.toggle_forward_key = "b"
-- wp_options.toggle_backward_mods = "SUPER|SHIFT"
-- wp_options.toggle_backward_key = "B"
-- wp_options.increase_brightness_mods = "SUPER|ALT"
-- wp_options.increase_brightness_key = "b"
-- wp_options.decrease_brightness_mods = "SUPER|ALT|SHIFT"
-- wp_options.decrease_brightness_key = "B"
local wp = require("sb.wallpapers")
wp.apply_to_config(config, wp_options)
local wp_keys = wp.get_keys(wp_options)

-- Load module keys into config.keys
config.keys = {}
-- Add keys from base module
if base_keys then
	for _, keybinding in ipairs(base_keys) do
		table.insert(config.keys, keybinding)
	end
end
-- Add keys from wallpapers module
if wp_keys then
	for _, keybinding in ipairs(wp_keys) do
		table.insert(config.keys, keybinding)
	end
end

return config
