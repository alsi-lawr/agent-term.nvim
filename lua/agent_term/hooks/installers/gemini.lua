local installer = require("agent_term.hooks.installers.installer")

local M = {}

local function gemini_context_path(path)
	if vim.fn.fnamemodify(path, ":p") == path then
		return ('"%s"'):format(path)
	end
	return ('"$PWD/%s"'):format(path)
end

function M.is_installed(opts)
	local settings_json = vim.fn.expand("~/.gemini/settings.json")
	local script_path = vim.fn.expand("~/.gemini/hooks/agent_term_context.py")

	if vim.fn.filereadable(script_path) == 0 then
		return false
	end

	local data = installer.read_json(settings_json)
	if not data or not data.hooks or not data.hooks.BeforeModel then
		return false
	end

	local hook = {
		name = "agent-term-context",
		type = "command",
		command = ("python3 %s %s"):format(script_path, gemini_context_path(opts.context_file_path)),
		description = "Inject editor context into LLM request",
	}

	return installer.has_event_hook(data.hooks.BeforeModel, hook)
end

function M.install(opts)
	local settings_json = vim.fn.expand("~/.gemini/settings.json")
	local script_path = vim.fn.expand("~/.gemini/hooks/agent_term_context.py")

	local data, read_err = installer.read_json(settings_json)
	if not data then
		return false, read_err
	end
	data.hooks = data.hooks or {}
	data.hooks.BeforeModel = data.hooks.BeforeModel or {}

	local hook = {
		name = "agent-term-context",
		type = "command",
		command = ("python3 %s %s"):format(script_path, gemini_context_path(opts.context_file_path)),
		description = "Inject editor context into LLM request",
	}

	local changed = installer.ensure_event_hook_exact(data.hooks.BeforeModel, hook)

	local script_ok, script_changed, script_err =
		installer.write_context_script_if_changed(script_path, "gemini_context.py")
	if not script_ok then
		return false, script_err
	end
	local json_ok, json_changed, json_err = installer.write_json_if_changed(settings_json, data)
	if not json_ok then
		return false, json_err
	end

	return true,
		{
			files = {
				settings_json,
				script_path,
			},
			changed = changed or script_changed or json_changed,
		}
end

return M
