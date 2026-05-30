local M = {}

function M.clear_codex_modules()
	for name, _ in pairs(package.loaded) do
		if name == "codex" or name:match("^codex%.") then
			package.loaded[name] = nil
		end
	end
end

return M
