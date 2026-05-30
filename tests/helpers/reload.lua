local M = {}

function M.clear_agent_term_modules()
	for name, _ in pairs(package.loaded) do
		if name == "agent_term" or name:match("^agent_term%.") then
			package.loaded[name] = nil
		end
	end
end

return M
