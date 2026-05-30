local setup_config = require("codex.setup.config")

local M = {}

---@class codex.Config
---@field codex? codex.CommandConfig
---@field float? codex.FloatConfig
---@field panel? codex.PanelConfig
---@field context? codex.ContextConfig
---@field keymaps? table<string, string|false|nil>|false

---@class codex.CommandConfig
---@field cmd? string[]
---@field resume? string[]
---@field resume_all? string[]
---@field resume_last? string[]

---@class codex.FloatConfig
---@field width? number
---@field height? number
---@field border? string|table

---@class codex.PanelConfig
---@field position? "left"|"right"|"bottom"
---@field width? number
---@field height? number

---@class codex.ContextConfig
---@field target_view? "default"|"float"|"panel"
---@field include_file_path? boolean
---@field include_filetype? boolean
---@field include_cursor? boolean
---@field include_selection_range? boolean
---@field include_diagnostics? boolean

M.options = vim.deepcopy(setup_config.defaults)

---@param user_opts? codex.Config
---@return codex.Config
function M.setup(user_opts)
	M.options = setup_config.build_options(user_opts)
	return M.options
end

return M
