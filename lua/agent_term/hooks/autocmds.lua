local context_builder = require("agent_term.context.builder")
local context_file = require("agent_term.context.file")
local config = require("agent_term.setup.runtime_config")
local state = require("agent_term.runtime.state")

local M = {}
local augroup = vim.api.nvim_create_augroup("agent_term_hooks", { clear = true })

local function auto_hook_enabled()
	local context = config.options.context
	local hook = type(context) == "table" and context.hook or nil
	return type(hook) == "table" and hook.enabled == true
end

local function is_editor_buffer(bufnr)
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	return bufnr ~= state.buf and vim.bo[bufnr].buftype == ""
end

local function update_context()
	if not auto_hook_enabled() or not state.has_running_job() then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not is_editor_buffer(bufnr) then
		return
	end

	local opts = config.options.context

	-- Priority: diagnostics > selection > file
	if opts.include_diagnostics then
		local diag_msg = context_builder.diagnostics_message()
		if diag_msg then
			context_file.write("diagnostics", diag_msg)
			return
		end
	end

	-- For selection, we check if it should be included and if a selection exists
	local sel_msg = context_builder.selection_message({})
	if sel_msg then
		context_file.write("selection", sel_msg)
		return
	end

	local buf_msg = context_builder.buffer_message()
	if buf_msg then
		context_file.write("buffer", buf_msg)
	end
end

local function clear_context()
	if not auto_hook_enabled() then
		return
	end
	-- Mark stale by writing empty content. The python hook script
	-- checks for empty content and returns 0 (no context) in that case.
	context_file.write("buffer", "")
end

function M.setup()
	vim.api.nvim_clear_autocmds({ group = augroup })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
		group = augroup,
		callback = function()
			update_context()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
		group = augroup,
		callback = function()
			-- Small delay to ensure we don't clear if we are just switching buffers
			-- and another BufEnter is about to fire.
			-- Actually, BufDelete is for the buffer being removed.
			-- If it's the current buffer, we might want to clear.
			clear_context()
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = augroup,
		pattern = { "[vV\x16sS]:*", "*:[vV\x16sS]" },
		callback = function()
			local mode = vim.api.nvim_get_mode().mode
			-- If we are no longer in any visual or select mode, we just left it.
			if not mode:find("^[vV\x16sS]") then
				update_context()
			end
		end,
	})

	-- Also update when diagnostics change, as they might arrive after BufEnter
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = augroup,
		callback = function()
			update_context()
		end,
	})
end

return M
