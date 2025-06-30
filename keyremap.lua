-- key remap
-- maps key to other key with optional modifiers also

local function pressFn(mods, key)  
    if key == nil then
          key = mods
          mods = {}
    end
      return function() hs.eventtap.keyStroke(mods, key, 1000) end
  end

local function remap(mods, key, pressFn)
    hs.hotkey.bind(mods, key, pressFn, nil, pressFn)
end

-- my list of remap
-- [shift]+[⌦] (forwarddelete) remap to "help" key on macOS (because not avaiable on the Logitech MX Key for Mac)
-- That also intepreted as Ins key in windows ? but not in vmware... Issue to be investigated further.
remap({ 'shift' }, 'forwarddelete', pressFn('help'))

-- Logitech MX Key for Mac have a num key pad with key [=] absolutely useless almost all time, then 
-- remap them as [%] key [shift]+[5] almost the same on all international keyboard, useful with calc apps.
-- Note that almost all calculator app return calculaton with enter key, but equal [=] key can be useful with spreadsheet
-- keep note that = can be obtained with [shift]+[=] on that numpad.
remap({}, 'pad=', pressFn('lshift', '5'))

-- questa parte sotto è da spostare in un file a parte, oppure in init.lua ...per ora rimane qui
-- some other bindings
-- [F16] open or focused CalcTape.app ...and return !
hs.hotkey.bind({}, "f16", function()
    FWin = hs.window.focusedWindow()
    FWinName = FWin:application():name()
    if FWinName == "CalcTape" then
        local appWindows = hs.application.get(PreFWinName):allWindows()
        if #appWindows > 0 then
            -- It seems that this list order changes after one window get focused,
            -- let's directly bring the last one to focus every time
            appWindows[#appWindows]:focus()
        else -- this should not happen, but just in case
            hs.application.launchOrFocus(PreFWinName)
        end
        hs.application.launchOrFocus(PreFWinName)
    else
        PreFWin = hs.window.focusedWindow()
        PreFWinName = PreFWin:application():name()
        hs.application.launchOrFocus('CalcTape.app')
    end
end)

-- hyper + y open/close (show/hide) hammerspoon console window
hs.hotkey.bind(Hyper, "y", function()
    hs.toggleConsole()
    if not hs.dockicon.visible() then
        hs.dockicon:show()
    else
        hs.dockicon:hide()
    end
end)
