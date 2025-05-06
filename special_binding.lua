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
-- Inoltre qui è implementato un sistema di misurazione del tempo di esecuzione delle funzioni,
-- che può essere utile per il debug e l'ottimizzazione delle prestazioni, questa parte è commentata.


local hotkey = require("hs.hotkey")
local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")

local alert = require("hs.alert")
local alertUid = 0

-- This function shows how to manage hs.alert so that they do not appear one below the other in cascade,
-- but always close the previous alert before showing a new one.
local function handleRightModifierKey(myKey)
    if alertUid ~= 0 then
        alert.closeAll(3)
        alertUid = 0
    end
    alertUid = alert("RightControl + " .. myKey .. " was pressed", 3)
end


-- set up your hotkeys in this table:
local myKeys = {
    hotkey.new({ "ctrl" }, "pad1", function() handleRightModifierKey("pad1") end),
    -- hotkey.new({ "ctrl" }, "pad2", function() alert("2 was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad3",
    --     function() Measurement('event mod intercepting ', function() alert("3 was pressed") end) end),
    hotkey.new({ "ctrl" }, "pad4", function() handleRightModifierKey("pad4") end),
    -- hotkey.new({ "ctrl" }, "pad5", function() alert("5 was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad6", function() alert("6 was pressed") end),
    hotkey.new({ "ctrl" }, "pad7", function() handleRightModifierKey("pad7") end),
    -- hotkey.new({ "ctrl" }, "pad8", function() alert("8 was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad9", function() alert("9 was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad0", function() alert("0 was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad.", function() alert(". was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad+", function() alert("+ was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad-", function() alert("- was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad*", function() alert("* was pressed") end),
    -- hotkey.new({ "ctrl" }, "pad/", function() alert("/ was pressed") end),
    hotkey.new({ "ctrl" }, "f16", function() handleRightModifierKey("f16") end),
    -- etc
}

local myKeysActive = false

-- this determines whether or not to enable/disable the keys
TheModEvent = eventtap.new({ eventtap.event.types.flagsChanged },
    function(e)
        local flags = e:rawFlags()
        -- deviceRightAlternate
        -- deviceRightCommand
        -- deviceRightControl
        -- deviceRightShift
        -- Corresponds to the right modifiers key on the keyboard (if present)
        if flags & eventtap.event.rawFlagMasks.deviceRightControl > 0 then
            if not myKeysActive then
                for _, v in ipairs(myKeys) do
                    v:enable()
                end
                myKeysActive = true
            end
        else
            if myKeysActive then
                for _, v in ipairs(myKeys) do
                    v:disable()
                end
                myKeysActive = false
            end
        end
    end
):start()
