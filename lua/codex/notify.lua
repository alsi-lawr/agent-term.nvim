local M = {}

local function send(msg, level)
	vim.notify(msg, level, { title = "codex.nvim" })
end

function M.info(msg)
	send(msg, vim.log.levels.INFO)
end

function M.warn(msg)
	send(msg, vim.log.levels.WARN)
end

function M.error(msg)
	send(msg, vim.log.levels.ERROR)
end

return M
