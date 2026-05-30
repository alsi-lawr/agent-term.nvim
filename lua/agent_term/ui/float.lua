local config = require("agent_term.config")
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

function M.open(buf)
	if state.has_valid_float_win() then
		vim.api.nvim_set_current_win(state.float_win)
		return state.float_win
	end

	local win = vim.api.nvim_open_win(buf, true, dimensions())
	state.float_win = win

	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		pattern = tostring(win),
		once = true,
		callback = function()
			if not state.has_valid_float_win() then
				state.reset_float_win()
			end
		end,
	})

	return win
end

function M.close()
	if not state.has_valid_float_win() then
		state.reset_float_win()
		return
	end

	vim.api.nvim_win_close(state.float_win, true)
	state.reset_float_win()
end

function M.focus()
	if not state.has_valid_float_win() then
		return false
	end

	vim.api.nvim_set_current_win(state.float_win)
	return true
end

return M
