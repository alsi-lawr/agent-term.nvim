---@diagnostic disable: undefined-field
local reload = require("tests.helpers.reload")

describe("Given panel context injection with active agents", function()
	local context_commands
	local enums
	local state
	local plugin
	local view_controller
	local source_buf
	local terminal_buf
	local sent_messages
	local notifications

	local function close_if_valid(win)
		if win and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	local function setup_plugin(context_opts)
		plugin.setup({
			agents = {
				codex = {
					cmd = { "codex" },
					context = context_opts or {},
				},
			},
		})
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

		source_buf = vim.api.nvim_create_buf(true, false)
		terminal_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(source_buf)
		vim.api.nvim_buf_set_name(source_buf, "/tmp/panel-source.lua")
		vim.bo[source_buf].filetype = "lua"
		vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, { "a", "b", "c", "d", "e" })
		vim.api.nvim_buf_set_mark(source_buf, "<", 4, 0, {})
		vim.api.nvim_buf_set_mark(source_buf, ">", 2, 0, {})

		package.loaded["agent_term.runtime.session"] = {
			ensure_session = function(_, agent_name)
				local s = require("agent_term.runtime.state")
				local entry = s.session(agent_name)
				entry.buf = terminal_buf
				entry.job_id = 111
				return terminal_buf
			end,
			send = function(text)
				sent_messages[#sent_messages + 1] = text
				return true
			end,
			close_views = function() end,
			close_all_views_except = function() end,
			kill = function() end,
		}

		plugin = require("agent_term")
		context_commands = require("agent_term.context.commands")
		enums = require("agent_term.enums")
		state = require("agent_term.runtime.state")
		view_controller = require("agent_term.ui.controller")
	end)

	after_each(function()
		state.each_session(function(_, session)
			close_if_valid(session.float_win)
			close_if_valid(session.panel_win)
		end)
		if source_buf and vim.api.nvim_buf_is_valid(source_buf) then
			pcall(vim.api.nvim_buf_delete, source_buf, { force = true })
		end
		if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
			pcall(vim.api.nvim_buf_delete, terminal_buf, { force = true })
		end
		reload.clear_agent_term_modules()
	end)

	it("When panel opens Then it captures source context before focus changes", function()
		setup_plugin({ target_view = "panel" })
		view_controller.open(enums.view.PANEL)

		assert.are.equal(terminal_buf, vim.api.nvim_get_current_buf())
		assert.is_not_nil(state.last_captured_context)
		assert.is_not_nil(state.last_captured_context.buffer:match("file: /tmp/panel%-source%.lua"))
		assert.is_not_nil(state.last_captured_context.selection:match("selection: lines 2%-4"))
	end)

	it(
		"When sending context from a focused panel Then the last captured source context is sent",
		function()
			setup_plugin({ target_view = "panel" })
			view_controller.open(enums.view.PANEL)
			vim.api.nvim_buf_set_name(terminal_buf, "/tmp/panel-terminal.txt")

			context_commands.send_buffer_context()

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
			assert.is_nil(sent_messages[1]:match("panel%-terminal"))
		end
	)

	it(
		"When source window is focused while panel exists Then current source context is sent",
		function()
			setup_plugin({ target_view = "panel" })
			local source_win = vim.api.nvim_get_current_win()
			view_controller.open(enums.view.PANEL)

			local other_buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(other_buf, "/tmp/current-source.lua")
			vim.api.nvim_buf_set_lines(other_buf, 0, -1, false, { "current" })
			vim.api.nvim_set_current_win(source_win)
			vim.api.nvim_set_current_buf(other_buf)

			context_commands.send_buffer_context()

			assert.are.equal(1, #sent_messages)
			assert.is_not_nil(sent_messages[1]:match("file: /tmp/current%-source%.lua"))
			assert.is_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))

			pcall(vim.api.nvim_buf_delete, other_buf, { force = true })
		end
	)

	it("When per-agent hook updates are enabled Then manual commands still paste context", function()
		setup_plugin({
			target_view = "panel",
			hook = { enabled = true },
		})
		view_controller.open(enums.view.PANEL)

		context_commands.send_selection_context({})

		assert.are.equal(1, #sent_messages)
		assert.is_not_nil(sent_messages[1]:match("selection: lines 2%-4"))
		assert.is_not_nil(sent_messages[1]:match("file: /tmp/panel%-source%.lua"))
	end)
end)
