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
---@field resume? false|agent_term.ResumeConfig

---@class agent_term.ResumeConfig
---@field default? string[]|false
---@field all? string[]|false
---@field last? string[]|false

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

---@param kind "default"|"all"|"last"
---@return string[]|false
function M.resume_command(kind)
	if type(M.options.agent.resume) ~= "table" then
		return false
	end
	return M.options.agent.resume[kind] or false
end

---@param kind "default"|"all"|"last"
---@return boolean
function M.has_resume(kind)
	return type(M.resume_command(kind)) == "table"
end

return M
