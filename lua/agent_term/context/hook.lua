local M = {}

local function has_user_hook_receiver(hook_event)
	local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
		event = "User",
		pattern = hook_event,
	})
	return ok and #autocmds > 0
end

---@param hook_event string
---@param context_text string
---@return boolean
function M.emit_user_hook(hook_event, context_text)
	if not has_user_hook_receiver(hook_event) then
		return false
	end

	local payload
	payload = {
		handled = false,
		ack = function()
			payload.handled = true
		end,
		hookSpecificOutput = {
			hookEventName = hook_event,
			additionalContext = context_text,
		},
	}

	local ok = pcall(vim.api.nvim_exec_autocmds, "User", {
		pattern = hook_event,
		modeline = false,
		data = payload,
	})
	return ok and payload.handled == true
end

return M
