local installer = require("agent_term.hooks.installers.installer")

local M = {}

local function project_path(...)
	return table.concat({ vim.fn.getcwd(), ... }, "/")
end

local function shell_context_path(path)
	if vim.fn.fnamemodify(path, ":p") == path then
		return ('"%s"'):format(path)
	end
	return ('"$(git rev-parse --show-toplevel)/%s"'):format(path)
end

---@param opts { context_file_path: string }
---@return boolean ok, { files: string[] }|string? result
function M.install(opts)
	local hooks_json = project_path(".codex", "hooks.json")
	local script_path = project_path(".codex", "hooks", "agent_term_context.py")

	local data, read_err = installer.read_json(hooks_json)
	if not data then
		return false, read_err
	end
	data.hooks = data.hooks or {}
	data.hooks.UserPromptSubmit = data.hooks.UserPromptSubmit or {}

	local command = table.concat({
		'python3 "$(git rev-parse --show-toplevel)/.codex/hooks/agent_term_context.py"',
		shell_context_path(opts.context_file_path),
	}, " ")
	local hook = {
		type = "command",
		command = command,
		timeout = 10,
		statusMessage = "Loading editor context",
	}

	installer.upsert_event_hook(data.hooks.UserPromptSubmit, function(candidate)
		return type(candidate.command) == "string"
			and candidate.command:find("agent_term_context.py", 1, true) ~= nil
	end, hook)

	local script_ok, script_err = installer.write_context_script(script_path)
	if not script_ok then
		return false, script_err
	end
	local json_ok, json_err = installer.write_json(hooks_json, data)
	if not json_ok then
		return false, json_err
	end

	return true, {
		files = {
			hooks_json,
			script_path,
		},
	}
end

return M
