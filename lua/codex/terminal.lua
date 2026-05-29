local config = require("codex.config")
local enums = require("codex.enums")
local notify = require("codex.notify")
local state = require("codex.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("codex_terminal", { clear = true })

local function command_name(cmd)
	if type(cmd) ~= "table" or #cmd == 0 then
		return ""
	end
	return cmd[1] or ""
end

local function can_run_cmd(cmd)
	local exe = command_name(cmd)
	if exe == "" then
		return false
	end
	return vim.fn.executable(exe) == 1
end

local function close_win_if_valid(win)
	if not (win and vim.api.nvim_win_is_valid(win)) then
		return
	end
	pcall(vim.api.nvim_win_close, win, true)
end

local function delete_buf_if_valid(buf)
	if buf and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
	end
end

local function clear_session_views()
	close_win_if_valid(state.float_win)
	close_win_if_valid(state.panel_win)
	state.reset_float_win()
	state.reset_panel_win()
end

local function clear_exited_session(job_id)
	if state.job_id ~= job_id then
		return
	end

	local buf = state.buf
	state.reset_terminal()
	clear_session_views()
	delete_buf_if_valid(buf)
end

function M.send(text)
	if not state.has_running_job() then
		return false
	end
	vim.api.nvim_chan_send(state.job_id, text)
	return true
end

function M.ensure_session(cmd)
	if state.has_valid_buf() and state.has_running_job() then
		return state.buf
	end

	if state.has_valid_buf() and not state.has_running_job() then
		delete_buf_if_valid(state.buf)
		state.reset_terminal()
	end

	local run_cmd = cmd or config.options.codex.cmd
	if not can_run_cmd(run_cmd) then
		notify.error(("Codex command not found: %s"):format(command_name(run_cmd)))
		return nil
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.buf = buf

	local job_id
	vim.api.nvim_buf_call(buf, function()
		job_id = vim.fn.jobstart(run_cmd, {
			term = true,
			on_exit = function(exited_job_id)
				vim.schedule(function()
					clear_exited_session(exited_job_id)
				end)
			end,
		})
	end)

	if not (job_id and job_id > 0) then
		notify.error(("Failed to start Codex command: %s"):format(table.concat(run_cmd, " ")))
		delete_buf_if_valid(buf)
		state.reset_terminal()
		return nil
	end

	state.job_id = job_id

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = augroup,
		buffer = buf,
		once = true,
		callback = function()
			state.reset_terminal()
			close_win_if_valid(state.float_win)
			close_win_if_valid(state.panel_win)
			state.reset_float_win()
			state.reset_panel_win()
		end,
	})

	return buf
end

function M.close_views()
	clear_session_views()
end

function M.kill()
	M.close_views()

	if state.job_id and state.job_id > 0 then
		pcall(vim.fn.jobstop, state.job_id)
	end

	if state.has_valid_buf() then
		delete_buf_if_valid(state.buf)
	end

	state.reset_terminal()
end

function M.start_resume(kind)
	if state.has_running_job() then
		notify.warn("Codex session is already running. Run :CodexKill first.")
		return nil
	end

	local commands = {
		[enums.resume_kind.RESUME] = config.options.codex.resume,
		[enums.resume_kind.RESUME_ALL] = config.options.codex.resume_all,
		[enums.resume_kind.RESUME_LAST] = config.options.codex.resume_last,
	}

	local cmd = commands[kind]
	if not cmd then
		notify.error(("Unknown resume command kind: %s"):format(tostring(kind)))
		return nil
	end

	return M.ensure_session(cmd)
end

return M
