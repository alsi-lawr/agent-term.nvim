local enums = require("agent_term.enums")
local keymaps = require("agent_term.setup.keymaps")
local notify = require("agent_term.notify")
local schema = require("agent_term.setup.schema")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

M.agent_presets = {
	codex = {
		cmd = { "codex" },
		resume = {
			default = { "codex", "resume" },
			all = { "codex", "resume", "--all" },
			last = { "codex", "resume", "--last" },
		},
	},
	gemini = {
		cmd = { "gemini" },
		resume = {
			default = { "gemini", "-r" },
			all = false,
			last = { "gemini", "-r", "latest" },
		},
	},
	claude = {
		cmd = { "claude" },
		resume = {
			default = { "claude", "--resume" },
			all = false,
			last = { "claude", "--continue" },
		},
	},
	aider = {
		cmd = { "aider" },
		resume = {
			default = { "aider", "--restore-chat-history" },
			all = false,
			last = false,
		},
	},
}

M.defaults = {
	agent = vim.deepcopy(M.agent_presets.codex),
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
	agent = true,
	backend = true,
	float = true,
	panel = true,
	context = true,
	keymaps = true,
}

local known_nested = {
	agent = {
		preset = true,
		cmd = true,
		resume = true,
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

local known_resume = {
	default = true,
	all = true,
	last = true,
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

local function merge_backend_alias(validated)
	if
		validated.agent == nil
		and (type(validated.backend) == "table" or type(validated.backend) == "string")
	then
		validated.agent = vim.deepcopy(validated.backend)
	end
	validated.backend = nil
end

local function known_presets()
	local names = {}
	for name, _ in pairs(M.agent_presets) do
		names[#names + 1] = name
	end
	table.sort(names)
	return table.concat(names, ", ")
end

---@param name string
---@return table<string, any>|nil
local function preset_by_name(name)
	local preset = M.agent_presets[name]
	if type(preset) ~= "table" then
		return nil
	end
	return vim.deepcopy(preset)
end

---@param validated table<string, any>
local function normalize_agent_shortcuts(validated)
	if type(validated.agent) == "string" then
		local preset = preset_by_name(validated.agent)
		if preset then
			validated.agent = preset
		else
			notify.warn(
				("Unknown agent preset `%s`. Supported presets: %s"):format(
					validated.agent,
					known_presets()
				)
			)
			validated.agent = nil
		end
		return
	end

	if type(validated.agent) ~= "table" or type(validated.agent.preset) ~= "string" then
		return
	end

	local preset = preset_by_name(validated.agent.preset)
	if not preset then
		notify.warn(
			("Unknown agent preset `%s`. Supported presets: %s"):format(
				validated.agent.preset,
				known_presets()
			)
		)
		validated.agent.preset = nil
		return
	end

	validated.agent.preset = nil
	validated.agent = vim.tbl_deep_extend("force", preset, validated.agent)
end

---@param validated agent_term.Config
local function validate_top_level_keys(validated)
	local unknown = schema.get_unknown_names(validated, is_known_name(known_top_level))
	warn_and_strip(
		validated,
		unknown,
		("Unknown agent-term.nvim config keys ignored: %s"):format(table.concat(unknown, ", "))
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
		("Unknown agent-term.nvim config keys ignored in `%s`: %s"):format(
			section,
			table.concat(unknown, ", ")
		)
	)
end

---@param validated agent_term.Config
local function validate_nested_keys(validated)
	for section, known in pairs(known_nested) do
		validate_nested_section(validated[section], section, known)
	end

	if type(validated.agent) == "table" and type(validated.agent.resume) == "table" then
		validate_nested_section(validated.agent.resume, "agent.resume", known_resume)
	end
end

---@param validated agent_term.Config
local function validate_keymap_names(validated)
	if type(validated.keymaps) ~= "table" then
		return
	end

	local unknown = keymaps.get_unknown_names(validated.keymaps)
	warn_and_strip(
		validated.keymaps,
		unknown,
		("Unknown agent-term.nvim keymaps ignored: %s"):format(table.concat(unknown, ", "))
	)
end

---@param user_opts agent_term.Config
---@return agent_term.Config
function M.validate_schema(user_opts)
	local validated = vim.deepcopy(user_opts)
	merge_backend_alias(validated)
	normalize_agent_shortcuts(validated)
	validate_top_level_keys(validated)
	validate_nested_keys(validated)
	validate_keymap_names(validated)
	return validated
end

local function fill_resume_capabilities(options)
	if type(options.agent.resume) ~= "table" then
		return
	end
	for _, key in ipairs({ "default", "all", "last" }) do
		if options.agent.resume[key] == nil then
			options.agent.resume[key] = false
		end
	end
end

---@param user_opts? agent_term.Config
---@return agent_term.Config
function M.build_options(user_opts)
	local validated = user_opts
	if type(user_opts) == "table" then
		validated = M.validate_schema(user_opts)
	end
	local defaults = vim.deepcopy(M.defaults)
	if
		type(validated) == "table"
		and type(validated.agent) == "table"
		and type(validated.agent.resume) == "table"
	then
		defaults.agent.resume = {}
	end
	local options = vim.tbl_deep_extend("force", defaults, validated or {})
	fill_resume_capabilities(options)
	return options
end

return M
