local reload = require("tests.helpers.reload")

describe("Given keymap name helpers", function()
	after_each(function()
		reload.clear_codex_modules()
	end)

	it("When checking known names Then is_known returns true only for supported keymaps", function()
		local keymaps = require("codex.keymaps")

		assert.is_true(keymaps.is_known("float_toggle"))
		assert.is_true(keymaps.is_known("send_selection_context"))
		assert.is_false(keymaps.is_known("unknown_action"))
	end)

	it("When listing unknown names Then only unsupported keymaps are returned", function()
		local keymaps = require("codex.keymaps")
		local unknown = keymaps.get_unknown_names({
			float_toggle = "<leader>ct",
			unknown_z = "<leader>z",
			unknown_a = "<leader>a",
		})

		assert.are.same({ "unknown_a", "unknown_z" }, unknown)
	end)
end)
