local reload = require("tests.helpers.reload")

describe("Given Agent Term runtime session management", function()
	local config
	local state
	local session

	local original_executable = vim.fn.executable
	local original_jobstart = vim.fn.jobstart
	local original_jobwait = vim.fn.jobwait
	local original_jobstop = vim.fn.jobstop
	local original_chan_send = vim.api.nvim_chan_send

	local notifications

	local function reset_runtime_state()
		if state then
			if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
				pcall(vim.api.nvim_win_close, state.float_win, true)
			end
			if state.panel_win and vim.api.nvim_win_is_valid(state.panel_win) then
				pcall(vim.api.nvim_win_close, state.panel_win, true)
			end
			if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
				pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
			end
			state.reset_float_win()
			state.reset_panel_win()
			state.reset_terminal()
		end
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

		config = require("agent_term.config")
		config.setup({
			agent = {
				cmd = { "codex" },
				resume = {
					default = { "codex", "resume" },
					all = { "codex", "resume", "--all" },
					last = { "codex", "resume", "--last" },
				},
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

		reset_runtime_state()
		reload.clear_agent_term_modules()
	end)

	it(
		"When the configured Agent Term executable is missing Then session start fails with a user-visible error",
		function()
			vim.fn.executable = function(_)
				return 0
			end

			local buf = session.ensure_session({ "missing-agent" })

			assert.is_nil(buf)
			assert.is_nil(state.buf)
			assert.is_nil(state.job_id)
			assert.are.equal(1, #notifications)
			assert.are.equal("error", notifications[1].level)
			assert.match("Agent command not found: missing%-agent", notifications[1].msg)
		end
	)

	it("When jobstart fails Then terminal state is cleaned up and the failure is reported", function()
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(_, _)
			return 0
		end

		local buf = session.ensure_session({ "codex" })

		assert.is_nil(buf)
		assert.is_nil(state.buf)
		assert.is_nil(state.job_id)
		assert.are.equal("error", notifications[#notifications].level)
		assert.match("Failed to start agent command: codex", notifications[#notifications].msg)
	end)

	it(
		"When a session starts successfully Then send works for running jobs and kill clears process and buffer state",
		function()
			local sent
			local stopped_job
			local started_cmd

			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, opts)
				started_cmd = cmd
				assert.is_true(opts.term)
				return 77
			end
			vim.fn.jobwait = function(ids, _)
				if ids[1] == 77 then
					return { -1 }
				end
				return { 0 }
			end
			vim.api.nvim_chan_send = function(job_id, text)
				sent = { job_id = job_id, text = text }
			end
			vim.fn.jobstop = function(job_id)
				stopped_job = job_id
				return 1
			end

			local buf = session.ensure_session({ "codex", "--version" })
			assert.is_true(vim.api.nvim_buf_is_valid(buf))
			assert.are.same({ "codex", "--version" }, started_cmd)
			assert.are.equal(buf, state.buf)
			assert.are.equal(77, state.job_id)

			assert.is_true(session.send("hello\n"))
			assert.are.same({ job_id = 77, text = "hello\n" }, sent)

			session.kill()
			assert.are.equal(77, stopped_job)
			assert.is_nil(state.buf)
			assert.is_nil(state.job_id)
		end
	)

	it(
		"When configured for Gemini Then the interactive command starts without resume support",
		function()
			local started_cmd
			config.setup({
				agent = {
					cmd = { "gemini" },
					resume = false,
				},
			})
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				started_cmd = cmd
				return 88
			end
			vim.fn.jobwait = function(ids, _)
				return { ids[1] == 88 and -1 or 0 }
			end

			local buf = session.ensure_session()

			assert.is_true(vim.api.nvim_buf_is_valid(buf))
			assert.are.same({ "gemini" }, started_cmd)
			assert.is_false(config.has_resume("default"))
		end
	)

	it("When resuming while already running Then it refuses and asks user to kill first", function()
		state.job_id = 55
		vim.fn.jobwait = function(ids, _)
			return { ids[1] == 55 and -1 or 0 }
		end

		local buf = session.start_resume("all")

		assert.is_nil(buf)
		assert.are.equal("warn", notifications[#notifications].level)
		assert.match("Run :AgentTermKill first", notifications[#notifications].msg)
	end)

	it(
		"When a resume capability is disabled Then it returns nil and reports a clear error",
		function()
			vim.fn.jobwait = function(_, _)
				return { 0 }
			end
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

			local buf = session.start_resume("all")

			assert.is_nil(buf)
			assert.are.equal("error", notifications[#notifications].level)
			assert.match("Resume capability is not configured: all", notifications[#notifications].msg)
		end
	)
end)
