-- keypadmon
-- Author: Fabio Celsalonga
-- Date: 2023-03
--
-- Monitor secondary keyboard connected, like separate numeric keypad (numpad) to manage the event.
-- In my case, focus the CalcTape application (targetAppID) as soon as the first key is pressed, then
-- return to the previous focused window (callerAppId) or Finder if caller it's uncertain.
-- TODO: needs to better isolate callerAppId to better handling focusedWindow.
--
-- Application notes:
-- use hs.eventtap with moderation, in all cases where hs.hotkey it's enought, use this! because
-- they use OS bultin functions, so use hs.eventtap only when hs.hotkey can't do what you want to do.
--


local INTRO = [[

## install
- add `local keypadmon = require("keypadmon"):new()` to `~/.hammerspoon/init.lua`
- this module require _ClassSingleton.lua

## use
- open the hammerspoon log console
- reload hammerspoon configuration via log console
- press any key on the second keyboard you want to use
- look for the log message telling you the Keyboard Identifier
- replace the `0` in the line `self.keyboardIdentifier = 0` with the Keyboard Identifier
- replace the name of application to send input in line `self.application = "CalcTape"`
- reload the hammerspoon configuration via log console
- if all went well, you are all set and the keyboard now sends to designated application.

]]

local Class = require('./_ClassSingleton')()

function Class:constructor()
    self.keyboardIdentifier = 3          -- identifier of my num keypad = 40 - set to 0 to identify other
    self.targetAppId = "de.sfr.calctape"  -- app that want focus
    self.callerAppId = "com.apple.finder" -- Finder it's default caller app if no other identified.
    self.memoryAppId = "" -- last valid caller 
    self:buildEventtap()
end

function Class:buildEventtap()
    self.eventtap = hs.eventtap.new({
        hs.eventtap.event.types.flagsChanged,
        hs.eventtap.event.types.keyUp,
        hs.eventtap.event.types.keyDown,
    }, function(event)
        if hs.application.frontmostApplication() then  -- assure not nil
            self.callerAppId = hs.application.frontmostApplication():bundleID()
        end
        if self.callerAppId ~= self.targetAppId then  -- if caller app is not the target itself, store it for lather
            self.memoryAppId = self.callerAppId
        end

        local currentModifiers = event:getFlags()
        local keyboardIdentifier = event:getProperty(hs.eventtap.event.properties.keyboardEventKeyboardType)
        local keyCode = event:getKeyCode()
        local rawEventData = event:getRawEventData()
        local keyPressed = hs.keycodes.map[event:getKeyCode()]

        if self.keyboardIdentifier == 0 and event:getType() == hs.eventtap.event.types.keyDown then
            print('Unknown Keyboard with Identifier: ' .. tostring(keyboardIdentifier))
        elseif self.keyboardIdentifier and keyboardIdentifier == self.keyboardIdentifier then
            if event:getType() == hs.eventtap.event.types.keyDown then
                --print("Key: " .. keyPressed .. "  from appId (caller/memory): " .. self.callerAppId .. " / " .. self.memoryAppId )
                -- "  mod: " .. tostring(currentModifiers) .. "  Keyboard: " .. tostring(keyboardIdentifier ..

                if self.callerAppId == self.targetAppId and keyPressed ~= "escape" then
                    return false
                elseif self.callerAppId == self.targetAppId and keyPressed == "escape" then
                    hs.application.launchOrFocusByBundleID(self.memoryAppId)
                    return false
                end

                hs.application.launchOrFocusByBundleID(self.targetAppId)
                return false
            elseif event:getType() == hs.eventtap.event.types.keyUp then
                --hs.application.launchOrFocus(self.application)
                --hs.eventtap.keyStroke({ currentModifiers }, keyPressed, 20000, calcTape)
                --print("Tasto: " .. tostring(keyCode) .. "  Keyboard: " .. tostring(keyboardIdentifier))
            end
            return false -- prevent default

        elseif self.keyboardIdentifier and keyboardIdentifier ~= self.keyboardIdentifier then
            if event:getType() == hs.eventtap.event.types.keyDown and self.callerAppId == self.targetAppId and keyPressed == "escape" then
                hs.application.launchOrFocusByBundleID(self.memoryAppId)
                return false
            end
        end

        return false     -- pass the event through unchanged
    end)
    self.eventtap:start()
end

return Class
