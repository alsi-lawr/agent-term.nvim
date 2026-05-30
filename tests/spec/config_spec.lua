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
		assert.are.equal("paste", opts.agent.context.mode)
		assert.are.same({ "codex", "resume" }, opts.agent.resume.default)
		assert.are.same({ "codex", "resume", "--all" }, opts.agent.resume.all)
		assert.are.same({ "codex", "resume", "--last" }, opts.agent.resume.last)
		assert.are.equal("right", opts.panel.position)
		assert.are.equal(".agent-term/context.json", opts.context.file_path)
		assert.are.equal("default", opts.context.target_view)
		assert.is_false(opts.keymaps)
	end)

	it("When unknown config keys are provided Then they are stripped and users are warned", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "gemini" },
				bogus_cmd_key = true,
				resume = false,
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
		assert.is_false(opts.agent.resume)
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

	it("When partial resume support is configured Then unavailable capabilities are false", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "some-agent" },
				resume = {
					default = { "some-agent", "resume" },
					all = false,
					last = false,
				},
			},
		})

		assert.are.same({ "some-agent", "resume" }, opts.agent.resume.default)
		assert.is_false(config.has_resume("all"))
		assert.is_false(config.has_resume("last"))
	end)

	it(
		"When agent is set to a preset string Then that preset is expanded to backend defaults",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agent = "gemini",
			})

			assert.are.same({ "gemini" }, opts.agent.cmd)
			assert.are.same({ "gemini", "-r" }, opts.agent.resume.default)
			assert.is_false(opts.agent.resume.all)
			assert.are.same({ "gemini", "-r", "latest" }, opts.agent.resume.last)
		end
	)

	it("When agent is set from enum constants Then the matching preset is used", function()
		local config = require("agent_term.setup.runtime_config")
		local enums = require("agent_term.enums")
		local opts = config.setup({
			agent = enums.agent.CLAUDE,
		})

		assert.are.same({ "claude" }, opts.agent.cmd)
		assert.are.equal("paste", opts.agent.context.mode)
		assert.are.same({ "claude", "--resume" }, opts.agent.resume.default)
		assert.is_false(opts.agent.resume.all)
		assert.are.same({ "claude", "--continue" }, opts.agent.resume.last)
	end)

	it(
		"When agent preset is configured as a table Then preset defaults are merged with overrides",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agent = {
					preset = "codex",
					cmd = { "codex", "--model", "gpt-5.4-mini" },
					resume = {
						all = false,
					},
				},
			})

			assert.are.same({ "codex", "--model", "gpt-5.4-mini" }, opts.agent.cmd)
			assert.are.equal("paste", opts.agent.context.mode)
			assert.are.same({ "codex", "resume" }, opts.agent.resume.default)
			assert.is_false(opts.agent.resume.all)
			assert.are.same({ "codex", "resume", "--last" }, opts.agent.resume.last)
		end
	)

	it("When backend is a preset string alias Then it maps to the same preset defaults", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			backend = "aider",
		})

		assert.are.same({ "aider" }, opts.agent.cmd)
		assert.are.same({ "aider", "--restore-chat-history" }, opts.agent.resume.default)
		assert.is_false(opts.agent.resume.all)
		assert.is_false(opts.agent.resume.last)
	end)

	it("When agent is set to copilot Then paste context is used with resume support", function()
		local config = require("agent_term.setup.runtime_config")
		local enums = require("agent_term.enums")
		local opts = config.setup({
			agent = enums.agent.COPILOT,
		})

		assert.are.same({ "copilot" }, opts.agent.cmd)
		assert.are.equal("paste", opts.agent.context.mode)
		assert.are.same({ "copilot", "--resume" }, opts.agent.resume.default)
		assert.is_false(opts.agent.resume.all)
		assert.are.same({ "copilot", "--continue" }, opts.agent.resume.last)
		assert.is_true(config.has_resume("default"))
		assert.is_false(config.has_resume("all"))
		assert.is_true(config.has_resume("last"))
	end)

	it("When agent is set to opencode Then paste context is used with continue support", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = "opencode",
		})

		assert.are.same({ "opencode" }, opts.agent.cmd)
		assert.are.equal("paste", opts.agent.context.mode)
		assert.is_false(opts.agent.resume.default)
		assert.is_false(opts.agent.resume.all)
		assert.are.same({ "opencode", "--continue" }, opts.agent.resume.last)
		assert.is_false(config.has_resume("default"))
		assert.is_false(config.has_resume("all"))
		assert.is_true(config.has_resume("last"))
	end)

	it("When agent cmd is custom without preset Then neutral backend defaults are used", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agent = {
				cmd = { "gemini" },
			},
		})

		assert.are.same({ "gemini" }, opts.agent.cmd)
		assert.is_false(opts.agent.resume)
		assert.are.equal("paste", opts.agent.context.mode)
		assert.is_false(config.has_resume("default"))
	end)

	it(
		"When custom agent opts explicitly configure context and resume Then they are preserved",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agent = {
					cmd = { "custom-agent" },
					context = {
						mode = "hook",
					},
					resume = {
						default = { "custom-agent", "resume" },
					},
				},
			})

			assert.are.same({ "custom-agent" }, opts.agent.cmd)
			assert.are.equal("hook", opts.agent.context.mode)
			assert.are.same({ "custom-agent", "resume" }, opts.agent.resume.default)
			assert.is_false(opts.agent.resume.all)
			assert.is_false(opts.agent.resume.last)
		end
	)

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
				resume = {
					default = "resume",
				},
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
		assert.are.same({ "codex", "resume" }, opts.agent.resume.default)
		assert.are.equal("paste", opts.agent.context.mode)
		assert.are.equal(".agent-term/context.json", opts.context.file_path)
		assert.are.equal(0.85, opts.float.width)
		assert.are.equal("right", opts.panel.position)
		assert.are.equal(0.35, opts.panel.height)
		assert.are.equal("default", opts.context.target_view)
		assert.is_true(opts.context.include_cursor)
		assert.is_true(#notifications >= 8)
	end)
end)
