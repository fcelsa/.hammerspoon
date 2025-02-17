--- drag_term.lua
--- hold down ⌥+⇧ (alt+shift) and drag mouse on screen draw a rectangle preview
--- wich then put Terminal app in that position and dimension;
--- rectangle needs to be at least 320x240 to trigger the opening of Terminal;
--- if Terminal.app it's closed will be open;
--- if more than Terminal window it's open, will take the last one had focus,
--- regardless if it is not in the foreground;
--- only unique or last one minimized windows are restored,
--- it brings it to the foreground and resizes it.
--- Works also on multi-screen setups.
--- Implementation note:
--- hs.eventtap.new should be a global variable and not local, otherwise,
--- after some time, it stops working due to Lua's garbage collection which
--- "unloads" local variables from memory after a while.
--- Fabio Celsalonga 1st implementation 10/03/2020 last update 17/02/2025

local color = { red = 192 / 255, green = 192 / 255, blue = 220 / 255, alpha = 0.3 }
local strokeColor = { red = 0 / 255, green = 100 / 255, blue = 255 / 255, alpha = 1 }

local fromPoint = nil

local rectanglePreview = hs.drawing.rectangle(hs.geometry.rect(0, 0, 0, 0))
rectanglePreview:setStrokeWidth(4)
rectanglePreview:setStrokeColor(strokeColor)
rectanglePreview:setFillColor(color)
rectanglePreview:setRoundedRectRadii(2, 2)
rectanglePreview:setStroke(true):setFill(true)
rectanglePreview:setLevel("floating")

local function OpenTerminal()
    local frame = rectanglePreview:frame()
    local termFocused = false
    local termAppRunning = nil
    local win = nil
    if frame.w >= 320 and frame.h >= 240 then
        termAppRunning = hs.application.get("com.apple.Terminal")
        termFocused = hs.application.launchOrFocus("Terminal")
        if termAppRunning ~= nil and termFocused then
            win = hs.window.focusedWindow()
            local f = win:frame()
            f.x = frame.x
            f.y = frame.y
            f.w = frame.w
            f.h = frame.h
            win:setFrame(f)
        elseif termAppRunning == nil and termFocused then  -- I'm sure that can be done better
            hs.timer.doAfter(1, function()
                win = hs.window.focusedWindow()
                local f = win:frame()
                f.x = frame.x
                f.y = frame.y
                f.w = frame.w
                f.h = frame.h
                win:setFrame(f)
            end)
        end
    end
end

DragEvent = hs.eventtap.new(
    { hs.eventtap.event.types.mouseMoved },
    function(e)
        if fromPoint == nil then
            return nil
        end
        local toPoint = hs.mouse.absolutePosition()
        local newFrame = hs.geometry.new({
            x1 = fromPoint.x,
            y1 = fromPoint.y,
            x2 = toPoint.x,
            y2 = toPoint.y,
        })
        rectanglePreview:setFrame(newFrame)
        return nil
    end
)

FlagsEvent = hs.eventtap.new(
    { hs.eventtap.event.types.flagsChanged },
    function(e)
        local flags = e:getFlags()
        if flags.alt and flags.shift then
            fromPoint = hs.mouse.absolutePosition()
            local startFrame = hs.geometry.rect(fromPoint.x, fromPoint.y, 0, 0)
            rectanglePreview:setFrame(startFrame)
            DragEvent:start()
            rectanglePreview:show()
        elseif fromPoint ~= nil then
            fromPoint = nil
            DragEvent:stop()
            rectanglePreview:hide()
            OpenTerminal()
        end
        return nil
    end
)
FlagsEvent:start()
