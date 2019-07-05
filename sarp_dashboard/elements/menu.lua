local Elements = Dashboard.Elements
local Arguments = Dashboard.Arguments

local activeColor = {7, 112, 196, 255}

Elements.SideMenu = function(x, y, w, h)
    Arguments.SideMenu = {x, y, w, h}
    buttons = {}

    local menuButtonW, menuButtonH = w, respc(50)
    local menuButtonX = x

    local menuIconW, menuIconH = respc(40), respc(40)
    local menuIconX = menuButtonX + respc(10)

    local menuTextW, menuTextH = menuButtonW, menuButtonH
    local menuTextX = menuIconW + respc(20)

    dxDrawRectangle(x, y, w, h, tocolor(24, 24, 24, 225))
    for k, v in ipairs(dashboardMenuItems) do
        local menuButtonY = y + (menuButtonH * (k - 1))
        local menuIconY = menuButtonY + ((menuButtonH - menuIconH) * 0.5)
        local menuTextY = menuButtonY

        if activeMenu == k then
            --dxDrawRectangle(menuButtonX, menuButtonY, menuButtonW, menuButtonH, tocolor(7, 112, 196, 255))
            dxDrawMenuButton("dashmenu:" .. k, v[1], menuButtonX, menuButtonY, menuButtonW, menuButtonH, activeColor, activeColor, {255, 255, 255, 255}, fonts.Roboto11, "left", "center", v[2], menuIconW, menuIconH, {255, 255, 255, 255})
        elseif cursorInBox(menuButtonX, menuButtonY, menuButtonW, menuButtonH) then
            --dxDrawRectangle(menuButtonX, menuButtonY, menuButtonW, menuButtonH, tocolor(53, 53, 53, 255))
            dxDrawMenuButton("dashmenu:" .. k, v[1], menuButtonX, menuButtonY, menuButtonW, menuButtonH, {53, 53, 53, 255}, activeColor, {255, 255, 255, 255}, fonts.Roboto11, "left", "center", v[2], menuIconW, menuIconH, {255, 255, 255, 255})
        elseif k % 2 == 0 then 
            --dxDrawRectangle(menuButtonX, menuButtonY, menuButtonW, menuButtonH, tocolor(53, 53, 53, 50))
            dxDrawMenuButton("dashmenu:" .. k, v[1], menuButtonX, menuButtonY, menuButtonW, menuButtonH, {53, 53, 53, 50}, activeColor, {255, 255, 255, 255}, fonts.Roboto11, "left", "center", v[2], menuIconW, menuIconH, {255, 255, 255, 255})
        else
            --dxDrawRectangle(menuButtonX, menuButtonY, menuButtonW, menuButtonH, tocolor(53, 53, 53, 100))
            dxDrawMenuButton("dashmenu:" .. k, v[1], menuButtonX, menuButtonY, menuButtonW, menuButtonH, {53, 53, 53, 100}, activeColor, {255, 255, 255, 255}, fonts.Roboto11, "left", "center", v[2], menuIconW, menuIconH, {255, 255, 255, 255})
        end
        --dxDrawImage(menuIconX, menuIconY, menuIconW, menuIconH, v[2], 0, 0, 0, tocolor(255, 255, 255, 255))
        --dxDrawText("" ..v[1], menuTextX, menuTextY, menuTextW + menuTextX, menuTextH + menuTextY, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "left", "center")
    end

    --activeButtonChecker()
end



local Handlers = Dashboard.Handlers
Handlers.SideMenu = {}
Handlers.SideMenu.ClickHandler = {function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    
    local x, y, w, h = unpack(Arguments.SideMenu)

    local menuButtonW, menuButtonH = w, respc(50)
    local menuButtonX = x

    local menuIconW, menuIconH = respc(40), respc(40)
    local menuIconX = menuButtonX + respc(10)

    if button == "left" and state == "down" then
        for k, v in ipairs(dashboardMenuItems) do
            local menuButtonY = y + (menuButtonH * (k - 1))
            local menuIconY = menuButtonY + ((menuButtonH - menuIconH) * 0.5)
            local menuTextY = menuButtonY
            
            if cursorInBox(menuButtonX, menuButtonY, menuButtonW, menuButtonH) then
                activeMenu = k
                --activePage = v[3]

                if Dashboard.SwitchMenu(v[3]) then
                    if activePage == "Character" then
                        showCharacter(0, false)
                    else
                        showCharacter(getElementModel(localPlayer), true)
                    end
                end
                
                break
            end
        end
    end
end, "onClientClick"}

