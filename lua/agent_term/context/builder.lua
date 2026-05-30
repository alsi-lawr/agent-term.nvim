local config = require("agent_term.config")
local diagnostics = require("agent_term.context.diagnostics")

local M = {}

local AMBIENT_INTRO = {
	"<neovim-context>",
	"This is ambient context from the user's current Neovim editor state.",
	"Do not assume the user wants to work on this %s unless their next prompt says or implies that.",
	"Use this only as additional context when relevant.",
	"",
}

local function push(lines, text)
	lines[#lines + 1] = text
end

local function make_header(kind)
	return {
		AMBIENT_INTRO[1],
		AMBIENT_INTRO[2],
		AMBIENT_INTRO[3]:format(kind),
		AMBIENT_INTRO[4],
		AMBIENT_INTRO[5],
	}
end

local function file_path(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	return path ~= "" and path or "[No Name]"
end

local function filetype(bufnr)
	local ft = vim.bo[bufnr].filetype
	return ft ~= "" and ft or ""
end

local function cursor_line()
	local pos = vim.api.nvim_win_get_cursor(0)
	return pos[1], pos[2] + 1
end

local function visible_range()
	local top = vim.fn.line("w0")
	local bottom = vim.fn.line("w$")
	if top <= 0 or bottom <= 0 then
		return nil, nil
	end
	return math.min(top, bottom), math.max(top, bottom)
end

local function command_line_range(opts)
	if not (opts and opts.range and opts.range > 0) then
		return nil, nil
	end
	return math.min(opts.line1, opts.line2), math.max(opts.line1, opts.line2)
end

local function visual_line_range(bufnr)
	local start = vim.api.nvim_buf_get_mark(bufnr, "<")
	local finish = vim.api.nvim_buf_get_mark(bufnr, ">")
	if start[1] == 0 or finish[1] == 0 then
		return nil, nil
	end
	return math.min(start[1], finish[1]), math.max(start[1], finish[1])
end

local function append_common_metadata(lines, bufnr, opts)
	if opts.include_file_path then
		push(lines, "file: " .. file_path(bufnr))
	end
	if opts.include_filetype then
		push(lines, "filetype: " .. filetype(bufnr))
	end
end

function M.buffer_message()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = make_header("file")
	push(lines, "type: buffer")

	local opts = config.options.context
	append_common_metadata(lines, bufnr, opts)
	if opts.include_cursor then
		local line, col = cursor_line()
		push(lines, ("cursor: line %d, column %d"):format(line, col))
	end

	local top, bottom = visible_range()
	if top and bottom then
		push(lines, ("visible_range: lines %d-%d"):format(top, bottom))
	end

	push(lines, "</neovim-context>")
	return table.concat(lines, "\n") .. "\n"
end

function M.selection_message(command_opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local first, last = command_line_range(command_opts)
	if not (first and last) then
		first, last = visual_line_range(bufnr)
	end

	if not (first and last) then
		return nil, "No visual selection range found. Reselect and retry."
	end

	local lines = make_header("selection")
	push(lines, "type: selection")

	local context_opts = config.options.context
	append_common_metadata(lines, bufnr, context_opts)
	if context_opts.include_selection_range then
		push(lines, ("selection: lines %d-%d"):format(first, last))
	end

	push(lines, "</neovim-context>")
	return table.concat(lines, "\n") .. "\n"
end

function M.diagnostics_message()
	local bufnr = vim.api.nvim_get_current_buf()
	local items = diagnostics.format_for_buffer(bufnr)
	if #items == 0 then
		return nil, "No diagnostics in current buffer."
	end

	local lines = make_header("diagnostics")
	push(lines, "type: diagnostics")

	local opts = config.options.context
	append_common_metadata(lines, bufnr, opts)

	if opts.include_diagnostics then
		push(lines, "")
		push(lines, "diagnostics:")
		for _, item in ipairs(items) do
			push(lines, item)
		end
	end

	push(lines, "</neovim-context>")
	return table.concat(lines, "\n") .. "\n"
end

return M
