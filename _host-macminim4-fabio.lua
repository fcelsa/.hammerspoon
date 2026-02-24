-- load and key binding Ksheet spoon
-- that show sheet of all shortcut menu item of focused application
-- chose your prefered keybinding
hs.loadSpoon("KSheet"):init()
HotKeys = {
    toggle = { Hyper, "pad7" },
    -- toggle = { "ctrl", "pad1" },
}
spoon.KSheet:bindHotkeys(HotKeys)
