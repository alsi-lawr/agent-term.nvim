local enums = require("agent_term.enums")
local keymaps = require("agent_term.setup.keymaps")
local notify = require("agent_term.notify")
local schema = require("agent_term.setup.schema")

local M = {}
local CONTEXT_TARGET_DEFAULT = "default"

---@type table<agent_term.SupportedAgent, agent_term.AgentPreset>
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

---@type agent_term.ContextConfig
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
		host = enums.float_host.NATIVE,
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
		host = true,
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

local valid_float_hosts = {
	[enums.float_host.NATIVE] = true,
	[enums.float_host.SNACKS] = true,
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
---@return agent_term.AgentPreset|nil
local function preset_by_name(name)
	local preset = M.agent_presets[name]
	if type(preset) ~= "table" then
		return nil
	end
	return vim.deepcopy(preset)
end

---@param preset agent_term.AgentPreset
---@return agent_term.UserAgentConfig
local function preset_to_user_agent(preset)
	return {
		preset = preset.preset,
		cmd = vim.deepcopy(preset.cmd),
	}
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

---@param agents agent_term.UserAgents
---@param index integer
---@param agent any
local function normalize_list_agent(agents, index, agent)
	if type(agent) ~= "string" then
		warn_invalid("agents." .. index, "a preset string")
		agents[index] = nil
		return
	end
	if agents[agent] == nil then
		agents[agent] = agent
	end
	agents[index] = nil
end

---@param agents agent_term.UserAgents
---@param name string
---@param preset_name string
local function expand_preset_agent(agents, name, preset_name)
	local preset = preset_by_name(preset_name)
	if not preset then
		notify.warn(
			("Unknown agent preset `%s`. Supported presets: %s"):format(preset_name, known_presets())
		)
		agents[name] = nil
		return
	end
	agents[name] = preset_to_user_agent(preset)
end

---@param agents agent_term.UserAgents
---@param name string
---@param agent table<string, any>
local function expand_configured_agent_preset(agents, name, agent)
	if type(agent.preset) ~= "string" then
		return
	end
	local preset = preset_by_name(agent.preset)
	if not preset then
		notify.warn(
			("Unknown agent preset `%s`. Supported presets: %s"):format(agent.preset, known_presets())
		)
		agent.preset = nil
		return
	end
	agent.preset = nil
	agents[name] = vim.tbl_deep_extend("force", preset, agent)
end

---@param agents agent_term.UserAgents
---@param name string
---@param agent any
local function normalize_named_agent(agents, name, agent)
	if type(agent) == "string" then
		expand_preset_agent(agents, name, agent)
		return
	end
	if type(agent) ~= "table" then
		warn_invalid("agents." .. name, "a table or preset string")
		agents[name] = nil
		return
	end
	expand_configured_agent_preset(agents, name, agent)
end

---@param agents agent_term.UserAgents
local function normalize_agents(agents)
	for index, agent in ipairs(agents) do
		normalize_list_agent(agents, index, agent)
	end

	for name, agent in pairs(agents) do
		normalize_named_agent(agents, name, agent)
	end
end

---@param validated agent_term.UserConfig
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

---@param name string
---@param agent any
local function validate_agent_nested_keys(name, agent)
	validate_nested_section(agent, "agents." .. name, known_agent)
	if type(agent) ~= "table" then
		return
	end

	validate_nested_section(agent.context, "agents." .. name .. ".context", known_nested.context)
	if type(agent.context) ~= "table" or type(agent.context.hook) ~= "table" then
		return
	end

	validate_nested_section(
		agent.context.hook,
		"agents." .. name .. ".context.hook",
		known_context_hook
	)
end

---@param agents table<string, any>
local function validate_agents_nested_keys(agents)
	for name, agent in pairs(agents) do
		validate_agent_nested_keys(name, agent)
	end
end

---@param validated agent_term.UserConfig
local function validate_nested_keys(validated)
	for section, known in pairs(known_nested) do
		validate_nested_section(validated[section], section, known)
	end
	if type(validated.agents) ~= "table" then
		return
	end
	validate_agents_nested_keys(validated.agents)
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

---@param validated agent_term.UserConfig
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

---@param context table<string, any>
---@param path string
local function validate_context_hook_values(context, path)
	local hook = context.hook
	if type(hook) ~= "table" then
		return
	end
	strip_invalid_field(hook, "enabled", path .. ".hook.enabled", is_boolean, "a boolean")
	if not is_empty_table(hook) then
		return
	end
	context.hook = nil
end

---@param context table<string, any>
---@param path string
local function validate_context_include_values(context, path)
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
	validate_context_hook_values(context, path)
	validate_context_include_values(context, path)
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

---@param agent table<string, any>
local function apply_preset_cmd(agent)
	if agent.cmd ~= nil or type(agent.preset) ~= "string" then
		return
	end
	local preset = preset_by_name(agent.preset)
	if not preset then
		return
	end
	agent.cmd = preset.cmd
end

---@param name string
---@param agent any
local function validate_agent_config_values(name, agent)
	if type(agent) ~= "table" then
		return
	end
	validate_agent_values(agent, "agents." .. name)
	apply_preset_cmd(agent)
end

---@param agents table<string, any>
local function validate_agents_values(agents)
	for name, agent in pairs(agents) do
		validate_agent_config_values(name, agent)
	end
end

---@param float agent_term.UserFloatConfig
local function validate_float_values(float)
	strip_invalid_field(
		float,
		"host",
		"float.host",
		is_known_value(valid_float_hosts),
		"`native` or `snacks`"
	)
	strip_invalid_field(float, "width", "float.width", is_number, "a number")
	strip_invalid_field(float, "height", "float.height", is_number, "a number")
end

---@param panel agent_term.UserPanelConfig
local function validate_panel_values(panel)
	strip_invalid_field(
		panel,
		"position",
		"panel.position",
		is_known_value(valid_panel_positions),
		"`left`, `right`, or `bottom`"
	)
	strip_invalid_field(panel, "width", "panel.width", is_number, "a number")
	strip_invalid_field(panel, "height", "panel.height", is_number, "a number")
end

---@param validated agent_term.UserConfig
local function validate_option_values(validated)
	validate_section_shapes(validated)

	if type(validated.agents) == "table" then
		validate_agents_values(validated.agents)
	end

	if type(validated.float) == "table" then
		validate_float_values(validated.float)
	end

	if type(validated.panel) == "table" then
		validate_panel_values(validated.panel)
	end
end

---@param validated agent_term.UserConfig
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
	for name, _ in pairs(agents) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

---@param user_opts agent_term.UserConfig
---@return agent_term.UserConfig
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

---@param user_opts? agent_term.UserConfig
---@return agent_term.ResolvedConfig
function M.build_options(user_opts)
	local validated = user_opts
	if type(user_opts) == "table" then
		validated = M.validate_schema(user_opts)
	end
	local defaults = vim.deepcopy(M.defaults)
	if type(validated) == "table" and type(validated.agents) == "table" then
		defaults.agents = {}
	end
	---@type agent_term.ResolvedConfig
	local options = vim.tbl_deep_extend("force", defaults, validated or {})
	for _, agent in pairs(options.agents) do
		agent.context = vim.tbl_deep_extend("force", vim.deepcopy(default_context), agent.context or {})
	end
	return options
end

return M
