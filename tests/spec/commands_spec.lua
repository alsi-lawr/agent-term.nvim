local reload = require("tests.helpers.reload")

describe("Given Agent Term command registration", function()
	local function exists(command)
		return vim.fn.exists(":" .. command) == 2
	end

	after_each(function()
		local commands = {
			"AgentTermOpen",
			"AgentTermClose",
			"AgentTermToggle",
			"AgentTermFocus",
			"AgentTermKill",
			"AgentTermFloatOpen",
			"AgentTermFloatClose",
			"AgentTermFloatToggle",
			"AgentTermFloatFocus",
			"AgentTermPanelOpen",
			"AgentTermPanelClose",
			"AgentTermPanelToggle",
			"AgentTermPanelFocus",
			"AgentTermSendBufferContext",
			"AgentTermSendSelectionContext",
			"AgentTermSendDiagnosticsContext",
			"AgentTermInstallHooks",
			"AgentTermIgnore",
		}
		for _, command in ipairs(commands) do
			pcall(vim.api.nvim_del_user_command, command)
		end
		reload.clear_agent_term_modules()
	end)

	it("When commands are set up Then the supported command surface is registered", function()
		local config = require("agent_term.setup.runtime_config")
		local commands = require("agent_term.commands.registry")
		config.setup()
		commands.setup()

		assert.is_true(exists("AgentTermToggle"))
		assert.is_true(exists("AgentTermPanelToggle"))
		assert.is_true(exists("AgentTermSendBufferContext"))
		assert.is_true(exists("AgentTermInstallHooks"))
		assert.is_true(exists("AgentTermIgnore"))
	end)
end)
