local M = {}
local applied_maps = {}
local context_commands = require("agent_term.context.commands")
local enums = require("agent_term.enums")
local resume = require("agent_term.runtime.resume")
local setup_keymaps = require("agent_term.setup.keymaps")
local terminal = require("agent_term.runtime.session")
local view_controller = require("agent_term.ui.controller")

local handlers = {
	float_open = function()
		view_controller.open(enums.view.FLOAT)
	end,
	float_close = function()
		view_controller.close(enums.view.FLOAT)
	end,
	float_toggle = function()
		view_controller.toggle(enums.view.FLOAT)
	end,
	panel_open = function()
		view_controller.open(enums.view.PANEL)
	end,
	panel_close = function()
		view_controller.close(enums.view.PANEL)
	end,
	panel_toggle = function()
		view_controller.toggle(enums.view.PANEL)
	end,
	close = terminal.close_views,
	kill = terminal.kill,
	send_buffer_context = context_commands.send_buffer_context,
	send_selection_context = context_commands.send_selection_context,
	send_diagnostics_context = context_commands.send_diagnostics_context,
	resume = resume.resume_default,
}

---@param name string
---@return boolean
function M.is_known(name)
	return setup_keymaps.is_known(name)
end

---@param maps table<string, any>
---@return string[]
function M.get_unknown_names(maps)
	return setup_keymaps.get_unknown_names(maps)
end

function M.setup()
	local config = require("agent_term.setup.runtime_config")
	local maps = config.options.keymaps or {}

	for _, applied in ipairs(applied_maps) do
		pcall(vim.keymap.del, applied.mode, applied.lhs)
	end
	applied_maps = {}

	for _, spec in ipairs(setup_keymaps.specs) do
		local key = maps[spec[1]]
		local resume_kind = spec[5]
		if key and (resume_kind == nil or config.has_resume(resume_kind)) then
			vim.keymap.set(spec[2], key, handlers[spec[3]], { desc = spec[4] })
			applied_maps[#applied_maps + 1] = { mode = spec[2], lhs = key }
		end
	end
end

return M
