local M = {
	buf = nil,
	job_id = nil,
	float_win = nil,
	panel_win = nil,
	last_captured_context = nil,
}

function M.has_valid_buf()
	return M.buf and vim.api.nvim_buf_is_valid(M.buf)
end

function M.has_running_job()
	if not (M.job_id and M.job_id > 0) then
		return false
	end
	return vim.fn.jobwait({ M.job_id }, 0)[1] == -1
end

function M.has_valid_float_win()
	return M.float_win and vim.api.nvim_win_is_valid(M.float_win)
end

---@return boolean
function M.has_valid_panel_win()
	return M.panel_win ~= nil and vim.api.nvim_win_is_valid(M.panel_win)
end

function M.reset_terminal()
	M.buf = nil
	M.job_id = nil
end

function M.reset_float_win()
	M.float_win = nil
end

function M.reset_panel_win()
	M.panel_win = nil
end

return M
