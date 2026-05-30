local commands = require("agent_term.commands.registry")
local captured_context = require("agent_term.context.captured")
local hooks = require("agent_term.hooks")
local keymaps = require("agent_term.setup.applied_keymaps")
local config = require("agent_term.setup.runtime_config")

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

return M
