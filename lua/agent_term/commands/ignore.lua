local notify = require("agent_term.notify")

local M = {}

local ENTRY = ".agent-term/"

local function read_lines(path)
	if vim.fn.filereadable(path) == 0 then
		return {}
	end
	return vim.fn.readfile(path)
end

local function has_entry(lines)
	for _, line in ipairs(lines) do
		local trimmed = vim.trim(line)
		if trimmed == ENTRY or trimmed == "/" .. ENTRY then
			return true
		end
	end
	return false
end

function M.ensure_ignored()
	local path = ".gitignore"
	local lines = read_lines(path)
	if has_entry(lines) then
		notify.info("`.agent-term/` is already ignored in .gitignore")
		return true
	end

	lines[#lines + 1] = "# Ignore agent-term.nvim context\n" .. ENTRY
	local ok = pcall(vim.fn.writefile, lines, path)
	if not ok then
		notify.error("Failed to update .gitignore")
		return false
	end

	notify.info("Added `.agent-term/` to .gitignore")
	return true
end

return M
