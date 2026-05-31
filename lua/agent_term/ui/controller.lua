local config = require("agent_term.setup.runtime_config")
local captured_context = require("agent_term.context.captured")
local enums = require("agent_term.enums")
local float = require("agent_term.ui.float")
local notify = require("agent_term.notify")
local panel = require("agent_term.ui.panel")
local state = require("agent_term.runtime.state")
local terminal = require("agent_term.runtime.session")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

local function enter_insert_mode()
	pcall(vim.cmd, "startinsert")
end

---@param view "float"|"panel"
---@param opts? { enter_insert?: boolean, agent_name?: string }
---@return boolean
function M.open(view, opts)
	opts = opts or {}
	local agent_name = opts.agent_name or config.active_agent
	captured_context.capture_before_view_switch()
	local buf = terminal.ensure_session(nil, agent_name)
	if not buf then
		return false
	end

	if view == enums.view.PANEL then
		float.close(agent_name)
		panel.open(buf, agent_name)
	else
		panel.close(agent_name)
		float.open(buf, agent_name)
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
		panel.close(config.active_agent)
		return
	end
	float.close(config.active_agent)
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
	local focused = view == enums.view.PANEL and panel.focus(config.active_agent)
		or float.focus(config.active_agent)
	if focused then
		enter_insert_mode()
		return
	end
	M.open(view)
end

---@return "float"|"panel"
function M.resolve_context_view()
	local context = config.context()
	local target = context and context.target_view or CONTEXT_TARGET_DEFAULT
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

---@param name? string
---@param opts? { bang?: boolean }
---@return boolean
function M.switch_agent(name, opts)
	opts = opts or {}
	if type(name) ~= "string" or name == "" then
		notify.info(("Active agent: %s"):format(config.active_agent or "none"))
		return true
	end

	local previous = config.active_agent
	local view = state.current_view()
	if not config.set_active_agent(name) then
		return false
	end

	if opts.bang then
		terminal.kill(name)
	end

	if view then
		if previous and previous ~= name then
			terminal.close_views(previous)
		end
		terminal.close_all_views_except(name)
		return M.open(view, { agent_name = name })
	end

	if opts.bang then
		return terminal.ensure_session(nil, name) ~= nil
	end

	return true
end

return M
