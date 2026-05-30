std = "lua51"
globals = {
	"vim",
}

files["tests/spec/**/*.lua"] = {
	std = "lua51+busted",
	globals = {
		"vim",
	},
}

files["tests/minimal_init.lua"] = {
	globals = {
		"vim",
	},
}

files["tests/types/*.lua"] = {
	std = "none",
	globals = {
		"describe",
		"it",
		"before_each",
		"after_each",
		"before_all",
		"after_all",
		"pending",
		"assert",
		"spy",
		"stub",
		"mock",
		"match",
	},
	unused_globals = false,
}
