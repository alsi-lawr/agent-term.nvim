local notify = require("agent_term.notify")
local setup_config = require("agent_term.setup.config")

local M = {}

---@class agent_term.Config
---@field agents? table<string, agent_term.AgentConfig|agent_term.SupportedAgent>
---@field active_agent? string
---@field float? agent_term.FloatConfig
---@field panel? agent_term.PanelConfig
---@field keymaps? table<string, string|false|nil>|false

---@alias agent_term.SupportedAgent
---| "codex"
---| "gemini"
---| "claude"
---| "aider"
---| "copilot"
---| "opencode"

---@class agent_term.AgentConfig
---@field preset? agent_term.SupportedAgent
---@field cmd? string[]
---@field auto_resume? false|"picker"|"last"
---@field context? agent_term.ContextConfig

---@class agent_term.FloatConfig
---@field width? number
---@field height? number
---@field border? string|table

---@class agent_term.PanelConfig
---@field position? "left"|"right"|"bottom"
---@field width? number
---@field height? number

---@class agent_term.ContextConfig
---@field file_path? string
---@field target_view? "default"|"float"|"panel"
---@field hook? agent_term.ContextHookConfig
---@field include_file_path? boolean
---@field include_filetype? boolean
---@field include_cursor? boolean
---@field include_selection_range? boolean
---@field include_diagnostics? boolean

---@class agent_term.ContextHookConfig
---@field enabled? boolean

M.options = setup_config.build_options()
M.active_agent = nil

local function state_dir()
	return vim.fn.stdpath("state") .. "/agent-term"
end

local function state_file()
	return state_dir() .. "/active-agent"
end

local function read_persisted_agent()
	local path = state_file()
	if vim.fn.filereadable(path) ~= 1 then
		return nil
	end
	local lines = vim.fn.readfile(path)
	local name = lines[1]
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return name
end

local function persist_agent(name)
	vim.fn.mkdir(state_dir(), "p")
	vim.fn.writefile({ name }, state_file())
end

---@return string[]
function M.agent_names()
	return setup_config.agent_names(M.options.agents)
end

---@return string|nil
local function first_agent_name()
	return M.agent_names()[1]
end

---@param name string|nil
---@return boolean
function M.has_agent(name)
	return type(name) == "string" and type(M.options.agents[name]) == "table"
end

---@param name? string
---@return agent_term.AgentConfig|nil
function M.agent(name)
	return M.options.agents[name or M.active_agent]
end

---@param name? string
---@return agent_term.ContextConfig|nil
function M.context(name)
	local agent = M.agent(name)
	return type(agent) == "table" and agent.context or nil
end

---@param cmd string[]|nil
---@return string
local function command_name(cmd)
	if type(cmd) ~= "table" or #cmd == 0 then
		return ""
	end
	return cmd[1] or ""
end

---@param name string
---@return boolean, string|nil
function M.can_run_agent(name)
	local agent = M.agent(name)
	local cmd = type(agent) == "table" and agent.cmd or nil
	local exe = command_name(cmd)
	if exe == "" then
		return false, ""
	end
	if vim.fn.executable(exe) ~= 1 then
		return false, exe
	end
	return true, exe
end

---@param name string
---@return boolean
function M.set_active_agent(name)
	if not M.has_agent(name) then
		notify.error(("Unknown agent: %s"):format(name))
		return false
	end
	local ok, exe = M.can_run_agent(name)
	if not ok then
		notify.error(("Agent command not found: %s"):format(exe or name))
		return false
	end
	M.active_agent = name
	persist_agent(name)
	return true
end

local function resolve_initial_active_agent()
	local fallback = first_agent_name()
	local persisted = read_persisted_agent()
	if persisted ~= nil then
		if M.has_agent(persisted) then
			return persisted
		end
		notify.warn(
			("Persisted active agent `%s` is no longer configured. Falling back to `%s`."):format(
				persisted,
				fallback or "none"
			)
		)
		return fallback
	end
	if M.has_agent(M.options.active_agent) then
		return M.options.active_agent
	end
	return fallback
end

---@param user_opts? agent_term.Config
---@return agent_term.Config
function M.setup(user_opts)
	M.options = setup_config.build_options(user_opts)
	M.active_agent = resolve_initial_active_agent()
	return M.options
end

---@param name? string
---@return string[]|nil
function M.auto_resume_command(name)
	local agent = M.agent(name)
	if type(agent) ~= "table" or agent.auto_resume == nil or agent.auto_resume == false then
		return nil
	end
	local preset = agent.preset
	if type(preset) ~= "string" then
		return nil
	end
	local args = setup_config.auto_resume_args_for_preset(preset, agent.auto_resume)
	if type(args) ~= "table" or type(agent.cmd) ~= "table" then
		return nil
	end
	local command = vim.deepcopy(agent.cmd)
	vim.list_extend(command, args)
	return command
end

return M
