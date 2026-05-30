local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)

local function add_rtp(path)
	if type(path) ~= "string" or path == "" then
		return false
	end
	if vim.fn.isdirectory(path) ~= 1 then
		return false
	end
	vim.opt.runtimepath:append(path)
	return true
end

if not add_rtp(vim.env.PLENARY_PATH) then
	local data = vim.fn.stdpath("data")
	local candidates = {
		data .. "/lazy/plenary.nvim",
		data .. "/site/pack/deps/start/plenary.nvim",
		data .. "/site/pack/packer/start/plenary.nvim",
	}

	local found = false
	for _, path in ipairs(candidates) do
		if add_rtp(path) then
			found = true
			break
		end
	end

	if not found then
		error("plenary.nvim not found. Set PLENARY_PATH or install plenary.nvim.")
	end
end

vim.opt.swapfile = false
vim.opt.shadafile = "NONE"
