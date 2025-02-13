
-- global utility functions


-- a method to implment case switch statements
-- usage example:
--[[
Switch(a, { 
    [1] = function()	-- for case 1
    print "Case 1."
end,
[2] = function()	-- for case 2
    print "Case 2."
end,
[3] = function()	-- for case 3
    print "Case 3."
end
})
]]
_G.Switch = function(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end


-- a method to implement a Measurement timer to check performance of a function
-- usage example:
-- local systemElement = ax.systemWideElement()
-- local currentElement = systemElement:attributeValue("AXFocusedUIElement")
-- Measurement('retrieving value', function() currentElement:attributeValue('AXValue') end)
_G.Measurement = function (name, fn)
    local logger = hs.logger.new('timer', 'debug')

    local startTime = hs.timer.absoluteTime()

    fn()

    local endTime = hs.timer.absoluteTime()

    local diffNs = endTime - startTime
    local diffMs = diffNs / 1000000

    logger.i(name .. " took: " .. diffMs .. "ms")
end



-- Finspect return flatened output from hs.inspect for debug purpose.
Finspect = function(...)
    local stuff = { ... }
    if #stuff == 1 and type(stuff[1]) == "table" then stuff = stuff[1] end
    return hs.inspect(stuff, { newline = " ", indent = "" })
end

