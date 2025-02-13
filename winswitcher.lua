-- winswitcher.lua
-- manage alt+tab  alt+\  alt+esc  to switch window with hs.window.switcher and hs.expose

switcher = hs.window.switcher.new() -- default windowfilter: only visible windows, all Spaces
switcher.ui.showTitles = false
switcher.ui.showThumbnails = false
switcher.ui.showSelectedThumbnail = true
switcher.ui.selectedThumbnailSize = 512
switcher.ui.showSelectedTitle = true
switcher.ui.textSize = 10
switcher.ui.backgroundColor = {0.2,0.2,0.3,0.6}
switcher_finder = hs.window.switcher.new{'Finder','ForkLift'} -- only Finder and forklift window for switch
switcher_finder.ui.showTitles = false
switcher_finder.ui.showThumbnails = false

enExpose = hs.expose.new()
enExpose.ui.highlightColor = {0.8,0.5,0,0.1}
enExpose.ui.backgroundColor = {0,0,0.8,0.6}
enExpose.ui.otherSpacesStripBackgroundColor = {0.1,0.1,0.8,0.6}
enExpose.ui.otherSpacesStripPosition = 'top'
enExpose.ui.otherSpacesStripWidth = 0.3
enExpose.ui.nonVisibleStripBackgroundColor = {0.03,0.1,0.15,0.6}

hs.grid.setGrid'4x3'

hs.hotkey.bind('alt', 'tab', 'Next window', function() switcher:next() end)
hs.hotkey.bind('alt', '\\', 'Finder window', function() switcher_finder:next() end)
hs.hotkey.bind('alt', 'escape', 'Enanched Expose', function() enExpose:toggleShow() end)
hs.hotkey.bind('cmd', 'escape', 'Show grid position', hs.grid.show)
hs.hotkey.bind(Hyper, '.', 'Show shortcut hint list', hs.hints.windowHints)
