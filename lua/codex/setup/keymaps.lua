local schema = require("codex.setup.schema")

local M = {}

M.specs = {
	{ "float_open", "n", "float_open", "Codex float open" },
	{ "float_close", "n", "float_close", "Codex float close" },
	{ "float_toggle", "n", "float_toggle", "Codex float toggle" },
	{ "panel_open", "n", "panel_open", "Codex panel open" },
	{ "panel_close", "n", "panel_close", "Codex panel close" },
	{ "panel_toggle", "n", "panel_toggle", "Codex panel toggle" },
	{ "close_all", "n", "close", "Codex close all views" },
	{ "kill", "n", "kill", "Codex kill session" },
	{ "send_buffer_context", "n", "send_buffer_context", "Codex send buffer context" },
	{
		"send_selection_context",
		{ "n", "x" },
		"send_selection_context",
		"Codex send selection context",
	},
	{ "send_diagnostics_context", "n", "send_diagnostics_context", "Codex send diagnostics context" },
	{ "resume", "n", "resume", "Codex resume" },
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
