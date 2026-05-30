files["lua/**"] = {
	std = "luajit",
	globals = {
		"vim",
	},
}

files["tests/**"] = {
	std = "luajit+busted",
	globals = {
		"vim",
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
