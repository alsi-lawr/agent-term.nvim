local config = require("agent_term.setup.runtime_config")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_float", { clear = true })
local winhighlight = table.concat({
	"Normal:AgentTermFloat",
	"NormalFloat:AgentTermFloat",
	"FloatBorder:AgentTermFloatBorder",
	"FloatTitle:AgentTermFloatTitle",
	"EndOfBuffer:",
}, ",")

local function apply_default_highlights()
	vim.api.nvim_set_hl(0, "AgentTermFloat", { default = true, link = "Normal" })
	vim.api.nvim_set_hl(0, "AgentTermFloatBorder", { default = true, link = "Normal" })
	vim.api.nvim_set_hl(0, "AgentTermFloatTitle", { default = true, link = "Title" })
end

apply_default_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	callback = apply_default_highlights,
})

local function clamp(value, min_value, max_value)
	return math.max(min_value, math.min(value, max_value))
end

local function size_from(value, total)
	if value > 0 and value <= 1 then
		return math.floor(total * value)
	end
	return math.floor(value)
end

local function window_config(agent_name)
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
		title = { { (" Agent Term · %s "):format(agent_name), "AgentTermFloatTitle" } },
		title_pos = "center",
	}
end

local function apply_window_options(win)
	vim.api.nvim_set_option_value("winhighlight", winhighlight, { win = win })
end

local function reconcile_layout()
	state.each_session(function(agent_name, session)
		if session.float_win and vim.api.nvim_win_is_valid(session.float_win) then
			vim.api.nvim_win_set_config(session.float_win, window_config(agent_name))
			apply_window_options(session.float_win)
		end
	end)
end

function M.reconcile_layout()
	reconcile_layout()
end

vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
	callback = function()
		vim.schedule(reconcile_layout)
	end,
})

function M.open(buf, agent_name)
	local session = state.session(agent_name)
	if session and state.has_valid_float_win(agent_name) then
		vim.api.nvim_set_current_win(session.float_win)
		return session.float_win
	end

	local win = vim.api.nvim_open_win(buf, true, window_config(agent_name))
	apply_window_options(win)
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
	if not session or not state.has_valid_float_win(agent_name) then
		state.reset_float_win(agent_name)
		return
	end

	vim.api.nvim_win_close(session.float_win, true)
	state.reset_float_win(agent_name)
end

function M.focus(agent_name)
	local session = state.session(agent_name)
	if not session or not state.has_valid_float_win(agent_name) then
		return false
	end

	vim.api.nvim_set_current_win(session.float_win)
	return true
end

return M
