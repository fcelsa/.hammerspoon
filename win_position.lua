-- win_position
-- Bind hotkey to move and/or resize window.
-- It's strong personalized to my preferences and workflow.

function MoveWindow(direction)
   return function()
      local win = hs.window.focusedWindow()
      if win == nil then
         win = hs.window.frontmostWindow()
         win:focus()
      end
      local wAppObj   = win:application()
      local wAppTit   = win:title()
      local wAppName  = wAppObj:name()
      local wF        = win:frame()
      local screen    = win:screen()
      local sMax      = screen:fullFrame()
      local sFrame    = screen:frame()
      local animtime  = 0.2
      local noResize  = string.find(wAppName, "VMware") or false
      local isFinder  = string.find(wAppName, "Finder") or false
      local isPreview = string.find(wAppName, "Anteprima") or false

      if direction == "left" then
         if isPreview then
            wF.x = sMax.x + 32
            wF.y = sMax.h * 0.15
            wF.w = (sMax.w / 3.2)
            wF.h = wF.w * 1.6
            animtime = 0.4
         else
            wF.x = sMax.x -- + 6
            wF.y = sMax.y -- + 10
            wF.w = (sMax.w / 2) - 9
            wF.h = sMax.h -- - 20
         end
      elseif direction == "right" then
         if isPreview then
            wF.x = (sMax.w - wF.w) - 64
            wF.y = sMax.h * 0.15
            wF.w = (sMax.w / 4) - 32
            wF.h = wF.w * 1.6
            animtime = 0.4
         else
            wF.x = (sMax.x + (sMax.w / 2)) + 3
            wF.y = sMax.y + 10
            wF.w = (sMax.w * 0.5) - 128
            wF.h = sMax.h - 20
         end
      elseif direction == "up" then
         wF.h = wF.h - 32
         wF.w = wF.w - 16
      elseif direction == "down" then
         wF.h = wF.h + 32
         wF.w = wF.w + 16
      elseif direction == "home" then
         wF.x = sMax.x + 6
         wF.y = sMax.y + 10
         wF.w = (sMax.w / 2) - 9
         wF.h = sMax.h - 20
         animtime = 0.3
      elseif direction == "end" then
         wF.x = (sMax.x + (sMax.w / 2)) + 3
         wF.y = sMax.y + 10
         wF.w = (sMax.w * 0.5) - 128
         wF.h = sMax.h - 20
         animtime = 0.3
      elseif direction == "PgUp" then
         if wF.h >= (sMax.h - 12) then
            wF.x = (sMax.x + (sMax.w * 0.25)) - 128
            wF.y = (sMax.y + (sMax.h * 0.005))
            wF.w = (sMax.w * 0.60)
            wF.h = (sMax.h * 0.70)
         else
            wF.x = sMax.x + 6
            wF.y = sMax.y + 6
            wF.w = sMax.w - 128
            wF.h = sMax.h - 12
         end
         animtime = 0.2
      elseif direction == "PgDown" then
         if wF.h >= (sMax.h - 12) then
            wF.x = (sMax.x + (sMax.w * 0.25)) - 128
            wF.y = (sMax.y + (sMax.h * 0.70)) + 12
            wF.w = (sMax.w * 0.60)
            wF.h = (sMax.h * 0.30) - 12
         else
            wF.x = (sMax.x + (sMax.w / 8))
            wF.y = sMax.y + 6
            wF.w = (sMax.w * 3 / 4) - 12
            wF.h = sMax.h - 12
         end
         animtime = 0.2
      elseif direction == "minimize" then
         if not isFinder then
            win:minimize()
         else
            wF.w = sMax.w / 2.5
            wF.h = sMax.h / 4
            wF.x = sMax.w / 2 - (wF.w / 2)
            wF.y = sMax.h - wF.h
         end
      elseif direction == "restore" then
         if not isFinder then
            win:centerOnScreen()
            return
         else
            wF.w = sMax.w / 2.5
            wF.h = sMax.h / 3
            wF.x = sMax.w / 2 - (wF.w / 2)
            wF.y = sMax.h - wF.h
            win:setFrame(wF, animtime)
            win:centerOnScreen()
            return
         end
      end

      if noResize then
         print("winposition not resizable! " .. wAppName)
      else
         win:setFrame(wF, animtime)
         --hs.alert.show(app_name .. " - new geometry: " .. " x " .. f.x .. " y " .. f.y .. " w " .. f.w .. " h " .. f.h)
         print("full   :  max.x " .. sMax.x .. " max.y " .. sMax.y .. " max.w " .. sMax.w .. " max.h " .. sMax.h)
         print("frame  :  x " .. sFrame.x .. " y " .. sFrame.y .. " w " .. sFrame.w .. " h " .. sFrame.h)
         print("window :  x " .. wF.x .. " y " .. wF.y .. " w " .. wF.w .. " h " .. wF.h)
      end
   end
end

function CascadeWindow()
   return function()
      local cascadeSpacing = 40
      local windows = hs.window.orderedWindows()
      local screen = windows[1]:screen():frame()
      local nOfSpaces = #windows - 1

      local xMargin = screen.w / 10 -- unused horizontal margin
      local yMargin = 20            -- unused vertical margin

      for i, win in ipairs(windows) do
         local wAppObj  = win:application()
         local wAppName = wAppObj:name()
         local noResize = string.find(wAppName, "VMware") or string.find(wAppName, "Code") or false

         local offset   = (i - 1) * cascadeSpacing
         local rect     = {
            x = xMargin + offset,
            y = screen.y + yMargin + offset,
            w = (screen.w / 1.5) - (2 * xMargin) - (nOfSpaces * cascadeSpacing),
            h = (screen.h / 1.5) - (2 * yMargin) - (nOfSpaces * cascadeSpacing),
         }
         if not noResize then
            win:setFrame(rect)
         end
      end
   end
end

local function moveWindowToDisplay(d)
   return function()
      local displays = hs.screen.allScreens()
      local win = hs.window.focusedWindow()
      win:moveToScreen(displays[d], false, true)
   end
end

hs.hotkey.bind(Hyper, "Left", MoveWindow("left"))
hs.hotkey.bind(Hyper, "Right", MoveWindow("right"))
hs.hotkey.bind(Hyper, "Up", MoveWindow("up"))
hs.hotkey.bind(Hyper, "Down", MoveWindow("down"))
hs.hotkey.bind(Hyper, "PageUp", MoveWindow("PgUp"))
hs.hotkey.bind(Hyper, "PageDown", MoveWindow("PgDown"))
hs.hotkey.bind(Hyper, "home", CascadeWindow())
hs.hotkey.bind(Hyper, "end", MoveWindow("end"))
hs.hotkey.bind(Hyper, "m", MoveWindow("minimize"))
hs.hotkey.bind(Hyper, "r", MoveWindow("restore"))
hs.hotkey.bind(Hyper, "space", MoveWindow("restore")) -- alternate restore
hs.hotkey.bind(Hyper, "pad1", moveWindowToDisplay(1))
hs.hotkey.bind(Hyper, "pad2", moveWindowToDisplay(2))
hs.hotkey.bind(Hyper, "pad3", moveWindowToDisplay(3))
