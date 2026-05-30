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
---@param data table<string, any>
---@return boolean ok, boolean changed, string? err
function M.write_json_if_changed(path, data)
	local existing, read_err = M.read_json(path)
	if not existing then
		return false, false, read_err
	end
	if vim.deep_equal(existing, data) then
		return true, false, nil
	end
	local ok, err = M.write_json(path, data)
	return ok, ok, err
end

---@param path string
---@param template_name? string
---@return boolean ok, string? err
function M.write_context_script(path, template_name)
	template_name = template_name or "agent_term_context.py"
	local content, err = templates.read(template_name)
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

---@param path string
---@return string|nil content, string? err
local function read_text(path)
	if vim.fn.filereadable(path) == 0 then
		return nil, nil
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil, tostring(lines)
	end
	return table.concat(lines, "\n") .. "\n", nil
end

---@param path string
---@param template_name? string
---@return boolean ok, boolean changed, string? err
function M.write_context_script_if_changed(path, template_name)
	template_name = template_name or "agent_term_context.py"
	local expected, template_err = templates.read(template_name)
	if not expected then
		return false, false, template_err
	end

	local current, read_err = read_text(path)
	if read_err then
		return false, false, read_err
	end
	if current == expected then
		return true, false, nil
	end

	local ok, err = M.write_context_script(path, template_name)
	return ok, ok, err
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

---@param event_entries table[]
---@param entry table<string, any>
---@return boolean exists
function M.has_event_hook(event_entries, entry)
	for _, group in ipairs(event_entries) do
		if type(group) == "table" and type(group.hooks) == "table" then
			for _, hook in ipairs(group.hooks) do
				if type(hook) == "table" and vim.deep_equal(hook, entry) then
					return true
				end
			end
		end
	end
	return false
end

---@param event_entries table[]
---@param entry table<string, any>
---@return boolean added
function M.ensure_event_hook_exact(event_entries, entry)
	if M.has_event_hook(event_entries, entry) then
		return false
	end
	event_entries[#event_entries + 1] = {
		hooks = { entry },
	}
	return true
end

return M
