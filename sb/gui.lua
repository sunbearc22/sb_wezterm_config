local wezterm = require("wezterm")
local mux = wezterm.mux

local all_screens_rows = 20 -- no. of roll cells
local all_screens_cols = 281 -- no. of col cells

-- function to update the wezterm.GLOBAL.started_windows table
local function update_global_started_windows(window)
	-- Initialize Global started_windows table
	local started_windows = wezterm.GLOBAL.started_windows or {}
	-- Get window id
	local id = tostring(window:window_id())
	-- If new windows, update it to wezterm.GLOBAL.started_windows
	if not started_windows[id] then
		started_windows[id] = true
		wezterm.GLOBAL.started_windows = started_windows
		wezterm.log_info(id .. " wezterm.GLOBAL.started_windows = " .. tostring(wezterm.GLOBAL.started_windows))
	end
end

-- function to access screens.by_name table and count the number of screens
local function count_screens()
	local screens = wezterm.gui.screens()
	local by_name = screens.by_name
	local count = 0
	for _, _ in pairs(by_name) do
		count = count + 1
	end
	wezterm.log_info("Detected " .. count .. " screen(s).")
	return count
end

wezterm.on("gui-startup", function(cmd)
	wezterm.log_info(string.format("[gui-startup] created new window"))
	-- Find out how many screens system has.
	local count = count_screens()
	-- Create maximized window for 1 screen
	if count == 1 then
		local tab, pane, window = mux.spawn_window(cmd or {})
		if window then
			window:maximize()
			update_global_started_windows(window)
		end
	-- Create maximized window for more than 1 screen
	elseif count > 1 then
		-- Todo:
		-- Need a function to relate the number of required cells required to
		-- maximize window for different screen counts in terms of
		-- screens.virtual_width & screens.virtual_height.
		-- For now, just use below values
		local tab, pane, window = mux.spawn_window(cmd or {
			width = all_screens_cols, -- no. of column cells
			height = all_screens_rows, -- no. of roll cells
			position = {
				x = 0,
				y = 0,
				origin = "ScreenCoordinateSystem",
			},
		})
		if window then
			update_global_started_windows(window)
		end
	else
		wezterm.log_error("No screen detected.")
	end
end)

-- wezterm.on("window-config-reloaded", function(window, pane)
-- 	wezterm.log_info(string.format("[window-config-reload] detected window: %s, pane: %s", window, pane))
-- 	-- Find out how many screens system has.
-- 	local count = count_screens()
-- 	-- Create maximized window for 1 screen
-- 	if count == 1 then
-- 		window:maximize()
-- 		update_global_started_windows(window)
-- 	-- Create maximized window for more than 1 screen
-- 	elseif count > 1 then
-- 		local screens = wezterm.gui.screens()
-- 		window:set_position(0, 0)
-- 		window:set_inner_size(screens.virtual_width, screens.virtual_height - 10)
-- 		update_global_started_windows(window)
-- 		wezterm.log_info(
-- 			"screens.virtual_width: " .. screens.virtual_width .. "screens.virtual_height" .. screens.virtual_height
-- 		)
-- 	else
-- 		wezterm.log_error("No screen detected.")
-- 	end
-- end)
