local config = require("agent_term.setup.runtime_config")
local enums = require("agent_term.enums")
local notify = require("agent_term.notify")

local M = {}
local resolved_name
local resolved_host

local function native_host()
	return require("agent_term.ui.float.native")
end

local function host()
	local requested = config.options.float.host
	if resolved_host and resolved_name == requested then
		return resolved_host
	end

	resolved_name = requested
	if requested == enums.float_host.SNACKS then
		local snacks_host = require("agent_term.ui.float.snacks")
		if snacks_host.is_available() then
			resolved_host = snacks_host
			return resolved_host
		end
		notify.warn(
			'agent-term.nvim `float.host = "snacks"` requires snacks.nvim; '
				.. "falling back to the native float host."
		)
	end

	resolved_host = native_host()
	return resolved_host
end

function M.reconcile_layout()
	host().reconcile_layout()
end

---@param buf integer
---@param agent_name string
---@return integer
function M.open(buf, agent_name)
	return host().open(buf, agent_name)
end

---@param agent_name string
function M.close(agent_name)
	host().close(agent_name)
end

---@param agent_name string
---@return boolean
function M.focus(agent_name)
	return host().focus(agent_name)
end

return M
