---@diagnostic disable: undefined-field
local reload = require("tests.helpers.reload")

describe("Given configuration setup", function()
	local original_notify = vim.notify
	local notifications

	before_each(function()
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
	end)

	after_each(function()
		vim.notify = original_notify
		reload.clear_codex_modules()
	end)

	it("When setup is called with no user options Then defaults are exposed unchanged", function()
		local config = require("codex.config")
		local opts = config.setup()

		assert.are.same({ "codex" }, opts.codex.cmd)
		assert.are.equal("right", opts.panel.position)
		assert.are.equal("default", opts.context.target_view)
		assert.is_false(opts.keymaps)
	end)

	it("When unknown config keys are provided Then they are stripped and users are warned", function()
		local config = require("codex.config")
		local opts = config.setup({
			codex = {
				cmd = { "codex", "--unsafe-shape" },
				bogus_cmd_key = true,
			},
			panel = {
				position = "bottom",
			},
			context = {
				target_view = "default",
				include_cursor = false,
			},
			experimental = { flag = true },
		})

		assert.are.same({ "codex", "--unsafe-shape" }, opts.codex.cmd)
		assert.are.equal("bottom", opts.panel.position)
		assert.are.equal("default", opts.context.target_view)
		assert.is_false(opts.context.include_cursor)
		assert.is_nil(opts.codex.bogus_cmd_key)
		assert.is_nil(opts.experimental)
		assert.are.equal(2, #notifications)
		assert.match("Unknown codex.nvim config keys ignored: experimental", notifications[1].msg)
		assert.match(
			"Unknown codex.nvim config keys ignored in `codex`: bogus_cmd_key",
			notifications[2].msg
		)
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
		assert.are.equal(vim.log.levels.WARN, notifications[2].level)
	end)

	it("When unknown keymaps are configured Then they are stripped and warned", function()
		local config = require("codex.config")
		local opts = config.setup({
			keymaps = {
				float_toggle = "<leader>ct",
				unknown_action = "<leader>xx",
			},
		})

		assert.are.equal("<leader>ct", opts.keymaps.float_toggle)
		assert.is_nil(opts.keymaps.unknown_action)
		assert.are.equal(1, #notifications)
		assert.match("Unknown codex.nvim keymaps ignored: unknown_action", notifications[1].msg)
		assert.are.equal(vim.log.levels.WARN, notifications[1].level)
	end)

	it("When keymaps is explicitly disabled Then setup preserves keymaps = false", function()
		local config = require("codex.config")
		local opts = config.setup({
			keymaps = false,
		})

		assert.is_false(opts.keymaps)
		assert.are.same({}, notifications)
	end)

	it(
		"When only part of a nested table is overridden Then defaults remain for unspecified keys",
		function()
			local config = require("codex.config")
			local opts = config.setup({
				context = {
					include_file_path = false,
				},
				panel = {
					width = 80,
				},
			})

			assert.is_false(opts.context.include_file_path)
			assert.is_true(opts.context.include_filetype)
			assert.is_true(opts.context.include_cursor)
			assert.are.equal(80, opts.panel.width)
			assert.are.equal(0.35, opts.panel.height)
			assert.are.equal("rounded", opts.float.border)
		end
	)
end)
