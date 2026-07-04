hl.monitor({
	output = "DP-2",
	mode = "preferred",
	position = "auto-up",
	scale = 1,
})

hl.monitor({
	output = "DP-1",
	mode = "preferred",
	position = "auto",
	scale = 1,
	mirror = "DP-2",
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "preferred",
	position = "auto-down",
	transform = 2,
	scale = 1,
})
