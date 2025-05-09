-- This module listens for "others" mouse button events namely the optional additional keys,
-- like the center and the sides one.
-- In the form of a module, it can be activated and deactivated only under certain conditions.
-- eventtap it consumes a lot of resources and this module in particular introduces some mouse lag

local module = {}

local eventtap = require "hs.eventtap"
local event    = eventtap.event

local mouseButtonHandler = function(e)
    local buttonNumber = e:getProperty(event.properties.mouseEventButtonNumber)
    if buttonNumber >= 3 then
        print("Mouse button true: " .. buttonNumber)
        return true  -- consume the event (disabling it)
    else
        print("Mouse button false: " .. buttonNumber)
        return false -- do nothing to the event, just pass it along
    end
end

module.mouseButtonListener = eventtap.new({ event.types.otherMouseDown }, mouseButtonHandler)

module.start = function()
    module.mouseButtonListener:start()
end

module.stop = function()
    module.mouseButtonListener:stop()
end

return module
