-- macminim1-fabio specific configuration.


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
