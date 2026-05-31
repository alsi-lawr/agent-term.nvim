local commands = require("agent_term.commands.registry")
local captured_context = require("agent_term.context.captured")
local hooks = require("agent_term.hooks")
local keymaps = require("agent_term.setup.applied_keymaps")
local config = require("agent_term.setup.runtime_config")
local view_controller = require("agent_term.ui.controller")

local M = {}

---@param opts? agent_term.Config
---@return nil
function M.setup(opts)
	config.setup(opts)
	captured_context.setup_tracking()
	hooks.setup_autocmds()
	commands.setup()
	keymaps.setup()
end

---@return string|nil
function M.get_active_agent()
	return config.active_agent
end

---@param name string
---@param opts? { bang?: boolean }
---@return boolean
function M.set_active_agent(name, opts)
	return view_controller.switch_agent(name, opts)
end

return M
