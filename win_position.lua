-- win_position
-- Bind hotkey to move and/or resize window.
-- It's strong personalized to my preferences and workflow
-- The code it's almost self explanatory.

MyToolBar = require("hs.webview.toolbar")

ChooserToolBar = MyToolBar.new("myConsole", {
   { id = "select1", selectable = true, image = ImgStatusChk },
   { id = "NSToolbarSpaceItem" },
   { id = "select2", selectable = true, image = ImgStatusPrt },
   { id = "notShown", selectable = true, image = hs.image.imageFromName("NSBonjour") },
   { id = "NSToolbarFlexibleSpaceItem" },
   { id = "navGroup", label = "Navigation", groupMembers = { "navLeft", "navRight" }},
   { id = "navLeft", image = hs.image.imageFromName("NSGoLeftTemplate"), allowedAlone = false },
   { id = "navRight", image = hs.image.imageFromName("NSGoRightTemplate"), allowedAlone = false },
   { id = "NSToolbarFlexibleSpaceItem" },
   { id = "cust", label = "customize", fn = function() print("sto cazzo!") end, image = hs.image.imageFromName("NSAdvanced") }
}):canCustomize(false)
:autosaves(true)
:selectedItem("select1")
:setCallback(function(...)
   print("a", hs.inspect(table.pack(...)))
end)


-- layouts it's a structure for the "chooser" class
Layouts = {
   {
      name = "Finder work",
      description = "Finder on work positions",
      action = 1
   },
   {
      name = "Finder cascade",
      description = "All Finder window cascade spaced",
      action = 2
   },
   {
      name = "Finder center (single)",
      description = "All Finder window on grid",
      action = 3
   },
   {
      name = "Finder grid",
      description = "All Finder window on grid",
      action = 4
   },
}

function ApplyLayout(layout)
   local currentWin = hs.window.focusedWindow()
   local screen = currentWin:screen():frame()
   local fV = { x = 4, y = 640, w = 920, h = 620 }
   local fD = { x = 4, y = 26, w = 920, h = 600 }
   local fU = { x = 1200, y = 320, w = 920, h = 720 }
   local c1 = { x = (screen.w / 4), y = (screen.h / 4), w = 1024, h = 768 }

   if layout.action == 1 then
      print(layout.name .. "selected!")
      local finderWindowOpen = hs.window.filter.new { 'Finder', 'ForkLift' }
      local xV, xD, xU = 0, 0, 0
      for _, win in ipairs(finderWindowOpen:getWindows()) do
         if win ~= nil and string.find(win:title(), "lavoro") then
            xV = xV + 1
            if xV > 1 then fV.x = fV.x + 16 + fV.w end
            win:setFrame(fV)
         end
         if win ~= nil and string.find(win:title(), "Download") then
            xD = xD + 1
            if xD > 1 then
               fD.x = fD.x + 20;
               fD.y = fD.y + 20
            end
            win:setFrame(fD)
         end
         if win ~= nil and string.find(win:title(), "Documenti") then
            xU = xU + 1
            if xU > 1 then
               fU.x = fU.x + 40;
               fU.y = fU.y + 40
            end
            win:setFrame(fU)
         end
      end
   end
   if layout.action == 2 then
      local finderWindowOpen = hs.window.filter.new { 'Finder', 'ForkLift' }
      local listOfWindows = finderWindowOpen:getWindows()
      CascadeWindow(listOfWindows)
   end
   if layout.action == 3 then
      currentWin:setFrame(c1)
   end

   currentWin:focus()
end

LayoutChooser = hs.chooser.new(function(selection)
   if not selection then return end
   ApplyLayout(Layouts[selection.index])
end)

local i = 0
LayoutChooser:choices(hs.fnutils.imap(Layouts, function(layout)
   i = i + 1
   return {
      index = i,
      text = layout.name,
      subText = layout.description
   }
end))

LayoutChooser:rows(#Layouts)
LayoutChooser:width(30)
LayoutChooser:rows(6)
LayoutChooser:subTextColor({ red = 0, green = 0, blue = 1, alpha = 0.8 })
LayoutChooser:attachedToolbar(ChooserToolBar)


function MoveWindow(direction)
   return function()
      local win = hs.window.focusedWindow()
      if win == nil then
         win = hs.window.frontmostWindow()
         win:focus()
         print(win:application())
      end
      local app       = win:application()
      local win_tit   = win:title()
      local app_name  = app:name()
      local f         = win:frame()
      local screen    = win:screen()
      local max       = screen:frame()
      local animtime  = 0.0
      local noResize  = string.find(app_name, "VMware") or false
      local isFinder  = string.find(app_name, "Finder") or false
      local isPreview = string.find(app_name, "Anteprima") or false

      if direction == "left" then
         if isPreview then
            f.x = max.x + 32
            f.y = max.h * 0.15
            f.w = (max.w / 4) - 9
            f.h = f.w * 1.5
            animtime = 0.5
         else
            f.x = max.x + 6
            f.y = max.y + 10
            f.w = (max.w / 2) - 9
            f.h = max.h - 20
            animtime = 0.2
         end
      elseif direction == "right" then
         if isPreview then
            f.y = max.h * 0.15
            f.w = (max.w / 4) - 32
            f.h = f.w * 1.5
            f.x = (max.w - f.w) - 64
            animtime = 0.5
         else
            f.x = (max.x + (max.w / 2)) + 3
            f.y = max.y + 10
            f.w = (max.w * 0.5) - 128
            f.h = max.h - 20
            animtime = 0.2
         end
      elseif direction == "up" then
         f.h = f.h - 32
         f.w = f.w - 16
      elseif direction == "down" then
         f.h = f.h + 32
         f.w = f.w + 16
      elseif direction == "home" then
         f.x = max.x + 6
         f.y = max.y + 10
         f.w = (max.w / 2) - 9
         f.h = max.h - 20
         animtime = 0.3
      elseif direction == "end" then
         f.x = (max.x + (max.w / 2)) + 3
         f.y = max.y + 10
         f.w = (max.w * 0.5) - 128
         f.h = max.h - 20
         animtime = 0.3
      elseif direction == "restore" then
         f.x = (max.x + (max.w / 4)) + 6
         f.y = (max.y + (max.h / 12)) + 6
         f.w = (max.w * 3 / 6)
         f.h = (max.h * 3 / 4)
         animtime = 0.2
      elseif direction == "PgUp" then
         if f.h >= (max.h - 12) then
            f.x = (max.x + (max.w * 0.25)) - 128
            f.y = (max.y + (max.h * 0.005))
            f.w = (max.w * 0.60)
            f.h = (max.h * 0.70)
         else
            f.x = max.x + 6
            f.y = max.y + 6
            f.w = max.w - 128
            f.h = max.h - 12
         end
         animtime = 0.2
      elseif direction == "PgDown" then
         if f.h >= (max.h - 12) then
            f.x = (max.x + (max.w * 0.25)) - 128
            f.y = (max.y + (max.h * 0.70)) + 12
            f.w = (max.w * 0.60)
            f.h = (max.h * 0.30) - 12
         else
            f.x = (max.x + (max.w / 8))
            f.y = max.y + 6
            f.w = (max.w * 3 / 4) - 12
            f.h = max.h - 12
         end
         animtime = 0.2
      end

      if direction == "minimize" then
         win:minimize()
      else
         if noResize then
            print("winposition not resizable! " .. app_name)
            print(" x " .. f.x .. " y " .. f.y .. " w " .. f.w .. " h " .. f.h)
         else
            win:setFrame(f, animtime)
            --hs.alert.show(app_name .. " - new geometry: " .. " x " .. f.x .. " y " .. f.y .. " w " .. f.w .. " h " .. f.h)
            print(" x " .. max.x .. " y " .. max.y .. " w " .. max.w .. " h " .. max.h)
            print(" x " .. f.x .. " y " .. f.y .. " w " .. f.w .. " h " .. f.h)
         end
      end
   end
end

function CascadeWindow(windows)
   local cascadeSpacing = 40
   if windows == nil then windows = hs.window.orderedWindows() end
   local screen = windows[1]:screen():frame()
   local nOfSpaces = #windows - 1

   local xMargin = screen.w / 10 -- unused horizontal margin
   local yMargin = 20            -- unused vertical margin

   for i, win in ipairs(windows) do
      local offset = (i - 1) * cascadeSpacing
      local rect = {
         x = xMargin + offset,
         y = screen.y + yMargin + offset,
         w = (screen.w / 2) - (2 * xMargin) - (nOfSpaces * cascadeSpacing),
         h = (screen.h / 2) - (2 * yMargin) - (nOfSpaces * cascadeSpacing),
      }
      win:setFrame(rect)
   end
end

function NextWindowFocus()
   local curWinFocus = hs.window.focusedWindow()
   local windows = hs.window.orderedWindows()
   local nextWindow = nil
   nextWindow = curWinFocus:focusWindowEast(windows, false, false)
   if nextWindow == false then
      nextWindow = curWinFocus:focusWindowNorth(windows, false, false)
   end
   if nextWindow == false then
      nextWindow = curWinFocus:focusWindowWest(windows, false, false)
   end
   if nextWindow == false then
      nextWindow = curWinFocus:focusWindowSouth(windows, false, false)
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
hs.hotkey.bind(Hyper, "home", MoveWindow("home"))
hs.hotkey.bind(Hyper, "end", MoveWindow("end"))
hs.hotkey.bind(Hyper, "m", MoveWindow("minimize"))
hs.hotkey.bind(Hyper, "r", MoveWindow("restore"))
hs.hotkey.bind(Hyper, "t", MoveWindow("test"))
hs.hotkey.bind(Hyper, ",", function() LayoutChooser:show() end)
-- hs.hotkey.bind(Hyper, "space", function()cascadeWindow()end)
hs.hotkey.bind("shift", "f18", function() NextWindowFocus() end)
hs.hotkey.bind(Hyper, "pad1", moveWindowToDisplay(1))
hs.hotkey.bind(Hyper, "pad2", moveWindowToDisplay(2))
hs.hotkey.bind(Hyper, "pad3", moveWindowToDisplay(3))
