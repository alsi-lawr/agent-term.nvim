local M = {}

local severity_name = {
	[vim.diagnostic.severity.ERROR] = "ERROR",
	[vim.diagnostic.severity.WARN] = "WARN",
	[vim.diagnostic.severity.INFO] = "INFO",
	[vim.diagnostic.severity.HINT] = "HINT",
}

function M.format_for_buffer(bufnr)
	local items = vim.diagnostic.get(bufnr)
	local out = {}

	for _, d in ipairs(items) do
		local line = (d.lnum or 0) + 1
		local col = (d.col or 0) + 1
		local severity = severity_name[d.severity] or "UNKNOWN"
		local source = d.source or "unknown"
		local code = d.code and (" [" .. tostring(d.code) .. "]") or ""
		local message = (d.message or ""):gsub("\n", " ")

		out[#out + 1] = ("- line %d, col %d, %s, %s%s: %s"):format(
			line,
			col,
			severity,
			source,
			code,
			message
		)
	end

	return out
end

return M
