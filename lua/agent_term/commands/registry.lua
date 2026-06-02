local config = require("agent_term.setup.runtime_config")
local dispatch = require("agent_term.runtime.dispatch")

local M = {}

local function complete_agents()
	return config.agent_names()
end

local COMMAND_SPECS = {
	{ "AgentTermOpen", "open", "Open/focus Agent Term", {} },
	{ "AgentTermClose", "close", "Close all Agent Term views", {} },
	{ "AgentTermToggle", "toggle", "Toggle Agent Term", {} },
	{ "AgentTermFocus", "focus", "Focus Agent Term", {} },
	{ "AgentTermKill", "kill", "Kill Agent Term terminal session", {} },
	{
		"AgentTermSwitch",
		"switch_agent",
		"Switch active Agent Term agent",
		{ nargs = "?", bang = true, complete = complete_agents },
	},

	{ "AgentTermFloatOpen", "float_open", "Open/focus Agent Term float", {} },
	{ "AgentTermFloatClose", "float_close", "Close Agent Term float", {} },
	{ "AgentTermFloatToggle", "float_toggle", "Toggle Agent Term float", {} },
	{ "AgentTermFloatFocus", "float_focus", "Focus Agent Term float", {} },

	{ "AgentTermPanelOpen", "panel_open", "Open/focus Agent Term panel", {} },
	{ "AgentTermPanelClose", "panel_close", "Close Agent Term panel", {} },
	{ "AgentTermPanelToggle", "panel_toggle", "Toggle Agent Term panel", {} },
	{ "AgentTermPanelFocus", "panel_focus", "Focus Agent Term panel", {} },

	{ "AgentTermSendBufferContext", "send_buffer_context", "Send buffer context to Agent Term", {} },
	{
		"AgentTermSendSelectionContext",
		"send_selection_context",
		"Send selection context to Agent Term",
		{ range = true },
	},
	{
		"AgentTermSendDiagnosticsContext",
		"send_diagnostics_context",
		"Send diagnostics context to Agent Term",
		{},
	},
	{ "AgentTermInstallHooks", "install_hooks", "Install native agent hooks", {} },
	{ "AgentTermIgnore", "ignore", "Add .agent-term/ to .gitignore", {} },
}

function M.setup()
	for _, spec in ipairs(COMMAND_SPECS) do
		pcall(vim.api.nvim_del_user_command, spec[1])
	end

	for _, spec in ipairs(COMMAND_SPECS) do
		local opts = vim.tbl_extend("force", spec[4], {
			desc = spec[3],
		})
		vim.api.nvim_create_user_command(spec[1], dispatch.get(spec[2]), opts)
	end
end

return M
