---@diagnostic disable: undefined-field
local reload = require("tests.helpers.reload")

local function state_file()
	return vim.fn.stdpath("state") .. "/agent-term/active-agent"
end

local function clear_persisted_agent()
	pcall(vim.fn.delete, state_file())
end

describe("Given multi-agent configuration", function()
	local original_notify = vim.notify
	local original_stdpath = vim.fn.stdpath
	local temp_state
	local notifications

	before_each(function()
		temp_state = vim.fn.tempname()
		vim.fn.mkdir(temp_state, "p")
		vim.fn.stdpath = function(what)
			if what == "state" then
				return temp_state
			end
			return original_stdpath(what)
		end
		clear_persisted_agent()
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
	end)

	after_each(function()
		clear_persisted_agent()
		vim.fn.stdpath = original_stdpath
		if temp_state then
			vim.fn.delete(temp_state, "rf")
		end
		vim.notify = original_notify
		reload.clear_agent_term_modules()
	end)

	it("When setup is called with no options Then codex is the default configured agent", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup()

		assert.are.same({ "codex" }, opts.agents.codex.cmd)
		assert.are.equal("codex", opts.agents.codex.preset)
		assert.are.equal("codex", config.active_agent)
		assert.is_false(opts.agents.codex.context.hook.enabled)
		assert.are.equal("native", opts.float.host)
		assert.are.equal("rounded", opts.float.border)
		assert.is_false(opts.keymaps)
	end)

	it("When an invalid float host is configured Then the native host remains active", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			float = { host = "popup" },
		})

		assert.are.equal("native", opts.float.host)
		assert.match("Invalid agent%-term%.nvim config `float.host` ignored", notifications[1].msg)
	end)

	it(
		"When agents are configured Then presets, overrides, and per-agent context are expanded",
		function()
			local config = require("agent_term.setup.runtime_config")
			local opts = config.setup({
				agents = {
					codex = {
						preset = "codex",
						cmd = { "codex", "--model", "gpt-5.4-mini" },
						auto_resume = "last",
						context = { hook = { enabled = true } },
					},
					agy = {
						preset = "agy",
						context = { include_cursor = false },
					},
					custom = {
						cmd = { "my-agent" },
					},
				},
			})

			assert.are.same({ "codex", "--model", "gpt-5.4-mini" }, opts.agents.codex.cmd)
			assert.are.equal("last", opts.agents.codex.auto_resume)
			assert.is_true(opts.agents.codex.context.hook.enabled)
			assert.are.same({ "agy" }, opts.agents.agy.cmd)
			assert.is_false(opts.agents.agy.context.include_cursor)
			assert.is_true(opts.agents.agy.context.include_file_path)
			assert.are.same({ "my-agent" }, opts.agents.custom.cmd)
			assert.is_nil(opts.agents.custom.preset)
		end
	)

	it("When agents include preset list entries Then they expand to named agents", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agents = {
				"claude",
				"codex",
				agy = {
					preset = "agy",
					auto_resume = "last",
				},
			},
		})

		assert.are.same({ "claude" }, opts.agents.claude.cmd)
		assert.are.equal("claude", opts.agents.claude.preset)
		assert.are.same({ "codex" }, opts.agents.codex.cmd)
		assert.are.equal("codex", opts.agents.codex.preset)
		assert.are.same({ "agy" }, opts.agents.agy.cmd)
		assert.are.equal("last", opts.agents.agy.auto_resume)
			assert.is_nil(opts.agents[1])
			assert.is_nil(opts.agents[2])
			assert.are.same({ "agy", "claude", "codex" }, config.agent_names())
	end)

	it("When preset list entries duplicate named agents Then explicit named config wins", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agents = {
				"agy",
				agy = {
					preset = "agy",
					cmd = { "agy", "--yolo" },
				},
			},
		})

		assert.are.same({ "agy", "--yolo" }, opts.agents.agy.cmd)
		assert.is_nil(opts.agents[1])
	end)

	it(
		"When no persisted agent exists Then the deterministic first configured agent is active",
		function()
			local config = require("agent_term.setup.runtime_config")
			config.setup({
				agents = {
					agy = { preset = "agy" },
					codex = { preset = "codex" },
				},
			})

			assert.are.equal("agy", config.active_agent)
		end
	)

	it("When a persisted active agent is valid Then it is loaded", function()
		vim.fn.mkdir(vim.fn.fnamemodify(state_file(), ":h"), "p")
		vim.fn.writefile({ "agy" }, state_file())

		local config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { preset = "codex" },
				agy = { preset = "agy" },
			},
		})

		assert.are.equal("agy", config.active_agent)
		assert.are.same({}, notifications)
	end)

	it("When a persisted active agent is invalid Then setup warns and falls back", function()
		vim.fn.mkdir(vim.fn.fnamemodify(state_file(), ":h"), "p")
		vim.fn.writefile({ "missing" }, state_file())

		local config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { preset = "codex" },
				agy = { preset = "agy" },
			},
		})

			assert.are.equal("agy", config.active_agent)
		assert.are.equal(1, #notifications)
		assert.match("Persisted active agent `missing` is no longer configured", notifications[1].msg)
	end)

	it("When unknown config keys are provided Then they are stripped and warned", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agents = {
				codex = {
					preset = "codex",
					transport = "hook",
				},
			},
			experimental = true,
		})

		assert.is_nil(opts.experimental)
		assert.is_nil(opts.agents.codex.transport)
		assert.are.equal(2, #notifications)
		assert.match(
			"Unknown agent%-term%.nvim config keys ignored: experimental",
			notifications[1].msg
		)
		assert.match(
			"Unknown agent%-term%.nvim config keys ignored in `agents.codex`: transport",
			notifications[2].msg
		)
	end)

	it("When invalid agent values are provided Then defaults remain safe", function()
		local config = require("agent_term.setup.runtime_config")
		local opts = config.setup({
			agents = {
				codex = {
					preset = "codex",
					cmd = "codex",
					auto_resume = "yes",
					context = { include_cursor = "yes" },
				},
			},
			panel = { position = "middle" },
		})

		assert.are.same({ "codex" }, opts.agents.codex.cmd)
		assert.is_nil(opts.agents.codex.auto_resume)
		assert.is_true(opts.agents.codex.context.include_cursor)
		assert.are.equal("right", opts.panel.position)
		assert.is_true(#notifications >= 4)
	end)

	it("When config resolves to no agents Then setup notifies and fails", function()
		local config = require("agent_term.setup.runtime_config")

		assert.has_error(function()
			config.setup({ agents = { "typo" } })
		end, "agent-term.nvim config must define at least one valid agent.")
		assert.match("Unknown agent preset `typo`", notifications[1].msg)
		assert.are.equal(
			"agent-term.nvim config must define at least one valid agent.",
			notifications[#notifications].msg
		)
	end)

	it("When active agent is switched Then it validates and persists the selection", function()
		local config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { cmd = { "codex" } },
				agy = { cmd = { "agy" } },
			},
		})
		local original_executable = vim.fn.executable
		vim.fn.executable = function(exe)
			return exe == "agy" and 1 or 0
		end

		assert.is_true(config.set_active_agent("agy"))
		assert.are.equal("agy", config.active_agent)
		assert.are.same({ "agy" }, vim.fn.readfile(state_file()))

		vim.fn.executable = original_executable
	end)

	it("When target executable is missing Then switch fails and is not persisted", function()
		local config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { cmd = { "codex" } },
				agy = { cmd = { "agy" } },
			},
		})
		local original_executable = vim.fn.executable
		vim.fn.executable = function(_)
			return 0
		end

			assert.is_false(config.set_active_agent("agy"))
			assert.are.equal("agy", config.active_agent)
		assert.are.equal(0, vim.fn.filereadable(state_file()))
		assert.match("Agent command not found: agy", notifications[#notifications].msg)

		vim.fn.executable = original_executable
	end)
end)
