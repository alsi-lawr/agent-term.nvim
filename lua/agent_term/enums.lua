local M = {}

M.view = {
	FLOAT = "float",
	PANEL = "panel",
}

M.panel_position = {
	LEFT = "left",
	RIGHT = "right",
	BOTTOM = "bottom",
}

M.resume_kind = {
	DEFAULT = "default",
	ALL = "all",
	LAST = "last",
}

M.agent = {
	CODEX = "codex",
	GEMINI = "gemini",
	CLAUDE = "claude",
	AIDER = "aider",
	COPILOT = "copilot",
	OPENCODE = "opencode",
}

return M
