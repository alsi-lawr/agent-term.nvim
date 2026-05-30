local reload = require("tests.helpers.reload")

describe("Given AgentTermIgnore", function()
	local original_cwd
	local original_notify
	local temp_dir
	local notifications
	local repo_root

	local function read(path)
		return table.concat(vim.fn.readfile(path), "\n")
	end

	before_each(function()
		reload.clear_agent_term_modules()
		original_cwd = vim.fn.getcwd()
		repo_root = original_cwd
		original_notify = vim.notify
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
		temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		vim.cmd.cd(vim.fn.fnameescape(temp_dir))
		vim.opt.runtimepath:prepend(repo_root)
	end)

	after_each(function()
		vim.notify = original_notify
		vim.cmd.cd(vim.fn.fnameescape(original_cwd))
		vim.fn.delete(temp_dir, "rf")
		reload.clear_agent_term_modules()
	end)

	it("When .gitignore is missing Then it creates it with /.agent-term/", function()
		local plugin = require("agent_term")
		plugin.setup()

		vim.cmd.AgentTermIgnore()

		assert.are.equal(1, vim.fn.filereadable(".gitignore"))
		assert.are.equal("/.agent-term/", read(".gitignore"))
	end)

	it("When entry is absent Then it appends /.agent-term/", function()
		vim.fn.writefile({ "*.log" }, ".gitignore")
		local plugin = require("agent_term")
		plugin.setup()

		vim.cmd.AgentTermIgnore()

		assert.is_true(read(".gitignore"):match("/%.agent%-term/") ~= nil)
	end)

	it("When entry already exists Then file is unchanged", function()
		vim.fn.writefile({ "*.log", "/.agent-term/" }, ".gitignore")
		local before = read(".gitignore")
		local plugin = require("agent_term")
		plugin.setup()

		vim.cmd.AgentTermIgnore()

		assert.are.equal(before, read(".gitignore"))
		assert.are.equal(vim.log.levels.INFO, notifications[#notifications].level)
	end)
end)
