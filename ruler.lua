-- ruler.lua
-- draw a rectangle on screen with [alt]+[shift] to draw a rectangle with transparency to use as highliner or ruler 
-- Fabio Celsalonga 20/03/2020

local color = { red=90/255, green=90/255, blue=80/255, alpha=0.3}
local strokeColor = { red=255/255, green=0/255, blue=0/255, alpha=0.7 }
-- default DPI used to convert px -> mm when physical size is unknown
local DEFAULT_DPI = 96

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

-- size label: shows width x height in pixels
local sizeLabel = hs.drawing.text(hs.geometry.rect(0, 0, 120, 18), "")
sizeLabel:setLevel("floating")
sizeLabel:setTextColor(strokeColor)
-- setTextSize may not be available on all versions; wrap in pcall
pcall(function() sizeLabel:setTextSize(12) end)

local function computeScreenScale()
  local s = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  if not s then return 1 end
  local mode = s:currentMode()
  if mode and mode.width and s.fullFrame then
    -- mode.width is pixels, fullFrame.w is points; ratio approximates backing scale
    local full = s:fullFrame()
    if full.w and full.w > 0 then
      return mode.width / full.w
    end
  end
  return 1
end

local function pxToMm(px)
  local scale = computeScreenScale() or 1
  local dpi = DEFAULT_DPI * scale
  return (px / dpi) * 25.4
end

local fromPoint = nil

DragEventRuler = hs.eventtap.new(
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

    -- update size label: width x height
    local w = math.abs(toPoint.x - fromPoint.x)
    local h = math.abs(toPoint.y - fromPoint.y)
    local originTxt = string.format("%.0f , %.0f", fromPoint.x, fromPoint.y)
    local mmw = pxToMm(w)
    local mmh = pxToMm(h)
    local txt = math.floor(w) .. " x " .. math.floor(h) .. " px  |  " .. string.format("%.1f x %.1f mm", mmw, mmh) .. "\n@ " .. originTxt
    pcall(function() sizeLabel:setText(txt) end)
    -- position label above rectangle if possible
    local lx = newFrame.x
    local ly = newFrame.y - 36
    if ly < 0 then ly = newFrame.y + 4 end
    pcall(function() sizeLabel:setFrame(hs.geometry.rect(lx, ly, 200, 36)) end)
    pcall(function() sizeLabel:show() end)

    return nil
  end
)

FlagsEventRuler = hs.eventtap.new(
  { hs.eventtap.event.types.flagsChanged },
  function(e)
    local flags = e:getFlags()
    if flags.alt and flags.cmd then
      fromPoint = hs.mouse.absolutePosition()
      local startFrame = hs.geometry.rect(fromPoint.x, fromPoint.y, 0, 0)
      rectanglePreview:setFrame(startFrame)
      DragEventRuler:start()
      rectanglePreview:show()
      sizeLabel:show()
    elseif fromPoint ~= nil then
      fromPoint = nil
      DragEventRuler:stop()
      rectanglePreview:hide()
      sizeLabel:hide()
      showRuler()
    end
    return nil
  end
)
FlagsEventRuler:start()
