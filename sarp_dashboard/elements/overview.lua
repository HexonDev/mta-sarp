local Elements = Dashboard.Elements
local Handlers = Dashboard.Handlers

local accountData = {}

local tileButtons = {
    {"tipp1", "files/group.png", "Frakció kezelés", "F3, a frakciópanel eléréséhez."},
    {"tipp2", "files/screw.png", "Mód kezelés", "/mods, a modpanelhez."},
    {"tipp3", "files/interface.png", "Interface kezelés", "/edithud, a szerkesztéshez."},
}

Dashboard.Elements.Overview = function(x, y, w, h)
    --buttons = {}
    local alphaMul = tabPanelAlphas["Overview"]

    dxDrawMetroBox(x, y, w, respc(300), tocolor(43, 87, 151, 200 * alphaMul), "files/man.png", respc(100 * 0.8), respc(256 * 0.8), tocolor(255, 255, 255, 200 * alphaMul), "left", getElementData(localPlayer, "acc.username"), tocolor(255, 255, 255, 255 * alphaMul), fonts.RobotoL18, nil, nil, nil, nil, nil, respc(110))         
--    dxDrawMetroBox(x, y, w, h, color, imagePath, imageW, imageH, imageColor, imageAlign, titleText, titleTextColor, titleTextFont, titleTextAlign, downText, downTextColor, downTextFont, downTextAlign, bg)   

    local jailData = getElementData(localPlayer, "acc.adminJail") or 0
    if jailData ~= 0 then
        local datas = split(jailData, "/")

        accountData[5][2] = datas[2] .. " (" .. datas[4] .. ")"
    else
        accountData[5][2] = "Nincs"
    end

    local offsetFromLeftRightSide = respc(20)
    local tileMarginOffset = respc(20)
    local rightSideAreaWidth = screenX - respc(300) - offsetFromLeftRightSide*4

    local visibleTiles = math.ceil((screenX / rightSideAreaWidth) + 1)
    local tileWidth = rightSideAreaWidth / visibleTiles

    local tileHeight = respc(200)
    
    local offsetX = x + offsetFromLeftRightSide
    local offsetY = y + respc(320)

    for i = 1, #tileButtons do
        local button = tileButtons[i]

        dxDrawMetroTileWithEffect(button[1], "Label?", offsetX, offsetY, tileWidth, tileHeight, {43, 87, 151}, button[2], respc(100), respc(100), nil, "center", nil, nil, nil, nil, button[3], tocolor(255, 255, 255, 255 * alphaMul), fonts.Roboto18L, "center")
        --drawButton("btn" .. i, "Label?", offsetX, offsetY, tileWidth, tileHeight, {43, 87, 151}, nil, fonts.Roboto14)
        if activeButton == button[1] then
            dxDrawRectangle(offsetX, offsetY + tileHeight, tileWidth, respc(50), tocolor(0, 0, 0, 50 * alphaMul))
            dxDrawText(button[4], offsetX, offsetY + tileHeight, offsetX + tileWidth,(offsetY + tileHeight) + respc(50), tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14, "center", "center")
        end

        if i % visibleTiles == 0 then
            offsetX = x + offsetFromLeftRightSide
            offsetY = offsetY + tileHeight + tileMarginOffset
        else
            offsetX = offsetX + tileWidth + tileMarginOffset
        end
    end

    local infoTextX = x + respc(120)
    for k, v in pairs(accountData) do
        local infoTextY = (y + respc(50)) + (dxGetFontHeight(1, fonts.Roboto16) * (k - 1))
        if v[1] == "Játszott idő" then
            local time = tonumber(getElementData(localPlayer, "char.playedMinutes")) * 60
            local timeText = string.format("%.2d nap %.2d óra %.2d perc", math.floor(time / 86400), math.floor((time % 86400) / 3600), math.floor((time / 3600) / 60))
            dxDrawText(v[1] .. ": " .. timeText, infoTextX, infoTextY, infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto16, "left", "top", false, false, false, true)
        else
            dxDrawText(tostring(v[1]) .. ": " .. tostring(v[2]) , infoTextX, infoTextY, infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto16, "left", "top", false, false, false, true)
        end
    end

    --[[
    local tileButtonW, tileButtonH = respc(460), respc(200) 
    local tileButtonY = y + respc(320)
    for k, v in pairs(tileButtons) do
        local tileButtonX = x + respc(60) + ((respc(60) + tileButtonW) * (k - 1))
        --dxDrawMetroBox()
        dxDrawMetroBox(tileButtonX, tileButtonY, tileButtonW, tileButtonH, tocolor(43, 87, 151, 200), v[1], respc(100), respc(100), tocolor(255, 255, 255, 200), "center", nil, nil, nil, nil, v[2], tocolor(255, 255, 255, 255), fonts.Roboto16L, "center")
        --dxDrawRectangle(tileButtonX, tileButtonY, tileButtonW, tileButtonH)
    end
    ]]

    activeButtonChecker()

end

Handlers.Overview = {}
Handlers.Overview.ProcessUserInfo = {function()
    accountData = {
        {"Felhasználó azonosító", getElementData(localPlayer, "acc.ID"), ""},
        {"Serial", getPlayerSerial(localPlayer), ""},
        {"Játszott idő", getElementData(localPlayer, "char.playedMinutes"), ""},
        {"Idő a fizetésig", 60 - getElementData(localPlayer, "char.playTimeForPayday") .. " perc", ""},
        {"Adminbörtön", (getElementData(localPlayer, "acc.adminJail") or 0) == 0 and "Nincs", ""},
    }
end, "function"}
