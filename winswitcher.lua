-- winswitcher.lua
-- manage alt+tab  alt+\  alt+esc  to switch window with hs.window.switcher and hs.expose

Switcher = hs.window.switcher.new() -- default windowfilter: only visible windows, all Spaces
Switcher.ui.showTitles = false
Switcher.ui.showThumbnails = false
Switcher.ui.showSelectedThumbnail = true
Switcher.ui.selectedThumbnailSize = 512
Switcher.ui.showSelectedTitle = true
Switcher.ui.textSize = 10
Switcher.ui.backgroundColor = {0.2,0.2,0.3,0.6}
Switcher_finder = hs.window.switcher.new{'Finder','ForkLift'} -- only Finder and forklift window for switch
Switcher_finder.ui.showTitles = false
Switcher_finder.ui.showThumbnails = false

EnExpose = hs.expose.new()
EnExpose.ui.highlightColor = {0.8,0.5,0,0.1}
EnExpose.ui.backgroundColor = {0,0,0.8,0.6}
EnExpose.ui.otherSpacesStripBackgroundColor = {0.1,0.1,0.8,0.6}
EnExpose.ui.otherSpacesStripPosition = 'top'
EnExpose.ui.otherSpacesStripWidth = 0.3
EnExpose.ui.nonVisibleStripBackgroundColor = {0.03,0.1,0.15,0.6}

hs.grid.setGrid'4x3'

hs.hotkey.bind('alt', 'tab', 'Next window', function() Switcher:next() end)
hs.hotkey.bind('alt', '\\', 'Finder window', function() Switcher_finder:next() end)
hs.hotkey.bind('alt', 'escape', 'Enanched Expose', function() EnExpose:toggleShow() end)
hs.hotkey.bind('cmd', 'escape', 'Show grid position', hs.grid.show)
hs.hotkey.bind(Hyper, '.', 'Show shortcut hint list', hs.hints.windowHints)
