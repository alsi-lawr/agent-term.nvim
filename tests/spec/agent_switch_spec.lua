local reload = require("tests.helpers.reload")

describe("Given runtime agent switching", function()
	local original_executable = vim.fn.executable
	local original_jobstart = vim.fn.jobstart
	local original_jobwait = vim.fn.jobwait
	local original_jobstop = vim.fn.jobstop
	local original_notify = vim.notify
	local original_stdpath = vim.fn.stdpath
	local temp_state
	local notifications

	local function state_file()
		return vim.fn.stdpath("state") .. "/agent-term/active-agent"
	end

	before_each(function()
		reload.clear_agent_term_modules()
		temp_state = vim.fn.tempname()
		vim.fn.mkdir(temp_state, "p")
		vim.fn.stdpath = function(what)
			if what == "state" then
				return temp_state
			end
			return original_stdpath(what)
		end
		pcall(vim.fn.delete, state_file())
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
	end)

	after_each(function()
		vim.fn.executable = original_executable
		vim.fn.jobstart = original_jobstart
		vim.fn.jobwait = original_jobwait
		vim.fn.jobstop = original_jobstop
		vim.notify = original_notify
		pcall(vim.fn.delete, state_file())
		vim.fn.stdpath = original_stdpath
		if temp_state then
			vim.fn.delete(temp_state, "rf")
		end
		reload.clear_agent_term_modules()
	end)

	local function setup_plugin()
		local plugin = require("agent_term")
		plugin.setup({
			active_agent = "codex",
			agents = {
				codex = { cmd = { "codex" } },
				agy = { cmd = { "agy" } },
			},
		})
		return plugin
	end

	it("When AgentTermSwitch is called with no args Then it reports the current agent", function()
		setup_plugin()

		vim.cmd.AgentTermSwitch()

		assert.are.equal(vim.log.levels.INFO, notifications[#notifications].level)
		assert.match("Active agent: codex", notifications[#notifications].msg)
	end)

	it("When AgentTermSwitch is called with an agent Then it switches and persists", function()
		setup_plugin()
		vim.fn.executable = function(exe)
			return exe == "agy" and 1 or 0
		end

		vim.cmd("AgentTermSwitch agy")

		local config = require("agent_term.setup.runtime_config")
		assert.are.equal("agy", config.active_agent)
		assert.are.same({ "agy" }, vim.fn.readfile(state_file()))
	end)

	it("When completing AgentTermSwitch Then only configured agent names are returned", function()
		setup_plugin()

		local completion = vim.fn.getcompletion("AgentTermSwitch ", "cmdline")

		assert.are.same({ "agy", "codex" }, completion)
	end)

	it(
		"When switching while a panel is open Then the same view type is opened for the target agent",
		function()
			setup_plugin()
			local starts = {}
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				starts[#starts + 1] = cmd
				return 300 + #starts
			end
			vim.fn.jobwait = function(ids, _)
				return ids[1] >= 301 and { -1 } or { 0 }
			end

			vim.cmd.AgentTermPanelOpen()
			local state = require("agent_term.runtime.state")
			local codex_win = state.session("codex").panel_win
			vim.cmd("AgentTermSwitch agy")

			assert.is_false(vim.api.nvim_win_is_valid(codex_win))
			assert.is_true(vim.api.nvim_win_is_valid(state.session("agy").panel_win))
			assert.are.same({ "codex" }, starts[1])
			assert.are.same({ "agy" }, starts[2])
			assert.are.equal(301, state.session("codex").job_id)
			assert.are.equal(302, state.session("agy").job_id)
		end
	)

	it(
		"When switching back to an existing agent session Then the existing session is preserved",
		function()
			setup_plugin()
			local starts = {}
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				starts[#starts + 1] = cmd
				return 400 + #starts
			end
			vim.fn.jobwait = function(ids, _)
				return ids[1] >= 401 and { -1 } or { 0 }
			end

			vim.cmd.AgentTermFloatOpen()
			vim.cmd("AgentTermSwitch agy")
			vim.cmd("AgentTermSwitch codex")

			local state = require("agent_term.runtime.state")
			assert.are.equal(2, #starts)
			assert.are.equal(401, state.session("codex").job_id)
			assert.are.equal(402, state.session("agy").job_id)
		end
	)

	it("When AgentTermSwitch bang is used Then only the target agent session is recreated", function()
		setup_plugin()
		local starts = {}
		local stopped = {}
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			starts[#starts + 1] = cmd
			return 500 + #starts
		end
		vim.fn.jobwait = function(ids, _)
			return ids[1] >= 501 and { -1 } or { 0 }
		end
		vim.fn.jobstop = function(job_id)
			stopped[#stopped + 1] = job_id
			return 1
		end

		vim.cmd.AgentTermFloatOpen()
		vim.cmd("AgentTermSwitch agy")
		vim.cmd("AgentTermSwitch! codex")

		local state = require("agent_term.runtime.state")
		assert.are.same({ 501 }, stopped)
		assert.are.equal(503, state.session("codex").job_id)
		assert.are.equal(502, state.session("agy").job_id)
	end)

	it(
		"When AgentTermSwitch bang is used without a view Then the target session is recreated",
		function()
			setup_plugin()
			local starts = {}
			local stopped = {}
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				starts[#starts + 1] = cmd
				return 600 + #starts
			end
			vim.fn.jobwait = function(ids, _)
				return ids[1] >= 601 and { -1 } or { 0 }
			end
			vim.fn.jobstop = function(job_id)
				stopped[#stopped + 1] = job_id
				return 1
			end

			local terminal = require("agent_term.runtime.session")
			terminal.ensure_session(nil, "codex")

			vim.cmd("AgentTermSwitch! codex")

			local state = require("agent_term.runtime.state")
			assert.are.same({ "codex" }, starts[1])
			assert.are.same({ "codex" }, starts[2])
			assert.are.same({ 601 }, stopped)
			assert.are.equal(602, state.session("codex").job_id)
			assert.is_nil(state.session("codex").float_win)
			assert.is_nil(state.session("codex").panel_win)
		end
	)
end)
