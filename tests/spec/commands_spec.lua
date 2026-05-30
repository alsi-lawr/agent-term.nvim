local reload = require("tests.helpers.reload")

describe("Given Agent Term command registration", function()
	local function api()
		return {
			open = function() end,
			close = function() end,
			toggle = function() end,
			focus = function() end,
			kill = function() end,
			float_open = function() end,
			float_close = function() end,
			float_toggle = function() end,
			float_focus = function() end,
			panel_open = function() end,
			panel_close = function() end,
			panel_toggle = function() end,
			panel_focus = function() end,
			send_buffer_context = function() end,
			send_selection_context = function() end,
			send_diagnostics_context = function() end,
			install_hooks = function() end,
			resume = function() end,
			resume_all = function() end,
			resume_last = function() end,
		}
	end

	local function exists(command)
		return vim.fn.exists(":" .. command) == 2
	end

	after_each(function()
		local commands = {
			"AgentTermResume",
			"AgentTermResumeAll",
			"AgentTermResumeLast",
			"AgentTermInstallHooks",
		}
		for _, command in ipairs(commands) do
			pcall(vim.api.nvim_del_user_command, command)
		end
		reload.clear_agent_term_modules()
	end)

	it("When the default backend is used Then resume commands are registered", function()
		local config = require("agent_term.setup.runtime_config")
		local commands = require("agent_term.setup.commands")
		config.setup()
		commands.setup(api())

		assert.is_true(exists("AgentTermResume"))
		assert.is_true(exists("AgentTermResumeAll"))
		assert.is_true(exists("AgentTermResumeLast"))
	end)

	it("When resume is disabled Then resume commands are not registered", function()
		local config = require("agent_term.setup.runtime_config")
		local commands = require("agent_term.setup.commands")
		config.setup({
			agent = {
				cmd = { "gemini" },
				resume = false,
			},
		})
		commands.setup(api())

		assert.is_false(exists("AgentTermResume"))
		assert.is_false(exists("AgentTermResumeAll"))
		assert.is_false(exists("AgentTermResumeLast"))
	end)

	it("When resume support is partial Then only configured capabilities are registered", function()
		local config = require("agent_term.setup.runtime_config")
		local commands = require("agent_term.setup.commands")
		config.setup({
			agent = {
				cmd = { "some-agent" },
				resume = {
					default = { "some-agent", "resume" },
					all = false,
					last = false,
				},
			},
		})
		commands.setup(api())

		assert.is_true(exists("AgentTermResume"))
		assert.is_false(exists("AgentTermResumeAll"))
		assert.is_false(exists("AgentTermResumeLast"))
	end)
end)
