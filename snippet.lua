-- snippet.lua
-- make a popup menu, to insert text or load in clipboard some predefined text
-- like date, special char and other snippet.
-- The code distinguish from input text, combobox and TextArea fields
-- to put popup under the text cursor and insert selected snippet, otherwise
-- use mouse pointer coordinates and the selected snippet are inserted to clipboard.
-- binding default assigned to hyper + v
--
--

local ax = require("hs.axuielement")

local menuHeaderStyledText = {
    font = { name = ".AppleSystemUIFont", size = 18 },
    color = hs.drawing.color.blue,
    paragraphStyle = {
        alignment = "left",
    },
    shadow = {
        blurRadius = 1,
    }
}

local scopeDesc = hs.styledtext.new("-", menuHeaderStyledText)
local scopeIns = true

local kbdSymbol = {
    { title = " ⌃ ", fn = function() ExecAction(scopeIns, "⌃") end },
    { title = " ⌘ ", fn = function() ExecAction(scopeIns, "⌘") end },
    { title = " ⌥ ", fn = function() ExecAction(scopeIns, "⌥") end },
    { title = " ⇥ ", fn = function() ExecAction(scopeIns, "⇥") end },
    { title = " ⌫ ", fn = function() ExecAction(scopeIns, "⌫") end },
}
local accSpecial = {
    { title = " ä ", fn = function() ExecAction(scopeIns, "ä") end },
    { title = " ë ", fn = function() ExecAction(scopeIns, "ë") end },
    { title = " ï ", fn = function() ExecAction(scopeIns, "ï") end },
    { title = " ö ", fn = function() ExecAction(scopeIns, "ö") end },
    { title = " ü ", fn = function() ExecAction(scopeIns, "ü") end },
    { title = " ß ", fn = function() ExecAction(scopeIns, "ß") end },
}


local function makePopUpMenu()
    local systemElement = ax.systemWideElement()
    local currentElement = systemElement and systemElement:attributeValue("AXFocusedUIElement") or nil
    local position = currentElement and currentElement:attributeValue("AXPosition") or nil
    local rangeElement = currentElement and currentElement:attributeValue("AXSelectedTextRange") or nil
    local elementBounds = {}

    if currentElement and rangeElement then
        local caretRange = {
            location = rangeElement.location,
            length = 1,
        }

        elementBounds = currentElement:parameterizedAttributeValue("AXBoundsForRange", caretRange)
    end

    local currentRole = currentElement and currentElement.AXRole or nil
    local currentValue = currentElement and currentElement.AXValue or nil
    local currentSize = currentElement and currentElement.AXSize or nil
    local isTextInput = currentValue ~= nil and
        (currentRole == "AXTextArea" or currentRole == "AXTextField" or currentRole == "AXComboBox")

    if isTextInput and position then
        local elementHeight = currentSize and currentSize.h or 0
        local elementCorrection = 5
        if elementHeight < 50 then
            elementCorrection = elementCorrection + elementHeight
            position = hs.geometry({ x = position.x, y = position.y + elementCorrection })
        elseif elementHeight > 50 and currentRole == "AXTextArea" and elementBounds and elementBounds.x and elementBounds.y and elementBounds.h then
            position = hs.geometry({ x = elementBounds.x, y = elementBounds.y + elementBounds.h + elementCorrection })
        end

        scopeDesc = hs.styledtext.new(" 📝 " .. Str_i18n('SnippetInsTxt'), menuHeaderStyledText)
        scopeIns = true
    else
        position = hs.mouse.absolutePosition()
        scopeDesc = hs.styledtext.new(" 📎 " .. Str_i18n('SnippetCpyTxt'), menuHeaderStyledText)
        scopeIns = false
    end

    MenuPopUp1:setMenu(TogglePopUpMenu())
    MenuPopUp1:popupMenu(position)
    -- alternative to open always at mouse pointe position
    -- MenuPopUp1:popupMenu(hs.mouse.absolutePosition())
end

function TogglePopUpMenu()
    -- The date options in the menu needs to be defined here at every call, so that os.date will
    -- be always updated; others fix items can be defined at beginning like constants, example is
    -- the submenu items kbdSymbol and accSpecial.
    local dataIntstd = os.date("%Y-%m-%d")                --2023-04-12
    local dataIntstf = os.date("%Y%m%d")                  --20230412
    local dataShortx = os.date("%x")                      --12.04.2023
    local dataEstesa = os.date("%A %d %B %Y")             --Mercoledì 12 Aprile 2023
    local dataNormal = os.date("%d/%m/%Y")                --12/04/2023
    local dataWeeknn = os.date("w.%V")                    --w.15
    local dataWeekyy = os.date("w.%V-%Y")                 --w.15-2023
    local dataWeekdd = os.date(Str_i18n('Week') .. " %V") --Settimana 15

    local popupMenu = {
        { title = scopeDesc,          disabled = true },
        { title = dataIntstd,         fn = function() ExecAction(scopeIns, dataIntstd) end },
        { title = dataIntstf,         fn = function() ExecAction(scopeIns, dataIntstf) end },
        { title = dataShortx,         fn = function() ExecAction(scopeIns, dataShortx) end },
        { title = dataEstesa,         fn = function() ExecAction(scopeIns, dataEstesa) end },
        { title = dataNormal,         fn = function() ExecAction(scopeIns, dataNormal) end },
        { title = dataWeeknn,         fn = function() ExecAction(scopeIns, dataWeeknn) end },
        { title = dataWeekyy,         fn = function() ExecAction(scopeIns, dataWeekyy) end },
        { title = dataWeekdd,         fn = function() ExecAction(scopeIns, dataWeekdd) end },
        { title = "-" },
        { title = Str_i18n('KeySym'), menu = kbdSymbol },
        { title = Str_i18n('KeyAcc'), menu = accSpecial },
        { title = "-" },
        {
            title = "Emoji",
            disabled = not scopeIns,
            fn = function() hs.eventtap.keyStroke({ "ctrl", "cmd" }, "space") end
        },
    }

    return popupMenu
end

function ExecAction(scope, contents)
    if scope then
        hs.eventtap.keyStrokes(contents)
    else
        hs.pasteboard.setContents(contents)
    end
end

MenuPopUp1 = hs.menubar.new(false)
MenuPopUp1:setTitle("Snippet")

-- hyper + v show popup menu for the snippet
hs.hotkey.bind(Hyper, 'v', makePopUpMenu)
