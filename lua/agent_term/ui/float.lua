local config = require("agent_term.setup.runtime_config")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_float", { clear = true })

local function clamp(value, min_value, max_value)
	return math.max(min_value, math.min(value, max_value))
end

local function size_from(value, total)
	if value > 0 and value <= 1 then
		return math.floor(total * value)
	end
	return math.floor(value)
end

local function dimensions()
	local columns = vim.o.columns
	local lines = vim.o.lines
	local opts = config.options.float

	local width = clamp(size_from(opts.width, columns), 20, math.max(20, columns - 2))
	local height = clamp(size_from(opts.height, lines), 5, math.max(5, lines - 2))

	return {
		relative = "editor",
		style = "minimal",
		border = opts.border,
		width = width,
		height = height,
		row = math.max(0, math.floor((lines - height) / 2)),
		col = math.max(0, math.floor((columns - width) / 2)),
	}
end

function M.open(buf, agent_name)
	local session = state.session(agent_name)
	if state.has_valid_float_win(agent_name) then
		vim.api.nvim_set_current_win(session.float_win)
		return session.float_win
	end

	local win = vim.api.nvim_open_win(buf, true, dimensions())
	session.float_win = win

	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		pattern = tostring(win),
		once = true,
		callback = function()
			if not state.has_valid_float_win(agent_name) then
				state.reset_float_win(agent_name)
			end
		end,
	})

	return win
end

function M.close(agent_name)
	local session = state.session(agent_name)
	if not state.has_valid_float_win(agent_name) then
		state.reset_float_win(agent_name)
		return
	end

	vim.api.nvim_win_close(session.float_win, true)
	state.reset_float_win(agent_name)
end

function M.focus(agent_name)
	local session = state.session(agent_name)
	if not state.has_valid_float_win(agent_name) then
		return false
	end

	vim.api.nvim_set_current_win(session.float_win)
	return true
end

return M
