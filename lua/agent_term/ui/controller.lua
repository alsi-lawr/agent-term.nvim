local config = require("agent_term.setup.runtime_config")
local captured_context = require("agent_term.context.captured")
local enums = require("agent_term.enums")
local float = require("agent_term.ui.float")
local panel = require("agent_term.ui.panel")
local state = require("agent_term.runtime.state")
local terminal = require("agent_term.runtime.session")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

local function enter_insert_mode()
	pcall(vim.cmd, "startinsert")
end

---@param view "float"|"panel"
---@param opts? { enter_insert?: boolean }
---@return boolean
function M.open(view, opts)
	opts = opts or {}
	captured_context.capture_before_view_switch()
	local buf = terminal.ensure_session()
	if not buf then
		return false
	end

	if view == enums.view.PANEL then
		float.close()
		panel.open(buf)
	else
		panel.close()
		float.open(buf)
	end

	if opts.enter_insert ~= false then
		enter_insert_mode()
	end

	return true
end

---@param view "float"|"panel"
---@return nil
function M.close(view)
	if view == enums.view.PANEL then
		panel.close()
		return
	end
	float.close()
end

---@param view "float"|"panel"
---@return nil
function M.toggle(view)
	local is_open = view == enums.view.PANEL and state.has_valid_panel_win()
		or state.has_valid_float_win()
	if is_open then
		M.close(view)
		return
	end
	M.open(view)
end

---@param view "float"|"panel"
---@return nil
function M.focus(view)
	captured_context.capture_before_view_switch()
	local focused = view == enums.view.PANEL and panel.focus() or float.focus()
	if focused then
		enter_insert_mode()
		return
	end
	M.open(view)
end

---@return "float"|"panel"
function M.resolve_context_view()
	local target = config.options.context.target_view
	if target == CONTEXT_TARGET_DEFAULT then
		if state.has_valid_panel_win() then
			return enums.view.PANEL
		end
		return enums.view.FLOAT
	end
	return target
end

---@return boolean
function M.ensure_started_for_context()
	if state.has_running_job() then
		return true
	end
	return M.open(M.resolve_context_view(), { enter_insert = false })
end

return M
