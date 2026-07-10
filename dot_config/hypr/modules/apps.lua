return {
	terminal = "ghostty",
	file_manager = "dolphin",
	menu = "hyprlauncher",
	browser = "zen-browser",
	launcher = [[sh -lc 'command -v noctalia >/dev/null 2>&1 && noctalia msg panel-toggle launcher || rofi -show drun']],
	noctalia = [[sh -lc 'command -v noctalia >/dev/null 2>&1 && noctalia --daemon']],
}
