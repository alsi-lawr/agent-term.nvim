local reload = require("tests.helpers.reload")

describe("Given native agent hook installation", function()
	local original_cwd
	local original_home
	local original_notify
	local temp_dir
	local notifications

	local function path(...)
		return table.concat({ temp_dir, ... }, "/")
	end

	local function read_json(file)
		local lines = vim.fn.readfile(file)
		return vim.json.decode(table.concat(lines, "\n"))
	end

	before_each(function()
		reload.clear_agent_term_modules()
		original_cwd = vim.fn.getcwd()
		original_notify = vim.notify
		notifications = {}
		vim.notify = function(msg, level)
			notifications[#notifications + 1] = { msg = msg, level = level }
		end
		original_home = vim.env.HOME
		temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		vim.env.HOME = temp_dir
		vim.cmd.cd(vim.fn.fnameescape(temp_dir))
	end)

	after_each(function()
		vim.notify = original_notify
		vim.env.HOME = original_home
		vim.cmd.cd(vim.fn.fnameescape(original_cwd))
		vim.fn.delete(temp_dir, "rf")
		reload.clear_agent_term_modules()
	end)

	it("When installing Codex hooks Then global hook config and script are written", function()
		local plugin = require("agent_term")
		plugin.setup({ agent = "codex" })

		assert.is_true(plugin.install_hooks())

		local hooks = read_json(path(".codex/hooks.json"))
		local handler = hooks.hooks.UserPromptSubmit[1].hooks[1]
		assert.are.equal("command", handler.type)
		assert.is_not_nil(handler.command:match("%.codex/hooks/agent_term_context%.py"))
		assert.is_not_nil(handler.command:match("%$PWD/.agent%-term/context%.json"))
		assert.is_true(require("agent_term.setup.runtime_config").options.context.hook.enabled)
		assert.are.equal(1, vim.fn.filereadable(path(".codex/hooks/agent_term_context.py")))
	end)

	it(
		"When the installed context script runs Then it emits UserPromptSubmit additionalContext",
		function()
			local plugin = require("agent_term")
			plugin.setup({ agent = "codex" })
			plugin.install_hooks()
			vim.fn.mkdir(path(".agent-term"), "p")
			vim.fn.writefile({
				vim.json.encode({
					version = 1,
					kind = "buffer",
					content = "file: /tmp/example.lua",
				}),
			}, path(".agent-term/context.json"))

			local output = vim.fn.system({
				"python3",
				path(".codex/hooks/agent_term_context.py"),
				path(".agent-term/context.json"),
			})

			assert.are.equal(0, vim.v.shell_error)
			local payload = vim.json.decode(output)
			assert.are.equal("UserPromptSubmit", payload.hookSpecificOutput.hookEventName)
			assert.are.equal("file: /tmp/example.lua", payload.hookSpecificOutput.additionalContext)
		end
	)

	it(
		"When AgentTermInstallHooks runs for Claude Then it dispatches to the Claude installer",
		function()
			local plugin = require("agent_term")
			plugin.setup({ agent = "claude" })

			vim.cmd.AgentTermInstallHooks()

			local settings = read_json(path(".claude/settings.json"))
			local handler = settings.hooks.UserPromptSubmit[1].hooks[1]
			assert.are.equal("command", handler.type)
			assert.are.equal("python3", handler.command)
			assert.are.equal(path(".claude/hooks/agent_term_context.py"), handler.args[1])
			assert.are.equal("${CLAUDE_PROJECT_DIR}/.agent-term/context.json", handler.args[2])
			assert.are.equal(1, vim.fn.filereadable(path(".claude/hooks/agent_term_context.py")))
		end
	)

	it("When global hook entries already exist Then install leaves config unchanged", function()
		local plugin = require("agent_term")
		plugin.setup({ agent = "codex" })
		assert.is_true(plugin.install_hooks())

		local hooks_path = path(".codex/hooks.json")
		local first_mtime = vim.fn.getftime(hooks_path)
		vim.wait(1100)

		assert.is_true(plugin.install_hooks())
		local second_mtime = vim.fn.getftime(hooks_path)
		assert.are.equal(first_mtime, second_mtime)
	end)

	it(
		"When AgentTermInstallHooks runs for Gemini Then it dispatches to the Gemini installer",
		function()
			local plugin = require("agent_term")
			plugin.setup({ agent = "gemini" })

			vim.cmd.AgentTermInstallHooks()

			local settings = read_json(path(".gemini/settings.json"))
			local handler = settings.hooks.BeforeModel[1].hooks[1]
			assert.are.equal("command", handler.type)
			assert.is_not_nil(handler.command:match("%.gemini/hooks/agent_term_context%.py"))
			assert.are.equal(1, vim.fn.filereadable(path(".gemini/hooks/agent_term_context.py")))
		end
	)

	it(
		"When installing hooks for an unsupported agent Then it warns and writes no hook files",
		function()
			local plugin = require("agent_term")
			plugin.setup({ agent = "aider" })

			assert.is_false(plugin.install_hooks())

			assert.are.equal(0, vim.fn.isdirectory(path(".codex")))
			assert.are.equal(0, vim.fn.isdirectory(path(".claude")))
			assert.are.equal(0, vim.fn.isdirectory(path(".gemini")))
			assert.are.equal(vim.log.levels.WARN, notifications[1].level)
			assert.is_not_nil(notifications[1].msg:match("not supported for `aider`"))
		end
	)
end)
