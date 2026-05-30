local M = {}

---@param input table<string, any>
---@param is_known fun(name: string): boolean
---@return string[]
function M.get_unknown_names(input, is_known)
	local unknown = {}
	if type(input) ~= "table" then
		return unknown
	end

	for name, _ in pairs(input) do
		if not is_known(name) then
			unknown[#unknown + 1] = name
		end
	end

	table.sort(unknown)
	return unknown
end

---@param input table<string, any>
---@param names string[]
function M.strip_unknown_names(input, names)
	for _, name in ipairs(names) do
		input[name] = nil
	end
end

return M
