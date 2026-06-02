local context = require("agent_term.context.builder")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_context_capture", { clear = true })

local NO_CAPTURED_CONTEXT_ERROR =
	"No captured editor context available yet. Focus a file buffer and retry."

local function is_editor_buffer(bufnr)
	local session = state.session()
	return (not session or bufnr ~= session.buf) and vim.bo[bufnr].buftype == ""
end

local function build_snapshot()
	local current_buf = vim.api.nvim_get_current_buf()
	if not is_editor_buffer(current_buf) then
		return nil
	end

	return {
		buffer = context.buffer_message(),
		selection = context.selection_message({}),
		diagnostics = context.diagnostics_message(),
	}
end

function M.capture_current_editor_context()
	local snapshot = build_snapshot()
	if snapshot then
		state.last_captured_context = snapshot
	end
end

function M.capture_before_view_switch()
	M.capture_current_editor_context()
end

function M.setup_tracking()
	vim.api.nvim_clear_autocmds({ group = augroup })
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		group = augroup,
		callback = M.capture_current_editor_context,
	})
	M.capture_current_editor_context()
end

---@param kind "buffer"|"selection"|"diagnostics"
---@param builder fun(): string|nil, string|nil
---@param is_panel_mode boolean
---@return string|nil, string|nil
function M.resolve_message(kind, builder, is_panel_mode)
	if not is_panel_mode then
		return builder()
	end

	if type(state.last_captured_context) ~= "table" then
		return nil, NO_CAPTURED_CONTEXT_ERROR
	end

	local message = state.last_captured_context[kind]
	if not message then
		return nil, NO_CAPTURED_CONTEXT_ERROR
	end

	return message, nil
end

return M
