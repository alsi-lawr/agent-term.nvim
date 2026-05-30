local config = require("agent_term.setup.runtime_config")
local context_hook = require("agent_term.context.hook")
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

local function backend_hook_event()
	local agent = config.options.agent
	if type(agent) ~= "table" or type(agent.context) ~= "table" then
		return "UserPromptSubmit"
	end
	return agent.context.hook_event or "UserPromptSubmit"
end

---@param message string
---@return boolean ok, boolean used_hook, boolean hook_failed
function M.submit(message)
	if backend_context_mode() == BACKEND_CONTEXT_MODE_HOOK then
		if context_hook.emit_user_hook(backend_hook_event(), message) then
			return true, true, false
		end
		local sent = terminal.send(message)
		return sent, false, true
	end

	return terminal.send(message), false, false
end

return M
