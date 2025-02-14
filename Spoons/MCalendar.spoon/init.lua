--- MCalendar hammerspoon spoon
---
--- Many month calendar on desktop
---
--- Download:

--- #TODO: make this a real spoon, remove caffeinateController and subscribe to new method with
--- hs.watchable - also set flags to avoid update when screen sleep .


local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MCalendar"
obj.version = "1.0.0"
obj.author = "<fabio.celsa@gmail.com>"
obj.homepage = "https://github.com/fcelsa"
obj.license = "MIT - https://opensource.org/licenses/MIT"


--- MCalendar.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('MCalendar', 'info')

--- MCalendar.tMonths
--- Variable
--- int total number of months in the main view
obj.tMonths = 6

--- MCalendar.pMonths
--- Variable
--- int number of months before the current to display
obj.pMonths = 2

--- MCalendar.screenTarget
--- Variable
--- int screen where want show MCalendar (1 primary screen)
obj.screenTarget = 2

--- MCalendar.bgAlpha
--- Variable
--- alpha value of the canvas
obj.bgAlpha = 0.6

--- MCalendar.defW
--- Variable
--- default width of canvas
obj.defW = 300
obj.defH = 150

-- local function to handle screen saver, lock/unloock events and sleep/wake
local function caffeinateController(eventType)
    if eventType == hs.caffeinate.watcher.screensDidUnlock then
        obj.logger.i("Screen unlocked")
        hs.timer.doAfter(29, function() obj.MCalCanvas:show() end)
    elseif eventType == hs.caffeinate.watcher.screensDidLock then
        obj.logger.i("Screen locked, then hide MCalCanvas")
        obj.MCalCanvas:hide()
    elseif eventType == hs.caffeinate.watcher.screensaverDidStart then
        obj.logger.i("Screen saver started")
        obj.MCalCanvas:hide()
    elseif eventType == hs.caffeinate.watcher.screensaverDidStop then
        obj.logger.i("Screen saver stopped")
        hs.timer.doAfter(29, function() obj.MCalCanvas:show() end)
    elseif eventType == hs.caffeinate.watcher.screensDidSleep then
        obj.logger.i("Screen went to sleep")
        obj.MCalCanvas:hide()
    elseif eventType == hs.caffeinate.watcher.screensDidWake then
        obj.logger.i("Screen woke up")
    elseif eventType == hs.caffeinate.watcher.systemWillSleep then
        obj.logger.i("The system is preparing to sleep")
        obj.MCalCanvas:stop()
    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        obj.logger.i("The system has woken up")
        obj.MCalCanvas:init()
    elseif eventType == hs.caffeinate.watcher.systemWillPowerOff then
        obj.logger.i("The system is preparing to power off")
    end
end



-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
obj.spoonPath = script_path()


obj.todayTable = os.date("*t")
-- todayTable = os.date("*t", os.time{year=2022, month=1, day=1})  -- to compute other date instead from today
obj.yearElab = obj.todayTable.year

local function monthElab(inc)
    local monthE = 1
    local yearE = obj.yearElab
    if inc < 0 then
        monthE = obj.todayTable.month + inc
        if monthE == 0 then
            monthE = 12
            yearE = yearE - 1
        end
    elseif inc == 0 then
        monthE = obj.todayTable.month + inc
    elseif inc >= 1 then
        monthE = obj.todayTable.month + inc
        if monthE > 12 then
            yearE = yearE + 1
            monthE = 0 + ((inc + obj.todayTable.month) % 12)
        end
    end
    return yearE, monthE
end

--- MCalendar:MCalCreateCanvas()
--- Method
--- create the canvas design
function obj:MCalCreateCanvas()
    if obj.MCalCanvas then
        return obj.MCalCanvas
    end

    local numScreens = 0
    for _ in pairs(hs.screen.allScreens()) do
        numScreens = numScreens + 1
    end

    local screen = hs.screen.allScreens()
    local screenFrame = screen[obj.screenTarget]:fullFrame()
    local rightBoundX = screenFrame.x1

    if numScreens > 1 and obj.screenTarget > 1 then
        rightBoundX = rightBoundX + 14
    else
        -- rightBoundX = rightBoundX - (obj.defW + 8)
        rightBoundX = 8
    end
    -- obj.logger.i("numScreens: " .. tostring(numScreens) .. "  screenFrame: " .. tostring(screenFrame))

    local bgColor = { red = 1, blue = 1, green = 1, alpha = 0.9 }
    local titleColor = { red = 1, blue = 1, green = 1, alpha = 0.7 }
    local headColor = { red = 0.2, blue = 0.4, green = 0.2, alpha = 0.95 }
    local midlinecolor = { red = 1, blue = 1, green = 1, alpha = 0.5 }

    local canvas = hs.canvas.new({
        x = rightBoundX,
        y = 140,
        w = obj.defW,
        h = obj.defH * obj.tMonths,
    })

    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:level(hs.canvas.windowLevels.desktopIcon + 1)
    canvas:alpha(0.6)

    canvas[1] = {
        id = "mcal_bg",
        type = "rectangle",
        action = "fill",
        fillColor = bgColor,
        roundedRectRadii = { xRadius = 8, yRadius = 8 },
    }


    canvas[2] = {
        id = "mcal_head",
        type = "text",
        text = "Prepare calendar...",
        textColor = headColor,
        textAlignment = "left",
        textSize = 18,
        frame = {
            x = 14,
            y = 10,
            w = "100%",
            h = "3%"
        }
    }

    local posX = 0
    local posY = 60
    local max_i = 3
    for i = 3, (obj.tMonths + 2) * 2, 1 do
        canvas[i] = {
            id = "mcal_mm" .. i,
            type = "text",
            text = "...init",
            textColor = titleColor,
            textAlignment = "left",
            textSize = 12,
            frame = {
                x = posX + 14,
                y = posY,
                w = "100%",
                h = "25%"
            }
        }
        posY = posY + 140
        if i > obj.tMonths + 1 and posX == 0 then
            posX = 300
            posY = 60
        end
        max_i = max_i + 1
    end

    canvas[max_i] = {
        id = "mcal_flowyear",
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, blue = 1, green = 0, alpha = 0.3 },
        frame = {
            x = 3,
            y = 32,
            w = 100,
            h = "0.3%"
        }
    }

    return canvas
end

--- MCalendar:MCalUpdate()
--- local function that update the canvas when needed.
local function MCalUpdate()
    local showing = obj.MCalCanvas:isShowing()
    if showing then
        --obj.MCalCanvas:bringToFront(true)
        return
    end

    local theMonth = ""
    local theHvsl = {}
    local imm = obj.pMonths * -1
    for inc = 3, (obj.tMonths + 2) * 2, 1 do
        theMonth, theHvsl[inc] = dofile(obj.spoonPath .. "ansicalendar.lua").monthPrinter(monthElab(imm))
        obj.MCalCanvas[inc].text = theMonth
        imm = imm + 1
    end

    local ndayPercent = ((os.date("%j") / 366) * 100)
    local titlestr = os.date("🗓   %Y                             " .. math.floor(ndayPercent) .. "%%")

    --obj.MCalCanvas[2].text = titlestr
    obj.MCalCanvas.mcal_head.text = titlestr

    --obj.MCalCanvas.mcal_mm3.textColor = {hex="#FF5520"}
    --obj.MCalCanvas.mcal_mm3.text = "Sti cazzi! cazzo!!"

    --for key, value in pairs(theHvsl) do
    --    print(theHvsl[key] .. " " .. value)
    --end

    obj.logger.i("update " .. tostring(showing))
end


--- MCalendar:init()
--- Method
--- default init entry point, prepare canvas and call start
function obj:init()
    self.logger.i("init happen!")
    self.MCalCanvas = self:MCalCreateCanvas()
    self:start()
    return self
end

--- MCalendar:start()
--- Method
--- default start MCalendar, start timer to update objects
function obj:start()
    if self.timer == nil then
        self.timer = hs.timer.doEvery(3600, function() MCalUpdate() end)
        self.timer:setNextTrigger(0)
    else
        self.timer:start()
    end
    if self.MCalCanvas then
        self.MCalCanvas:show()
        self.MCalCanvas:clickActivating(false)
    end

    if self.caffeinateWatcher == nil then
        self.caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateController)
        self.caffeinateWatcher:start()
    end

    local c = obj.MCalCanvas:canvasMouseEvents(true, true, true, false)
    c:mouseCallback(
        function(_, event, id, x, y)
            local currentSize = obj.MCalCanvas:size()
            local doubleSize = { h = currentSize.h, w = obj.defW * 2 }
            local defaultSize = { h = currentSize.h, w = obj.defW }
            --self.logger.i("event: " .. event .. " " .. x .. "  " .. y .. "  id:" .. id)
            --self.logger.i("Mcal current size " .. currentSize.w)
            if event == "mouseEnter" then
                obj.MCalCanvas:alpha(0.9)
                obj.MCalCanvas:level(hs.canvas.windowLevels.floating)
            end
            if event == "mouseExit" then
                obj.MCalCanvas:alpha(0.6)
                obj.MCalCanvas:level(hs.canvas.windowLevels.desktopIcon + 1)
            end
            if event == "mouseDown" and y >= 35 then
                obj.MCalCanvas:level(hs.canvas.windowLevels.dragging)
                if currentSize.w == defaultSize.w then
                    obj.MCalCanvas:size(doubleSize)
                else
                    obj.MCalCanvas:size(defaultSize)
                end
            end
            --if event == "mouseUp" then
                --obj.MCalCanvas:level(hs.canvas.windowLevels.desktopIcon + 1)
                --local newSize = { h = currentSize.h, w = obj.defW }
                --obj.MCalCanvas:size(newSize)
            --end
        end
    )
    return self
end

--- MCalendar:stop()
--- Method
--- Stop MCalendar timer and destroy the canvas
function obj:stop()
    if self.timer then
        self.timer:stop()
    end
    if self.MCalCanvas then
        self.MCalCanvas:delete()
    end
    if self.caffeinateWatcher then
        self.caffeinateWatcher:stop()
    end
    return self
end

return obj
