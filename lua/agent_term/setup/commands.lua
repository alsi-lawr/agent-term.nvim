local config = require("agent_term.setup.runtime_config")
local enums = require("agent_term.enums")

local M = {}

local COMMAND_SPECS = {
	{ "AgentTermOpen", "open", "Open/focus Agent Term", {} },
	{ "AgentTermClose", "close", "Close all Agent Term views", {} },
	{ "AgentTermToggle", "toggle", "Toggle Agent Term", {} },
	{ "AgentTermFocus", "focus", "Focus Agent Term", {} },
	{ "AgentTermKill", "kill", "Kill Agent Term terminal session", {} },

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
	{ "AgentTermIgnore", "ignore", "Add /.agent-term/ to .gitignore", {} },

	{ "AgentTermResume", "resume", "Start resume session", {}, enums.resume_kind.DEFAULT },
	{ "AgentTermResumeAll", "resume_all", "Start resume --all session", {}, enums.resume_kind.ALL },
	{
		"AgentTermResumeLast",
		"resume_last",
		"Start resume --last session",
		{},
		enums.resume_kind.LAST,
	},
}

local function should_register(spec)
	local resume_kind = spec[5]
	return resume_kind == nil or config.has_resume(resume_kind)
end

function M.setup(api)
	for _, spec in ipairs(COMMAND_SPECS) do
		pcall(vim.api.nvim_del_user_command, spec[1])
	end

	for _, spec in ipairs(COMMAND_SPECS) do
		if should_register(spec) then
			local opts = vim.tbl_extend("force", spec[4], {
				desc = spec[3],
			})
			vim.api.nvim_create_user_command(spec[1], function(command_opts)
				api[spec[2]](command_opts)
			end, opts)
		end
	end
end

return M
