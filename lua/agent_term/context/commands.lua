local captured_context = require("agent_term.context.captured")
local context = require("agent_term.context.builder")
local notify = require("agent_term.notify")
local state = require("agent_term.runtime.state")
local submission = require("agent_term.context.submission")
local view_controller = require("agent_term.ui.controller")

local M = {}

local function is_panel_focused()
	return state.has_valid_panel_win() and vim.api.nvim_get_current_win() == state.panel_win
end

---@param kind "buffer"|"selection"|"diagnostics"
---@param builder fun(): string|nil, string|nil
---@param force_paste? boolean
local function send_context(kind, builder, force_paste)
	local message, err = builder()
	if not message then
		notify.info(err)
		return
	end

	if not view_controller.ensure_started_for_context() then
		return
	end

	local sent, used_hook, hook_failure = submission.submit(message, kind, force_paste)
	if not sent then
		if used_hook and hook_failure then
			notify.error(("Failed to write backend hook context: %s"):format(hook_failure))
			return
		end
		notify.error("Agent session is not running.")
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
	end, true)
end

---@param opts? vim.api.keyset.create_user_command.command_args
function M.send_selection_context(opts)
	send_context("selection", function()
		return captured_context.resolve_message("selection", function()
			return context.selection_message(opts)
		end, is_panel_focused())
	end, true)
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
