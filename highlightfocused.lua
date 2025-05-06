---@diagnostic disable: need-check-nil
-- highlightfocused
--
-- higlight targetAppID with a colored frame (frameColor)
-- Fabio Celsalonga
-- Aprile 2023
--
--

-- se si usa il modulo hs.window.highlight già pronto di hammerspoon, il codice potrebbe essere questo:
--  hs.window.highlight.ui.overlay = true
--  hs.window.highlight.ui.frameWidth = 12
--  hs.window.highlight.ui.frameColor = { 0, 1, 0.3, 0.6 }
--  hs.window.highlight.start(nil, { 'CalcTape' })
-- ma io non voglio il dim del resto delle app o nasconderle, voglio solo evidenziare l'applicazione/i target.
-- l'approccio quindi è diverso ed uso gli eventi di hs.window.filter
-- per come è concepito ora, funziona bene solo per app a singola finestra specifiche,
-- #TODO: può essere migliorato e reso più generico.
-- Gennaio 2025 corretto il bug che faceva evidenziare anche la finestra di impostazioni ed about,
-- ora evidenzia solo la finestra principale di CalcTape, attraverso il titolo della finestra.


local targetAppId = "de.sfr.calctape"
local targetName = hs.application.nameForBundleID(targetAppId)
local frameColor = { ["red"] = 0, ["blue"] = 0.4, ["green"] = 0.8, ["alpha"] = 0.6 }
local theCanvas = nil
local allwindows = hs.window.filter.new(targetName)

allwindows:subscribe(hs.window.filter.windowCreated, function() DrawCanvas("create") end)
allwindows:subscribe(hs.window.filter.windowFocused, function() DrawCanvas("focus") end)
allwindows:subscribe(hs.window.filter.windowMoved, function() DrawCanvas("moved") end)
allwindows:subscribe(hs.window.filter.windowUnfocused, function() DrawCanvas("unfocus") end)

function DrawCanvas(reason)
    local win = hs.window.focusedWindow() or nil
    if win ~= nil and theCanvas == nil and win:application():bundleID() == targetAppId and (reason == "create" or reason == "focus") then
        local top_left = win:topLeft()
        local size = win:size()
        local geometry = hs.geometry.rect(top_left['x'], top_left['y'], size['w'], size['h'])
        local win_title = win:title()

        -- Avoid highlighting the settings and about window of CalcTape.
        if not string.find(win_title, "CalcTape") or not string.find(win_title, "Pref") then
            theCanvas = hs.canvas.new(hs.geometry.rect(top_left['x'] - 16, top_left['y'] - 16, size['w'] + 32,
                size['h'] + 32))

            theCanvas[1] = {
                type = "rectangle",
                action = "stroke",
                strokeWidth = 6.0,
                strokeColor = frameColor,
                roundedRectRadii = { xRadius = 8, yRadius = 8 },
                frame = { x = 12, y = 12, h = geometry.h + 6, w = geometry.w + 6 }
            }

            theCanvas:show(0.5)
        end
    elseif reason == "moved" or reason == "unfocus" then
        if theCanvas ~= nil then
            theCanvas:delete()
            theCanvas = nil
        end
    end
end
