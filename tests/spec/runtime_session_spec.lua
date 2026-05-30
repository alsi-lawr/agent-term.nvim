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

		config = require("agent_term.setup.runtime_config")
		config.setup({
			agent = "codex",
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

	it("When auto resume is false Then the configured interactive command starts", function()
		local started_cmd
		config.setup({
			agent = {
				preset = "gemini",
				auto_resume = false,
			},
		})
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			started_cmd = cmd
			return 88
		end

		local buf = session.ensure_session()

		assert.is_true(vim.api.nvim_buf_is_valid(buf))
		assert.are.same({ "gemini" }, started_cmd)
	end)

	it("When auto resume uses picker mode Then startup uses the preset picker command", function()
		local started_cmd
		config.setup({
			agent = {
				preset = "codex",
				auto_resume = "picker",
			},
		})
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			started_cmd = cmd
			return 89
		end

		local buf = session.ensure_session()

		assert.is_true(vim.api.nvim_buf_is_valid(buf))
		assert.are.same({ "codex", "resume" }, started_cmd)
	end)

	it("When auto resume uses last mode Then startup appends preset args to the command", function()
		local started_cmd
		config.setup({
			agent = {
				preset = "codex",
				cmd = { "codex", "--model", "gpt-5.4-mini" },
				auto_resume = "last",
			},
		})
		vim.fn.executable = function(_)
			return 1
		end
		vim.fn.jobstart = function(cmd, _)
			started_cmd = cmd
			return 90
		end

		local buf = session.ensure_session()

		assert.is_true(vim.api.nvim_buf_is_valid(buf))
		assert.are.same({ "codex", "--model", "gpt-5.4-mini", "resume", "--last" }, started_cmd)
	end)

	it(
		"When auto resume is configured for a custom command Then startup uses the custom command",
		function()
			local started_cmd
			config.setup({
				agent = {
					cmd = { "my-agent" },
					auto_resume = "last",
				},
			})
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				started_cmd = cmd
				return 91
			end

			local buf = session.ensure_session()

			assert.is_true(vim.api.nvim_buf_is_valid(buf))
			assert.are.same({ "my-agent" }, started_cmd)
		end
	)

	it(
		"When auto resume mode is unavailable for a preset Then startup uses the normal command",
		function()
			local started_cmd
			config.setup({
				agent = {
					preset = "opencode",
					auto_resume = "picker",
				},
			})
			vim.fn.executable = function(_)
				return 1
			end
			vim.fn.jobstart = function(cmd, _)
				started_cmd = cmd
				return 92
			end

			local buf = session.ensure_session()

			assert.is_true(vim.api.nvim_buf_is_valid(buf))
			assert.are.same({ "opencode" }, started_cmd)
		end
	)
end)
