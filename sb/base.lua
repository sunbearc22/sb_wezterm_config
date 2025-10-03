--[[
About his module:
- It contains 2 module functions.
  - apply_to_config(config, options)
    - apply the base wezterm configurations that I want. For example:
      - location and size of window at startup
      - disable window resizing when font size is changed
      - use integrated buttton and resizing window decoration
      - show tab bar at the bottom
      - increase font size and line height
      - increase scrollback
      - enable scroll_bar
      - set window padding
      - set cursor to be a blinking bar 
      - prioritize discrete gpu for rendering
  - get_keys(options)
    - contains the event handler to resize the window width to
      (1/4, 1/2, 3/4, 4/4, 1/4right) of all screens.
    - returns the shortcut keys, i.e. Leader key(Super+k) -> 1, 2, 3, 4 or 5,
      to do the window resizing.
]]
local wezterm = require("wezterm")

local all_screens_rows = 33 -- no. of roll cells
local all_screens_cols = 382 -- no. of col cells

local M = {}

function M.apply_to_config(config, options)
	local screens_padx = options.screens_padx or 0
	local screens_pady = options.screens_pady or 0
	local leader_key = options.leader_key or "k"
	local leader_mods = options.leader_mods or "SUPER"

	-- Define LEADER key and mods
	-- timeout_milliseconds defaults to 1000 and can be omitted
	config.leader = { key = leader_key, mods = leader_mods, timeout_milliseconds = 2000 }

	-- Make wezterm GUI appear from the top left corner of the screen(s)
	local start_point = string.format("%d,%d", screens_padx, screens_pady)
	config.default_gui_startup_args = { "start", "--position", start_point }

	-- New window width and height to fill 2 screens.
	config.initial_cols = all_screens_cols
	config.initial_rows = all_screens_rows

	-- Window size should not change when font size is changed
	config.adjust_window_size_when_changing_font_size = false

	-- Window decoration - use default
	-- config.window_decorations = "TITLE | RESIZE" --default
	-- config.window_decorations = "RESIZE" -- GNOME/Ubuntu ignores wezterm attempt to disable the Title bar
	config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

	-- Tab bar at the bottom
	config.tab_bar_at_bottom = true

	-- Set Font (use default Jet Brain Mono)
	-- config.font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
	-- config.harfbuzz_features = {"zero" , "ss01", "cv05"}
	config.font_size = 13
	config.line_height = 1.3

	-- Increase scrollback to retain per tab to
	config.scrollback_lines = 3500

	-- Enable scroll_bar
	config.enable_scroll_bar = true

	-- Define padding in terms of no. of pixels
	config.window_padding = {
		left = 6,
		right = 6, -- controls the scroll-bar's width
		top = 6,
		bottom = 6,
	}

	-- Change cursor to BlinkingBar and control bar size and blinking behaviour
	config.default_cursor_style = "BlinkingBar"
	config.cursor_thickness = "2px"
	config.animation_fps = 20
	config.cursor_blink_ease_in = "EaseIn"
	config.cursor_blink_ease_out = "EaseOut"
	config.cursor_blink_rate = 1000

	-- Prioritize the use of the integrated GPU over discrete GPU as renderer
	-- for wezterm since it is often unused.
	local gpus = wezterm.gui.enumerate_gpus()
	local has_integrated_gpu = false
	local has_discrete_gpu = false
	for _, gpu in ipairs(gpus) do
		if gpu.type == "Integrated" then
			has_integrated_gpu = true
		elseif gpu.type == "Discrete" then
			has_discrete_gpu = true
		end
	end
	if has_discrete_gpu then
		config.webgpu_power_preference = "HighPerformance" -- use the discrete GPU
		wezterm.log_info("Using Discrete GPU.")
	elseif has_integrated_gpu then
		config.webgpu_power_preference = "LowPower" -- use the integrated GPU
		wezterm.log_info("Using Integrated GPU.")
	end
end

function M.get_keys(options)
	local window_span_all_screens_key = options.window_span_all_screens_key or "4"
	local window_span_all_screens_mods = options.window_span_all_screens_mods or "LEADER"
	local window_span_three_quarter_screens_key = options.window_span_three_quarter_screens_key or "3"
	local window_span_three_quarter_screens_mods = options.window_span_three_quarter_screens_mods or "LEADER"
	local window_span_half_screens_key = options.window_span_half_screens_key or "2"
	local window_span_half_screens_mods = options.window_span_half_screens_mods or "LEADER"
	local window_span_quarter_screens_key = options.window_span_quarter_screens_key or "1"
	local window_span_quarter_screens_mods = options.window_span_quarter_screens_mods or "LEADER"
	local window_span_quarter_right_screens_key = options.window_span_quarter_right_screens_key or "5"
	local window_span_quarter_right_screens_mods = options.window_span_quarter_right_screens_mods or "LEADER"

	local screens_padx = options.screens_padx or 0
	local screens_pady = options.screens_pady or 0

	-- Event handlers span window across screens
	wezterm.on("window-span-screens", function(window, pane, span_type)
		-- Window spanning logic
		wezterm.log_info("window-span-screens event handler activated...")
		-- Find out how many screens system has
		local screens = wezterm.gui.screens()
		local by_name = screens.by_name
		local count = 0
		for _, _ in pairs(by_name) do
			count = count + 1
		end
		wezterm.log_info("Detected " .. count .. " screen(s).")

		-- ndow span all screens
		if count == 0 then
			wezterm.log_error("No screen detected.")
		end

		-- Default is for window to span across all screens
		local extra_y = 35 -- adjust it to fit your screens
		local new_width = screens.virtual_width - 2 * screens_padx
		local new_height = screens.virtual_height - 2 * screens_pady - extra_y
		local x_start = screens_padx
		-- Other choices
		if span_type == "three-quarter" then
			new_width = math.floor(screens.virtual_width * 0.75) - 2 * screens_padx
		elseif span_type == "half" then
			new_width = math.floor(screens.virtual_width * 0.5) - 2 * screens_padx
		elseif span_type == "quarter" then
			new_width = math.floor(screens.virtual_width * 0.25) - 2 * screens_padx
		elseif span_type == "quarter-right" then
			new_width = math.floor(screens.virtual_width * 0.25) - 2 * screens_padx
			new_height = screens.virtual_height - 2 * screens_pady - extra_y - 42
			x_start = screens_padx + math.floor(screens.virtual_width * 0.75)
		end
		window:set_position(x_start, screens_pady)
		window:set_inner_size(new_width, new_height)
		wezterm.log_info(
			"Window(" .. span_type .. "): width=" .. new_width .. ", height=" .. new_height .. ", x=" .. x_start
		)
	end)

	-- Return key bindings so that wezterm can insert it to config.keys
	return {
		-- Make window span across all screens
		{
			key = window_span_all_screens_key,
			mods = window_span_all_screens_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("window-span-screens", window, pane, "all")
			end),
		},
		-- Make window span across three quarter width of screens
		{
			key = window_span_three_quarter_screens_key,
			mods = window_span_three_quarter_screens_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("window-span-screens", window, pane, "three-quarter")
			end),
		},
		-- Make window span across half width of screens
		{
			key = window_span_half_screens_key,
			mods = window_span_half_screens_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("window-span-screens", window, pane, "half")
			end),
		},
		-- make window span across quarter width of screens and place to the right end
		{
			key = window_span_quarter_screens_key,
			mods = window_span_quarter_screens_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("window-span-screens", window, pane, "quarter")
			end),
		},
		{
			key = window_span_quarter_right_screens_key,
			mods = window_span_quarter_right_screens_mods,
			action = wezterm.action_callback(function(window, pane)
				wezterm.emit("window-span-screens", window, pane, "quarter-right")
			end),
		},
	}
end

return M
