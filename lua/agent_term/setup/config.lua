local enums = require("agent_term.enums")
local keymaps = require("agent_term.setup.keymaps")
local notify = require("agent_term.notify")
local schema = require("agent_term.setup.schema")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

M.agent_presets = {
	codex = {
		preset = "codex",
		cmd = { "codex" },
	},
	gemini = {
		preset = "gemini",
		cmd = { "gemini" },
	},
	claude = {
		preset = "claude",
		cmd = { "claude" },
	},
	aider = {
		preset = "aider",
		cmd = { "aider" },
	},
	copilot = {
		preset = "copilot",
		cmd = { "copilot" },
	},
	opencode = {
		preset = "opencode",
		cmd = { "opencode" },
	},
}

local auto_resume_args = {
	codex = {
		picker = { "resume" },
		last = { "resume", "--last" },
	},
	gemini = {
		picker = { "-r" },
		last = { "-r", "latest" },
	},
	claude = {
		picker = { "--resume" },
		last = { "--continue" },
	},
	aider = {
		last = { "--restore-chat-history" },
	},
	copilot = {
		picker = { "--resume" },
		last = { "--continue" },
	},
	opencode = {
		last = { "--continue" },
	},
}

local default_context = {
	file_path = ".agent-term/context.json",
	target_view = CONTEXT_TARGET_DEFAULT,
	hook = {
		enabled = false,
	},
	include_file_path = true,
	include_filetype = true,
	include_cursor = true,
	include_selection_range = true,
	include_diagnostics = true,
}

M.defaults = {
	agents = {
		codex = vim.tbl_deep_extend("force", vim.deepcopy(M.agent_presets.codex), {
			context = vim.deepcopy(default_context),
		}),
	},
	active_agent = nil,
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
	keymaps = false,
}

local known_top_level = {
	agents = true,
	active_agent = true,
	float = true,
	panel = true,
	keymaps = true,
}

local known_agent = {
	preset = true,
	cmd = true,
	auto_resume = true,
	context = true,
}

local known_nested = {
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
		file_path = true,
		target_view = true,
		hook = true,
		include_file_path = true,
		include_filetype = true,
		include_cursor = true,
		include_selection_range = true,
		include_diagnostics = true,
	},
}

local known_context_hook = {
	enabled = true,
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

local valid_auto_resume_modes = {
	picker = true,
	last = true,
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

---@param name string
---@param mode "picker"|"last"
---@return string[]|nil
function M.auto_resume_args_for_preset(name, mode)
	local modes = auto_resume_args[name]
	if type(modes) ~= "table" then
		return nil
	end
	local args = modes[mode]
	if type(args) ~= "table" then
		return nil
	end
	return vim.deepcopy(args)
end

---@param agents table<string|integer, any>
local function normalize_agents(agents)
	for index, agent in ipairs(agents) do
		if type(agent) == "string" then
			if agents[agent] == nil then
				agents[agent] = agent
			end
			agents[index] = nil
		else
			warn_invalid("agents." .. index, "a preset string")
			agents[index] = nil
		end
	end

	for name, agent in pairs(agents) do
		if type(agent) == "string" then
			local preset = preset_by_name(agent)
			if preset then
				agents[name] = preset
			else
				notify.warn(
					("Unknown agent preset `%s`. Supported presets: %s"):format(agent, known_presets())
				)
				agents[name] = nil
			end
		elseif type(agent) == "table" and type(agent.preset) == "string" then
			local preset = preset_by_name(agent.preset)
			if preset then
				agent.preset = nil
				agents[name] = vim.tbl_deep_extend("force", preset, agent)
			else
				notify.warn(
					("Unknown agent preset `%s`. Supported presets: %s"):format(agent.preset, known_presets())
				)
				agent.preset = nil
			end
		elseif type(agent) ~= "table" then
			warn_invalid("agents." .. name, "a table or preset string")
			agents[name] = nil
		end
	end
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

---@param agents table<string, any>
local function validate_agent_nested_keys(agents)
	for name, agent in pairs(agents) do
		validate_nested_section(agent, "agents." .. name, known_agent)
		if type(agent) == "table" then
			validate_nested_section(agent.context, "agents." .. name .. ".context", known_nested.context)
			if type(agent.context) == "table" and type(agent.context.hook) == "table" then
				validate_nested_section(
					agent.context.hook,
					"agents." .. name .. ".context.hook",
					known_context_hook
				)
			end
		end
	end
end

---@param validated agent_term.Config
local function validate_nested_keys(validated)
	for section, known in pairs(known_nested) do
		validate_nested_section(validated[section], section, known)
	end
	if type(validated.agents) == "table" then
		validate_agent_nested_keys(validated.agents)
	end
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
	if validated.agents ~= nil and type(validated.agents) ~= "table" then
		warn_invalid("agents", "a table")
		validated.agents = nil
	end
	if validated.active_agent ~= nil and not is_string(validated.active_agent) then
		warn_invalid("active_agent", "a non-empty string")
		validated.active_agent = nil
	end
	for _, section in ipairs({ "float", "panel" }) do
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

---@param context table<string, any>|nil
---@param path string
local function validate_context_values(context, path)
	if type(context) ~= "table" then
		return
	end
	strip_invalid_field(context, "file_path", path .. ".file_path", is_string, "a non-empty string")
	strip_invalid_field(
		context,
		"target_view",
		path .. ".target_view",
		is_known_value(valid_context_targets),
		"`default`, `float`, or `panel`"
	)
	strip_invalid_field(context, "hook", path .. ".hook", function(value)
		return type(value) == "table"
	end, "a table")
	if type(context.hook) == "table" then
		strip_invalid_field(context.hook, "enabled", path .. ".hook.enabled", is_boolean, "a boolean")
		if is_empty_table(context.hook) then
			context.hook = nil
		end
	end
	for _, key in ipairs({
		"include_file_path",
		"include_filetype",
		"include_cursor",
		"include_selection_range",
		"include_diagnostics",
	}) do
		strip_invalid_field(context, key, path .. "." .. key, is_boolean, "a boolean")
	end
end

---@param agent table<string, any>
---@param path string
local function validate_agent_values(agent, path)
	strip_invalid_field(agent, "cmd", path .. ".cmd", is_string_list, "a non-empty string[]")
	strip_invalid_field(agent, "auto_resume", path .. ".auto_resume", function(value)
		return value == false or is_known_value(valid_auto_resume_modes)(value)
	end, "`picker`, `last`, or false")
	strip_invalid_field(agent, "context", path .. ".context", function(value)
		return type(value) == "table"
	end, "a table")
	validate_context_values(agent.context, path .. ".context")
end

---@param validated agent_term.Config
local function validate_option_values(validated)
	validate_section_shapes(validated)

	if type(validated.agents) == "table" then
		for name, agent in pairs(validated.agents) do
			if type(agent) == "table" then
				validate_agent_values(agent, "agents." .. name)
				if agent.cmd == nil and type(agent.preset) == "string" then
					local preset = preset_by_name(agent.preset)
					if preset then
						agent.cmd = preset.cmd
					end
				end
			end
		end
	end

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

---@param agents table<string, agent_term.AgentConfig>
---@return string[]
function M.agent_names(agents)
	local names = {}
	for name, _ in pairs(agents or {}) do
		if type(name) == "string" then
			names[#names + 1] = name
		end
	end
	table.sort(names)
	return names
end

---@param user_opts agent_term.Config
---@return agent_term.Config
function M.validate_schema(user_opts)
	local validated = vim.deepcopy(user_opts)
	validate_top_level_keys(validated)
	validate_section_shapes(validated)
	if type(validated.agents) == "table" then
		normalize_agents(validated.agents)
	end
	validate_nested_keys(validated)
	validate_keymap_names(validated)
	validate_option_values(validated)
	return validated
end

---@param user_opts? agent_term.Config
---@return agent_term.Config
function M.build_options(user_opts)
	local validated = user_opts
	if type(user_opts) == "table" then
		validated = M.validate_schema(user_opts)
	end
	local defaults = vim.deepcopy(M.defaults)
	if type(validated) == "table" and type(validated.agents) == "table" then
		defaults.agents = {}
	end
	local options = vim.tbl_deep_extend("force", defaults, validated or {})
	for _, agent in pairs(options.agents) do
		agent.context = vim.tbl_deep_extend("force", vim.deepcopy(default_context), agent.context or {})
	end
	return options
end

return M
