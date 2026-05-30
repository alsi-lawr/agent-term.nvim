local M = {}

local function template_dir()
	local source = debug.getinfo(1, "S").source:sub(2)
	return vim.fn.fnamemodify(source, ":h") .. "/templates"
end

---@param name string
---@return string|nil content, string? err
function M.read(name)
	local path = template_dir() .. "/" .. name
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil, tostring(lines)
	end
	return table.concat(lines, "\n") .. "\n", nil
end

return M
