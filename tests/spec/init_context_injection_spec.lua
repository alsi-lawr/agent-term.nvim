---@diagnostic disable: undefined-field
local reload = require("tests.helpers.reload")

describe("Given panel silent context injection", function()
	local state
	local plugin
	local source_buf
	local terminal_buf
	local sent_messages
	local notifications
	local original_cwd
	local temp_dir

	local function close_if_valid(win)
		if win and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	local function read_context_file()
		local path = temp_dir .. "/.agent-term/context.json"
		local lines = vim.fn.readfile(path)
		return vim.json.decode(table.concat(lines, "\n"))
	end

	before_each(function()
		reload.clear_agent_term_modules()
		notifications = {}
		sent_messages = {}
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
		original_cwd = vim.fn.getcwd()
		temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		vim.cmd.cd(vim.fn.fnameescape(temp_dir))

		source_buf = vim.api.nvim_create_buf(true, false)
		terminal_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(source_buf)
		vim.api.nvim_buf_set_name(source_buf, "/tmp/panel-source.lua")
		vim.bo[source_buf].filetype = "lua"
		vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, { "a", "b", "c", "d", "e" })
		vim.api.nvim_buf_set_mark(source_buf, "<", 4, 0, {})
		vim.api.nvim_buf_set_mark(source_buf, ">", 2, 0, {})

		package.loaded["agent_term.runtime.session"] = {
			ensure_session = function(_)
				local s = require("agent_term.runtime.state")
				s.buf = terminal_buf
				s.job_id = 111
				return terminal_buf
			end,
			send = function(text)
				sent_messages[#sent_messages + 1] = text
				return true
			end,
			close_views = function() end,
			kill = function() end,
			start_resume = function(_)
				return nil
			end,
		}

		package.loaded["agent_term.hooks.installers.codex"] = {
			is_installed = function()
				return true
			end,
			install = function()
				return true, { files = {}, changed = false }
			end,
		}

		plugin = require("agent_term")
		state = require("agent_term.runtime.state")
	end)

	after_each(function()
		close_if_valid(state and state.float_win)
		close_if_valid(state and state.panel_win)
		if original_cwd then
			vim.cmd.cd(vim.fn.fnameescape(original_cwd))
		end
		if temp_dir then
			vim.fn.delete(temp_dir, "rf")
		end
		if source_buf and vim.api.nvim_buf_is_valid(source_buf) then
			pcall(vim.api.nvim_buf_delete, source_buf, { force = true })
		end
		if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
			pcall(vim.api.nvim_buf_delete, terminal_buf, { force = true })
		end
		reload.clear_agent_term_modules()
	end)

	it("When panel opens Then it captures buffer context before current buffer changes", function()
		plugin.setup({ context = { target_view = "panel" } })
		plugin.panel_open()

		assert.are.equal(terminal_buf, vim.api.nvim_get_current_buf())
		assert.is_not_nil(state.last_captured_context)
		assert.is_not_nil(state.last_captured_context.buffer:match("file: /tmp/panel%-source%.lua"))
	end)

	it("When panel opens Then it captures selection context before focus changes", function()
		plugin.setup({ context = { target_view = "panel" } })
		plugin.panel_open()

		assert.is_not_nil(state.last_captured_context)
		assert.is_not_nil(state.last_captured_context.selection:match("selection: lines 2%-4"))
	end)

	it("When sending context from panel Then submission uses last captured context", function()
		plugin.setup({
			context = { target_view = "panel" },
			agent = {
				context = {
					mode = "paste",
				},
			},
		})
		plugin.panel_open()
		vim.api.nvim_buf_set_name(terminal_buf, "/tmp/panel-terminal.txt")

		plugin.send_buffer_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
		assert.is_nil(sent_messages[1]:match("panel%-terminal"))
	end)

	it("When buffer context starts a default float Then source buffer context is sent", function()
		plugin.setup({
			agent = {
				context = {
					mode = "paste",
				},
			},
		})
		state.buf = nil
		state.job_id = nil

		plugin.send_buffer_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
		assert.is_nil(sent_messages[1]:match("type: diagnostics"))
	end)

	it(
		"When selection context starts a default float Then source selection context is sent",
		function()
			plugin.setup({
				agent = {
					context = {
						mode = "paste",
					},
				},
			})
			state.buf = nil
			state.job_id = nil

			plugin.send_selection_context({})

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("type: selection"))
			assert.is_not_nil(sent_messages[1]:match("selection: lines 2%-4"))
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
		end
	)

	it(
		"When a panel is open but source window is focused Then current buffer context is sent",
		function()
			plugin.setup({
				context = { target_view = "panel" },
				agent = {
					context = {
						mode = "paste",
					},
				},
			})
			local source_win = vim.api.nvim_get_current_win()
			plugin.panel_open()

			local other_buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(other_buf, "/tmp/current-source.lua")
			vim.api.nvim_buf_set_lines(other_buf, 0, -1, false, { "current" })
			vim.api.nvim_set_current_win(source_win)
			vim.api.nvim_set_current_buf(other_buf)

			plugin.send_buffer_context()

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/current%-source%.lua"))
			assert.is_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))

			pcall(vim.api.nvim_buf_delete, other_buf, { force = true })
		end
	)

	it("When normal navigation returns to panel Then the latest source buffer is captured", function()
		plugin.setup({
			context = { target_view = "panel" },
			agent = {
				context = {
					mode = "paste",
				},
			},
		})
		local source_win = vim.api.nvim_get_current_win()
		plugin.panel_open()

		local latest_buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(latest_buf, "/tmp/latest-source.lua")
		vim.api.nvim_buf_set_lines(latest_buf, 0, -1, false, { "latest" })
		vim.api.nvim_set_current_win(source_win)
		vim.api.nvim_set_current_buf(latest_buf)
		vim.api.nvim_set_current_win(state.panel_win)

		plugin.send_buffer_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/latest%-source%.lua"))
		assert.is_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))

		pcall(vim.api.nvim_buf_delete, latest_buf, { force = true })
	end)

	it("When no context has been captured Then panel submission is handled cleanly", function()
		plugin.setup({ context = { target_view = "panel" } })
		plugin.panel_open()
		state.last_captured_context = nil

		plugin.send_buffer_context()

		assert.are.equal(0, #sent_messages)
		assert.are.equal("info", notifications[#notifications].level)
		assert.is_not_nil(
			notifications[#notifications].msg:match("No captured editor context available")
		)
	end)

	it(
		"When diagnostics are sent from a focused panel Then captured source diagnostics are sent",
		function()
			local ns = vim.api.nvim_create_namespace("agent_term-panel-diag")
			vim.diagnostic.set(ns, source_buf, {
				{
					lnum = 1,
					col = 2,
					severity = vim.diagnostic.severity.ERROR,
					source = "lua_ls",
					message = "bad call",
				},
			})
			plugin.setup({
				context = { target_view = "panel" },
				agent = {
					context = {
						mode = "paste",
					},
				},
			})
			plugin.panel_open()

			plugin.send_diagnostics_context()

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("type: diagnostics"))
			assert.is_not_nil(sent_messages[1]:match("lua_ls: bad call"))
		end
	)

	it("When diagnostics context starts a default float Then source diagnostics are sent", function()
		local ns = vim.api.nvim_create_namespace("agent_term-float-diag")
		vim.diagnostic.set(ns, source_buf, {
			{
				lnum = 2,
				col = 0,
				severity = vim.diagnostic.severity.WARN,
				source = "stylua",
				message = "format",
			},
		})
		plugin.setup({
			agent = {
				context = {
					mode = "paste",
				},
			},
		})
		state.buf = nil
		state.job_id = nil

		plugin.send_diagnostics_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("type: diagnostics"))
		assert.is_not_nil(sent_messages[1]:match("stylua: format"))
	end)

	it("When diagnostics context opens a target panel Then source diagnostics are sent", function()
		local ns = vim.api.nvim_create_namespace("agent_term-target-panel-diag")
		vim.diagnostic.set(ns, source_buf, {
			{
				lnum = 3,
				col = 1,
				severity = vim.diagnostic.severity.INFO,
				source = "test",
				message = "note",
			},
		})
		plugin.setup({
			context = { target_view = "panel" },
			agent = {
				context = {
					mode = "paste",
				},
			},
		})
		state.buf = nil
		state.job_id = nil

		plugin.send_diagnostics_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("type: diagnostics"))
		assert.is_not_nil(sent_messages[1]:match("test: note"))
	end)

	it("When hook mode is enabled Then context is written instead of visibly pasted", function()
		plugin.setup({
			context = { target_view = "panel" },
			agent = {
				context = {
					mode = "hook",
				},
			},
		})
		plugin.panel_open()

		plugin.send_buffer_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
	end)

	it("When hook mode starts a default float Then source context is written", function()
		plugin.setup({
			agent = {
				context = {
					mode = "hook",
				},
			},
		})
		state.buf = nil
		state.job_id = nil

		plugin.send_buffer_context()

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
	end)

	it(
		"When hook mode has a panel open but source is focused Then current source context is written",
		function()
			plugin.setup({
				context = { target_view = "panel" },
				agent = {
					context = {
						mode = "hook",
					},
				},
			})
			local source_win = vim.api.nvim_get_current_win()
			plugin.panel_open()

			local other_buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(other_buf, "/tmp/hook-source.lua")
			vim.api.nvim_buf_set_lines(other_buf, 0, -1, false, { "hooked" })
			vim.api.nvim_set_current_win(source_win)
			vim.api.nvim_set_current_buf(other_buf)

			plugin.send_buffer_context()

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/hook%-source%.lua"))
			assert.is_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))

			pcall(vim.api.nvim_buf_delete, other_buf, { force = true })
		end
	)

	it(
		"When hook mode sends selection context from a panel Then captured selection is written",
		function()
			plugin.setup({
				context = { target_view = "panel" },
				agent = {
					context = {
						mode = "hook",
					},
				},
			})
			plugin.panel_open()

			plugin.send_selection_context({})

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("selection: lines 2%-4"))
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
		end
	)
end)
