local reload = require("tests.helpers.reload")

describe("Given diagnostics formatting", function()
	local bufnr

	before_each(function()
		reload.clear_agent_term_modules()
		bufnr = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(bufnr)
	end)

	after_each(function()
		if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
		end
		reload.clear_agent_term_modules()
	end)

	it(
		"When diagnostics are formatted Then line and column become 1-based with readable fields",
		function()
			local ns = vim.api.nvim_create_namespace("agent_term-tests-diagnostics")
			vim.diagnostic.set(ns, bufnr, {
				{
					lnum = 1,
					col = 2,
					severity = vim.diagnostic.severity.ERROR,
					source = "lua_ls",
					code = "E100",
					message = "first line\nsecond line",
				},
				{
					lnum = 0,
					col = 0,
					severity = 999,
					message = "missing source and code",
				},
			})

			local diagnostics = require("agent_term.context.diagnostics")
			local out = diagnostics.format_for_buffer(bufnr)

			assert.are.same({
				"- line 2, col 3, ERROR, lua_ls [E100]: first line second line",
				"- line 1, col 1, UNKNOWN, unknown: missing source and code",
			}, out)
		end
	)
end)
