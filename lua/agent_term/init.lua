local commands = require("agent_term.setup.commands")
local config = require("agent_term.setup.runtime_config")
local captured_context = require("agent_term.context.captured")
local context_commands = require("agent_term.context.commands")
local enums = require("agent_term.enums")
local hooks = require("agent_term.hooks")
local gitignore = require("agent_term.setup.gitignore")
local keymaps = require("agent_term.setup.applied_keymaps")
local resume = require("agent_term.runtime.resume")
local terminal = require("agent_term.runtime.session")
local view_controller = require("agent_term.ui.controller")

local M = {}

function M.float_open()
	view_controller.open(enums.view.FLOAT)
end

function M.float_close()
	view_controller.close(enums.view.FLOAT)
end

function M.float_toggle()
	view_controller.toggle(enums.view.FLOAT)
end

function M.float_focus()
	view_controller.focus(enums.view.FLOAT)
end

function M.panel_open()
	view_controller.open(enums.view.PANEL)
end

function M.panel_close()
	view_controller.close(enums.view.PANEL)
end

function M.panel_toggle()
	view_controller.toggle(enums.view.PANEL)
end

function M.panel_focus()
	view_controller.focus(enums.view.PANEL)
end

function M.close()
	terminal.close_views()
end

function M.kill()
	terminal.kill()
end

M.send_buffer_context = context_commands.send_buffer_context
M.send_selection_context = context_commands.send_selection_context
M.send_diagnostics_context = context_commands.send_diagnostics_context
M.install_hooks = hooks.install
M.ignore = gitignore.ensure_agent_term_ignored
M.resume = resume.resume_default
M.resume_all = resume.resume_all
M.resume_last = resume.resume_last
M.open = M.float_open
M.toggle = M.float_toggle
M.focus = M.float_focus

---@param kind "default"|"all"|"last"
---@return boolean
function M.has_resume(kind)
	return config.has_resume(kind)
end

---@param opts? agent_term.Config
---@return nil
function M.setup(opts)
	config.setup(opts)
	captured_context.setup_tracking()
	hooks.setup_autocmds()
	commands.setup(M)
	keymaps.setup(M)
end

return M
