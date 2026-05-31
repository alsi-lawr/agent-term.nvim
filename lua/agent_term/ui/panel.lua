local config = require("agent_term.setup.runtime_config")
local enums = require("agent_term.enums")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_panel", { clear = true })

local function size_from(value, total)
	if value > 0 and value <= 1 then
		return math.max(1, math.floor(total * value))
	end
	return math.max(1, math.floor(value))
end

local function apply_window_options(win)
	vim.api.nvim_set_option_value("number", false, { win = win })
	vim.api.nvim_set_option_value("relativenumber", false, { win = win })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = win })

	if config.options.panel.position == enums.panel_position.BOTTOM then
		vim.api.nvim_set_option_value("winfixheight", true, { win = win })
	else
		vim.api.nvim_set_option_value("winfixwidth", true, { win = win })
	end
end

function M.open(buf, agent_name)
	local session = state.session(agent_name)
	if state.has_valid_panel_win(agent_name) then
		vim.api.nvim_set_current_win(session.panel_win)
		return session.panel_win
	end

	local pos = config.options.panel.position
	if pos == enums.panel_position.LEFT then
		vim.cmd("topleft vsplit")
	elseif pos == enums.panel_position.RIGHT then
		vim.cmd("botright vsplit")
	else
		vim.cmd("botright split")
	end

	local win = vim.api.nvim_get_current_win()
	if pos == enums.panel_position.BOTTOM then
		vim.api.nvim_win_set_height(win, size_from(config.options.panel.height, vim.o.lines))
	else
		vim.api.nvim_win_set_width(win, size_from(config.options.panel.width, vim.o.columns))
	end

	vim.api.nvim_win_set_buf(win, buf)
	apply_window_options(win)
	session.panel_win = win

	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		pattern = tostring(win),
		once = true,
		callback = function()
			if not state.has_valid_panel_win(agent_name) then
				state.reset_panel_win(agent_name)
			end
		end,
	})

	return win
end

function M.close(agent_name)
	local session = state.session(agent_name)
	if not state.has_valid_panel_win(agent_name) then
		state.reset_panel_win(agent_name)
		return
	end

	vim.api.nvim_win_close(session.panel_win, true)
	state.reset_panel_win(agent_name)
end

function M.focus(agent_name)
	local session = state.session(agent_name)
	if not state.has_valid_panel_win(agent_name) then
		return false
	end

	vim.api.nvim_set_current_win(session.panel_win)
	return true
end

return M
