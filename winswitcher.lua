-- winswitcher.lua
-- manage cmd+\ and cmd+esc to switch window with hs.window.switcher
-- take in account that hs.window.switcher is a bit of a memory hog, 
-- so we want to keep it alive and not reinstantiate it every time. 
-- In my tests, instantiating it on demand was causing 100MB+ memory spikes, 
-- while keeping it alive is around 50MB.

-- hs.window.filter.forceRefreshOnSpaceChange = true
local AllWindowsFilter = hs.window.filter.new(true):setCurrentSpace(nil)
local OtherSpacesFilter = hs.window.filter.new(true):setCurrentSpace(false)

AllWindowsFilter:subscribe(hs.window.filter.windowsChanged, function () end)
OtherSpacesFilter:subscribe(hs.window.filter.windowsChanged, function () end)

local function SwitcherUIPrefs()
	return {
		showTitles = false,
		showThumbnails = false,
		showSelectedThumbnail = true,
		thumbnailSize = 128,
		showSelectedTitle = true,
		fontName = 'Menlo',
		textSize = 6,
		textColor = { 1, 0.95, 0.8, 1 },
		titleBackgroundColor = { 0.1, 0.1, 0.1, 0.9 },
	}
end

Switcher = hs.window.switcher.new(
	AllWindowsFilter,
	SwitcherUIPrefs()
)
OtherSpacesSwitcher = hs.window.switcher.new(
	OtherSpacesFilter,
	SwitcherUIPrefs()
)
hs.hotkey.bind('cmd', '\\', function() Switcher:next() end)
hs.hotkey.bind({'cmd', 'shift'}, '\\', function() Switcher:previous() end)
hs.hotkey.bind('cmd', 'escape', function() OtherSpacesSwitcher:next() end)
