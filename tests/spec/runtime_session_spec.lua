local reload = require("tests.helpers.reload")

describe("Given Agent Term per-agent runtime sessions", function()
	local config
	local state
	local session

	local original_executable = vim.fn.executable
	local original_jobstart = vim.fn.jobstart
	local original_jobwait = vim.fn.jobwait
	local original_jobstop = vim.fn.jobstop
	local original_chan_send = vim.api.nvim_chan_send
	local notifications

	local function clear_state()
		if not state then
			return
		end
		state.each_session(function(name, entry)
			if entry.float_win and vim.api.nvim_win_is_valid(entry.float_win) then
				pcall(vim.api.nvim_win_close, entry.float_win, true)
			end
			if entry.panel_win and vim.api.nvim_win_is_valid(entry.panel_win) then
				pcall(vim.api.nvim_win_close, entry.panel_win, true)
			end
			if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then
				pcall(vim.api.nvim_buf_delete, entry.buf, { force = true })
			end
			state.reset_float_win(name)
			state.reset_panel_win(name)
			state.reset_terminal(name)
		end)
	end

	before_each(function()
		reload.clear_agent_term_modules()
		notifications = {}
		package.loaded["agent_term.notify"] = {
			info = function(msg)
				notifications[#notifications + 1] = { level = "info", msg = msg }
			end,
			warn = function(msg)
				notifications[#notifications + 1] = { level = "warn", msg = msg }
			end,
			error = function(msg)
				notifications[#notifications + 1] = { level = "error", msg = msg }
			end,
		}
		config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { preset = "codex" },
				agy = { preset = "agy" },
			},
		})
		state = require("agent_term.runtime.state")
		session = require("agent_term.runtime.session")
	end)

	after_each(function()
		vim.fn.executable = original_executable
		vim.fn.jobstart = original_jobstart
		vim.fn.jobwait = original_jobwait
		vim.fn.jobstop = original_jobstop
		vim.api.nvim_chan_send = original_chan_send
		clear_state()
		reload.clear_agent_term_modules()
	end)

	it("When an executable is missing Then session start fails with a user-visible error", function()
		vim.fn.executable = function(_)
			return 0
		end

		local buf = session.ensure_session({ "missing-agent" }, "codex")

		assert.is_nil(buf)
		assert.is_nil(state.session("codex").buf)
		assert.is_nil(state.session("codex").job_id)
		assert.are.equal("error", notifications[#notifications].level)
		assert.match("Agent command not found: missing%-agent", notifications[#notifications].msg)
	end)

	it("When jobstart fails Then only the target agent state is cleaned up", function()
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(_, _)
			return 0
		end

		local buf = session.ensure_session({ "codex" }, "codex")

		assert.is_nil(buf)
		assert.is_nil(state.session("codex").buf)
		assert.is_nil(state.session("codex").job_id)
		assert.match("Failed to start agent command: codex", notifications[#notifications].msg)
	end)

	it("When different agents start Then each keeps an independent session", function()
		local starts = {}
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			starts[#starts + 1] = cmd
			return 70 + #starts
		end
		vim.fn.jobwait = function(ids, _)
			return ids[1] >= 71 and ids[1] <= 72 and { -1 } or { 0 }
		end

		local codex_buf = session.ensure_session(nil, "codex")
		local agy_buf = session.ensure_session(nil, "agy")
		local codex_again = session.ensure_session(nil, "codex")

		assert.are.equal(codex_buf, codex_again)
		assert.are_not.equal(codex_buf, agy_buf)
		assert.are.equal(71, state.session("codex").job_id)
		assert.are.equal(72, state.session("agy").job_id)
		assert.are.same({ "codex" }, starts[1])
		assert.are.same({ "agy" }, starts[2])
	end)

	it("When sending text Then it targets the active agent session", function()
		local sent
		config.active_agent = "agy"
		state.session("agy").job_id = 99
		vim.fn.jobwait = function(ids, _)
			return ids[1] == 99 and { -1 } or { 0 }
		end
		vim.api.nvim_chan_send = function(job_id, text)
			sent = { job_id = job_id, text = text }
		end

		assert.is_true(session.send("hello\n"))
		assert.are.same({ job_id = 99, text = "hello\n" }, sent)
	end)

	it("When killing an agent Then unrelated agent sessions survive", function()
		local stopped
		state.session("codex").job_id = 101
		state.session("agy").job_id = 202
		vim.fn.jobstop = function(job_id)
			stopped = job_id
			return 1
		end

		session.kill("agy")

		assert.are.equal(202, stopped)
		assert.are.equal(101, state.session("codex").job_id)
		assert.is_nil(state.session("agy").job_id)
	end)

	it("When auto-resume is configured per agent Then startup uses that agent's mode", function()
		local starts = {}
		config.setup({
			agents = {
				codex = {
					preset = "codex",
					cmd = { "codex", "--model", "gpt-5.4-mini" },
					auto_resume = "last",
				},
				agy = {
					preset = "agy",
					auto_resume = "picker",
				},
				custom = {
					cmd = { "my-agent" },
					auto_resume = "last",
				},
			},
		})
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			starts[#starts + 1] = cmd
			return 80 + #starts
		end

		session.ensure_session(nil, "codex")
		session.ensure_session(nil, "agy")
		session.ensure_session(nil, "custom")

		assert.are.same({ "codex", "--model", "gpt-5.4-mini", "resume", "--last" }, starts[1])
		assert.are.same({ "agy", "--continue" }, starts[2])
		assert.are.same({ "my-agent" }, starts[3])
	end)
end)
