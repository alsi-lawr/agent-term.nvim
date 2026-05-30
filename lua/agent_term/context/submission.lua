local config = require("agent_term.setup.runtime_config")
local context_file = require("agent_term.context.file")
local terminal = require("agent_term.runtime.session")

local M = {}
local BACKEND_CONTEXT_MODE_HOOK = "hook"

local function backend_context_mode()
	local agent = config.options.agent
	if type(agent) ~= "table" or type(agent.context) ~= "table" then
		return "paste"
	end
	return agent.context.mode or "paste"
end

---@param message string
---@param kind "buffer"|"selection"|"diagnostics"
---@param force_paste? boolean
---@return boolean ok, boolean used_hook, string? hook_failure
function M.submit(message, kind, force_paste)
	if force_paste or backend_context_mode() ~= BACKEND_CONTEXT_MODE_HOOK then
		return terminal.send(message), false, nil
	end

	local ok, err = context_file.write(kind, message)
	if not ok then
		return false, true, err
	end
	return true, true, nil
end

return M
