local setup_config = require("agent_term.setup.config")

local M = {}

---@class agent_term.Config
---@field agent? agent_term.AgentConfig|agent_term.SupportedAgent
---@field backend? agent_term.AgentConfig|agent_term.SupportedAgent
---@field float? agent_term.FloatConfig
---@field panel? agent_term.PanelConfig
---@field context? agent_term.ContextConfig
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

---@param user_opts? agent_term.Config
---@return agent_term.Config
function M.setup(user_opts)
	M.options = setup_config.build_options(user_opts)
	return M.options
end

---@return string[]|nil
function M.auto_resume_command()
	local agent = M.options.agent
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
