local templates = require("agent_term.hooks.templates")

local M = {}

---@param path string
---@return table<string, any>|nil data, string? err
function M.read_json(path)
	if vim.fn.filereadable(path) == 0 then
		return {}, nil
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil, tostring(lines)
	end
	local content = table.concat(lines, "\n")
	if content == "" then
		return {}, nil
	end
	local decoded_ok, decoded = pcall(vim.json.decode, content)
	if not decoded_ok or type(decoded) ~= "table" then
		return nil, ("could not parse `%s` as JSON"):format(path)
	end
	return decoded, nil
end

---@param path string
---@param data table<string, any>
---@return boolean ok, string? err
function M.write_json(path, data)
	local dir = vim.fn.fnamemodify(path, ":h")
	if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) == 0 then
		return false, ("could not create `%s`"):format(dir)
	end
	local ok, err = pcall(vim.fn.writefile, { vim.json.encode(data) }, path)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

---@param path string
---@return boolean ok, string? err
function M.write_context_script(path)
	local content, err = templates.read("agent_term_context.py")
	if not content then
		return false, err
	end
	local dir = vim.fn.fnamemodify(path, ":h")
	if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) == 0 then
		return false, ("could not create `%s`"):format(dir)
	end
	local ok, write_err = pcall(vim.fn.writefile, vim.split(content, "\n", { plain = true }), path)
	if not ok then
		return false, tostring(write_err)
	end
	local uv = vim.uv or vim.loop
	if uv and uv.fs_chmod then
		uv.fs_chmod(path, 493)
	end
	return true, nil
end

---@param event_entries table[]
---@param marker fun(hook: table<string, any>): boolean
---@param entry table<string, any>
function M.upsert_event_hook(event_entries, marker, entry)
	for _, group in ipairs(event_entries) do
		if type(group) == "table" and type(group.hooks) == "table" then
			for index, hook in ipairs(group.hooks) do
				if type(hook) == "table" and marker(hook) then
					group.hooks[index] = entry
					return
				end
			end
		end
	end
	event_entries[#event_entries + 1] = {
		hooks = { entry },
	}
end

return M
