local Elements = Dashboard.Elements
local Handlers = Dashboard.Handlers

local Shaders = {
    {"palette1", "Just for Szabolcs", false},
    {"vignette1", "Just for you", false},
    {"hexon", "Hexon effekt mindenkinek!!!!!", false}
}
local GameSettings = {
    {"Interface kezelése", function()
        Dashboard.Show()
        executeCommandHandler("edithud", "@edit")
    end},
    {"Mód kezelése", function()
        Dashboard.Show()
        executeCommandHandler("mods", "@edit")
    end},
    {"Beszéd animáció: 1", function()
        --Dashboard.Show()
        --executeCommandHandler("mods", "@edit")
        print("Ok")
    end},
}

local SettingsSlider = {
    [3] = {function()
        print("Slider")
    end, true},

}



Elements.Settings = function(x, y, w, h)
    --buttons = {}
    local alphaMul = tabPanelAlphas["Settings"]

    local gameX, gameY = x + respc(100), y + respc(70)
    local gameW, gameH = respc(210), respc(50)
    local sliderX = gameX + respc(10)

    dxDrawText("Beállítások", gameX, gameY, gameX, gameY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.RobotoL24)
    for k, v in pairs(GameSettings) do
        local gameY = gameY + dxGetFontHeight(1, fonts.RobotoL24) + respc(20) + ((respc(52) + respc(10)) * (k - 1))
        --dxDrawMetroTileWithEffect(key, label, x, y, w, h, activeColor, imagePath, imageW, imageH, imageColor, imageAlign, titleText, titleTextColor, titleTextFont, titleTextAlign, downText, downTextColor, downTextFont, downTextAlign, centerText, centerTextColor, centerTextFont, centerTextAlign)
        --dxDrawMetroTileWithEffect("gamesettings:" .. k, "Label?", gameX, gameY, gameW, gameH, {43, 87, 151}, button[2], respc(100), respc(100), nil, "center", nil, nil, nil, nil, button[3], tocolor(255, 255, 255, 255 * alphaMul), fonts.Roboto18L, "center")

        dxDrawMetroButtonWithBorder("gamesettings:" .. k, v[1], gameX, gameY, gameW, gameH, {43, 87, 151, 125 * alphaMul}, {43, 87, 151, 175 * alphaMul}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)

        if SettingsSlider[k] then
            drawButtonSlider("gamesettings:" .. k .. ":slider", v[4], gameX + gameW + respc(10), gameY + (gameH / 2) - respc(16), respc(32), {50, 50, 50, 255}, {7, 112, 196, 255})
        end
        
        --------------------------(key, label, x, y, w, h, buttonColor, activeColor, textColor, font, textAlign1, textAlign2, imagePath, imageW, imageH, imageColor)
    end


    
    --[[for k, v in pairs(Shaders) do
        local sliderY = shaderY + dxGetFontHeight(1, fonts.RobotoL24) + respc(20) + ((respc(32) + respc(10)) * (k - 1))
        drawButtonSlider(v[1], v[3], sliderX, sliderY, respc(32), {50, 50, 50, 255}, {7, 112, 196, 255})
        dxDrawText(v[2], sliderX + respc(90), sliderY, sliderX, sliderY + respc(32), tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14, "left", "center")
    end]]

    activeButtonChecker()
end


Handlers.Settings = {}
Handlers.Settings.Click = {function(button, state)
    if button == "left" and state == "down" then
        for k, v in pairs(GameSettings) do
            if activeButton == "gamesettings:" .. k then
                outputChatBox(v[1])
                v[2]()
                break
            elseif activeButton == "gamesettings:" .. k .. ":slider" then
                SettingsSlider[k][1]()
                print("asd")
                break
            end
            print(activeButton)
        end
    end
end, "onClientClick"}