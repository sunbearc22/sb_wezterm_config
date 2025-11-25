--[[
My wezterm config for Ubuntu 24.04 system with dual monitors in landscape mode.
1. Implement base features.
2. Configure theme and color of base features to be consistent with
   system theme and color.
3. Configure tabs' shape, title and color and make title-bar transparent.
   Also provide key bindings to activate and move tab.
4. Show wallpapers and provide key bindings to change wallpaper and its brightness.
5. Provide key bindings to span window across screen(s).
]]
local wezterm = require("wezterm")

local config = wezterm.config_builder()

local repos = {
    "https://github.com/sunbearc22/sb_base.wezterm.git",
    "https://github.com/sunbearc22/sb_show_system_color.wezterm.git",
    "https://github.com/sunbearc22/sb_show_tabs.wezterm.git",
    "https://github.com/sunbearc22/sb_show_wallpapers.wezterm.git",
    "https://github.com/sunbearc22/sb_window_spanning.wezterm.git"
}
for _, repo in ipairs(repos) do
    wezterm.plugin.require(repo).apply_to_config(config, {})
end

-- Configure Statrship's color
require("sb.change_starship_colors")

require("sb_equalize_panes").apply_to_config(config, {})

return config
