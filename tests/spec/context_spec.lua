---@diagnostic disable: need-check-nil
local reload = require("tests.helpers.reload")

describe("Given context message builders", function()
	local bufnr

	before_each(function()
		reload.clear_codex_modules()
		bufnr = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(bufnr)
	end)

	after_each(function()
		if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
		end
		reload.clear_codex_modules()
	end)

	it("When building buffer context Then ambient metadata and visible range are included", function()
		local config = require("codex.config")
		config.setup({
			context = {
				include_file_path = true,
				include_filetype = true,
				include_cursor = true,
			},
		})

		vim.api.nvim_buf_set_name(bufnr, "/tmp/context-buffer.lua")
		vim.bo[bufnr].filetype = "lua"
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "one", "two", "three", "four" })
		vim.api.nvim_win_set_cursor(0, { 2, 1 })

		local context = require("codex.context.builder")
		local message = context.buffer_message()

		assert.is_not_nil(message:match("type: buffer"))
		assert.is_not_nil(message:match("file: /tmp/context%-buffer%.lua"))
		assert.is_not_nil(message:match("filetype: lua"))
		assert.is_not_nil(message:match("cursor: line 2, column 2"))
		assert.is_not_nil(message:match("visible_range: lines 1%-4"))
		assert.is_not_nil(message:match("</neovim%-context>\n$"))
	end)

	it(
		"When selection context is invoked with a command range Then the explicit range wins",
		function()
			local config = require("codex.config")
			config.setup({
				context = {
					include_file_path = false,
					include_filetype = false,
					include_selection_range = true,
				},
			})

			local context = require("codex.context.builder")
			local message = context.selection_message({ range = 2, line1 = 9, line2 = 3 })

			assert.is_not_nil(message)
			assert.is_not_nil(message:match("type: selection"))
			assert.is_not_nil(message:match("selection: lines 3%-9"))
			assert.is_nil(message:match("file:"))
			assert.is_nil(message:match("filetype:"))
		end
	)

	it(
		"When selection context has no command range Then visual marks are used, else a clear error is returned",
		function()
			local config = require("codex.config")
			config.setup()

			local context = require("codex.context.builder")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				"a",
				"b",
				"c",
				"d",
				"e",
				"f",
				"g",
				"h",
				"i",
				"j",
			})

			vim.api.nvim_buf_set_mark(bufnr, "<", 8, 0, {})
			vim.api.nvim_buf_set_mark(bufnr, ">", 2, 0, {})
			local message = context.selection_message({})
			assert.is_not_nil(message)
			assert.is_not_nil(message:match("selection: lines 2%-8"))

			vim.api.nvim_buf_set_mark(bufnr, "<", 0, 0, {})
			vim.api.nvim_buf_set_mark(bufnr, ">", 0, 0, {})
			local missing, err = context.selection_message({})
			assert.is_nil(missing)
			assert.are.equal("No visual selection range found. Reselect and retry.", err)
		end
	)

	it(
		"When diagnostics exist Then diagnostics context includes formatted diagnostics from current buffer",
		function()
			local config = require("codex.config")
			config.setup({
				context = {
					include_file_path = false,
					include_filetype = false,
					include_diagnostics = true,
				},
			})

			local ns = vim.api.nvim_create_namespace("codex-tests-context-diag")
			vim.diagnostic.set(ns, bufnr, {
				{
					lnum = 2,
					col = 3,
					severity = vim.diagnostic.severity.ERROR,
					source = "lua_ls",
					message = "bad token",
				},
				{
					lnum = 7,
					col = 0,
					severity = vim.diagnostic.severity.WARN,
					source = "stylua",
					message = "trailing space",
				},
			})

			local context = require("codex.context.builder")

			local message = context.diagnostics_message()
			assert.is_not_nil(message)
			assert.is_not_nil(message:match("type: diagnostics"))
			assert.is_not_nil(message:match("diagnostics:\n%- line 3, col 4, ERROR, lua_ls: bad token"))
			assert.is_not_nil(message:match("%- line 8, col 1, WARN, stylua: trailing space"))
		end
	)

	it(
		"When no diagnostics are present Then diagnostics context returns a practical no-op error",
		function()
			local config = require("codex.config")
			config.setup()
			local context = require("codex.context.builder")

			local message, err = context.diagnostics_message()
			assert.is_nil(message)
			assert.are.equal("No diagnostics in current buffer.", err)
		end
	)
end)
