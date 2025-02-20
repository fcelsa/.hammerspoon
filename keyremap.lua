-- key remap
-- maps key to other key with modifiers also

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
-- That also intepreted as Ins key in windows ? not in vmware...
remap({ 'shift' }, 'forwarddelete', pressFn('help'))

-- Logitech MX Key for Mac have a num key pad with key [=] absolutely useless almost all time, then 
-- remap them as [%] key [shift]+[5] almost the same on all international keyboard, useful with calc apps.
remap({}, 'pad=', pressFn('lshift', '5'))

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

-- hyper + y open hammerspoon console
hs.hotkey.bind(Hyper, "y", function()
    hs.toggleConsole()
    if not hs.dockicon.visible() then
        hs.dockicon:show()
    else
        hs.dockicon:hide()
    end
end)
