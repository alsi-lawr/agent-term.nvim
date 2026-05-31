local config = require("agent_term.setup.runtime_config")

local M = {
	sessions = {},
	last_captured_context = nil,
}

local function active_agent_name(name)
	return name or config.active_agent
end

function M.session(name)
	name = active_agent_name(name)
	if type(name) ~= "string" then
		return nil
	end
	M.sessions[name] = M.sessions[name]
		or {
			buf = nil,
			job_id = nil,
			float_win = nil,
			panel_win = nil,
		}
	return M.sessions[name]
end

function M.each_session(fn)
	for name, session in pairs(M.sessions) do
		fn(name, session)
	end
end

function M.has_valid_buf(name)
	local session = M.session(name)
	return session and session.buf and vim.api.nvim_buf_is_valid(session.buf)
end

function M.has_running_job(name)
	local session = M.session(name)
	if not (session and session.job_id and session.job_id > 0) then
		return false
	end
	return vim.fn.jobwait({ session.job_id }, 0)[1] == -1
end

function M.has_valid_float_win(name)
	local session = M.session(name)
	return session and session.float_win and vim.api.nvim_win_is_valid(session.float_win)
end

---@return boolean
function M.has_valid_panel_win(name)
	local session = M.session(name)
	return session ~= nil
		and session.panel_win ~= nil
		and vim.api.nvim_win_is_valid(session.panel_win)
end

function M.reset_terminal(name)
	local session = M.session(name)
	if not session then
		return
	end
	session.buf = nil
	session.job_id = nil
end

function M.reset_float_win(name)
	local session = M.session(name)
	if session then
		session.float_win = nil
	end
end

function M.reset_panel_win(name)
	local session = M.session(name)
	if session then
		session.panel_win = nil
	end
end

function M.current_view()
	local active = M.session()
	if active and active.float_win and vim.api.nvim_win_is_valid(active.float_win) then
		return "float"
	end
	if active and active.panel_win and vim.api.nvim_win_is_valid(active.panel_win) then
		return "panel"
	end
	return nil
end

return M
