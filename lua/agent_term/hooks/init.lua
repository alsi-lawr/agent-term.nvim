local config = require("agent_term.setup.runtime_config")
local notify = require("agent_term.notify")

local M = {}

local installers = {
	codex = require("agent_term.hooks.installers.codex"),
	claude = require("agent_term.hooks.installers.claude"),
}

local function command_name()
	local agent = config.options.agent
	local cmd = type(agent) == "table" and agent.cmd or nil
	if type(cmd) ~= "table" or type(cmd[1]) ~= "string" then
		return nil
	end
	return vim.fn.fnamemodify(cmd[1], ":t")
end

local function context_file_path()
	local context_opts = config.options.context
	if type(context_opts) == "table" and type(context_opts.file_path) == "string" then
		return context_opts.file_path
	end
	return ".agent-term/context.json"
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

	config.options.agent.context = config.options.agent.context or {}
	config.options.agent.context.mode = "hook"

	notify.info(
		("Installed native %s hooks. Wrote: %s"):format(agent_name, table.concat(result.files, ", "))
	)
	return true
end

return M
