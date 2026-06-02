local config = require("agent_term.setup.runtime_config")
local notify = require("agent_term.notify")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_terminal", { clear = true })

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

local function clear_session_views(agent_name)
	local session = state.session(agent_name)
	if not session then
		return
	end
	close_win_if_valid(session.float_win)
	close_win_if_valid(session.panel_win)
	state.reset_float_win(agent_name)
	state.reset_panel_win(agent_name)
end

local function clear_exited_session(agent_name, job_id)
	local session = state.session(agent_name)
	if not session or session.job_id ~= job_id then
		return
	end

	local buf = session.buf
	state.reset_terminal(agent_name)
	clear_session_views(agent_name)
	delete_buf_if_valid(buf)
end

function M.send(text)
	if not state.has_running_job() then
		return false
	end
	local session = state.session()
	if not session then
		return false
	end
	vim.api.nvim_chan_send(session.job_id, text)
	return true
end

function M.ensure_session(cmd, agent_name)
	agent_name = agent_name or config.active_agent
	local session = state.session(agent_name)
	if not session then
		return nil
	end

	if state.has_valid_buf(agent_name) and state.has_running_job(agent_name) then
		return session.buf
	end

	if state.has_valid_buf(agent_name) and not state.has_running_job(agent_name) then
		delete_buf_if_valid(session.buf)
		state.reset_terminal(agent_name)
	end

	local agent = config.agent(agent_name)
	local run_cmd = cmd or config.auto_resume_command(agent_name) or agent.cmd
	if not can_run_cmd(run_cmd) then
		notify.error(("Agent command not found: %s"):format(command_name(run_cmd)))
		return nil
	end

	local buf = vim.api.nvim_create_buf(false, true)
	session.buf = buf

	local job_id
	vim.api.nvim_buf_call(buf, function()
		job_id = vim.fn.jobstart(run_cmd, {
			term = true,
			on_exit = function(exited_job_id)
				vim.schedule(function()
					clear_exited_session(agent_name, exited_job_id)
				end)
			end,
		})
	end)

	if not (job_id and job_id > 0) then
		notify.error(("Failed to start agent command: %s"):format(table.concat(run_cmd, " ")))
		delete_buf_if_valid(buf)
		state.reset_terminal(agent_name)
		return nil
	end

	session.job_id = job_id

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = augroup,
		buffer = buf,
		once = true,
		callback = function()
			state.reset_terminal(agent_name)
			clear_session_views(agent_name)
		end,
	})

	return buf
end

function M.close_views(agent_name)
	clear_session_views(agent_name or config.active_agent)
end

function M.close_all_views_except(agent_name)
	state.each_session(function(name, session)
		if name == agent_name then
			return
		end
		close_win_if_valid(session.float_win)
		close_win_if_valid(session.panel_win)
		state.reset_float_win(name)
		state.reset_panel_win(name)
	end)
end

function M.kill(agent_name)
	agent_name = agent_name or config.active_agent
	local session = state.session(agent_name)
	if not session then
		return
	end

	M.close_views(agent_name)

	if session.job_id and session.job_id > 0 then
		pcall(vim.fn.jobstop, session.job_id)
	end

	if state.has_valid_buf(agent_name) then
		delete_buf_if_valid(session.buf)
	end

	state.reset_terminal(agent_name)
end

return M
