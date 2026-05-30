---@diagnostic disable: undefined-field
local reload = require("tests.helpers.reload")

describe("Given configuration setup", function()
	local original_notify = vim.notify
	local notifications

	before_each(function()
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
	end)

	after_each(function()
		vim.notify = original_notify
		reload.clear_agent_term_modules()
	end)

	it("When setup is called with no user options Then defaults are exposed unchanged", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup()

		assert.are.same({ "codex" }, opts.agent.cmd)
		assert.are.equal("codex", opts.agent.preset)
		assert.is_nil(opts.agent.auto_resume)
		assert.are.equal("right", opts.panel.position)
		assert.are.equal(".agent-term/context.json", opts.context.file_path)
		assert.are.equal("default", opts.context.target_view)
		assert.is_false(opts.context.hook.enabled)
		assert.is_false(opts.keymaps)
	end)

	it("When unknown config keys are provided Then they are stripped and users are warned", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "gemini" },
				auto_resume = "last",
				bogus_cmd_key = true,
			},
			panel = {
				position = "bottom",
			},
			context = {
				target_view = "default",
				include_cursor = false,
			},
			experimental = { flag = true },
		})

		assert.are.same({ "gemini" }, opts.agent.cmd)
		assert.are.equal("last", opts.agent.auto_resume)
		assert.are.equal("bottom", opts.panel.position)
		assert.are.equal("default", opts.context.target_view)
		assert.is_false(opts.context.include_cursor)
		assert.is_nil(opts.agent.bogus_cmd_key)
		assert.is_nil(opts.experimental)
		assert.are.equal(2, #notifications)
		assert.are.equal(
			"Unknown agent-term.nvim config keys ignored: experimental",
			notifications[1].msg
		)
		assert.are.equal(
			"Unknown agent-term.nvim config keys ignored in `agent`: bogus_cmd_key",
			notifications[2].msg
		)
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
		assert.are.equal(vim.log.levels.WARN, notifications[2].level)
	end)

	it("When auto resume mode is configured Then it is preserved", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "some-agent" },
				auto_resume = "picker",
			},
		})

		assert.are.same({ "some-agent" }, opts.agent.cmd)
		assert.are.equal("picker", opts.agent.auto_resume)
	end)

	it("When auto resume is explicitly false Then it is preserved as disabled", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "some-agent" },
				auto_resume = false,
			},
		})

		assert.are.same({ "some-agent" }, opts.agent.cmd)
		assert.is_false(opts.agent.auto_resume)
	end)

	it(
		"When agent is set to a preset string Then that preset is expanded to backend defaults",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agent = "gemini",
			})

			assert.are.same({ "gemini" }, opts.agent.cmd)
			assert.are.equal("gemini", opts.agent.preset)
			assert.is_nil(opts.agent.auto_resume)
		end
	)

	it("When agent is set from enum constants Then the matching preset is used", function()
		local config = require("agent_term.setup.runtime_config")
		local enums = require("agent_term.enums")
		local opts = config.setup({
			agent = enums.agent.CLAUDE,
		})

		assert.are.same({ "claude" }, opts.agent.cmd)
		assert.are.equal("claude", opts.agent.preset)
		assert.is_nil(opts.agent.auto_resume)
	end)

	it(
		"When agent preset is configured as a table Then preset defaults are merged with overrides",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agent = {
					preset = "codex",
					cmd = { "codex", "--model", "gpt-5.4-mini" },
					auto_resume = "last",
				},
			})

			assert.are.same({ "codex", "--model", "gpt-5.4-mini" }, opts.agent.cmd)
			assert.are.equal("codex", opts.agent.preset)
			assert.are.equal("last", opts.agent.auto_resume)
		end
	)

	it("When backend is a preset string alias Then it maps to the same preset defaults", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			backend = "aider",
		})

		assert.are.same({ "aider" }, opts.agent.cmd)
		assert.are.equal("aider", opts.agent.preset)
		assert.is_nil(opts.agent.auto_resume)
	end)

	it("When agent is set to copilot Then paste context is used by default", function()
		local config = require("agent_term.setup.runtime_config")
		local enums = require("agent_term.enums")
		local opts = config.setup({
			agent = enums.agent.COPILOT,
		})

		assert.are.same({ "copilot" }, opts.agent.cmd)
		assert.are.equal("copilot", opts.agent.preset)
		assert.is_nil(opts.agent.auto_resume)
		assert.is_false(opts.context.hook.enabled)
	end)

	it("When agent is set to opencode Then paste context is used by default", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = "opencode",
		})

		assert.are.same({ "opencode" }, opts.agent.cmd)
		assert.are.equal("opencode", opts.agent.preset)
		assert.is_nil(opts.agent.auto_resume)
		assert.is_false(opts.context.hook.enabled)
	end)

	it("When agent cmd is custom without preset Then neutral backend defaults are used", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "gemini" },
			},
		})

		assert.are.same({ "gemini" }, opts.agent.cmd)
		assert.is_nil(opts.agent.auto_resume)
		assert.is_nil(opts.agent.preset)
	end)

	it("When unknown agent config keys are provided Then they are ignored", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "custom-agent" },
				auto_resume = "last",
				transport = "hook",
			},
		})

		assert.are.same({ "custom-agent" }, opts.agent.cmd)
		assert.are.equal("last", opts.agent.auto_resume)
		assert.is_false(opts.context.hook.enabled)
		assert.are.equal(1, #notifications)
		assert.match(
			"Unknown agent%-term%.nvim config keys ignored in `agent`: transport",
			notifications[1].msg
		)
	end)

	it("When an unknown preset is used Then a warning is shown and defaults are kept", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = "not-real",
		})

		assert.are.same({ "codex" }, opts.agent.cmd)
		assert.are.equal(1, #notifications)
		assert.match("Unknown agent preset", notifications[1].msg)
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
	end)

	it("When unknown keymaps are configured Then they are stripped and warned", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			keymaps = {
				float_toggle = "<leader>ct",
				unknown_action = "<leader>xx",
			},
		})

		assert.are.equal("<leader>ct", opts.keymaps.float_toggle)
		assert.is_nil(opts.keymaps.unknown_action)
		assert.are.equal(1, #notifications)
		assert.are.equal(
			"Unknown agent-term.nvim keymaps ignored: unknown_action",
			notifications[1].msg
		)
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
	end)

	it("When keymaps is explicitly disabled Then setup preserves keymaps = false", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			keymaps = false,
		})

		assert.is_false(opts.keymaps)
		assert.are.same({}, notifications)
	end)

	it(
		"When only part of a nested table is overridden Then defaults remain for unspecified keys",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				context = {
					include_file_path = false,
				},
				panel = {
					width = 80,
				},
			})

			assert.is_false(opts.context.include_file_path)
			assert.is_true(opts.context.include_filetype)
			assert.is_true(opts.context.include_cursor)
			assert.are.equal(80, opts.panel.width)
			assert.are.equal(0.35, opts.panel.height)
			assert.are.equal("rounded", opts.float.border)
		end
	)

	it("When invalid config values are provided Then safe defaults are used with warnings", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = "codex",
				auto_resume = "yes",
				context = {
					mode = "silent",
				},
			},
			float = {
				width = "80",
			},
			panel = {
				position = "middle",
				height = "large",
			},
			context = {
				file_path = {},
				target_view = "side",
				include_cursor = "yes",
			},
		})

		assert.are.same({ "codex" }, opts.agent.cmd)
		assert.is_nil(opts.agent.auto_resume)
		assert.are.equal(".agent-term/context.json", opts.context.file_path)
		assert.are.equal(0.85, opts.float.width)
		assert.are.equal("right", opts.panel.position)
		assert.are.equal(0.35, opts.panel.height)
		assert.are.equal("default", opts.context.target_view)
		assert.is_true(opts.context.include_cursor)
		assert.is_true(#notifications >= 8)
	end)
end)
