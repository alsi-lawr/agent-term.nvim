local enums = require("codex.enums")
local keymaps = require("codex.setup.keymaps")
local notify = require("codex.notify")
local schema = require("codex.setup.schema")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

M.defaults = {
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

local known_top_level = {
	codex = true,
	float = true,
	panel = true,
	context = true,
	keymaps = true,
}

local known_nested = {
	codex = {
		cmd = true,
		resume = true,
		resume_all = true,
		resume_last = true,
	},
	float = {
		width = true,
		height = true,
		border = true,
	},
	panel = {
		position = true,
		width = true,
		height = true,
	},
	context = {
		target_view = true,
		include_file_path = true,
		include_filetype = true,
		include_cursor = true,
		include_selection_range = true,
		include_diagnostics = true,
	},
}

---@param known table<string, boolean>
---@return fun(name: string): boolean
local function is_known_name(known)
	return function(name)
		return known[name] == true
	end
end

---@param target table<string, any>
---@param unknown string[]
---@param message string
local function warn_and_strip(target, unknown, message)
	if #unknown == 0 then
		return
	end
	notify.warn(message)
	schema.strip_unknown_names(target, unknown)
end

---@param validated codex.Config
local function validate_top_level_keys(validated)
	local unknown = schema.get_unknown_names(validated, is_known_name(known_top_level))
	warn_and_strip(
		validated,
		unknown,
		("Unknown codex.nvim config keys ignored: %s"):format(table.concat(unknown, ", "))
	)
end

---@param section_opts any
---@param section string
---@param known table<string, boolean>
local function validate_nested_section(section_opts, section, known)
	if type(section_opts) ~= "table" then
		return
	end

	local unknown = schema.get_unknown_names(section_opts, is_known_name(known))
	warn_and_strip(
		section_opts,
		unknown,
		("Unknown codex.nvim config keys ignored in `%s`: %s"):format(
			section,
			table.concat(unknown, ", ")
		)
	)
end

---@param validated codex.Config
local function validate_nested_keys(validated)
	for section, known in pairs(known_nested) do
		validate_nested_section(validated[section], section, known)
	end
end

---@param validated codex.Config
local function validate_keymap_names(validated)
	if type(validated.keymaps) ~= "table" then
		return
	end

	local unknown = keymaps.get_unknown_names(validated.keymaps)
	warn_and_strip(
		validated.keymaps,
		unknown,
		("Unknown codex.nvim keymaps ignored: %s"):format(table.concat(unknown, ", "))
	)
end

---@param user_opts codex.Config
---@return codex.Config
function M.validate_schema(user_opts)
	local validated = vim.deepcopy(user_opts)
	validate_top_level_keys(validated)
	validate_nested_keys(validated)
	validate_keymap_names(validated)
	return validated
end

---@param user_opts? codex.Config
---@return codex.Config
function M.build_options(user_opts)
	local validated = user_opts
	if type(user_opts) == "table" then
		validated = M.validate_schema(user_opts)
	end
	return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), validated or {})
end

return M
