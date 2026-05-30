local M = {}
local applied_maps = {}
local setup_keymaps = require("agent_term.setup.keymaps")

---@param name string
---@return boolean
function M.is_known(name)
	return setup_keymaps.is_known(name)
end

---@param maps table<string, any>
---@return string[]
function M.get_unknown_names(maps)
	return setup_keymaps.get_unknown_names(maps)
end

function M.setup(api)
	local config = require("agent_term.setup.runtime_config")
	local maps = config.options.keymaps or {}

	for _, applied in ipairs(applied_maps) do
		pcall(vim.keymap.del, applied.mode, applied.lhs)
	end
	applied_maps = {}

	for _, spec in ipairs(setup_keymaps.specs) do
		local key = maps[spec[1]]
		local resume_kind = spec[5]
		if key and (resume_kind == nil or config.has_resume(resume_kind)) then
			vim.keymap.set(spec[2], key, api[spec[3]], { desc = spec[4] })
			applied_maps[#applied_maps + 1] = { mode = spec[2], lhs = key }
		end
	end
end

return M
