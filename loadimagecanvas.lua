-- load an image on screen canvas.

local screen = hs.window.focusedWindow():screen():frame()

local COORIDNATE_X = screen.w / 2
local COORIDNATE_Y = screen.h / 2
local WIDTH = 1000
local HEIGHT = 700

function CleanCanvas(c)
    if c ~= nil then
        c:hide(.3)
        hs.timer.doAfter(1, function()
            c:delete()
            c = nil
        end)
    end
end

function ShowImage()
    local canvas = hs.canvas.new({x = COORIDNATE_X - WIDTH / 2, y = COORIDNATE_Y - HEIGHT / 2, w = WIDTH, h = HEIGHT})
    canvas:appendElements({
        id = 'after-work',
        type = 'image',
        image = hs.image.imageFromPath(os.getenv("HOME") .. '/.hammerspoon/assets/images/2023.png'),
        imageScaling = 'scaleToFit',
        imageAnimates = true
    })

    canvas:show(.3)

    local c = canvas:canvasMouseEvents(true, nil, nil, nil)

    local d = canvas:mouseCallback(function ()
        CleanCanvas(c)
    end)
end
