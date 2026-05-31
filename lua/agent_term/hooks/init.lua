local config = require("agent_term.setup.runtime_config")
local notify = require("agent_term.notify")
local autocmds = require("agent_term.hooks.autocmds")

local M = {}

local installers = {
	codex = require("agent_term.hooks.installers.codex"),
	claude = require("agent_term.hooks.installers.claude"),
	gemini = require("agent_term.hooks.installers.gemini"),
}

local function command_name()
	local agent = config.agent()
	local cmd = type(agent) == "table" and agent.cmd or nil
	if type(cmd) ~= "table" or type(cmd[1]) ~= "string" then
		return nil
	end
	return vim.fn.fnamemodify(cmd[1], ":t")
end

local function context_file_path()
	local context_opts = config.context()
	if type(context_opts) == "table" and type(context_opts.file_path) == "string" then
		return context_opts.file_path
	end
	return ".agent-term/context.json"
end

local function auto_hook_enabled()
	local context = config.context()
	local hook = type(context) == "table" and context.hook or nil
	return type(hook) == "table" and hook.enabled == true
end

function M.install()
	local agent_name = command_name()
	local installer = agent_name and installers[agent_name] or nil
	if not installer then
		notify.warn(
			("Native hook installation is not supported for `%s`. Using paste mode."):format(
				agent_name or "unknown"
			)
		)
		return false
	end

	local ok, result = installer.install({
		context_file_path = context_file_path(),
	})
	if not ok then
		notify.error(("Failed to install native %s hooks: %s"):format(agent_name, result))
		return false
	end

	local context = config.context()
	context.hook = context.hook or {}
	context.hook.enabled = true

	local msg
	if result and result.changed then
		msg = ("Installed native %s hooks. Files: %s"):format(
			agent_name,
			table.concat(result.files, ", ")
		)
	elseif result then
		msg = ("Native %s hooks already installed. Files unchanged: %s"):format(
			agent_name,
			table.concat(result.files, ", ")
		)
	end
	notify.info(msg)
	return true
end

function M.detect()
	local agent_name = command_name()
	local installer = agent_name and installers[agent_name] or nil

	if not auto_hook_enabled() then
		return false
	end

	if not installer or type(installer.is_installed) ~= "function" then
		return false
	end

	if not installer.is_installed({
		context_file_path = context_file_path(),
	}) then
		config.context().hook.enabled = false
		notify.warn(
			(
				"Automatic hook updates enabled for `%s` but native hooks were not found. "
				.. "Disabling automatic hook updates. Run :AgentTermInstallHooks to install."
			):format(agent_name)
		)
		return true
	end

	return false
end

function M.setup_autocmds()
	M.detect()
	autocmds.setup()
end

return M
