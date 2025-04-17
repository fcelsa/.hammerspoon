--[[ hammerspoon init.lua
configuration file by fcelsa - Fabio Celsalonga
original written for Sparrow hackintosh workstation on Nov 2017
update 14/05/2018 date calendar on menu bar
update 27/02/2020 experiment whit other menu bar
update 04/03/2020 add window positioning winposition.lua
update 09/03/2020 add drag_term.lua
update 14/03/2020 fix and extend calendar for menubar added moonphase
update Apr 2020 for new workstation "Prime"
update 10/07/2020 little refactoring and changed [ins] key map to [shift]+[forwarddelete]
update 27/12/2022 Experiment with ClipBoardTool
update 15/02/2023 Enabled modified version of HCalendar spoon
update 18/03/2023 new external module for keybinding and experiment with attached num keypad.
update Apr 2023 new: my spoon MCalendar to inset calendar on desktop
                new: file snippet.lua a popup menu to insert or copy date, special char and snippet.
                new: utility file to collect some useful lua code.
                new: i18n implementation (rudimentary with simple table)
--]]

-- global key bindings defined here for easier referencing.
Hyper = { "cmd", "alt", "ctrl" }
Shift_hyper = { "cmd", "alt", "ctrl", "shift" }


-- load external lua source -----------------------------------------------------------------------------------------

-- Internationalization file and Locale settings
local i18n = require 'i18n'

-- utility functions file
local utility = require("utility")

-- special bindings
local special_binding = require("special_binding")

-- menubar
-- local menu_cal = require("menu_cal"):init()

-- window position managements
local win_position = require "win_position"

-- remap keyboard
local keyremap = require "keyremap"

-- netutils: binding on Hyper+p show network connection quality
local netutils = require "netutils"

-- drag_term: drag mouse with ⌥+shift draw a box to set a terminal window size.
local drag_term = require("drag_term")

-- winswitcher: window switch and positioning management.
local winswitcher = require("winswitcher")

-- showkey: show keypress on screen. Binding on ⌃+⌘+shift+p to toggle on/off
-- è utile in caso di cambio tastiera e per testare nuove configurazioni.
local showkey = require("showkey")

-- keypadmon: monitor a secondary keyboard, like numpad to focus specific application on demand.
-- disbled at the moment due to conlifct problem with Maccy application.
--local keypadmon = require("keypadmon"):new()

-- highlightfocused: show colored border around focused window, all or specific application.
local highlightfocused = require("highlightfocused")

-- snippet: a popup menu for text snippet insertion or clipboard. Binding on Hyper+v 
local snippet = require("snippet")

-- application watcher - only experiment at the moment.
-- local appwatcher = require("appwatcher")

local gemini_helper = require("gemini_helper")


-- end load external lua source -------------------------------------------------------------------------------------


-- system icon used around...
ImgStatusOn = hs.image.imageFromName("NSStatusAvailable")
ImgStatusNo = hs.image.imageFromName("NSStatusNone")
ImgStatusOff = hs.image.imageFromName("NSStatusUnavailable")
ImgStatusPrt = hs.image.imageFromName("NSStatusPartiallyAvailable")
ImgStatusChk = hs.image.imageFromName("NSMenuOnStateTemplate")
ImgTest = hs.image.imageFromName("NXdefaulticon")
CalImageCurr = hs.image.imageFromPath(hs.configdir .. "/assets/images/2023.png")
CalImageNext = hs.image.imageFromPath(hs.configdir .. "/assets/images/2024.png")

-- style definition for screen alert
local whiteStyle = hs.alert.defaultStyle -- default if none defined on call
whiteStyle.fillColor = { white = 0.7, alpha = 0.8 }
whiteStyle.textColor = { white = 0, alpha = 1 }
whiteStyle.textSize = 32

local redStyle = {}
redStyle.fillColor = { red = 1.0, green = 0.0, blue = 0.0, alpha = 0.6 }
redStyle.textColor = { white = 0.0, alpha = 1.0 }
redStyle.textSize = 64
redStyle.textColor = { red = 239 / 255, green = 239 / 255, blue = 23 / 255, alpha = 0.8 }

hs.alert.show("🔨  hammerspoon started..." .. Str_i18n('Hello'), whiteStyle, 6)

hs.notify.new({title='Hammerspoon', informativeText='Config loaded'}):send()


-- watcher that reload config file when .hammerspoon changed
function ReloadConfig(files)
    DoReload = false
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            DoReload = true
        end
    end
    if DoReload then
        hs.reload()
    end
end

-- Watcher for hammerspoon reloading, uncomment to enable.
-- HammersWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", ReloadConfig):start()

-- watcher for library folder
function LibraryFolderWatch()
    hs.alert.show("🔨 alert: Library Launch Agents folder was modified !", redStyle, 10)
end

LibraryWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/Library/LaunchAgents/", LibraryFolderWatch):start()


-- Load external spoon section -------------------------------------------------------

-- hs.loadSpoon('FadeLogo'):start(6)
local fadeLogo = hs.loadSpoon('FadeLogo')
if fadeLogo ~= nil then
    -- fadeLogo.image_size = hs.geometry.size(1024, 768)
    fadeLogo.image = ImgStatusChk
    fadeLogo:start(6)
end

--hs.loadSpoon("HCalendar")
--spoon.HCalendar.showProgress = true

-- selected text translation
hs.loadSpoon("PopupTranslateSelection")
local wm = hs.webview.windowMasks
spoon.PopupTranslateSelection.popup_style = wm.utility|wm.HUD|wm.titled|wm.closable|wm.resizable
HotKeys = {
    translate_to_it = { Hyper, "i" },
    translate_it_en = { Hyper, "e" },
    translate_de_en = { Shift_hyper, "e" },
    translate_en_de = { Shift_hyper, "d" },
}
spoon.PopupTranslateSelection:bindHotkeys(HotKeys)

-- load and key binding Ksheet spoon
-- that show sheet of all shortcut menu item of focused application
-- chose your prefered keybinding
hs.loadSpoon("KSheet"):init()
HotKeys = {
    toggle = { Hyper, "pad7" },
    -- toggle = { "ctrl", "pad1" },
}
spoon.KSheet:bindHotkeys(HotKeys)

-- move and resize windows from anyware inside focused window
local SkyRocket = hs.loadSpoon("SkyRocket")
if SkyRocket ~= nil then
    Sky = SkyRocket:new({
        -- Which modifiers to hold to move a window?
        moveModifiers = { 'cmd', 'shift' },
        -- Which modifiers to hold to resize a window?
        resizeModifiers = { 'ctrl', 'shift' },
    })
end

-- MCalendar
hs.loadSpoon('MCalendar')


-- end load spoon section -------------------------------------------------------
