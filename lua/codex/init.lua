local commands = require("codex.commands")
local config = require("codex.config")
local context = require("codex.context")
local enums = require("codex.enums")
local float = require("codex.float")
local keymaps = require("codex.keymaps")
local notify = require("codex.notify")
local panel = require("codex.panel")
local state = require("codex.state")
local terminal = require("codex.terminal")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

local function enter_insert_mode()
	pcall(vim.cmd, "startinsert")
end

local function open_view(view, opts)
	opts = opts or {}
	local buf = terminal.ensure_session(config.options.codex.cmd)
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

local function resolve_context_view()
	local target = config.options.context.target_view
	if target == CONTEXT_TARGET_DEFAULT then
		if state.has_valid_panel_win() then
			return enums.view.PANEL
		end
		return enums.view.FLOAT
	end
	return target
end

local function ensure_started_for_context()
	if state.has_running_job() then
		return true
	end
	return open_view(resolve_context_view(), { enter_insert = false })
end

local function send_context(builder)
	if not ensure_started_for_context() then
		return
	end

	local message, err = builder()
	if not message then
		notify.info(err)
		return
	end

	if not terminal.send(message) then
		notify.error("Codex session is not running.")
		return
	end

	notify.info("Context sent to Codex.")
end

local function attach_view_api(prefix, view_name, view_mod, is_open_fn)
	M[prefix .. "_open"] = function()
		open_view(view_name)
	end

	M[prefix .. "_close"] = function()
		view_mod.close()
	end

	M[prefix .. "_toggle"] = function()
		if is_open_fn() then
			view_mod.close()
			return
		end
		M[prefix .. "_open"]()
	end

	M[prefix .. "_focus"] = function()
		if view_mod.focus() then
			enter_insert_mode()
			return
		end
		M[prefix .. "_open"]()
	end
end

local function resume_with(kind)
	if not terminal.start_resume(kind) then
		return
	end
	if state.has_valid_panel_win() then
		M.panel_open()
	else
		M.float_open()
	end
end

---@return nil
function M.close()
	terminal.close_views()
end

---@return nil
function M.kill()
	terminal.kill()
end

---@return nil
function M.send_buffer_context()
	send_context(context.buffer_message)
end

---@param opts? vim.api.keyset.create_user_command.command_args
---@return nil
function M.send_selection_context(opts)
	send_context(function()
		return context.selection_message(opts)
	end)
end

---@return nil
function M.send_diagnostics_context()
	send_context(context.diagnostics_message)
end

---@return nil
function M.resume()
	resume_with(enums.resume_kind.RESUME)
end

---@return nil
function M.resume_all()
	resume_with(enums.resume_kind.RESUME_ALL)
end

---@return nil
function M.resume_last()
	resume_with(enums.resume_kind.RESUME_LAST)
end

attach_view_api(enums.view.FLOAT, enums.view.FLOAT, float, state.has_valid_float_win)
attach_view_api(enums.view.PANEL, enums.view.PANEL, panel, state.has_valid_panel_win)

---@param opts? codex.Config
---@return nil
function M.setup(opts)
	config.setup(opts)
	commands.setup(M)
	keymaps.setup(M)
end

return M
