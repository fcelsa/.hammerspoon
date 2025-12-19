
-- snippet code to manage alert messages without overlapping previous ones
-- This function shows how to manage hs.alert so that they do not appear one below the other in cascade,
-- but always close the previous alert before showing a new one.
local alert = require("hs.alert")
local alertUid = 0

local function handleAlert(parameter)
    if alertUid ~= 0 then
        alert.closeAll(3)
        alertUid = 0
    end
    alertUid = alert("alert prepend text " .. parameter .. " alert post text ", 3)
end


-- snippet code example for a chiooser with toolbar
MyToolBar = require("hs.webview.toolbar")

ChooserToolBar = MyToolBar.new("myConsole", {
       { id = "select1",                   selectable = true,                                   image = ImgStatusChk },
       { id = "NSToolbarSpaceItem" },
       { id = "select2",                   selectable = true,                                   image = ImgStatusPrt },
       { id = "notShown",                  selectable = true,                                   image = hs.image.imageFromName("NSBonjour") },
       { id = "NSToolbarFlexibleSpaceItem" },
       { id = "navGroup",                  label = "Navigation",                                groupMembers = { "navLeft", "navRight" } },
       { id = "navLeft",                   image = hs.image.imageFromName("NSGoLeftTemplate"),  allowedAlone = false },
       { id = "navRight",                  image = hs.image.imageFromName("NSGoRightTemplate"), allowedAlone = false },
       { id = "NSToolbarFlexibleSpaceItem" },
       {
          id = "cust",
          label = "customize",
          fn = function()
             print(
                "sto cazzo!")
          end,
          image = hs.image.imageFromName("NSAdvanced")
       }
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
