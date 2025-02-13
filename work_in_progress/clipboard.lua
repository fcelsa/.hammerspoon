-- clipboard.lua
-- Marzo 2020
-- Pasteboard/clipboard management code for hammerspoon


local obj = {}
obj.__index = obj
obj.mainMenu = nil
obj.subMenu1 = nil

local iconAscii = [[ASCII:
............
.0123456789.
.A........b.
.B........c.
.C........d.
.D........e.
.E........f.
.F..........
.G..........
.H..........
.I..........
.J..........
.Kabcdeghij.
............
]]

local colorRED = {red=255/255, green=0/255, blue=0/255}
local colorPINK = {red=255/255, green=192/255, blue=203/255}
local colorORANGE = {red=255/255, green=165/255, blue=0/255}
local colorYELLOW = {red=255/255, green=255/255, blue=0/255}
local colorPURPLE = {red=128/255, green=0/255, blue=128/255}
local colorGREEN = {red=0/255, green=128/255, blue=0/255}
local colorBLUE = {red=0/255, green=0/255, blue=255/255}
local colorBROWN = {red=165/255, green=42/255, blue=42/255}
local colorWHITE = {red=255/255, green=255/255, blue=255/255}
local colorGRAY = {red=128/255, green=128/255, blue=128/255}


function obj:listOfFiles()
   local listOfFileDir = {}
   local iterFn, dirObj = hs.fs.dir("/Volumes/PrimeData/lavoro condivisa/diessec")
   local file = dirObj:next() -- get the first file in the directory
   local i = 0
   while (file) do
       file = dirObj:next() -- get the next file in the directory
       table.insert(listOfFileDir, file)
       i = i + 1
   end
   dirObj:close() -- necessary to make sure that the directory stream is closed
   print(hs.inspect.inspect(listOfFileDir))
end



function obj:init()
   os.setlocale("it")
   self.mainMenu = hs.menubar.new()
   self.mainMenu:setIcon(iconAscii)
   self.mainMenu:setIcon(ImgStatusChk)
   self:mainMenuMaker()
   return self
end


function obj:mainMenuMaker()

   local itemRedStyle = hs.styledtext.new("RED", { color = colorRED })
   local indianred = hs.styledtext.new("indianred #CD5C5C", { color = { hex = "#CD5C5C" }})
   local lightcoral = hs.styledtext.new("lightcoral #F08080", { color = { hex = "#F08080" }})
   local salmon = hs.styledtext.new("salmon #FA8072", { color = { hex = "#FA8072" }})

   local subItemRedList = {
      { title = indianred, fn = function() hs.pasteboard.setContents("#CD5C5C") end },
      { title = lightcoral },
   }
   
   local mainMenuTable = {
      { title = "Color TrkColorPicker", fn = function() hs.application.launchOrFocus('TrkColorPicker') end },
      { title = "-" },
      { title = itemRedStyle, menu = subItemRedList },
      { title = "-" },
      { title = "stocazzo", fn = obj:listOfFiles() },
   }

   self.mainMenu:setMenu(mainMenuTable)

end

return obj
