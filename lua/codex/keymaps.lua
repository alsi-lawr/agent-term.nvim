local config = require("codex.config")

local M = {}
local applied_maps = {}

local map_specs = {
	{ "float_open", "n", "float_open", "Codex float open" },
	{ "float_close", "n", "float_close", "Codex float close" },
	{ "float_toggle", "n", "float_toggle", "Codex float toggle" },
	{ "panel_open", "n", "panel_open", "Codex panel open" },
	{ "panel_close", "n", "panel_close", "Codex panel close" },
	{ "panel_toggle", "n", "panel_toggle", "Codex panel toggle" },
	{ "close_all", "n", "close", "Codex close all views" },
	{ "kill", "n", "kill", "Codex kill session" },
	{ "send_buffer_context", "n", "send_buffer_context", "Codex send buffer context" },
	{ "send_selection_context", { "n", "x" }, "send_selection_context", "Codex send selection context" },
	{ "send_diagnostics_context", "n", "send_diagnostics_context", "Codex send diagnostics context" },
	{ "resume", "n", "resume", "Codex resume" },
}

function M.setup(api)
	local maps = config.options.keymaps or {}

	for _, applied in ipairs(applied_maps) do
		pcall(vim.keymap.del, applied.mode, applied.lhs)
	end
	applied_maps = {}

	for _, spec in ipairs(map_specs) do
		local key = maps[spec[1]]
		if key then
			vim.keymap.set(spec[2], key, api[spec[3]], { desc = spec[4] })
			applied_maps[#applied_maps + 1] = { mode = spec[2], lhs = key }
		end
	end
end

return M
