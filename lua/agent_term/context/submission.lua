local config = require("agent_term.setup.runtime_config")
local context_file = require("agent_term.context.file")
local terminal = require("agent_term.runtime.session")

local M = {}

---@param message string
---@param kind "buffer"|"selection"|"diagnostics"
---@return boolean ok, boolean used_hook, string? hook_failure
function M.submit(message, kind)
	if config.auto_hook_enabled() then
		local ok, err = context_file.write(kind, message)
		if not ok then
			return false, true, err
		end
	end

	return terminal.send(message), false, nil
end

return M
