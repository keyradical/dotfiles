hs.hotkey.bind({ "cmd" }, "S", function()
	hs.application.launchOrFocus("Slack")
end)

hs.hotkey.bind({ "cmd" }, "return", function()
	hs.application.launchOrFocus("kitty")
end)

hs.hotkey.bind({ "cmd" }, "B", function()
	hs.application.launchOrFocus("Brave Browser")
end)

hs.hotkey.bind({ "cmd" }, "L", function()
	hs.application.launchOrFocus("Linear")
end)

hs.hotkey.bind({ "cmd" }, "O", function()
	hs.application.launchOrFocus("Obsidian")
end)

hs.hotkey.bind({ "ctrl", "cmd" }, "Z", function()
	hs.application.launchOrFocus("zoom.us")
end)

hs.hotkey.bind({ "ctrl", "cmd" }, "N", function()
	hs.application.launchOrFocus("Notion")
end)

hs.hotkey.bind({ "ctrl", "cmd" }, "S", function()
	hs.application.launchOrFocus("Settings")
end)

hs.hotkey.bind({ "ctrl", "cmd" }, "A", function()
	hs.application.launchOrFocus("Claude")
end)
