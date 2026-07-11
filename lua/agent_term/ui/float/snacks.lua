local config = require("agent_term.setup.runtime_config")
local state = require("agent_term.runtime.state")

local M = {}

---@class agent_term.SnacksFloatWindow
---@field buf? integer
---@field win? integer
---@field show fun(self: agent_term.SnacksFloatWindow): agent_term.SnacksFloatWindow?
---@field hide fun(self: agent_term.SnacksFloatWindow): agent_term.SnacksFloatWindow?
---@field focus fun(self: agent_term.SnacksFloatWindow)
---@field update fun(self: agent_term.SnacksFloatWindow)

---@type table<string, agent_term.SnacksFloatWindow>
local instances = {}
local snacks

local function is_callable(value)
	if type(value) == "function" then
		return true
	end
	local metatable = type(value) == "table" and getmetatable(value) or nil
	return metatable ~= nil and type(metatable.__call) == "function"
end

local function load_snacks()
	if snacks then
		return snacks
	end

	local ok, loaded = pcall(require, "snacks")
	if not ok or type(loaded) ~= "table" then
		return nil
	end
	local has_win, win = pcall(function()
		return loaded.win
	end)
	if not has_win or not is_callable(win) then
		return nil
	end

	snacks = loaded
	return snacks
end

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
	local opts = config.options.float
	return {
		width = clamp(size_from(opts.width, vim.o.columns), 20, math.max(20, vim.o.columns - 2)),
		height = clamp(size_from(opts.height, vim.o.lines), 5, math.max(5, vim.o.lines - 2)),
	}
end

---@param agent_name string
---@return table
local function window_config(agent_name)
	local opts = config.options.float
	return {
		buf = nil,
		position = "float",
		relative = "editor",
		enter = true,
		minimal = true,
		fixbuf = true,
		resize = true,
		backdrop = 60,
		border = opts.border,
		width = function()
			return dimensions().width
		end,
		height = function()
			return dimensions().height
		end,
		title = { { (" Agent Term · %s "):format(agent_name), "SnacksTitle" } },
		title_pos = "center",
		keys = {
			q = false,
		},
	}
end

---@param agent_name string
---@param instance agent_term.SnacksFloatWindow
local function reset_closed_window(agent_name, instance)
	local session = state.session(agent_name)
	if session and session.float_win == instance.win then
		state.reset_float_win(agent_name)
	end
end

function M.is_available()
	return load_snacks() ~= nil
end

function M.reconcile_layout()
	for agent_name, instance in pairs(instances) do
		if instance.win and vim.api.nvim_win_is_valid(instance.win) then
			instance:update()
			local session = state.session(agent_name)
			if session then
				session.float_win = instance.win
			end
		end
	end
end

---@param buf integer
---@param agent_name string
---@return integer
function M.open(buf, agent_name)
	local session = assert(state.session(agent_name))
	local instance = instances[agent_name]
	if instance and instance.buf == buf then
		if instance.win and vim.api.nvim_win_is_valid(instance.win) then
			instance:focus()
		else
			instance:show()
		end
		session.float_win = assert(instance.win)
		return session.float_win
	end

	if instance and instance.win and vim.api.nvim_win_is_valid(instance.win) then
		instance:hide()
	end

	local loaded = assert(load_snacks())
	local opts = window_config(agent_name)
	opts.buf = buf
	opts.on_close = function(closed)
		reset_closed_window(agent_name, closed)
	end
	instance = loaded.win(opts)
	instances[agent_name] = instance
	session.float_win = assert(instance.win)
	return session.float_win
end

---@param agent_name string
function M.close(agent_name)
	local instance = instances[agent_name]
	if instance and instance.win and vim.api.nvim_win_is_valid(instance.win) then
		instance:hide()
	end
	state.reset_float_win(agent_name)
end

---@param agent_name string
---@return boolean
function M.focus(agent_name)
	local instance = instances[agent_name]
	if not (instance and instance.win and vim.api.nvim_win_is_valid(instance.win)) then
		return false
	end
	instance:focus()
	return true
end

return M
