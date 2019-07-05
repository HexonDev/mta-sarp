local Elements = Dashboard.Elements
local Handlers = Dashboard.Handlers

local characterData = {}

Elements.Admin = function(x, y, w, h)
    local alphaMul = tabPanelAlphas["Admin"]

    -- Frakciók
    --characterData[#characterData][2] = processPlayerGroups():sub(3)

    dxDrawText("Adminisztrátorok", x + respc(40), y + respc(40), x + respc(40), y + respc(40), tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.RobotoL24)

    local dataTextX = x + respc(50)
    for k, v in ipairs(characterData) do
        local dataTextY = (y + respc(200)) + ((dxGetFontHeight(1, fonts.Roboto14) + respc(10)) * (k - 1))
        dxDrawText(v[1] .. ": " .. v[2] .. v[3], dataTextX, dataTextY, dataTextX, dataTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
    end


    activeButtonChecker()
end

Handlers.Admin = {}

Handlers.Admin.ProcessPlayerInfo = {function()
    characterData = {
        {"Azonosító", getElementData(localPlayer, "char.ID"), ""},
        {"Kor", "char.Age", ""},
        {"Készpénz", "Érték", "$"},
        {"Banki egyenleg", "Érték", "$"},
        {"Munka", getElementData(localPlayer, "char.Job"), ""},
        {"Tartózkodási hely", getZoneName(getElementPosition(localPlayer)), ""},
        {"Szervezet(ek)", "Betöltés...", ""}, -- Ez mindig legyen az utolsó a táblában!!!
    }
end, "function"}


