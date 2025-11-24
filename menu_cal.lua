-- hammerspoon menucal.lua
-- Fabio Celsalonga 03/2020
-- a special calendar on menubar

local moonphase = require "moonphase"
local mycalendar = require "mycalendar"

local function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local objmcal = {}
objmcal.__index = objmcal
objmcal.menucalMenu = nil
objmcal.menucalTimer = nil

function objmcal:init()
   assert(os.setlocale('it_IT'))
   self.menucalMenu = hs.menubar.new()
   self.updateMenucal()
   self.startUpdatingMenucal()
   return self
end

function objmcal.updateMenucal()
   local dataShortx = os.date("%x")
   local dataEstesa = os.date("%A %d %B %Y") --'{:%A %d %B %Y}'.format(now)
   local dataNormal = os.date("%d/%m/%Y")    --'{:%d/%m/%Y}'.format(now)
   local dataIntstd = os.date("%Y-%m-%d")
   local dataIntstf = os.date("%Y%m%d")
   local dataWeeknn = os.date("w.%V")
   local dataWeekyy = os.date("w.%V-%Y")
   local dataWeekdd = os.date("Settimana %V")

   -- con le due righe sotto si sceglie se elaborare una specifica data o oggi
   local oggiTable = os.date("*t")
   --local oggiTable = os.date("*t", os.time{year=2022, month=1, day=1})

   local annoElab = oggiTable.year

   -- sono sicuro che c'è un modo più elegante di ottenere lo stesso risultato,
   -- ma questo funziona e non me ne frega un cazzo se è poco elegante!
   -- ok trovato un modo un poco più elegante e che funziona per ogni valore di inc
   local function meseElab(inc)
      local mese = 1
      local anno = annoElab
      if inc == -1 then
         mese = oggiTable.month + inc
         if mese == 0 then
            mese = 12
            anno = anno - 1
         end
      elseif inc == 0 then
         mese = tonumber(oggiTable.month)|1
      elseif inc >= 1 then
         mese = oggiTable.month + inc
         if mese > 12 then
            anno = anno + 1
            mese = 0 + ((inc + oggiTable.month) % 12)
         end
      end
      -- print(string.format("%s %s", anno, mese))
      return anno, mese
   end

   local menuCalSub1Table = {
      { title = dataShortx,            fn = function() hs.pasteboard.setContents(dataShortx) end },
      { title = dataEstesa,            fn = function() hs.pasteboard.setContents(dataEstesa) end },
      { title = dataNormal,            fn = function() hs.pasteboard.setContents(dataNormal) end },
      { title = dataIntstd,            fn = function() hs.pasteboard.setContents(dataIntstd) end },
      { title = dataIntstf,            fn = function() hs.pasteboard.setContents(dataIntstf) end },
      { title = dataWeeknn,            fn = function() hs.pasteboard.setContents(dataWeeknn) end },
      { title = dataWeekyy,            fn = function() hs.pasteboard.setContents(dataWeekyy) end },
      { title = dataWeekdd,            fn = function() hs.pasteboard.setContents(dataWeekdd) end },
      { title = "-" },
      { title = "⌃ ⌘ ⌥ ⇥ ⌫", fn = function() hs.pasteboard.setContents("⌃ ⌘ ⌥ ⇥ ⌫") end },
      { title = "-" },
      { title = "ä ë ï ö ü ß",   fn = function() hs.pasteboard.setContents("ä ë ï ö ü ß") end },
   }

   local menuCalPrevMonth = {
      { title = MonthPrinter(meseElab(-1)),  disabled = true },
      { title = "-" },
    }
   
  local hotkeysList = hs.hotkey.getHotkeys()
  local menuItemHotKeys = {}
  
    for key, value in pairs(hotkeysList) do
        local item = { title = value["msg"] }
        table.insert(menuItemHotKeys, item)
    end


   local Title1 = hs.styledtext.ansi('\27[31mTrkColorPicker\27[0m\n')
   local menucalMenuTable = {
      { title = MonthPrinter(meseElab(0)), menu = menuCalPrevMonth },
      { title = "-" },
      { title = MonthPrinter(meseElab(1)) },
      { title = "-" },
      { title = MonthPrinter(meseElab(2)) },
      { title = "-" },
      { title = MonthPrinter(meseElab(3)) },
      { title = "-" },
      { title = MonthPrinter(meseElab(4)) },
      { title = "-" },
      { title = "Notes.app",               fn = function() hs.application.launchOrFocus('Notes.app') end },
      { title = Title1,                    fn = function() hs.application.launchOrFocus('TrkColorPicker') end },
      { title = "checked item",            checked = true },
      { title = "-" },
        { title = "Clipboard copia",         menu = menuCalSub1Table },
        { title = "Hot keys",         menu = menuItemHotKeys },
   }

   local menucalDateFormat = os.date("%a %d %b w.%V")
   local dd = os.date("%d")
   local mm = os.date("%m")
   local yy = os.date("%Y")
   local moonPhaseToday, moonPhaseTodayEmoji = TheMoon(dd, mm, yy)
   objmcal.menucalMenu:setTitle("🗓 " .. menucalDateFormat .. " " .. moonPhaseTodayEmoji)
   objmcal.menucalMenu:setTooltip(moonPhaseToday)
   objmcal.menucalMenu:setMenu(menucalMenuTable)
end

function objmcal.startUpdatingMenucal()
   objmcal.menucalTimer = hs.timer.doEvery(1200, objmcal.updateMenucal):start()
end

return objmcal
