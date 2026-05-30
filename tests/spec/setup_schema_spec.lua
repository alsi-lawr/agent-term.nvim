local reload = require("tests.helpers.reload")

describe("Given setup schema helpers", function()
	after_each(function()
		reload.clear_agent_term_modules()
	end)

	it("When collecting unknown names Then only keys rejected by the checker are returned", function()
		local schema = require("agent_term.setup.schema")
		local unknown = schema.get_unknown_names({
			a = 1,
			b = 2,
			c = 3,
		}, function(name)
			return name == "a" or name == "c"
		end)

		assert.are.same({ "b" }, unknown)
	end)

	it("When stripping unknown names Then those keys are removed from the table", function()
		local schema = require("agent_term.setup.schema")
		local input = { keep = 1, drop_a = true, drop_b = true }

		schema.strip_unknown_names(input, { "drop_a", "drop_b" })

		assert.are.same({ keep = 1 }, input)
	end)
end)
