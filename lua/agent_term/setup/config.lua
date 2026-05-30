local enums = require("agent_term.enums")
local keymaps = require("agent_term.setup.keymaps")
local notify = require("agent_term.notify")
local schema = require("agent_term.setup.schema")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

M.agent_presets = {
	codex = {
		cmd = { "codex" },
		context = {
			mode = "hook",
			hook_event = "UserPromptSubmit",
		},
		resume = {
			default = { "codex", "resume" },
			all = { "codex", "resume", "--all" },
			last = { "codex", "resume", "--last" },
		},
	},
	gemini = {
		cmd = { "gemini" },
		context = {
			mode = "paste",
		},
		resume = {
			default = { "gemini", "-r" },
			all = false,
			last = { "gemini", "-r", "latest" },
		},
	},
	claude = {
		cmd = { "claude" },
		context = {
			mode = "hook",
			hook_event = "UserPromptSubmit",
		},
		resume = {
			default = { "claude", "--resume" },
			all = false,
			last = { "claude", "--continue" },
		},
	},
	aider = {
		cmd = { "aider" },
		context = {
			mode = "paste",
		},
		resume = {
			default = { "aider", "--restore-chat-history" },
			all = false,
			last = false,
		},
	},
	copilot = {
		cmd = { "copilot" },
		context = {
			mode = "paste",
		},
		resume = {
			default = { "copilot", "--resume" },
			all = false,
			last = { "copilot", "--continue" },
		},
	},
	opencode = {
		cmd = { "opencode" },
		context = {
			mode = "paste",
		},
		resume = {
			default = false,
			all = false,
			last = { "opencode", "--continue" },
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
		context = true,
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

local known_agent_context = {
	mode = true,
	hook_event = true,
}

local valid_context_targets = {
	[CONTEXT_TARGET_DEFAULT] = true,
	[enums.view.FLOAT] = true,
	[enums.view.PANEL] = true,
}

local valid_panel_positions = {
	[enums.panel_position.LEFT] = true,
	[enums.panel_position.RIGHT] = true,
	[enums.panel_position.BOTTOM] = true,
}

local valid_agent_context_modes = {
	paste = true,
	hook = true,
}

---@param known table<string, boolean>
---@return fun(name: string): boolean
local function is_known_name(known)
	return function(name)
		return known[name] == true
	end
end

---@param value any
---@return boolean
local function is_string_list(value)
	if type(value) ~= "table" or #value == 0 then
		return false
	end
	for _, item in ipairs(value) do
		if type(item) ~= "string" or item == "" then
			return false
		end
	end
	return true
end

---@param opts agent_term.Config|nil
---@return any
local function raw_agent_config(opts)
	if type(opts) ~= "table" then
		return nil
	end
	if opts.agent ~= nil then
		return opts.agent
	end
	return opts.backend
end

---@param opts agent_term.Config|nil
---@return boolean
local function is_plain_custom_agent(opts)
	local agent = raw_agent_config(opts)
	return type(agent) == "table" and agent.preset == nil and is_string_list(agent.cmd)
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

---@param path string
---@param expected string
local function warn_invalid(path, expected)
	notify.warn(("Invalid agent-term.nvim config `%s` ignored; expected %s."):format(path, expected))
end

---@param tbl table<string, any>
---@param key string
---@param path string
---@param is_valid fun(value: any): boolean
---@param expected string
local function strip_invalid_field(tbl, key, path, is_valid, expected)
	if tbl[key] == nil or is_valid(tbl[key]) then
		return
	end
	warn_invalid(path, expected)
	tbl[key] = nil
end

---@param tbl table<any, any>
---@return boolean
local function is_empty_table(tbl)
	return next(tbl) == nil
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
	if type(validated.agent) == "table" and type(validated.agent.context) == "table" then
		validate_nested_section(validated.agent.context, "agent.context", known_agent_context)
	end
end

---@param value any
---@return boolean
local function is_table_or_false(value)
	return value == false or type(value) == "table"
end

---@param value any
---@return boolean
local function is_boolean(value)
	return type(value) == "boolean"
end

---@param value any
---@return boolean
local function is_number(value)
	return type(value) == "number"
end

---@param value any
---@return boolean
local function is_string(value)
	return type(value) == "string" and value ~= ""
end

---@param known table<string, boolean>
---@return fun(value: any): boolean
local function is_known_value(known)
	return function(value)
		return type(value) == "string" and known[value] == true
	end
end

---@param validated agent_term.Config
local function validate_section_shapes(validated)
	for _, section in ipairs({ "float", "panel", "context" }) do
		if validated[section] ~= nil and type(validated[section]) ~= "table" then
			warn_invalid(section, "a table")
			validated[section] = nil
		end
	end

	if
		validated.keymaps ~= nil
		and validated.keymaps ~= false
		and type(validated.keymaps) ~= "table"
	then
		warn_invalid("keymaps", "a table or false")
		validated.keymaps = nil
	end
end

---@param validated agent_term.Config
local function validate_agent_values(validated)
	if type(validated.agent) ~= "table" then
		return
	end

	strip_invalid_field(validated.agent, "cmd", "agent.cmd", is_string_list, "a non-empty string[]")
	strip_invalid_field(
		validated.agent,
		"resume",
		"agent.resume",
		is_table_or_false,
		"a table or false"
	)

	if type(validated.agent.resume) == "table" then
		for _, kind in ipairs({ "default", "all", "last" }) do
			strip_invalid_field(
				validated.agent.resume,
				kind,
				("agent.resume.%s"):format(kind),
				function(value)
					return value == false or is_string_list(value)
				end,
				"a non-empty string[] or false"
			)
		end
		if is_empty_table(validated.agent.resume) then
			validated.agent.resume = nil
		end
	end

	strip_invalid_field(validated.agent, "context", "agent.context", function(value)
		return type(value) == "table"
	end, "a table")

	if type(validated.agent.context) == "table" then
		strip_invalid_field(
			validated.agent.context,
			"mode",
			"agent.context.mode",
			is_known_value(valid_agent_context_modes),
			"`paste` or `hook`"
		)
		strip_invalid_field(
			validated.agent.context,
			"hook_event",
			"agent.context.hook_event",
			is_string,
			"a non-empty string"
		)
		if is_empty_table(validated.agent.context) then
			validated.agent.context = nil
		end
	end
end

---@param validated agent_term.Config
local function validate_option_values(validated)
	validate_section_shapes(validated)
	validate_agent_values(validated)

	if type(validated.float) == "table" then
		strip_invalid_field(validated.float, "width", "float.width", is_number, "a number")
		strip_invalid_field(validated.float, "height", "float.height", is_number, "a number")
	end

	if type(validated.panel) == "table" then
		strip_invalid_field(
			validated.panel,
			"position",
			"panel.position",
			is_known_value(valid_panel_positions),
			"`left`, `right`, or `bottom`"
		)
		strip_invalid_field(validated.panel, "width", "panel.width", is_number, "a number")
		strip_invalid_field(validated.panel, "height", "panel.height", is_number, "a number")
	end

	if type(validated.context) == "table" then
		strip_invalid_field(
			validated.context,
			"target_view",
			"context.target_view",
			is_known_value(valid_context_targets),
			"`default`, `float`, or `panel`"
		)
		for _, key in ipairs({
			"include_file_path",
			"include_filetype",
			"include_cursor",
			"include_selection_range",
			"include_diagnostics",
		}) do
			strip_invalid_field(validated.context, key, "context." .. key, is_boolean, "a boolean")
		end
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
	validate_section_shapes(validated)
	validate_nested_keys(validated)
	validate_keymap_names(validated)
	validate_option_values(validated)
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
	local plain_custom_agent = is_plain_custom_agent(user_opts)
	local validated = user_opts
	if type(user_opts) == "table" then
		validated = M.validate_schema(user_opts)
	end
	local defaults = vim.deepcopy(M.defaults)
	if plain_custom_agent then
		defaults.agent = {
			resume = false,
			context = {
				mode = "paste",
			},
		}
	end
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
