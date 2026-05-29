local M = {}
local enums = require("codex.enums")
local CONTEXT_TARGET_DEFAULT = "default"

local KEYMAP_NAMES = {
	"float_open",
	"float_close",
	"float_toggle",
	"panel_open",
	"panel_close",
	"panel_toggle",
	"close_all",
	"kill",
	"send_buffer_context",
	"send_selection_context",
	"send_diagnostics_context",
	"resume",
}

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

local defaults = {
	codex = {
		cmd = { "codex" },
		resume = { "codex", "resume" },
		resume_all = { "codex", "resume", "--all" },
		resume_last = { "codex", "resume", "--last" },
	},
	float = {
		width = 0.85,
		height = 0.8,
		border = "rounded",
	},
	panel = {
		position = enums.panel_position.RIGHT,
		width = 0.35,
		height = 0.35,
	},
	context = {
		target_view = CONTEXT_TARGET_DEFAULT,
		include_file_path = true,
		include_filetype = true,
		include_cursor = true,
		include_selection_range = true,
		include_diagnostics = true,
	},
	keymaps = false,
}

M.options = vim.deepcopy(defaults)

local function normalize_ratio_or_size(value, fallback)
	if type(value) ~= "number" or value <= 0 then
		return fallback
	end
	return value
end

local function normalize_key(value)
	if value == false or value == nil then
		return nil
	end
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function normalize_cmd(value, fallback)
	if type(value) ~= "table" then
		return fallback
	end

	local out = {}
	for _, v in ipairs(value) do
		if type(v) == "string" and v ~= "" then
			out[#out + 1] = v
		end
	end

	if #out == 0 then
		return fallback
	end
	return out
end

local function normalize_border(value)
	local valid = {
		none = true,
		single = true,
		double = true,
		rounded = true,
		solid = true,
		shadow = true,
	}

	if type(value) == "table" then
		return value
	end

	if type(value) == "string" and valid[value] then
		return value
	end

	return defaults.float.border
end

---@param user_opts? codex.Config
---@return codex.Config
function M.setup(user_opts)
	local merged = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})

	merged.codex = merged.codex or {}
	merged.codex.cmd = normalize_cmd(merged.codex.cmd, defaults.codex.cmd)
	merged.codex.resume = normalize_cmd(merged.codex.resume, defaults.codex.resume)
	merged.codex.resume_all = normalize_cmd(merged.codex.resume_all, defaults.codex.resume_all)
	merged.codex.resume_last = normalize_cmd(merged.codex.resume_last, defaults.codex.resume_last)

	merged.float = merged.float or {}
	merged.float.width = normalize_ratio_or_size(merged.float.width, defaults.float.width)
	merged.float.height = normalize_ratio_or_size(merged.float.height, defaults.float.height)
	merged.float.border = normalize_border(merged.float.border)

	merged.panel = merged.panel or {}
	merged.panel.width = normalize_ratio_or_size(merged.panel.width, defaults.panel.width)
	merged.panel.height = normalize_ratio_or_size(merged.panel.height, defaults.panel.height)
	if
		merged.panel.position ~= enums.panel_position.LEFT
		and merged.panel.position ~= enums.panel_position.RIGHT
		and merged.panel.position ~= enums.panel_position.BOTTOM
	then
		merged.panel.position = defaults.panel.position
	end

	merged.context = merged.context or {}
	if
		merged.context.target_view ~= CONTEXT_TARGET_DEFAULT
		and merged.context.target_view ~= enums.view.FLOAT
		and merged.context.target_view ~= enums.view.PANEL
	then
		merged.context.target_view = defaults.context.target_view
	end
	merged.context.include_file_path = merged.context.include_file_path ~= false
	merged.context.include_filetype = merged.context.include_filetype ~= false
	merged.context.include_cursor = merged.context.include_cursor ~= false
	merged.context.include_selection_range = merged.context.include_selection_range ~= false
	merged.context.include_diagnostics = merged.context.include_diagnostics ~= false

	if type(merged.keymaps) == "table" then
		for _, name in ipairs(KEYMAP_NAMES) do
			merged.keymaps[name] = normalize_key(merged.keymaps[name])
		end
	else
		merged.keymaps = {}
	end

	M.options = merged
	return M.options
end

return M
