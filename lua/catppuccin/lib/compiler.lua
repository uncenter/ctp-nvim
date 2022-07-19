local M = {}

-- Credit: https://github.com/EdenEast/nightfox.nvim
local fmt = string.format
local echo = require("catppuccin.utils.echo")
local is_windows = vim.startswith(vim.loop.os_uname().sysname, "Windows")

local function inspect(t)
	local list = {}
	for k, v in pairs(t) do
		local q = type(v) == "string" and [["]] or ""
		table.insert(list, fmt([[%s = %s%s%s]], k, q, v, q))
	end

	table.sort(list)
	return fmt([[{ %s }]], table.concat(list, ", "))
end

function M.compile()
	local theme = require("catppuccin.lib.mapper").apply()
	local lines = {
		[[
-- This file is autogenerated by CATPPUCCIN.
-- DO NOT make changes directly to this file.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
	vim.cmd("syntax reset")
end
vim.g.colors_name = "catppuccin"]],
	}
	local config = require("catppuccin.config").options
	if is_windows then
		config.compile.path = config.compile.path:gsub("/", "\\")
	end

	for property, value in pairs(theme.properties) do
		if type(value) == "string" then
			table.insert(lines, fmt('vim.o.%s = "%s"', property, value))
		elseif type(value) == "bool" then
			table.insert(lines, fmt("vim.o.%s = %s", property, value))
		elseif type(value) == "table" then
			table.insert(lines, fmt("vim.o.%s = %s", property, inspect(value)))
		end
	end
	local tbl = vim.tbl_deep_extend("keep", config.custom_highlights, theme.integrations, theme.syntax, theme.editor)

	for group, color in pairs(tbl) do
		if color.link then
			table.insert(lines, fmt([[vim.api.nvim_set_hl(0, "%s", { link = "%s" })]], group, color.link))
		else
			if color.style then
				for _, style in ipairs(color.style) do
					color[style] = true
				end
			end
			color.style = nil
			table.insert(lines, fmt([[vim.api.nvim_set_hl(0, "%s", %s)]], group, inspect(color)))
		end
	end

	if config.term_colors == true then
		for k, v in pairs(theme.terminal) do
			table.insert(lines, fmt('vim.g.%s = "%s"', k, v))
		end
	end
	os.execute(string.format("mkdir %s %s", is_windows and "" or "-p", config.compile.path))
	local file = io.open(
		config.compile.path
			.. (is_windows and "\\" or "/")
			.. vim.g.catppuccin_flavour
			.. config.compile.suffix
			.. ".lua",
		"w"
	)
	local ok, err = pcall(file.write, file, table.concat(lines, "\n"))
	if not ok then
		echo("failed to compile", "error")
		print(err)
	else
		echo("compiled successfully!")
	end
	file:close()
end

function M.clean()
	local config = require("catppuccin.config").options
	local compiled_path = config.compile.path
		.. (is_windows and "\\" or "/")
		.. vim.g.catppuccin_flavour
		.. config.compile.suffix
		.. ".lua"
	local ok, err = pcall(os.remove, compiled_path)
	if not ok then
		echo("failed to clean compiled cache", "error")
		print(err)
	else
		echo("successfully cleaned compiled cache!")
	end
end

return M
