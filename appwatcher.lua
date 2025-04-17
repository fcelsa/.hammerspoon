-- AppWatcher example, check when appName is activated and print in console.
-- Originally implemented to experiment dock label changes with AXTitle attribute, but not working as expected.
-- Apparently it's a read only attribute.
-- Leave here for future reference and other possible uses.

local APP_TO_WATCH = "Moonlight"

-- Callback of the watcher
function ListAttributeOfApp(newLabel)
    local dockApp = hs.axuielement.applicationElement('Dock'):attributeValue('AXChildren')
    
    for i, child in ipairs(dockApp[1]) do
        local title = child:attributeValue("AXTitle")
        print("Dock item " .. i .. ": " .. title)
        if title and title == APP_TO_WATCH then
            print("AppWatcher " .. title .. " found in Dock")
            print(child)
        end
    end
end

function ApplicationWatcherCallback(appName, eventType, appObject)
    if appName == APP_TO_WATCH and eventType == hs.application.watcher.activated then
        ListAttributeOfApp("test")
    end
end

-- Creazione del watcher
AppWatcher = hs.application.watcher.new(ApplicationWatcherCallback)
AppWatcher:start()
