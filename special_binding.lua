-- special_binding.lua
--
-- set specific special binding, that distinguish from left and right modifiers.
-- Implemented in the efficient way as clarified here by asmagill: https://github.com/Hammerspoon/hammerspoon/discussions/3113#discussioncomment-3341851
--

local hotkey = require("hs.hotkey")
local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")

local alert = require("hs.alert")

-- set up your hotkeys in this table:
local myKeys = {
    hotkey.new({ "ctrl" }, "pad1", function() alert("1 was pressed") end),
    hotkey.new({ "ctrl" }, "pad2", function() alert("2 was pressed") end),
    hotkey.new({ "ctrl" }, "pad3",
        function() Measurement('event mod intercepting ', function() alert("3 was pressed") end) end),
    -- etc
}

local myKeysActive = false

-- this determines whether or not to enable/disable the keys
TheModEvent = eventtap.new({ eventtap.event.types.flagsChanged },
    function(e)
        local flags = e:rawFlags()
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
