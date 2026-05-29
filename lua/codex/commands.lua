local M = {}

local COMMAND_SPECS = {
	{ "CodexFloatOpen", "float_open", "Open/focus Codex float", {} },
	{ "CodexFloatClose", "float_close", "Close Codex float", {} },
	{ "CodexFloatToggle", "float_toggle", "Toggle Codex float", {} },
	{ "CodexFloatFocus", "float_focus", "Focus Codex float", {} },

	{ "CodexPanelOpen", "panel_open", "Open/focus Codex panel", {} },
	{ "CodexPanelClose", "panel_close", "Close Codex panel", {} },
	{ "CodexPanelToggle", "panel_toggle", "Toggle Codex panel", {} },
	{ "CodexPanelFocus", "panel_focus", "Focus Codex panel", {} },

	{ "CodexClose", "close", "Close all Codex views", {} },
	{ "CodexKill", "kill", "Kill Codex terminal session", {} },

	{ "CodexSendBufferContext", "send_buffer_context", "Send buffer context to Codex", {} },
	{ "CodexSendSelectionContext", "send_selection_context", "Send selection context to Codex", { range = true } },
	{ "CodexSendDiagnosticsContext", "send_diagnostics_context", "Send diagnostics context to Codex", {} },

	{ "CodexResume", "resume", "Start codex resume session", {} },
	{ "CodexResumeAll", "resume_all", "Start codex resume --all session", {} },
	{ "CodexResumeLast", "resume_last", "Start codex resume --last session", {} },
}

function M.setup(api)
	for _, spec in ipairs(COMMAND_SPECS) do
		pcall(vim.api.nvim_del_user_command, spec[1])
		local opts = vim.tbl_extend("force", spec[4], {
			desc = spec[3],
		})
		vim.api.nvim_create_user_command(spec[1], function(command_opts)
			api[spec[2]](command_opts)
		end, opts)
	end
end

return M
