-- winswitcher.lua
-- manage alt+tab  alt+\  alt+esc  to switch window with hs.window.switcher and hs.expose

-- in questa modalità è lento... e non risolve il problema di "tutte le finestre"...
-- inoltre istanziare uno switcher già di suo vale 50MB in più.
hs.window.filter.forceRefreshOnSpaceChange = true
Filter = hs.window.filter.new(true):setOverrideFilter{ allowTitles = 1 }
Switcher = hs.window.switcher.new(Filter)
Switcher.ui.showTitles = false
Switcher.ui.showThumbnails = false
-- Switcher.ui.showSelectedThumbnail = false
-- Switcher.ui.selectedThumbnailSize = 512
Switcher.ui.showSelectedTitle = true
Switcher.ui.textSize = 10
Switcher.ui.backgroundColor = { 0.2, 0.5, 0.5, 0.5 }
hs.hotkey.bind('cmd', 'escape', 'Next window', function () Switcher:next() end)

-- Switcher_finder = hs.window.switcher.new{'Finder','ForkLift'} -- only Finder and forklift window for switch
-- Switcher_finder.ui.showTitles = false
-- Switcher_finder.ui.showThumbnails = false

-- EnExpose = hs.expose.new()
-- EnExpose.ui.highlightColor = {0.8,0.5,0,0.1}
-- EnExpose.ui.backgroundColor = {0,0,0.8,0.6}
-- EnExpose.ui.otherSpacesStripBackgroundColor = {0.1,0.1,0.8,0.6}
-- EnExpose.ui.otherSpacesStripPosition = 'top'
-- EnExpose.ui.otherSpacesStripWidth = 0.3
-- EnExpose.ui.nonVisibleStripBackgroundColor = {0.03,0.1,0.15,0.6}
-- hs.hotkey.bind('cmd', 'escape', 'Enanched Expose', function() EnExpose:toggleShow() end)

-- hs.grid.setGrid'4x3'

-- hs.hotkey.bind('alt', 'tab', 'Next window', function() Switcher:next() end)
-- hs.hotkey.bind('alt', '\\', 'Finder window', function() Switcher_finder:next() end)
-- hs.hotkey.bind('alt', 'escape', 'Enanched Expose', function() EnExpose:toggleShow() end)
-- hs.hotkey.bind('cmd', 'escape', 'Show grid position', hs.grid.show)
-- hs.hotkey.bind(Hyper, '.', 'Show shortcut hint list', hs.hints.windowHints)
