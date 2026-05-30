local schema = require("agent_term.setup.schema")
local enums = require("agent_term.enums")

local M = {}

M.specs = {
	{ "float_open", "n", "float_open", "Agent Term float open" },
	{ "float_close", "n", "float_close", "Agent Term float close" },
	{ "float_toggle", "n", "float_toggle", "Agent Term float toggle" },
	{ "panel_open", "n", "panel_open", "Agent Term panel open" },
	{ "panel_close", "n", "panel_close", "Agent Term panel close" },
	{ "panel_toggle", "n", "panel_toggle", "Agent Term panel toggle" },
	{ "close_all", "n", "close", "Agent Term close all views" },
	{ "kill", "n", "kill", "Agent Term kill session" },
	{ "send_buffer_context", "n", "send_buffer_context", "Agent Term send buffer context" },
	{
		"send_selection_context",
		{ "n", "x" },
		"send_selection_context",
		"Agent Term send selection context",
	},
	{
		"send_diagnostics_context",
		"n",
		"send_diagnostics_context",
		"Agent Term send diagnostics context",
	},
	{ "resume", "n", "resume", "Agent Term resume", enums.resume_kind.DEFAULT },
}

local known_names = {}
for _, spec in ipairs(M.specs) do
	known_names[spec[1]] = true
end

---@param name string
---@return boolean
function M.is_known(name)
	return known_names[name] == true
end

---@param maps table<string, any>
---@return string[]
function M.get_unknown_names(maps)
	return schema.get_unknown_names(maps, M.is_known)
end

return M
