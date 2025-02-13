-- drag_term.lua
-- draw a rectangle on screen with ⌥+shift to put Terminal in that position and dimension.
-- If terminal.app it's closed will be open; if more than terminal window it's open, will take the first one found.
-- Fabio Celsalonga 10/03/2020
-- TODO: hs.eventtap.new dovrebbe essere una global e non local, altrimenti dopo un po' di tempo non funziona più.
--       questo a causa della garbage collection del lua che "scarica" dalla memoria le local dopo un po' di tempo.
-- fix anche della dimensione del rettangolo, altrimenti bastava premere solo ctrl+shift per triggerare l'apertura
-- ora deve essere selezionato un rettangolo più grande di 640x480

local color = { red = 192 / 255, green = 192 / 255, blue = 220 / 255, alpha = 0.3 }
local strokeColor = { red = 0 / 255, green = 100 / 255, blue = 255 / 255, alpha = 1 }

local rectanglePreview = hs.drawing.rectangle(hs.geometry.rect(0, 0, 0, 0))
rectanglePreview:setStrokeWidth(4)
rectanglePreview:setStrokeColor(strokeColor)
rectanglePreview:setFillColor(color)
rectanglePreview:setRoundedRectRadii(2, 2)
rectanglePreview:setStroke(true):setFill(true)
rectanglePreview:setLevel("floating")


local function OpenTerminal()
    local frame = rectanglePreview:frame()
    --local createTermWithBounds = string.format([[
    --  if application /"Terminal" is not running then
    --    launch application "Terminal"
    --  end if
    --  tell application "Terminal"
    --    set newWindow to (create window with default profile)
    --    set the bounds of newWindow to {%i, %i, %i, %i}
    --  end tell
    --]], frame.x, frame.y, frame.x + frame.w, frame.y + frame.h)
    -- print("x: " .. frame.x .. "  y:" .. frame.y .. "  w:" .. frame.w .. "  h:" .. frame.h)
    if frame.w >= 640 and frame.h >= 480 then
        local termFocused = hs.application.launchOrFocus("Terminal")
        if termFocused then
            local win = hs.window.focusedWindow()
            local f = win:frame()
            f.x = frame.x
            f.y = frame.y
            f.w = frame.w
            f.h = frame.h
            win:setFrame(f)
        end
    end
end

local fromPoint = nil

DragEvent = hs.eventtap.new(
    { hs.eventtap.event.types.mouseMoved },
    function(e)
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
