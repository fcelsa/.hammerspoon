--- === HCalendar ===
---
--- A horizonal calendar inset into the desktop
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HCalendar.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/HCalendar.spoon.zip)
--- modified by fcelsa 2022 2023


local obj={}
obj.__index = obj

-- Metadata
obj.name = "HCalendar"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.hcalw = 31*24+20
obj.hcalh = 100
obj.midlinecolor = {red=1, blue=1, green=1, alpha=0.5}


-- parte aggiunta per showimage
local screen = hs.window.focusedWindow():screen():frame()
obj.calImageW = 1024
obj.calImageH = 768
obj.calImageX = 10 -- screen.w / 2
obj.calImageY = screen.h - 16 - obj.calImageH --screen.h / 2

function obj:CreateCalImage()
    obj.imgCanvas = hs.canvas.new({ x = obj.calImageX, y = obj.calImageY, w = obj.calImageW, h = obj.calImageH })
    obj.imgCanvas:appendElements({
        id = 'calImage',
        type = 'image',
        image = hs.image.imageFromPath(os.getenv("HOME") .. '/.hammerspoon/assets/images/2023.png'),
        imageScaling = 'scaleProportionally',
        imageAnimates = true,
        imageAlpha = .8,
        withShadow = true,
    })

    local c = obj.imgCanvas:canvasMouseEvents(true, nil, nil, nil)
    local d = obj.imgCanvas:mouseCallback(function()
        if c:isShowing() and c:isOccluded() then
            c:bringToFront(false)
        else
            c:sendToBack()
        end

        end)
    
end


-- fine parte aggiunta per showimage



--- HCalendar.showProgress (Boolean)
--- Variable
--- Control whether or not progress through the month is shown.

local function updateHcalCanvas()

    -- fcelsa add: flowed day % year flowed and set title string, with week number
    local ndayPercent = ((os.date("%j") / 366) * 100)
    local titlestr = os.date("%Y  " .. math.floor(ndayPercent) .. "%%" .. "          %B") ..
        "     🗓      s " .. os.date("%V")
    

    obj.canvas[2].text = titlestr
    local currentyear = os.date("%Y")
    local currentmonth = os.date("%m")
    local currentday = os.date("%d")
    local weeknames = {"Do", "Lu", "Ma", "Me", "Gi", "Ve", "Sa"}
    local firstdayofnextmonth = os.time{year=currentyear, month=currentmonth+1, day=1}
    local lastdayofcurrentmonth = os.date("*t", firstdayofnextmonth-24*60*60).day
    local midlinecolor = obj.midlinecolor
    for i=1,lastdayofcurrentmonth do  -- fabio fix? i=1,31 no! ma ,lastdayofcurrentmonth
        local weekdayofqueriedday = os.date("*t", os.time{year=currentyear, month=currentmonth, day=i}).wday
        local mappedweekdaystr = weeknames[weekdayofqueriedday]
        obj.canvas[2+i].text = mappedweekdaystr
        obj.canvas[64+i].text = i
        if mappedweekdaystr == "Sa" then
            obj.canvas[2+i].textColor = {hex="#d0cdd7"}
            obj.canvas[33+i].fillColor = {hex="#d0cdd7"}
            obj.canvas[64+i].textColor = {hex="#d0cdd7"}
        end
        if mappedweekdaystr == "Do" then
            obj.canvas[2+i].textColor = {hex="#FF5520"}
            obj.canvas[33+i].fillColor = {hex="#FF5520"}
            obj.canvas[64+i].textColor = {hex="#FF5520"}
        end
        if obj.showProgress and i < math.tointeger(currentday) then
            obj.canvas[33+i].fillColor = {hex="#00BAFF", alpha=0.6}
            obj.canvas[96].frame.x = tostring((10+24*(i-1))/obj.hcalw)
        elseif i == math.tointeger(currentday) then
            obj.canvas[33+i].fillColor = {hex="#00BAFF", alpha=0.6}
            obj.canvas[96].frame.x = tostring((10+24*(i-1))/obj.hcalw)
            if obj.showProgress then
                local currentHour = os.date('%H')
                local currentMinute = os.date('%M')
                local totalMinutes = 1440
                local percentCurrentDay = (60*currentHour)/totalMinutes
                -- midline rectangle is 24 long and 0 < currentHour < 24
                -- therefore the width is the current hour
                obj.canvas[33+i].frame.w = tostring(currentHour/(obj.hcalw-20))
                --(10 + 24i - 24)/obj.hcalw
                -- (24i - 14)/obj.hcalw
                -- 10+24i is next day
                obj.canvas[97].frame.x = tostring(obj.canvas[33+i].frame.w + obj.canvas[33+i].frame.x)
                obj.canvas[97].frame.w = tostring((24-currentHour)/(obj.hcalw-20))
                if mappedweekdaystr == "Sa" or mappedweekdaystr == "Do" then
                    obj.canvas[97].fillColor = {hex="#FF7878"}
                end
            end
--        else
--            obj.canvas[33+i].fillColor = midlinecolor
        end
        -- hide extra day
        if i > lastdayofcurrentmonth then
            obj.canvas[2+i].textColor.alpha = 0
            obj.canvas[33+i].fillColor.alpah = 0
            obj.canvas[64+i].textColor.alpah = 0
        end
        -- conditionally show progress fill bar
        if obj.showProgress then
            obj.canvas[97].fillColor.alpha = 0.5
        else
            obj.canvas[97].fillColor.alpha = 0
        end

    end

    -- year flowing update
    local flowedYear = (string.match((obj.canvas[98].frame.w) , "%d%d") * ndayPercent) / 100
    obj.canvas[99].frame.w = tostring(flowedYear .."%")

    -- trim the canvas
    obj.canvas:size({
        w = lastdayofcurrentmonth*24+20,
        h = 100
    })

end

--- HCalendar:createCanvas()
--- Method
--- Create the calendar canvas
function obj:createCanvas()
    if obj.canvas then
        return obj.canvas
    end

    local hcalbgcolor = {red=0, blue=0, green=0, alpha=0.3}
    local hcaltitlecolor = {red=1, blue=1, green=1, alpha=0.7}
    local todaycolor = {red=0.8, blue=1, green=0.8, alpha=0.3}
    local midlinecolor = {red=1, blue=1, green=1, alpha=0.5}
    local cscreen = hs.screen.mainScreen()
    local cres = cscreen:fullFrame()
    local canvas = hs.canvas.new({
        x = 12,
        y = cres.h-obj.hcalh-12,
        w = obj.hcalw,
        h = obj.hcalh,
    })

    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:level(hs.canvas.windowLevels.desktopIcon + 1)

    canvas[1] = {
        id = "hcal_bg",
        type = "rectangle",
        action = "fill",
        fillColor = hcalbgcolor,
        roundedRectRadii = { xRadius = 10, yRadius = 10 },
    }

    canvas[2] = {
        id = "hcal_title",
        type = "text",
        text = "",
        textSize = 18,
        textColor = hcaltitlecolor,
        textAlignment = "left",
        frame = {
            x = tostring(10/obj.hcalw),
            y = tostring(10/obj.hcalh),
            w = tostring(1-20/obj.hcalw),
            h = "30%"
        }
    }

    -- upside weekday string
    for i=3, 3+30 do
        canvas[i] = {
            type = "text",
            text = "",
            textFont = "Menlo",
            textSize = 13,
            textAlignment = "center",
            frame = {
                x = tostring((10+24*(i-3))/obj.hcalw),
                y = "45%",
                w = tostring(24/(obj.hcalw-20)),
                h = "23%"
            }
        }
    end

    -- midline rectangle
    for i=34, 34+30 do
        canvas[i] = {
            type = "rectangle",
            action = "fill",
            fillColor = midlinecolor,
            frame = {
                x = tostring((10+24*(i-34))/obj.hcalw),
                y = "65%",
                w = tostring(24/(obj.hcalw-20)),
                h = "4%"
            }
        }
    end

    -- downside day string
    for i=65, 65+30 do
        canvas[i] = {
            type = "text",
            text = "",
            textFont = "Menlo",
            textSize = 13,
            textAlignment = "center",
            frame = {
                x = tostring((10+24*(i-65))/obj.hcalw),
                y = "70%",
                w = tostring(24/(obj.hcalw-20)),
                h = "23%"
            }
        }
    end

    -- today cover rectangle
    canvas[96] = {
        type = "rectangle",
        action = "fill",
        fillColor = todaycolor,
        roundedRectRadii = {xRadius = 3, yRadius = 3},
        frame = {
            x = tostring(10/obj.hcalw),
            y = "44%",
            w = tostring(24/(obj.hcalw-20)),
            h = "46%"
        }
    }

    -- today progress midline
    canvas[97] = {
        type = "rectangle",
        action = "fill",
        fillColor = midlinecolor,
        frame = {
            x = tostring(10/obj.hcalw),
            y = "65%",
            w = tostring(24/(obj.hcalw-20)),
            h = "4%"
        }
    }

    -- fcelsa add: full year line
    canvas[98] = {
        type = "rectangle",
        action = "fill",
        fillColor = {red=0, blue=1, green=0, alpha=0.3},
        frame = {
            x = tostring(10/obj.hcalw),
            y = tostring(30/obj.hcalh),
            w = "12%",
            h = "4%"
            }
    }

    -- fcelsa add: prepared year flowed line
    canvas[99] = {
        type = "rectangle",
        action = "fill",
        fillColor = {red=0, blue=1, green=0, alpha=0.8},
        frame = {
            x = tostring(10/obj.hcalw),
            y = tostring(30/obj.hcalh),
            w = "1%",
            h = "4%"
            }
    }

    return canvas
end

--- HCalendar:init()
--- Method
--- Initializes the spoon
function obj:init()
    self.canvas = self:createCanvas()
    if self.timer == nil then
        self.timer = hs.timer.doEvery(1800, function() updateHcalCanvas() end)
        self.timer:setNextTrigger(0)
    end
    self:start()

    return self
end

--- HCalendar:start()
--- Method
--- Start HCalendar timer and show the canvas
function obj:start()
    if self.timer == nil then
        self.timer = hs.timer.doEvery(1800, function() updateHcalCanvas() end)
        self.timer:setNextTrigger(0)
    else
        self.timer:start()
    end
    if self.canvas then
        self.canvas:show()
    end

    self:CreateCalImage()

    self.canvas:canvasMouseEvents(nil, true, true, nil)
    self.canvas:mouseCallback(
            function(_, event, id, x, y) print("Mouse event " ..
                event .. " happening! for id " .. id .. " at coordinates " .. x .. "  " .. y)
                if event == "mouseUp" then
                    if obj.imgCanvas:isShowing() then
                        obj.imgCanvas:hide(.9)
                    else
                        obj.imgCanvas:show(.9)
                        obj.imgCanvas:bringToFront(false)
                    end
                end

            end
    )

    return self
end

--- HCalendar:stop()
--- Method
--- Stop HCalendar timer and hide the canvas
function obj:stop()
    if self.timer then
        self.timer:stop()
    end
    if self.canvas then
        self.canvas:hide()
    end

    return self
end

return obj
