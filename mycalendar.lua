-- mycalendar.lua
-- Marzo 2020
-- Scritto nel periodo di blocco per l'epidemia COVID-19, giusto per memoria.
-- output multi month ansi calendar
-- 31/03/2020 
-- bug fix monthEsteso non tornava correttamente il mese, perché se chiedo che mese esteso è il 31 di Febbraio... Lua giustamente non mi manda in culo, ma mi ritorna Marzo!!
-- bug fix Agosto 2020 ha il 31 di lunedi che non veniva visualizzato se l'output del mese era impostato con inizio il lunedi, non usciva la riga in più.


local fgBlk = "\27[0;30m"     -- black
local fgRed = "\27[0;31m"     -- red
local fgGrn = "\27[0;32m"     -- green
local fgYel = "\27[0;33m"     -- yellow
local fgBlu = "\27[0;34m"     -- blue
local fgMgn = "\27[0;35m"     -- magenta
local fgCya = "\27[0;36m"     -- cyan
local fgWht = "\27[0;37m"     -- white  (anche se quasi mai è un white vero, per esempio powershell win10 è 204,204,204 xterm è 229 putty 187 e Terminale macOS è 203,204,205
local fgBBlk = "\27[0;90m"     -- bright Black
local fgBRed = "\27[0;91m"     -- bright red
local fgBGrn = "\27[0;92m"     -- bright green
local fgBYel = "\27[0;93m"     -- bright yellow
local fgBBlu = "\27[0;94m"     -- bright blue
local fgBMgn = "\27[0;95m"     -- bright magenta
local fgBCya = "\27[0;96m"     -- bright cyan
local fgBWht = "\27[0;97m"     -- bright white
local ansiReset = "\27[0m"        -- return to normal at EOL
local highlB = "\27[44;37;33m"  -- evidenziato blue giallo
local highlBB = "\27[44;37;104m"  -- evidenziato blue chiaro giallo

local function calc_easter(year)
    -- Return Easter Sunday and Monday for the given year in the form GG-MM
    local a = year % 19
    local b = year // 100
    local c = year % 100
    local d = (19 * a + b - b // 4 - ((b - (b + 8) // 25 + 1) // 3) + 15) % 30
    local e = (32 + 2 * (b % 4) + 2 * (c // 4) - d - (c % 4)) % 7
    local f = d + e - 7 * ((a + 11 * d + 22 * e) // 451) + 114
    local month = f // 31
    local day = f % 31 + 1
    local mday = day + 1
    return string.format("%02d-%02d", day, month), string.format("%02d-%02d", mday, month)
end

local function isHoliday(selectedYear, selectedMonth, selectedDay)
    -- holydays list, default Italian; you can adjust this to your needs
    -- automatic append Easter date (sunday and monday) for the selectedYear
    -- function return two values, true if day, month pairs it's in the list
    -- and the whole description of the festive day.
    -- selectedYear it's AAAAA selectedMonth it's MM selectedDay it's DD integer
    local h_list = {
                    ['01-01'] = 'Capodanno', 
                    ['06-01'] = 'Epifania', 
                    ['25-04'] = 'Anniversario Liberazione', 
                    ['01-05'] = 'Festa del Lavoro', 
                    ['02-06'] = 'Festa della Repubblica', 
                    ['15-08'] = 'Ferragosto', 
                    ['01-11'] = 'Tutti i Santi', 
                    ['08-12'] = 'Immacolata', 
                    ['25-12'] = 'Natale', 
                    ['26-12'] = 'Santo Stefano',
                    }

    local easter_sunday, easter_monday = calc_easter(selectedYear)
    h_list[easter_sunday] = 'Pasqua'
    h_list[easter_monday] = 'Lunedi di Pasqua'
    --table.insert(h_list, easter_sunday)
    --table.insert(h_list, easter_monday)
    
    local matched = false
    local value = ""
    local dateToMatch = string.format("%02d-%02d", selectedDay, selectedMonth)
    for k, v in pairs(h_list) do
        if k == dateToMatch then
            matched = true
            value = v
            break
        end
    end
    return matched, value
end

function monthPrinter(anno, mese)
    local annoElab = anno
    local meseElab = mese
    -- table con la rappresentazione della data di oggi
    local oggi = os.date("*t")
    -- oggi.year
    -- oggi.month
    -- oggi.day
    -- oggi.yday è il giorno dell'anno 1= 1 Gennaio
    -- oggi.wday è il giorno della settimana 1= Domenica

    local function get_days_in_month(mnth, yr)
        local days = os.date('*t',os.time{year=yr,month=mnth+1,day=0})['day']
        print("days in month: " .. days)
        return days
    end

    local function get_day_of_week(dd, mm, yy) 
        local days = { "Do", "Lu", "Ma", "Me", "Gi", "Ve", "Sa" }
        local mmx = mm
        if (mm == 1) then  mmx = 13; yy = yy-1  end
        if (mm == 2) then  mmx = 14; yy = yy-1  end
        local val8 = dd + (mmx*2) +  math.floor(((mmx+1)*3)/5)   + yy + math.floor(yy/4)  - math.floor(yy/100)  + math.floor(yy/400) + 2
        local val9 = math.floor(val8/7)
        local dw = val8-(val9*7) 
        if (dw == 0) then
          dw = 7
        end
        return dw, days[dw]
    end

    local function getWeekNumber(day)
        return os.date("%V",os.time{year=annoElab,month=meseElab,day=day})
    end

    local yy, mm, dd = tonumber(annoElab), tonumber(meseElab), tonumber(oggi.day)
    local month_days = get_days_in_month(mm, yy)
    local day_week = get_day_of_week(1, mm, yy)
    local day_start = 2     -- giorno di inizio della settimana 1=Domenica, 2=Lunedi
    local days_of_week = {{ "Dom", 1 }, { "Lun", 2 } , { "Mar", 3 }, { "Mer", 4 }, { "Gio", 5 }, { "Ven", 6 }, { "Sab", 7 }}
    local days_of_week_ordered = {}
  
    for k=1, 7 do
        p = k+day_start-1
        if (p>7) then
            p=p-7
        end
        v = {}
        v.dayname = days_of_week[p][1]
        v.daynum = days_of_week[p][2]
        table.insert(days_of_week_ordered, v)
    end

    -- si inizia con l'intestazione anno mese ...
    local monthEsteso = os.date("%B",os.time{year=annoElab,month=meseElab,day=1}) 
    local out = hs.styledtext.ansi(annoElab .. "       " .. monthEsteso .. "\n", {font={name="Monospac821 BT",size=16}})
    out = out .."W |"
    for i,v in ipairs(days_of_week_ordered) do
        if v.dayname == "Sab" then 
            out = out .. hs.styledtext.ansi(fgMgn .. " Sab" .. ansiReset, {font={name="Monospac821 BT",size=16}})
        elseif v.dayname == "Dom" then
            out = out .. hs.styledtext.ansi(fgRed .. " Dom" .. ansiReset, {font={name="Monospac821 BT",size=16}})
        else
            out = out .. hs.styledtext.ansi(" " .. v.dayname, {font={name="Monospac821 BT",size=16}})
        end
        if (day_week == v.daynum) then
            d = - i + 2
        end
    end
    out = out .. hs.styledtext.ansi("\n" .. ansiReset, {font={name="Monospac821 BT",size=16}})

    local festivi = ""

    while (d < month_days+1) do
        -- colonna del numero della settimana
        local weekNumber = getWeekNumber(d)
        if weekNumber == os.date("%V",os.time{year=oggi.year,month=oggi.month,day=oggi.day}) then 
            out = out .. hs.styledtext.ansi( fgBlu .. getWeekNumber(d) .. "*".. ansiReset, {font={name="Monospac821 BT",size=16}})
        else
            out = out .. hs.styledtext.ansi( fgBBlk .. getWeekNumber(d) .. "|".. ansiReset, {font={name="Monospac821 BT",size=16}})
        end
        -- inizia il ciclo dei giorni del mese
        local weekOut = ""
        local formD = ""
        local trimSpace = false
        for i,v in ipairs(days_of_week) do
            if (d>=1 and d <=month_days) then
                if trimSpace then 
                    formD = string.format("%3s", d)
                else
                    formD = string.format("%4s", d)
                end
                if os.date("*t", os.time{year=annoElab,month=meseElab,day=d})['wday'] == 7 then
                    --print(string.format("[DEBUG]  %02d %02d", d, os.date("*t", os.time{year=annoElab,month=meseElab,day=d})['wday']))
                    weekOut = weekOut .. fgMgn
                end
                if os.date("*t", os.time{year=annoElab,month=meseElab,day=d})['wday'] == 1 or isHoliday(yy, mm, d) then
                    weekOut = weekOut .. fgRed
                    local giorno, festivo = isHoliday(yy, mm, d)
                    if giorno then 
                        festivi = festivi .. "\n" .. string.format("    %2s", d) .. "  " .. festivo
                    end
                end
                if d==dd and mm == oggi.month then
                    weekOut = weekOut .. fgBlu .. " [" .. string.format("%-2s", d) .. "]" .. ansiReset
                    trimSpace = true
                else
                    weekOut = weekOut .. formD .. ansiReset
                    trimSpace = false
                end
            else
                weekOut = weekOut .. "    " .. ansiReset
            end
            --print(weekOut)
            d = d + 1
        end
        out = out .. hs.styledtext.ansi(weekOut .. ansiReset .."\n", {font={name="Monospac821 BT",size=16}})
    end
    
    if string.len(festivi) > 1 then 
        out = out .. hs.styledtext.ansi( fgRed .. festivi .. ansiReset, {font={name="Monospac821 BT",size=13}})
    end

    return out

end
