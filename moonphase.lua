-- moonphase.lua
-- Moon phase for lua calendar manubar

local function roundToNthDecimal(num, n)
   local mult = 10 ^ (n or 0)
   return math.floor(num * mult + 0.5) / mult
end

local function julianDate(d, m, y)
   local mm, yy, k1, k2, k3, j
   yy = y - math.floor((12 - m) / 10)
   mm = m + 9
   if (mm >= 12) then
      mm = mm - 12
   end
   k1 = math.floor(365.25 * (yy + 4712))
   k2 = math.floor(30.6001 * mm + 0.5)
   k3 = math.floor(math.floor((yy / 100) + 49) * 0.75) - 38
   j = k1 + k2 + d + 59
   if (j > 2299160) then
      j = j - k3
   end
   return j
end

local function moonAge(d, m, y)
   local j, ip, ag
   j = julianDate(d, m, y)
   ip = (j + 4.867) / 29.53059
   ip = ip - math.floor(ip)
   if (ip < 0.5) then
      ag = ip * 29.53059 + 29.53059 / 2
   else
      ag = ip * 29.53059 - 29.53059 / 2
   end
   print(string.format("Moon age: %d", math.floor(ag)))
   print(string.format("Moon age: %.6f", ag))

   return ag
end

-- sarebbe da finire di perfezionare, capita che ritorni una fase per due giorni consecutivi

function TheMoon(d, m, y)
   local dayMoon = moonAge(d, m, y)
   local dayMoonText = ""
   local dayMoonEmoji = ""

   if dayMoon >= 28.01 then
      dayMoonText = "🌑 Luna nuova      "
      dayMoonEmoji = "🌑"
   elseif dayMoon < 28.01 and dayMoon > 23 then
      dayMoonText = "🌘 Luna calante    "
      dayMoonEmoji = "🌘"
   elseif dayMoon < 23 and dayMoon >= 20.09 then
      dayMoonText = "🌗 Ultimo quarto   "
      dayMoonEmoji = "🌗"
   elseif dayMoon < 20.09 and dayMoon > 15 then
      dayMoonText = "🌖 Gibbosa calante "
      dayMoonEmoji = "🌖"
   elseif dayMoon < 15 and dayMoon > 13 then
      dayMoonText = "🌕 Luna piena      "
      dayMoonEmoji = "🌕"
   elseif dayMoon < 13 and dayMoon > 8 then
      dayMoonText = "🌔 Gibbosa cresente"
      dayMoonEmoji = "🌔"
   elseif dayMoon < 8 and dayMoon >= 5.5 then
      dayMoonText = "🌓 Primo quarto    "
      dayMoonEmoji = "🌓"
   elseif dayMoon < 5.5 and dayMoon > 0.46 then
      dayMoonText = "🌒 Luna crescente  "
      dayMoonEmoji = "🌒"
   else
      dayMoonText = "🌑 Luna nuova      "
      dayMoonEmoji = "🌑"
   end
   return dayMoonText, dayMoonEmoji
end
