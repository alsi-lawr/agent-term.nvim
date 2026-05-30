local config = require("agent_term.setup.runtime_config")

local M = {}

local function context_file_path()
	local context_opts = config.options.context
	local configured = ".agent-term/context.json"
	if type(context_opts) == "table" and type(context_opts.file_path) == "string" then
		configured = context_opts.file_path
	end
	return vim.fn.fnamemodify(vim.fn.expand(configured), ":p")
end

---@return string
function M.path()
	return context_file_path()
end

---@param kind "buffer"|"selection"|"diagnostics"
---@param content string
---@return boolean ok, string? err
function M.write(kind, content)
	local path = context_file_path()
	local dir = vim.fn.fnamemodify(path, ":h")
	if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) == 0 then
		return false, ("could not create context directory `%s`"):format(dir)
	end

	local payload = {
		version = 1,
		kind = kind,
		content = content,
		updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	local encoded = vim.json.encode(payload)
	local ok, err = pcall(vim.fn.writefile, { encoded }, path)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

return M
