local function scriptPath()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local SkyRocket = {}

SkyRocket.author = "David Balatero <d@balatero.com>"
SkyRocket.extension = "Franz B. <csaa6335@gmail.com>"
SkyRocket.homepage = "https://github.com/franzbu/SkyRocket.spoon"
SkyRocket.license = "MIT"
SkyRocket.name = "SkyRocket"
SkyRocket.version = "1.0.6"
SkyRocket.spoonPath = scriptPath()

-- Modified from original fcelsa 2025
-- made it standalone in sync with my .hammerspoon setup repo.


local dragTypes = {
  move = 1,
  resize = 2,
}

local function tableToMap(table)
  local map = {}

  for _, value in pairs(table) do
    map[value] = true
  end

  return map
end

local function createResizeCanvas(alpha)
  local canvas = hs.canvas.new {}

  canvas:insertElement(
    {
      id = 'opaque_layer',
      action = 'fill',
      type = 'rectangle',
      fillColor = { red = 0, green = 0, blue = 0, alpha = alpha },
      roundedRectRadii = { xRadius = 5.0, yRadius = 5.0 },
    },
    1
  )
  return canvas
end

local function getWindowUnderMouse()
  -- Invoke `hs.application` because `hs.window.orderedWindows()` doesn't do it
  -- and breaks itself
  local _ = hs.application

  local my_pos = hs.geometry.new(hs.mouse.absolutePosition())
  local my_screen = hs.mouse.getCurrentScreen()

  return hs.fnutils.find(hs.window.orderedWindows(), function(w)
    return my_screen == w:screen() and my_pos:inside(w:frame())
  end)
end

-- Usage:
--     resizer = SkyRocket:new({
--     margin = 30,
--     opacity = 0.3,
--     moveModifiers = {'alt'},
--     moveMouseButton = 'left',
--     resizeModifiers = {'alt'},
--     resizeMouseButton = 'right',
--   })


local function buttonNameToEventType(name, optionName)
  if name == 'left' then
    return hs.eventtap.event.types.leftMouseDown
  end
  if name == 'right' then
    return hs.eventtap.event.types.rightMouseDown
  end
  error(optionName .. ': only "left" and "right" mouse button supported, got ' .. name)
end

function SkyRocket:new(options)
  options = options or {}
  margin = options.margin or 30

  local resizer = {
    disabledApps = tableToMap(options.disabledApps or {}),
    dragging = false,
    dragType = nil,
    moveStartMouseEvent = buttonNameToEventType(options.moveMouseButton or 'left', 'moveMouseButton'),
    moveModifiers = options.moveModifiers or { 'cmd', 'shift' },
    windowCanvas = createResizeCanvas(options.opacity or 0.3),
    resizeStartMouseEvent = buttonNameToEventType(options.resizeMouseButton or 'left', 'resizeMouseButton'),
    resizeModifiers = options.resizeModifiers or { 'ctrl', 'shift' },
    targetWindow = nil,
  }

  setmetatable(resizer, self)
  self.__index = self

  resizer.clickHandler = hs.eventtap.new(
    {
      hs.eventtap.event.types.leftMouseDown,
      hs.eventtap.event.types.rightMouseDown,
    },
    resizer:handleClick()
  )

  resizer.cancelHandler = hs.eventtap.new(
    {
      hs.eventtap.event.types.leftMouseUp,
      hs.eventtap.event.types.rightMouseUp,
    },
    resizer:handleCancel()
  )

  resizer.dragHandler = hs.eventtap.new(
    {
      hs.eventtap.event.types.leftMouseDragged,
      hs.eventtap.event.types.rightMouseDragged,
    },
    resizer:handleDrag()
  )

  resizer.clickHandler:start()

  return resizer
end

function SkyRocket:stop()
  self.dragging = false
  self.dragType = nil

  self.windowCanvas:hide()
  self.cancelHandler:stop()
  self.dragHandler:stop()
  self.clickHandler:start()
end

function SkyRocket:isResizing()
  return self.dragType == dragTypes.resize
end

function SkyRocket:isMoving()
  return self.dragType == dragTypes.move
end

function SkyRocket:handleDrag()
  return function(event)
    if not self.dragging then return nil end

    local dx = event:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
    local dy = event:getProperty(hs.eventtap.event.properties.mouseEventDeltaY)

    if self:isMoving() then
      local current = self.windowCanvas:topLeft()
      self.windowCanvas:topLeft({
        x = current.x + dx,
        y = current.y + dy,
      })
      return true
    elseif self:isResizing() then
      local current = self.windowCanvas:frame()

      local m = margin / 2
      if mH <= -m and mV <= m and mV > -m then -- 9 o'clock
        self.windowCanvas:topLeft({
          x = current.x + dx,
          y = current.y,
        })
        self.windowCanvas:size({
          w = current.w - dx,
          h = current.h
        })
      elseif mH <= -m and mV <= -m then -- 10:30
        self.windowCanvas:topLeft({
          x = current.x + dx,
          y = current.y + dy,
        })
        self.windowCanvas:size({
          w = current.w - dx,
          h = current.h - dy
        })
      elseif mH > -m and mH <= m and mV <= -m then -- 12 o'clock
        self.windowCanvas:topLeft({
          x = current.x,
          y = current.y + dy,
        })
        self.windowCanvas:size({
          w = current.w,
          h = current.h - dy
        })
      elseif mH > m and mV <= -m then -- 1:30
        self.windowCanvas:topLeft({
          x = current.x,
          y = current.y + dy,
        })
        self.windowCanvas:size({
          w = current.w + dx,
          h = current.h - dy
        })
      elseif mH > m and mV > -m and mV <= m then -- 3 o'clock
        self.windowCanvas:topLeft({
          x = current.x,
          y = current.y,
        })
        self.windowCanvas:size({
          w = current.w + dx,
          h = current.h
        })
      elseif mH > m and mV > m then -- 4:30
        self.windowCanvas:topLeft({
          x = current.x,
          y = current.y,
        })
        self.windowCanvas:size({
          w = current.w + dx,
          h = current.h + dy
        })
      elseif mV > m and mH <= m and mH > -m then -- 6 o'clock
        self.windowCanvas:topLeft({
          x = current.x,
          y = current.y,
        })
        self.windowCanvas:size({
          w = current.w,
          h = current.h + dy
        })
      elseif mH <= -m and mV > m then -- 7:30
        self.windowCanvas:topLeft({
          x = current.x + dx,
          y = current.y,
        })
        self.windowCanvas:size({
          w = current.w - dx,
          h = current.h + dy,
        })
      else
        local current = self.windowCanvas:topLeft()
        self.windowCanvas:topLeft({
          x = current.x + dx,
          y = current.y + dy,
        })
      end
      return true
    else
      return nil
    end
  end
end

function SkyRocket:handleCancel()
  return function()
    if not self.dragging then return end

    if self:isResizing() then
      self:resizeWindowToCanvas()
    else
      self:moveWindowToCanvas()
    end

    self:stop()
  end
end

function SkyRocket:resizeCanvasToWindow()
  local position = self.targetWindow:topLeft()
  local size = self.targetWindow:size()

  self.windowCanvas:topLeft({ x = position.x, y = position.y })
  self.windowCanvas:size({ w = size.w, h = size.h })

  -- determine in which part of the window the mouse pointer is when moving/resizing starts,
  -- this cannot happen in handleDrag() because this can only be done once at the beginning of each resizing (otherwise upper left increase of window size turns into lower right decrease)
  local frame = self.windowCanvas:frame()
  local x = frame.x
  local y = frame.y
  local w = frame.w
  local h = frame.h

  local mousePos = hs.mouse.absolutePosition()
  local mx = w + x - mousePos.x -- distance between right border of window and cursor
  local dmah = w / 2 - mx       -- absolute delta: mid window - cursor
  mH = dmah * 100 / w           -- delta from mid window: -50(left border of window) to 50 (left border)

  local my = h + y - mousePos.y
  local dmav = h / 2 - my
  mV = dmav * 100 / h -- delta from mid window in %: from -50(=top border of window) to 50 (bottom border)
end

function SkyRocket:resizeWindowToCanvas()
  if not self.targetWindow then return end
  if not self.windowCanvas then return end

  local frame = self.windowCanvas:frame()

  -- window is not allowed to extend past left and right margins of screen
  local win = self.targetWindow
  local max = win:screen():frame() -- max.x = 0; max.y = 0; max.w = screen width; max.h = screen height

  local xNew = frame.x
  local wNew = frame.w
  if frame.x < 0 then
    wNew = frame.w + frame.x
    xNew = 0
  elseif frame.x + frame.w > max.w then
    wNew = max.w - frame.x
    xNew = max.w - wNew
  end

  -- if window is resized past start of menu bar, height of window is corrected accordingly
  local maxWithMB = win:screen():fullFrame()
  -- compute only the menu bar height (exclude dock) using the origin difference
  local menuBarHeight = max.y - maxWithMB.y
  if menuBarHeight < 0 then menuBarHeight = 0 end

  local yNew = frame.y
  local hNew = frame.h

  if frame.y < menuBarHeight then
    hNew = frame.h + frame.y - menuBarHeight
    yNew = menuBarHeight
  end

  self.targetWindow:move(hs.geometry.new(xNew, yNew, wNew, hNew), nil, false, 0)
  self.targetWindow:focus()
end

function SkyRocket:moveWindowToCanvas()
  if not self.targetWindow then return end
  if not self.windowCanvas then return end

  local frame = self.windowCanvas:frame()

  self.targetWindow:move(hs.geometry.new(frame.x, frame.y, frame.w, frame.h), nil, false, 0)
  self.targetWindow:focus()
end

function SkyRocket:handleClick()
  return function(event)
    if self.dragging then return true end

    local flags = event:getFlags()
    local eventType = event:getType()

    local isMoving = eventType == self.moveStartMouseEvent and flags:containExactly(self.moveModifiers)
    local isResizing = eventType == self.resizeStartMouseEvent and flags:containExactly(self.resizeModifiers)

    if isMoving or isResizing then
      local currentWindow = getWindowUnderMouse()

      if currentWindow == nil then
        return nil
      else
        if self.disabledApps[currentWindow:application():name()] then
          return nil
        end
      end

      self.dragging = true
      self.targetWindow = currentWindow

      if isMoving then
        self.dragType = dragTypes.move
      else
        self.dragType = dragTypes.resize
      end

      self:resizeCanvasToWindow()
      self.windowCanvas:show()

      self.cancelHandler:start()
      self.dragHandler:start()
      self.clickHandler:stop()

      -- Prevent selection
      return true
    else
      return nil
    end
  end
end

return SkyRocket
