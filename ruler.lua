-- ruler.lua
-- draw a rectangle on screen with [alt]+[shift] to draw a rectangle with transparency to use as highliner or ruler 
-- Fabio Celsalonga 20/03/2020

local color = { red=192/255, green=192/255, blue=220/255, alpha=0.2}
local strokeColor = { red=0/255, green=100/255, blue=255/255, alpha=0.8 }

local rectanglePreview = hs.drawing.rectangle(hs.geometry.rect(0, 0, 0, 0))
rectanglePreview:setStrokeWidth(1)
rectanglePreview:setStrokeColor(strokeColor)
rectanglePreview:setFillColor(color)
rectanglePreview:setRoundedRectRadii(2, 2)
rectanglePreview:setStroke(true):setFill(true)
rectanglePreview:setLevel("floating")

local function showRuler()
  rectanglePreview:show()
end

local fromPoint = nil

drag_event_ruler = hs.eventtap.new(
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

flags_event_ruler = hs.eventtap.new(
  { hs.eventtap.event.types.flagsChanged },
  function(e)
    local flags = e:getFlags()
    if flags.ralt and flags.rshift then
      fromPoint = hs.mouse.absolutePosition()
      local startFrame = hs.geometry.rect(fromPoint.x, fromPoint.y, 0, 0)
      rectanglePreview:setFrame(startFrame)
      drag_event_ruler:start()
      rectanglePreview:show()
    elseif fromPoint ~= nil then
      fromPoint = nil
      drag_event_ruler:stop()
      rectanglePreview:hide()
      showRuler()
    end
    return nil
  end
)
flags_event_ruler:start()
