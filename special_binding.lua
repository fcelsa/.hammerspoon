-- special_binding.lua
--
-- set specific special binding, that distinguish from left and right modifiers.
-- Implemented in the efficient way as clarified here by asmagill: https://github.com/Hammerspoon/hammerspoon/discussions/3113#discussioncomment-3341851
-- In short, as explained in the link above, hs.hotkey cannot handle the right and left modifier keys,
-- so hs.eventtap is used to intercept events and then hs.hotkey functions are used to perform the actions.
-- Pay attention to potential conflicts with other applications that may use the same key combinations.
-- Further useful information on this topic is available here: https://github.com/Hammerspoon/hammerspoon/issues/1128
--
-- Questo codice non è effettivamente utilizzato per scopi specifici, è qui per eventuali esigenze future.
-- Inoltre qui è implementato il sistema di misurazione del tempo di esecuzione delle funzioni,
-- che può essere utile per il debug e l'ottimizzazione delle prestazioni, questa parte è commentata,
-- chiama la funzione Measurement definita globalmente in utility.lua.

local module = {}

local hotkey = require("hs.hotkey")
local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local window = require("hs.window")

local function handleRightModifierKey(myKey)
    Switch(myKey, {
        ['pad1'] = function()
            window.focusedWindow():moveToUnit({ 0.0, 0.5, 0.5, 0.5 })
        end,
        ['pad2'] = function()
            window.focusedWindow():moveToUnit({0, 0.5, 1, 0.5})
        end,
        ['pad3'] = function()
            window.focusedWindow():moveToUnit({ 0.5, 0.5, 0.5, 0.5 })
        end,
        ['pad4'] = function()
            window.focusedWindow():moveToUnit({0, 0, 0.5, 1})
        end,
        ['pad5'] = function()
            window.focusedWindow():centerOnScreen()
        end,
        ['pad6'] = function()
            window.focusedWindow():moveToUnit({0.5, 0, 0.5, 1})
        end,
        ['pad7'] = function()
            window.focusedWindow():moveToUnit({ 0, 0, 0.5, 0.5 })
        end,
        ['pad8'] = function()
            window.focusedWindow():moveToUnit({0, 0, 1, 0.5})
        end,
        ['pad9'] = function()
            window.focusedWindow():moveToUnit({0.5, 0, 0.5, 0.5})
        end,
        ['pad0'] = function()
            window.switcher.nextWindow()
        end,
        ['default'] = function()
            print("No case matched for " .. myKey)
        end
    })
end


-- set up your hotkeys in this table:
local myKeys = {
    hotkey.new({ "ctrl", "shift" }, "pad1", function() handleRightModifierKey("pad1") end),
    hotkey.new({ "ctrl", "shift" }, "pad2", function() handleRightModifierKey("pad2") end),
    hotkey.new({ "ctrl", "shift" }, "pad3", function() handleRightModifierKey("pad3") end),
    hotkey.new({ "ctrl", "shift" }, "pad4", function() handleRightModifierKey("pad4") end),
    hotkey.new({ "ctrl", "shift" }, "pad5", function() handleRightModifierKey("pad5") end),
    hotkey.new({ "ctrl", "shift" }, "pad6", function() handleRightModifierKey("pad6") end),
    hotkey.new({ "ctrl", "shift" }, "pad7", function() handleRightModifierKey("pad7") end),
    hotkey.new({ "ctrl", "shift" }, "pad8", function() handleRightModifierKey("pad8") end),
    hotkey.new({ "ctrl", "shift" }, "pad9", function() handleRightModifierKey("pad9") end),
    hotkey.new({ "ctrl", "shift" }, "pad0", function() handleRightModifierKey("pad0") end),
    -- hotkey.new({ "ctrl" }, "pad.", function() alert(". was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad+", function() alert("+ was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad-", function() alert("- was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad*", function() alert("* was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad/", function() alert("/ was pressed") end),
    hotkey.new({ "ctrl" }, "f16", function() handleRightModifierKey("f16") end),
    -- etc
}

local myKeysActive = false

local specialBindingHandler = function(e)
    local flags = e:rawFlags()
    -- deviceRightAlternate
    -- deviceRightCommand
    -- deviceRightControl
    -- deviceRightShift
    -- Corresponds to the right modifiers key on the keyboard (if present)
    if flags & eventtap.event.rawFlagMasks.deviceRightControl > 0 then
        for _, v in ipairs(myKeys) do
            v:enable()
        end
        myKeysActive = true
    else
        for _, v in ipairs(myKeys) do
            v:disable()
        end
        myKeysActive = false
    end
end

-- this determines whether or not to enable/disable the keys
module.TheModEvent = eventtap.new({ eventtap.event.types.flagsChanged }, specialBindingHandler)

module.start = function()
    module.TheModEvent:start()
end

module.stop = function()
    module.TheModEvent:stop()
end

return module
