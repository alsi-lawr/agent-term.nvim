local captured_context = require("agent_term.context.captured")
local context = require("agent_term.context.builder")
local notify = require("agent_term.notify")
local state = require("agent_term.runtime.state")
local submission = require("agent_term.context.submission")
local view_controller = require("agent_term.ui.controller")

local M = {}

---@return boolean
local function is_panel_focused()
	local session = state.session()
	return state.has_valid_panel_win()
		and session ~= nil
		and vim.api.nvim_get_current_win() == session.panel_win
end

---@param sent boolean
---@param used_hook boolean
---@param hook_failure string|nil
---@return boolean
local function notify_send_failure(sent, used_hook, hook_failure)
	if sent then
		return false
	end
	if used_hook and hook_failure then
		notify.error(("Failed to write agent hook context: %s"):format(hook_failure))
		return true
	end
	notify.error("Agent session is not running.")
	return true
end

---@param kind "buffer"|"selection"|"diagnostics"
---@param builder fun(): string|nil, string|nil
local function send_context(kind, builder)
	local message, err = builder()
	if not message then
		notify.info(err)
		return
	end

	if not view_controller.ensure_started_for_context() then
		return
	end

	local sent, used_hook, hook_failure = submission.submit(message, kind)
	if notify_send_failure(sent, used_hook, hook_failure) then
		return
	end

	if used_hook then
		notify.info("Context written for native agent hook injection.")
		return
	end
	notify.info("Context sent to agent.")
end

function M.send_buffer_context()
	send_context("buffer", function()
		return captured_context.resolve_message("buffer", context.buffer_message, is_panel_focused())
	end)
end

---@param opts? table
function M.send_selection_context(opts)
	send_context("selection", function()
		return captured_context.resolve_message("selection", function()
			return context.selection_message(opts)
		end, is_panel_focused())
	end)
end

function M.send_diagnostics_context()
	send_context("diagnostics", function()
		return captured_context.resolve_message(
			"diagnostics",
			context.diagnostics_message,
			is_panel_focused()
		)
	end)
end

return M
