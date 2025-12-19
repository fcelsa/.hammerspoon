-- netutils: module for network connection utility

-- PingResult function test network quality and show alert with result.
function PingResult(object, message, seqnum, error)
    local avg

    if message == "didFinish" then
        avg = tonumber(string.match(object:summary(), '/(%d+.%d+)/'))
        if avg == 0.0 then
            hs.alert.show("No network")
        elseif avg < 200.0 then
            hs.alert.show("Network good (" .. avg .. "ms)")
        elseif avg < 500.0 then
            hs.alert.show("Network poor(" .. avg .. "ms)")
        else
            hs.alert.show("Network bad(" .. avg .. "ms)")
        end
    end
end

-- NetworkName function to show alert with all network names of the system.
function NetworkName(networks)
    local networksName = ""
    if networks then
        for _, network in pairs(networks) do
            networksName = networksName .. network .. "\n"
        end
        hs.alert.show("Networks:\n" .. networksName, 10)
    end
end

-- NetworkWifi function to show alert with current wifi network name.
function NetworkWifi()
    local wifi = hs.wifi.currentNetwork()
    if wifi then
        hs.alert.show("WiFi Network: " .. wifi, 5)
    else
        hs.alert.show("No WiFi Network", 5)
    end
end

hs.hotkey.bind(Hyper, "p", function() hs.network.ping.ping("8.8.8.8", 1, 0.01, 1.0, "any", PingResult) end)
hs.hotkey.bind(Hyper, "n", function() NetworkName(hs.host.addresses()) end)
hs.hotkey.bind(Hyper, "w", function() NetworkWifi() end)
