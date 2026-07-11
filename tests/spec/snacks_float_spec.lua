local reload = require("tests.helpers.reload")

describe("Given configurable float hosts", function()
	local config
	local float
	local state
	local original_loaded_snacks
	local original_preload_snacks
	local original_notify
	local notifications
	local bufs_to_delete

	local function track_buf(buf)
		bufs_to_delete[#bufs_to_delete + 1] = buf
		return buf
	end

	local function close_if_valid(win)
		if win and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	local function setup(host, float_opts)
		float_opts = vim.tbl_extend("force", float_opts or {}, { host = host })
		config.setup({
			agents = {
				codex = { preset = "codex" },
			},
			float = float_opts,
		})
	end

	local function make_fake_snacks()
		local fake = { instances = {} }

		function fake.win(opts)
			local instance = {
				buf = opts.buf,
				focus_calls = 0,
				hide_calls = 0,
				opts = opts,
				show_calls = 0,
				update_calls = 0,
			}

			function instance:show()
				self.show_calls = self.show_calls + 1
				self.win = vim.api.nvim_open_win(self.buf, opts.enter, {
					relative = opts.relative,
					style = "minimal",
					border = opts.border,
					width = opts.width(),
					height = opts.height(),
					row = 1,
					col = 1,
					title = opts.title,
					title_pos = opts.title_pos,
				})
				return self
			end

			function instance:hide()
				self.hide_calls = self.hide_calls + 1
				local win = self.win
				if opts.on_close then
					opts.on_close(self)
				end
				self.win = nil
				close_if_valid(win)
				return self
			end

			function instance:focus()
				self.focus_calls = self.focus_calls + 1
				vim.api.nvim_set_current_win(self.win)
			end

			function instance:update()
				self.update_calls = self.update_calls + 1
			end

			function instance:close_externally()
				close_if_valid(self.win)
				if opts.on_close then
					opts.on_close(self)
				end
			end

			instance:show()
			fake.instances[#fake.instances + 1] = instance
			return instance
		end

		return fake
	end

	before_each(function()
		original_loaded_snacks = package.loaded.snacks
		original_preload_snacks = package.preload.snacks
		original_notify = vim.notify
		package.loaded.snacks = nil
		package.preload.snacks = nil
		notifications = {}
		bufs_to_delete = {}
		vim.notify = function(message, level)
			notifications[#notifications + 1] = { message = message, level = level }
		end

		reload.clear_agent_term_modules()
		config = require("agent_term.setup.runtime_config")
		state = require("agent_term.runtime.state")
		float = require("agent_term.ui.float")
	end)

	after_each(function()
		state.each_session(function(name, session)
			close_if_valid(session.float_win)
			state.reset_float_win(name)
		end)
		for _, buf in ipairs(bufs_to_delete) do
			if vim.api.nvim_buf_is_valid(buf) then
				pcall(vim.api.nvim_buf_delete, buf, { force = true })
			end
		end

		vim.notify = original_notify
		package.preload.snacks = original_preload_snacks
		package.loaded.snacks = original_loaded_snacks
		reload.clear_agent_term_modules()
	end)

	it("When the native host is selected Then snacks.nvim is not loaded", function()
		local load_count = 0
		package.preload.snacks = function()
			load_count = load_count + 1
			return make_fake_snacks()
		end
		setup("native")

		local buf = track_buf(vim.api.nvim_create_buf(false, true))
		float.open(buf, "codex")

		assert.are.equal(0, load_count)
	end)

	it("When the Snacks host is selected Then it wraps and preserves the terminal buffer", function()
		local fake = make_fake_snacks()
		package.preload.snacks = function()
			return fake
		end
		setup("snacks", {
			width = 0.5,
			height = 0.4,
			border = "double",
		})

		local buf = track_buf(vim.api.nvim_create_buf(false, true))
		local win = float.open(buf, "codex")
		local instance = fake.instances[1]

		assert.are.equal(buf, instance.opts.buf)
		assert.are.equal(buf, vim.api.nvim_win_get_buf(win))
		assert.are.equal(win, state.session("codex").float_win)
		assert.are.equal(math.floor(vim.o.columns * 0.5), instance.opts.width())
		assert.are.equal(math.floor(vim.o.lines * 0.4), instance.opts.height())
		assert.are.equal("double", instance.opts.border)
		assert.are.equal(60, instance.opts.backdrop)
		assert.is_true(instance.opts.resize)
		assert.is_true(instance.opts.enter)
		assert.is_false(instance.opts.keys.q)
		assert.are.same({ { " Agent Term · codex ", "SnacksTitle" } }, instance.opts.title)

		assert.are.equal(win, float.open(buf, "codex"))
		assert.are.equal(1, instance.focus_calls)
		float.reconcile_layout()
		assert.are.equal(1, instance.update_calls)

		float.close("codex")
		assert.are.equal(1, instance.hide_calls)
		assert.is_nil(state.session("codex").float_win)
		assert.is_true(vim.api.nvim_buf_is_valid(buf))

		local reopened = float.open(buf, "codex")
		assert.is_true(vim.api.nvim_win_is_valid(reopened))
		assert.are.equal(2, instance.show_calls)
		assert.are.equal(1, #fake.instances)
	end)

	it("When Snacks cannot load Then a warning is issued and the native host is used", function()
		package.preload.snacks = function()
			error("snacks unavailable")
		end
		setup("snacks")

		local buf = track_buf(vim.api.nvim_create_buf(false, true))
		local win = float.open(buf, "codex")

		assert.is_true(vim.api.nvim_win_is_valid(win))
		assert.are.equal(buf, vim.api.nvim_win_get_buf(win))
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
		assert.match("requires snacks.nvim", notifications[1].message, 1, true)
		assert.match("falling back to the native float host", notifications[1].message, 1, true)

		assert.are.equal(win, float.open(buf, "codex"))
		assert.are.equal(1, #notifications)
	end)

	it("When a Snacks window closes externally Then its host callback clears float state", function()
		local fake = make_fake_snacks()
		package.preload.snacks = function()
			return fake
		end
		setup("snacks")

		local buf = track_buf(vim.api.nvim_create_buf(false, true))
		local win = float.open(buf, "codex")

		fake.instances[1]:close_externally()

		assert.is_false(vim.api.nvim_win_is_valid(win))
		assert.is_nil(state.session("codex").float_win)
	end)
end)
