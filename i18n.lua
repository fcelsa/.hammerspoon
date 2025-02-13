-- i18n.lua
--
-- a simple implement of locale string return
-- usage:
-- print(Str_i18n('Hello'))


assert(os.setlocale('it_IT'))                             -- set default locale for Lua code (en_US fr_FR etc. etc.)
local currentLocale = string.sub(os.setlocale(nil), 1, 2) -- the default language for indexing table

local i18n = { locales = {} }
i18n.locales.en = {
    Hello = "Hello",
    Week = "Week",
    KeySym = "Keyboard symbol",
    KeyAcc = "Special accents"
}

i18n.locales.it = {
    Hello = "Ciao",
    Week = "Settimana",
    KeySym = "Simboli tastiera",
    KeyAcc = "Accenti speciali"
}

i18n.locales.es = {
    Hello = "Hola",
    Week = "Semana"
}


_G.Str_i18n = function(id)
    local result = i18n.locales[currentLocale][id]
    if not result then
        result = i18n.locales.en[id] -- fallback to en
    end
    assert(result, ("The id %q was not found in the current locale (%q)"):format(id, currentLocale))
    return result
end
