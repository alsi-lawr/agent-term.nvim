local reload = require("tests.helpers.reload")

describe("Given Agent Term UI views", function()
	local state
	local config
	local float
	local panel
	local bufs_to_delete = {}
	local original_columns
	local original_lines

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
		original_columns = vim.o.columns
		original_lines = vim.o.lines
		reload.clear_agent_term_modules()
		config = require("agent_term.setup.runtime_config")
		config.setup({
			agents = {
				codex = { preset = "codex" },
				agy = { preset = "agy" },
			},
		})
		state = require("agent_term.runtime.state")
		float = require("agent_term.ui.float")
		panel = require("agent_term.ui.panel")
	end)

	after_each(function()
		state.each_session(function(name, session)
			close_if_valid(session.float_win)
			close_if_valid(session.panel_win)
			state.reset_float_win(name)
			state.reset_panel_win(name)
		end)

		for _, bufnr in ipairs(bufs_to_delete) do
			if vim.api.nvim_buf_is_valid(bufnr) then
				pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
			end
		end
		bufs_to_delete = {}
		vim.o.columns = original_columns
		vim.o.lines = original_lines
		reload.clear_agent_term_modules()
	end)

	it("When opening and closing the float Then state is tracked per agent", function()
		local codex_buf = track_buf(vim.api.nvim_create_buf(false, true))
		local agy_buf = track_buf(vim.api.nvim_create_buf(false, true))

		local first = float.open(codex_buf, "codex")
		assert.is_true(vim.api.nvim_win_is_valid(first))
		assert.are.equal(first, state.session("codex").float_win)

		local second = float.open(codex_buf, "codex")
		assert.are.equal(first, second)

		local agy = float.open(agy_buf, "agy")
		assert.are.equal(agy, state.session("agy").float_win)
		assert.are_not.equal(first, agy)

		float.close("codex")
		assert.is_nil(state.session("codex").float_win)
		assert.are.equal(agy, state.session("agy").float_win)
	end)

	it("When opening the native float Then its rounded frame and title identify the agent", function()
		local bufnr = track_buf(vim.api.nvim_create_buf(false, true))
		local win = float.open(bufnr, "codex")
		local win_config = vim.api.nvim_win_get_config(win)
		local window_highlights = vim.api.nvim_get_option_value("winhighlight", { win = win })

		assert.are.equal("rounded", config.options.float.border)
		assert.are.same({ "╭", "─", "╮", "│", "╯", "─", "╰", "│" }, win_config.border)
		assert.are.same({ { " Agent Term · codex ", "AgentTermFloatTitle" } }, win_config.title)
		assert.are.equal("center", win_config.title_pos)
		assert.matches("Normal:AgentTermFloat", window_highlights, 1, true)
		assert.matches("FloatBorder:AgentTermFloatBorder", window_highlights, 1, true)
		assert.matches("FloatTitle:AgentTermFloatTitle", window_highlights, 1, true)
		assert.are.equal(
			"Normal",
			vim.api.nvim_get_hl(0, { name = "AgentTermFloat", link = true }).link
		)
		assert.are.equal(
			"Normal",
			vim.api.nvim_get_hl(0, { name = "AgentTermFloatBorder", link = true }).link
		)
		assert.are.equal(
			"Title",
			vim.api.nvim_get_hl(0, { name = "AgentTermFloatTitle", link = true }).link
		)
	end)

	it("When Neovim dimensions change Then the native float is resized and recentered", function()
		config.setup({
			agents = {
				codex = { preset = "codex" },
			},
			float = {
				width = 0.5,
				height = 0.5,
			},
		})

		local bufnr = track_buf(vim.api.nvim_create_buf(false, true))
		local win = float.open(bufnr, "codex")
		vim.o.columns = original_columns + 20
		vim.o.lines = original_lines + 10

		float.reconcile_layout()

		local win_config = vim.api.nvim_win_get_config(win)
		local expected_width = math.floor(vim.o.columns * 0.5)
		local expected_height = math.floor(vim.o.lines * 0.5)
		assert.are.equal(expected_width, win_config.width)
		assert.are.equal(expected_height, win_config.height)
		assert.are.equal(math.floor((vim.o.lines - expected_height) / 2), win_config.row)
		assert.are.equal(math.floor((vim.o.columns - expected_width) / 2), win_config.col)
	end)

	it("When opening and closing the panel Then focus and lifecycle state stay per agent", function()
		config.setup({
			agents = {
				codex = { preset = "codex" },
			},
			panel = {
				position = "bottom",
				height = 0.3,
			},
		})

		local bufnr = track_buf(vim.api.nvim_create_buf(false, true))
		local win = panel.open(bufnr, "codex")

		assert.is_true(vim.api.nvim_win_is_valid(win))
		assert.are.equal(win, state.session("codex").panel_win)
		assert.are.equal(bufnr, vim.api.nvim_win_get_buf(win))
		assert.is_true(panel.focus("codex"))
		assert.are.equal(win, vim.api.nvim_get_current_win())

		panel.close("codex")
		assert.is_nil(state.session("codex").panel_win)
		assert.is_false(panel.focus("codex"))
	end)

	it(
		"When external layout changes resize a side panel Then the configured width is restored",
		function()
			config.setup({
				agents = {
					codex = { preset = "codex" },
				},
				panel = {
					position = "right",
					width = 0.35,
				},
			})

			local bufnr = track_buf(vim.api.nvim_create_buf(false, true))
			local win = panel.open(bufnr, "codex")
			local expected = math.max(1, math.floor(vim.o.columns * 0.35))

			vim.api.nvim_win_set_width(win, math.max(1, expected - 10))
			panel.reconcile_layout()

			assert.are.equal(expected, vim.api.nvim_win_get_width(win))
		end
	)
end)
