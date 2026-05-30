local enums = require("agent_term.enums")
local state = require("agent_term.runtime.state")
local terminal = require("agent_term.runtime.session")
local view_controller = require("agent_term.ui.controller")

local M = {}

---@param kind "default"|"all"|"last"
function M.resume(kind)
	if not terminal.start_resume(kind) then
		return
	end
	if state.has_valid_panel_win() then
		view_controller.open(enums.view.PANEL)
		return
	end
	view_controller.open(enums.view.FLOAT)
end

function M.resume_default()
	M.resume(enums.resume_kind.DEFAULT)
end

function M.resume_all()
	M.resume(enums.resume_kind.ALL)
end

function M.resume_last()
	M.resume(enums.resume_kind.LAST)
end

return M
