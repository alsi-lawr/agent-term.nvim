local context_commands = require("agent_term.context.commands")
local enums = require("agent_term.enums")
local hooks = require("agent_term.hooks")
local ignore = require("agent_term.commands.ignore")
local terminal = require("agent_term.runtime.session")
local view_controller = require("agent_term.ui.controller")

local M = {}

local handlers = {
	open = function()
		view_controller.open(enums.view.FLOAT)
	end,
	close = terminal.close_views,
	toggle = function()
		view_controller.toggle(enums.view.FLOAT)
	end,
	focus = function()
		view_controller.focus(enums.view.FLOAT)
	end,
	kill = terminal.kill,
	float_open = function()
		view_controller.open(enums.view.FLOAT)
	end,
	float_close = function()
		view_controller.close(enums.view.FLOAT)
	end,
	float_toggle = function()
		view_controller.toggle(enums.view.FLOAT)
	end,
	float_focus = function()
		view_controller.focus(enums.view.FLOAT)
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
	panel_focus = function()
		view_controller.focus(enums.view.PANEL)
	end,
	send_buffer_context = context_commands.send_buffer_context,
	send_selection_context = context_commands.send_selection_context,
	send_diagnostics_context = context_commands.send_diagnostics_context,
	install_hooks = hooks.install,
	ignore = ignore.ensure_ignored,
}

---@param name string
---@return function
function M.get(name)
	return handlers[name]
end

return M
