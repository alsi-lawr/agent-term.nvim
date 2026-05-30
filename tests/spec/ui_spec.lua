local reload = require("tests.helpers.reload")

describe("Given Agent Term UI views", function()
	local state
	local config
	local float
	local panel
	local bufs_to_delete = {}

	local function track_buf(bufnr)
		bufs_to_delete[#bufs_to_delete + 1] = bufnr
		return bufnr
	end

	local function close_if_valid(win)
		if win and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	before_each(function()
		reload.clear_agent_term_modules()
		config = require("agent_term.setup.runtime_config")
		config.setup()
		state = require("agent_term.runtime.state")
		float = require("agent_term.ui.float")
		panel = require("agent_term.ui.panel")
	end)

	after_each(function()
		close_if_valid(state.float_win)
		close_if_valid(state.panel_win)
		state.reset_float_win()
		state.reset_panel_win()

		for _, bufnr in ipairs(bufs_to_delete) do
			if vim.api.nvim_buf_is_valid(bufnr) then
				pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
			end
		end
		bufs_to_delete = {}
		reload.clear_agent_term_modules()
	end)

	it(
		"When opening and closing the float Then it reuses valid windows and recovers from stale ones",
		function()
			local bufnr = track_buf(vim.api.nvim_create_buf(false, true))

			local first = float.open(bufnr)
			assert.is_true(vim.api.nvim_win_is_valid(first))
			assert.are.equal(first, state.float_win)

			local second = float.open(bufnr)
			assert.are.equal(first, second)
			assert.are.equal(second, vim.api.nvim_get_current_win())

			vim.api.nvim_win_close(first, true)
			local recovered = float.open(bufnr)
			assert.is_true(vim.api.nvim_win_is_valid(recovered))
			assert.are_not.equal(first, recovered)
			assert.are.equal(recovered, state.float_win)

			float.close()
			assert.is_nil(state.float_win)
		end
	)

	it("When opening and closing the panel Then focus and lifecycle state stay consistent", function()
		config.setup({
			panel = {
				position = "bottom",
				height = 0.3,
			},
		})

		local bufnr = track_buf(vim.api.nvim_create_buf(false, true))
		local win = panel.open(bufnr)

		assert.is_true(vim.api.nvim_win_is_valid(win))
		assert.are.equal(win, state.panel_win)
		assert.are.equal(bufnr, vim.api.nvim_win_get_buf(win))
		assert.is_true(panel.focus())
		assert.are.equal(win, vim.api.nvim_get_current_win())

		panel.close()
		assert.is_nil(state.panel_win)
		assert.is_false(panel.focus())
	end)
end)
