local installer = require("agent_term.hooks.installers.installer")

local M = {}

local function project_path(...)
	return table.concat({ vim.fn.getcwd(), ... }, "/")
end

local function claude_context_path(path)
	if vim.fn.fnamemodify(path, ":p") == path then
		return path
	end
	return ("${CLAUDE_PROJECT_DIR}/%s"):format(path)
end

---@param opts { context_file_path: string }
---@return boolean ok, { files: string[] }|string? result
function M.install(opts)
	local settings_json = project_path(".claude", "settings.json")
	local script_path = project_path(".claude", "hooks", "agent_term_context.py")

	local data, read_err = installer.read_json(settings_json)
	if not data then
		return false, read_err
	end
	data.hooks = data.hooks or {}
	data.hooks.UserPromptSubmit = data.hooks.UserPromptSubmit or {}

	local hook = {
		type = "command",
		command = "python3",
		args = {
			"${CLAUDE_PROJECT_DIR}/.claude/hooks/agent_term_context.py",
			claude_context_path(opts.context_file_path),
		},
		timeout = 10,
	}

	installer.upsert_event_hook(data.hooks.UserPromptSubmit, function(candidate)
		return type(candidate.args) == "table"
			and candidate.args[1] == "${CLAUDE_PROJECT_DIR}/.claude/hooks/agent_term_context.py"
	end, hook)

	local script_ok, script_err = installer.write_context_script(script_path)
	if not script_ok then
		return false, script_err
	end
	local json_ok, json_err = installer.write_json(settings_json, data)
	if not json_ok then
		return false, json_err
	end

	return true, {
		files = {
			settings_json,
			script_path,
		},
	}
end

return M
