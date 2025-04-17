require("api_keys")
local geminiApiKey = GEMINI_API_KEY

hs.hotkey.bind(Hyper, "G", function()
    hs.eventtap.keyStroke({ "cmd" }, "C")
    hs.timer.doAfter(0.3, function()
        local input = hs.pasteboard.getContents()
        if not input or input == "" then
            hs.alert.show("📋 No text selected")
            return
        end
        EnglishGrammarCheck(input)
    end)
end)

function EnglishGrammarCheck(input)
    -- Prompt that expects strict JSON response
    local prompt = [[
You are a grammar and punctuation checker.
Use strict rules of written English, prefer an informal international English, suitable in commercial and technical context.

Analyze the sentence below, then return ONLY one of the following JSON responses:
- If the sentence it is in italian language or any other than english, translate it to english, reply with: {"result": "translated", "text": "<translated version>"}
- If the sentence is grammatically and punctuationally correct, reply with: {"result": "true"}
- If it is not correct, reply with: {"result": "corrected", "text": "<corrected version>"}

Please do not add any other text, just the JSON response, remove carriage return and new lines also if present in sentence.

Sentence: "]] .. input .. [["
]]

    -- Gemini API Payload
    local jsonBody = hs.json.encode({
        contents = {
            {
                parts = {
                    { text = prompt }
                }
            }
        }
    })

    local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" ..
        geminiApiKey

    -- Send Request to Gemini
    hs.http.asyncPost(url, jsonBody, {
        ["Content-Type"] = "application/json"
    }, function(status, body)
        if status ~= 200 then
            hs.alert.show("❌ Gemini API error: " .. tostring(status))
            return
        end

        -- Parse Gemini response structure
        local ok, response = pcall(hs.json.decode, body)
        if not ok or not response then
            hs.alert.show("❌ Failed to decode Gemini response")
            return
        end

        local textResponse = response.candidates and response.candidates[1] and
            response.candidates[1].content and
            response.candidates[1].content.parts and
            response.candidates[1].content.parts[1] and
            response.candidates[1].content.parts[1].text

        if not textResponse then
            hs.alert.show("❌ No valid content in Gemini response")
            return
        end

        -- Decode Gemini's JSON-in-text reply
        local parsed = hs.json.decode(textResponse)
        if not parsed then
            hs.alert.show("❌ Failed to parse JSON from Gemini text response")
            print(textResponse)
            return
        end

        -- Handle grammar correction or translation logic
        if parsed.result == "true" then
            hs.alert.show("✅ Already correct!")
        elseif parsed.result == "corrected" or parsed.result == "translated" and parsed.text then
            hs.pasteboard.setContents(parsed.text)
            hs.eventtap.keyStroke({}, "delete")
            hs.timer.doAfter(0.1, function()
                hs.eventtap.keyStroke({ "cmd" }, "v")
            end)
            hs.alert.show("✅ Selected text " .. parsed.result .. " !")
        else
            hs.alert.show("❌ Unexpected format in response")
        end
    end)
end
