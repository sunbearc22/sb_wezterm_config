--[[
What does this module do?
 1. Makes the titlebar (this is where the tabs are located) to be transparent
 2. Randomize the appearance of the left and right ends of the tabs
 3. Provide a function to suggest the tab's name/label
 4. Provide an event handler for format-tab-title. Essentially, it changes the
    tab's shape, showing process icon on its left and autonaming, and changing
    its colors when in the active, inactive and hover states.
 5. Provide a event handler to add the option to rename current tab in the
    command palette.
--]]
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply_to_config(config)
	-- Make the titlebar (when active and inactive) transparent
	-- This is where the wezterm tabs, left and right status are located.
	config.window_frame = {
		inactive_titlebar_bg = "none",
		active_titlebar_bg = "none",
	}

	-- Randomize the shape of the tab's left and right ends
	math.randomseed(os.time())
	local left_tab_end = {
		"", -- nf-ple-left_half_circle_thick
		"", -- nf-pl-right_hard_divider
		"", -- nf-ple-lower_right_triangle
		"", -- nf-ple-upper_right_triangle
		"", -- nf-ple-pixelated_squares_big_mirrored
	}
	local right_tab_end = {
		"", -- nf-ple-right_half_circle_thick
		"", -- nf-pl-left_hard_divider
		"", -- nf-ple-lower_left_triangle
		"", -- nf-ple-upper_left_triangle
		"", -- nf-ple-pixelated_squares_big
	}
	local lte = math.random(1, 5)
	local rte = math.random(1, 5)
	local LEFT_TAB_END = left_tab_end[lte]
	local RIGHT_TAB_END = right_tab_end[rte]

	-- This function returns the suggested title for a tab.
	-- It prefers the title that was set via `tab:set_title()`
	-- or `wezterm cli set-tab-title`, but falls back to the
	-- title of the active pane in that tab.
	local function tab_title(tab_info)
		local title = tab_info.tab_title
		-- if the tab title is explicitly set, take that
		if title and #title > 0 then
			return title
		end
		-- Otherwise, use the title from the active pane in that tab
		return tab_info.active_pane.title
	end

	wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
		-- Color when the tab is inactive
		local edge_background = "none" -- The area behind the tab (make transparent)
		local background = wezterm.GLOBAL.system.shades[4] -- The tab's area
		local foreground = wezterm.GLOBAL.system.shades[9] -- The tab's font
		-- Color of the tab when it is active
		if tab.is_active then
			background = wezterm.GLOBAL.system.color
			foreground = wezterm.GLOBAL.system.tints[7]
		-- Color of the tab when the mouse cursor hovers over the tab
		elseif hover then
			background = wezterm.GLOBAL.system.analogous[2]
			foreground = wezterm.GLOBAL.system.shades[7]
		end
		-- Color of the left and right ends of the tab to be the same color as the tab
		local edge_foreground = background

		-- Create the tab's title
		local title = tab_title(tab)
		-- Ensure that the titles fit in the available space,
		-- and that we have room for the edges.
		title = wezterm.truncate_right(title, max_width - 2)

		-- Get the logo of the process named in title.
		local process_icons = {
			wezterm = "$W", -- WezTerm terminal
			wez = "$W", -- WezTerm terminal (short form)
			nvim = "", -- neovim icon
			bash = "", -- nf-mdi-console
			ssh = "󰣀", -- nf-linux-ssh
			dns = "󰇖", -- nf-linux-dns
			python = "", -- nf-fa-python
			lua = "", -- lua icon
			ollama = "🦙",
			gimp = "", -- nf-mdi-image-filter-vintage
			inkscape = "", -- nf-mdi-vector-rectangle
			krita = "", -- nf-mdi-palette
			freecad = "", -- nf-mdi-cube-outline
			kdenlive = "", -- nf-mdi-video
			libreoffice = "", -- nf-linux-libreoffice
			libreofficebase = "", -- nf-linux-libreoffice-base
			libreofficecalc = "", -- nf-linux-libreoffice-calc
			libreofficeimpress = "", -- nf-linux-libreoffice-impress
			libreofficemath = "", -- nf-linux-libreoffice-math
			libreofficewriter = "", -- nf-linux-libreoffice-writer
			steam = "", -- nf-linux-steam
			thunderbird = "", -- nf-linux-thunderbird
		}
		local lower_title = string.lower(title)
		local logo = ""
		for pattern, icon in pairs(process_icons) do
			if lower_title:find(pattern) then
				logo = icon
				break -- Found match, no need to check further
			end
		end

		-- Create a new LEFT-TAB_END with the logo
		local LOGO_LEFT_TAB_END = logo .. " " .. LEFT_TAB_END

		-- Return the tab's new configuration
		return {
			{ Background = { Color = edge_background } }, -- tab's left end
			{ Foreground = { Color = edge_foreground } }, --      "
			{ Text = LOGO_LEFT_TAB_END }, --      "
			{ Background = { Color = background } }, -- tab's middle region
			{ Foreground = { Color = foreground } }, --      "
			{ Text = title }, --      "
			{ Background = { Color = edge_background } }, -- tab's right end
			{ Foreground = { Color = edge_foreground } }, --      "
			{ Text = RIGHT_TAB_END }, --      "
		}
	end)

	-- Event handler to add an option in the command palette to rename current tab.
	wezterm.on("augment-command-palette", function(window, pane)
		return {
			{
				brief = "Rename Tab",
				icon = "md_rename_box",
				action = act.PromptInputLine({
					description = "Enter new name for tab",
					initial_value = "",
					action = wezterm.action_callback(function(window, pane, line)
						if line then
							window:active_tab():set_title(line)
						end
					end),
				}),
			},
		}
	end)
end

return M
