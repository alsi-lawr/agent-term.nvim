local installer = require("agent_term.hooks.installers.installer")

local M = {}

local function shell_quoted(value)
	return ('"%s"'):format((value or ""):gsub('"', '\\"'))
end

local function read_preinvocation(data)
	if not data or type(data) ~= "table" then
		return nil
	end
	if type(data.hooks) ~= "table" then
		return nil
	end
	return data.hooks.PreInvocation
end

local function same_command(entry, candidate)
	return type(entry) == "table" and type(candidate) == "table" and vim.deep_equal(entry, candidate)
end

---@param handlers table|nil
---@param entry table
---@return boolean
local function has_preinvocation_handler(handlers, entry)
	if type(handlers) ~= "table" then
		return false
	end
	for _, hook in ipairs(handlers) do
		if type(hook) == "table" then
			if same_command(hook, entry) then
				return true
			end
			if type(hook.hooks) == "table" then
				for _, nested in ipairs(hook.hooks) do
					if same_command(nested, entry) then
						return true
					end
				end
			end
		end
	end
	return false
end

---@param handlers table|nil
---@param entry table
---@return boolean added
local function add_preinvocation_handler(handlers, entry)
	if type(handlers) == "table" then
		for _, existing in ipairs(handlers) do
			if same_command(existing, entry) then
				return false
			end
		end
	end
	handlers = handlers or {}
	handlers[#handlers + 1] = entry
	return true
end

---@param opts { context_file_path: string }
---@return boolean
function M.is_installed(opts)
	local hooks_json = vim.fn.expand("~/.gemini/config/hooks.json")
	local script_path = vim.fn.expand("~/.gemini/config/hooks/agent_term_context.py")

	if vim.fn.filereadable(script_path) == 0 then
		return false
	end

	local data = installer.read_json(hooks_json)
	if not data then
		return false
	end

	local handlers = read_preinvocation(data)
	local hook = {
		command = ("python3 %s %s"):format(
			shell_quoted(script_path),
			shell_quoted(opts.context_file_path)
		),
		timeout = 10,
	}
	return has_preinvocation_handler(handlers, hook)
end

---@param opts { context_file_path: string }
---@return boolean ok, { files: string[], changed: boolean }|string? result
function M.install(opts)
	local hooks_json = vim.fn.expand("~/.gemini/config/hooks.json")
	local script_path = vim.fn.expand("~/.gemini/config/hooks/agent_term_context.py")

	local data, read_err = installer.read_json(hooks_json)
	if not data then
		return false, read_err
	end

	data.hooks = data.hooks or {}
	if type(data.hooks.PreInvocation) ~= "table" then
		data.hooks.PreInvocation = {}
	end

	local hook = {
		command = ("python3 %s %s"):format(
			shell_quoted(script_path),
			shell_quoted(opts.context_file_path)
		),
		timeout = 10,
	}

	local changed = add_preinvocation_handler(data.hooks.PreInvocation, hook)

	local script_ok, script_changed, script_err =
		installer.write_context_script_if_changed(script_path, "agy_context.py")
	if not script_ok then
		return false, script_err
	end

	local json_ok, json_changed, json_err = installer.write_json_if_changed(hooks_json, data)
	if not json_ok then
		return false, json_err
	end

	return true,
		{
			files = {
				hooks_json,
				script_path,
			},
			changed = changed or script_changed or json_changed,
		}
end

return M
