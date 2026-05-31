local config = require("agent_term.setup.runtime_config")
local context_file = require("agent_term.context.file")
local terminal = require("agent_term.runtime.session")

local M = {}

local function auto_hook_enabled()
	local context = config.context()
	local hook = type(context) == "table" and context.hook or nil
	return type(hook) == "table" and hook.enabled == true
end

---@param message string
---@param kind "buffer"|"selection"|"diagnostics"
---@return boolean ok, boolean used_hook, string? hook_failure
function M.submit(message, kind)
	if auto_hook_enabled() then
		local ok, err = context_file.write(kind, message)
		if not ok then
			return false, true, err
		end
	end

	return terminal.send(message), false, nil
end

return M
