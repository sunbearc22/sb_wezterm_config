--[[
This module contains functions to return a color's:
  - shades,  (default 10)  
  - tinits,  (default 10)
  - triadic colors  (default 2)
  - complementary color (default 1), 
  - analogous colors (default 2)
Their returned arrary contains the original color + the default number of results. So their array size is always 1 larger than the required number of results. 
--]]
local wezterm = require("wezterm")

-- Function to check if hex_color is valid or not.
local function hex_is_valid(hex_color)
	-- Basic validation
	if not hex_color or type(hex_color) ~= "string" then
		wezterm.log_error("Invalid input: hex_color must be a string")
		return false
	end

	if #hex_color ~= 7 or string.sub(hex_color, 1, 1) ~= "#" then
		wezterm.log_error("Invalid hex color format. Expected format: #RRGGBB")
		return false
	end

	return true
end

-- Function to convert hex_color to rgb numbers
local function hex_to_rgb(hex_color)
	-- Convert hex to RGB components
	local r = tonumber(string.sub(hex_color, 2, 3), 16)
	local g = tonumber(string.sub(hex_color, 4, 5), 16)
	local b = tonumber(string.sub(hex_color, 6, 7), 16)

	return r, g, b
end

-- Function to convert rgb numbers to hex_color.
local function rgb_to_hex(r, g, b)
	return string.lower(string.format("#%02x%02x%02x", r, g, b))
end

-- Function to get the shades of a color
local function get_shades_of(hex_color, num_shades)
	-- Set default value for num_shades
	num_shades = num_shades or 10
	-- Check hex_color
	if not hex_is_valid(hex_color) then
		return {}
	end
	-- Convert base hex color to RGB components
	local r_base, g_base, b_base = hex_to_rgb(hex_color)

	local result = {}
	-- Linear function gradient
	local r_grad = -r_base / num_shades
	local g_grad = -g_base / num_shades
	local b_grad = -b_base / num_shades
	for i = 0, num_shades do
		--- Linear function from base color to black (0,0,0)
		local r = math.max(0, math.floor(r_grad * i + r_base))
		local g = math.max(0, math.floor(g_grad * i + g_base))
		local b = math.max(0, math.floor(b_grad * i + b_base))
		-- Format as hex string
		local shade = rgb_to_hex(r, g, b)
		-- insert to result
		table.insert(result, shade)
	end
	return result
end

-- Function to get the tints of a color
local function get_tints_of(hex_color, num_tints)
	-- Set default value for num_tints
	num_tints = num_tints or 10
	-- Check hex_color
	if not hex_is_valid(hex_color) then
		return {}
	end
	-- Convert base hex color to RGB components
	local r_base, g_base, b_base = hex_to_rgb(hex_color)

	local result = {}
	-- Linear function gradient
	local r_grad = (255 - r_base) / num_tints
	local g_grad = (255 - g_base) / num_tints
	local b_grad = (255 - b_base) / num_tints
	for i = 0, num_tints do
		-- Linear function from base color to white (255,255,255)
		local r = math.min(255, math.floor(r_grad * i + r_base))
		local g = math.min(255, math.floor(g_grad * i + g_base))
		local b = math.min(255, math.floor(b_grad * i + b_base))
		-- Format as hex string
		local shade = rgb_to_hex(r, g, b)
		-- insert to result
		table.insert(result, shade)
	end
	return result
end

-- Function to get the triadic colors of a color
local function get_triadic_colors_of(hex_color)
	-- Check hex_color
	if not hex_is_valid(hex_color) then
		return {}
	end
	-- Convert hex to RGB components
	local r, g, b = hex_to_rgb(hex_color)
	return {
		string.lower(hex_color),
		rgb_to_hex(b, r, g),
		rgb_to_hex(g, b, r),
	}
end

local function get_complementary_color_of(hex_color)
	if not hex_is_valid(hex_color) then
		return {}
	end
	-- Convert base hex color to RGB components
	local r, g, b = hex_to_rgb(hex_color)
	-- Calculate complementary color by subtracting each component from 255
	local comp_r = 255 - r
	local comp_g = 255 - g
	local comp_b = 255 - b
	-- Return as hex string
	return {
		string.lower(hex_color),
		rgb_to_hex(comp_r, comp_g, comp_b),
	}
end

-- Helper function to convert RGB to HSL
local function rgbToHsl(r, g, b)
	-- Normalize RGB values to 0-1 range
	r = r / 255
	g = g / 255
	b = b / 255

	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min

	-- Calculate Lightness
	local l = (max + min) / 2

	-- Calculate Saturation
	local s = 0
	if delta ~= 0 then
		s = delta / (1 - math.abs(2 * l - 1))
	end

	-- Calculate Hue
	local h = 0
	if delta ~= 0 then
		if max == r then
			h = 60 * (((g - b) / delta) % 6)
		elseif max == g then
			h = 60 * ((b - r) / delta + 2)
		else
			h = 60 * ((r - g) / delta + 4)
		end
	end

	return h, s, l
end

-- Helper function to convert HSL to RGB
local function hslToRgb(h, s, l)
	local r, g, b

	if s == 0 then
		-- Grayscale
		r = l * 255
		g = l * 255
		b = l * 255
	else
		local hue2rgb = function(p, q, t)
			if t < 0 then
				t = t + 1
			end
			if t > 1 then
				t = t - 1
			end
			if t < 1 / 6 then
				return p + (q - p) * 6 * t
			end
			if t < 1 / 2 then
				return q
			end
			if t < 2 / 3 then
				return p + (q - p) * (2 / 3 - t) * 6
			end
			return p
		end

		local q = l < 0.5 and l * (1 + s) or l + s - l * s
		local p = 2 * l - q

		r = hue2rgb(p, q, h / 360 + 1 / 3)
		g = hue2rgb(p, q, h / 360)
		b = hue2rgb(p, q, h / 360 - 1 / 3)
	end

	return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

-- Function to get the Analogous Colors of a color
local function get_analogous_colors_of(hex_color, num_colors, angle_offset)
	if not hex_is_valid(hex_color) then
		return {}
	end
	-- Convert base hex color to RGB components
	local r, g, b = hex_to_rgb(hex_color)
	-- Convert RGB to HSL for easier manipulation
	local h, s, l = rgbToHsl(r, g, b)

	-- Default values for num_colors and angle_offset
	if not num_colors then
		num_colors = 2
	end
	if not angle_offset then
		angle_offset = 30
	end
	-- Ensure we don't exceed 360 degrees
	if angle_offset > 180 then
		angle_offset = 180
	end

	local analogous_colors = {}
	-- Add the original color as the first element
	table.insert(analogous_colors, string.lower(hex_color))
	-- Generate the analogous colors
	for i = 1, num_colors do
		-- Calculate angle offset (can be positive or negative)
		local angle = (i - (num_colors + 1) / 2) * angle_offset
		-- Add to hue and wrap around 360
		local new_hue = (h + angle) % 360
		-- Convert back to RGB
		local r_new, g_new, b_new = hslToRgb(new_hue, s, l)
		-- Convert to hex and add to results
		table.insert(analogous_colors, rgb_to_hex(r_new, g_new, b_new))
	end

	return analogous_colors
end

-- wezterm.log_info("Shades of YaruDarkPurple:")
-- local yarudarkpurple_shades = get_shades_of("#7764d8", 10)
-- for i, color in ipairs(yarudarkpurple_shades) do
-- 	wezterm.log_info(string.format("Shade %d: %s", i, color))
-- end
--
-- wezterm.log_info("Tints of YaruDarkPurple:")
-- local yarudarkpurple_tints = get_tints_of("#7764d8", 10)
-- for i, color in ipairs(yarudarkpurple_tints) do
-- 	wezterm.log_info(string.format("Tint %d: %s", i, color))
-- end
--
-- wezterm.log_info("Triadic of YaruDarkPurple:")
-- local yarudarkpurple_triadic = get_triadic_colors_of("#7764d8")
-- for i, color in ipairs(yarudarkpurple_triadic) do
-- 	wezterm.log_info(string.format("Triadic %d: %s", i, color))
-- end
--
-- wezterm.log_info("Complementary of YaruDarkPurple: ")
-- local yarudarkpurple_complementary = get_complementary_color_of("#7764d8")
-- for i, color in ipairs(yarudarkpurple_complementary) do
-- 	wezterm.log_info(string.format("Complementary %d: %s", i, color))
-- end
--
-- wezterm.log_info("Analogous colors for YaruDarkPurple:")
-- local yarudarkpurple_analogous = get_analogous_colors_of("#7764d8", 3, 30)
-- for i, color in ipairs(yarudarkpurple_analogous) do
-- 	wezterm.log_info(string.format("Analogous %d: %s", i, color))
-- end

return {
	get_shades_of = get_shades_of,
	get_tints_of = get_tints_of,
	get_triadic_colors_of = get_triadic_colors_of,
	get_complementary_color_of = get_complementary_color_of,
	get_analogous_colors_of = get_analogous_colors_of,
}
