local screenX, screenY = guiGetScreenSize()

local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

function loadFonts()
    fonts = {
		Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
		Roboto13 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(13), false, "antialiased"),
        Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
        Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(16), false, "cleartype"),
        Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
        RobotoL = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL14 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(14), false, "cleartype"),
        RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
        RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL24 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(24), false, "cleartype"),
        RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
        RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
        RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
    }
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    loadFonts()
end)

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

panelState = nil

local panelMealsW, panelMealsH = respc(350), respc(400)
local panelMealsX, panelMealsY = (screenX - panelMealsW) * 0.5, (screenY - panelMealsH) * 0.5

local rowW, rowH = panelMealsW - respc(20), respc(40)
local rowX, rowStartY = panelMealsX + respc(10), panelMealsY + 30 + respc(20)

local panelOrdersW, panelOrdersH = respc(350), respc(400)
local panelOrdersX, panelOrdersY = (screenX - panelOrdersW) * 0.5, (screenY - panelOrdersH) * 0.5

local orderRowW, orderRowH = panelOrdersW - respc(20), respc(40)
local orderRowX, orderRowStartY = panelOrdersX + respc(10), panelOrdersY + 30 + respc(20)

local selectedMeal = nil
local selectedOrder = nil

local startTick = nil

addEventHandler("onClientRender", root, function()

    buttons = {}

    --if getPlayerName(localPlayer) ~= "Cody_Russel" then
    --    return
    --end

    if not isValidInterior(getElementInterior(localPlayer), getElementDimension(localPlayer)) then
        return
    end

    absX, absY = 0, 0

    if isCursorShowing() then
        local relX, relY = getCursorPosition()

        absX = screenX * relX
        absY = screenY * relY
    end

    if panelState == "meals" then

        --if not panelState then
            
        --end

        --> Háttér
        dxDrawRectangle(panelMealsX, panelMealsY, panelMealsW, panelMealsH, tocolor(31, 31, 31, 240))

        --> Fejléc
        dxDrawRectangle(panelMealsX, panelMealsY, panelMealsW, 30, tocolor(31, 31, 31, 240))
        dxDrawImage(math.floor(panelMealsX + 3), math.floor(panelMealsY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
        dxDrawText("Menü lista", panelMealsX + 30, panelMealsY, 0, panelMealsY + 30, tocolor(255, 255, 255), 1, fonts.RobotoL, "left", "center")

        --> Bezárás
        local closeTextWidth = dxGetTextWidth("X", 1, fonts.RobotoL)
        local closeTextPosX = panelMealsX + panelMealsW - closeTextWidth - 5
        local closeColor = tocolor(255, 255, 255)

        if absX >= closeTextPosX and absY >= panelMealsY and absX <= closeTextPosX + closeTextWidth and absY <= panelMealsY + 30 then
            closeColor = tocolor(215, 89, 89)

            if getKeyState("mouse1") then
                panelState = nil
                showCursor(false)
                --print("Bezárás")
                return
            end
        end
        
        dxDrawText("X", closeTextPosX, panelMealsY, 0, panelMealsY + 30, closeColor, 1, fonts.RobotoL, "left", "center")

        --> Tartalom
        local playerInt = getElementInterior(localPlayer)
        local playerDim = getElementInterior(localPlayer)
        local restaurant = restaurants[playerInt]
        
        for k, v in pairs(restaurant["meals"]) do
            local rowY = rowStartY + (rowH * (k - 1))

            local colorOfRow = tocolor(10, 10, 10, 125)

            if k % 2 == 0 then
                colorOfRow = tocolor(10, 10, 10, 75)
            end
            
            if selectedMeal == k then
                colorOfRow = tocolor(7, 112, 196, 190)
            end
            

            dxDrawRectangle(rowX, rowY, rowW, rowH, colorOfRow)
            dxDrawText(v[2], rowX + respc(10), rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "left", "center")
            dxDrawText("$" .. v[3], rowX, rowY, rowX + rowW - respc(10), rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "right", "center")
        end

        if selectedMeal then

            local countTextX, countTextY = panelMealsX, rowStartY + (#restaurant["meals"] * rowH) + respc(20)
            local fontHeight = dxGetFontHeight(1, fonts.Roboto11)
            
            dxDrawText("Elkészítési idő: " .. restaurant["meals"][selectedMeal][4] .. " másodperc", countTextX, countTextY, countTextX + panelMealsW, countTextY + panelMealsH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "center")
            
            if not createdMeals[selectedMeal] then
                createdMeals[selectedMeal] = 0
            end
            
            dxDrawText("Elkészítve: " .. createdMeals[selectedMeal] .. "db", countTextX, countTextY + fontHeight, countTextX + panelMealsW, countTextY + panelMealsH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "center")

            local makeButtonW, makeButtonH = respc(150), respc(40)
            local makeButtonX, makeButtonY = panelMealsX + respc(10), panelMealsY + panelMealsH - respc(10) - makeButtonH 

            local serveButtonW, serveButtonH = respc(150), respc(40)
            local serveButtonX, serveButtonY = panelMealsX + panelMealsW - respc(10) - serveButtonW, panelMealsY + panelMealsH - respc(10) - serveButtonH 

            dxDrawMetroButtonWithBorder("food:make", "Elkészítés", makeButtonX, makeButtonY, makeButtonW, makeButtonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)
            dxDrawMetroButtonWithBorder("food:serve", "Felszolgálás", serveButtonX, serveButtonY, serveButtonW, serveButtonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)
        end
    elseif panelState == "making" then
        local barW, barH = 251, 10
        local barX, barY = (screenX - barW) * 0.5, screenY - 5 - 46 - barH - 5

        dxDrawRectangle(barX, barY, barW, barH, tocolor(31, 31, 31, 240))
        
        local playerInt = getElementInterior(localPlayer)
        local playerDim = getElementInterior(localPlayer)
        local restaurant = restaurants[playerInt]

        if startTick then
            local currentTick = getTickCount()
            local elapsedTick = currentTick - startTick
            local endTick = startTick + restaurant["meals"][selectedMeal][4] * 1000
            local duration = endTick - startTick
            local barProgress = elapsedTick / duration
            local barFill = interpolateBetween(
                0, 0, 0,
                1, 0, 0,
                barProgress, "Linear"
            )
            --print(barFill .. " :: " .. barProgress)
            dxDrawRectangle(barX + 2, barY + 2, (barW - 4) * barFill, barH - 4, tocolor(7, 112, 196, 240))  

            if barProgress >= 1 then
                stopMealMaking()
            end
        end
    elseif panelState == "order" then
        --> Háttér
        dxDrawRectangle(panelOrdersX, panelOrdersY, panelOrdersW, panelOrdersH, tocolor(31, 31, 31, 240))

        --> Fejléc
        dxDrawRectangle(panelOrdersX, panelOrdersY, panelOrdersW, 30, tocolor(31, 31, 31, 240))
        dxDrawImage(math.floor(panelOrdersX + 3), math.floor(panelOrdersY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
        dxDrawText("Rendelés felvétel", panelOrdersX + 30, panelOrdersY, 0, panelOrdersY + 30, tocolor(255, 255, 255), 1, fonts.RobotoL, "left", "center")

        --> Bezárás
        local closeTextWidth = dxGetTextWidth("X", 1, fonts.RobotoL)
        local closeTextPosX = panelOrdersX + panelOrdersW - closeTextWidth - 5
        local closeColor = tocolor(255, 255, 255)

        if absX >= closeTextPosX and absY >= panelOrdersY and absX <= closeTextPosX + closeTextWidth and absY <= panelOrdersY + 30 then
            closeColor = tocolor(215, 89, 89)

            if getKeyState("mouse1") then
                panelState = nil
                showCursor(false)
                --print("Bezárás")
                return
            end
        end
        
        dxDrawText("X", closeTextPosX, panelOrdersY, 0, panelOrdersY + 30, closeColor, 1, fonts.RobotoL, "left", "center")

        --> Tartalom
        local playerInt = getElementInterior(localPlayer)
        local playerDim = getElementInterior(localPlayer)
        local restaurant = restaurants[playerInt]

        if selectedOrder then

            local playerInt = getElementInterior(localPlayer)
            local playerDim = getElementInterior(localPlayer)
            local restaurant = restaurants[playerInt]
            
            local i = 0
            for k, v in pairs(createdOrders[selectedOrder]) do
                local rowY = orderRowStartY + (rowH * i)

                local colorOfRow = tocolor(10, 10, 10, 125)

                if i % 2 ~= 0 then
                    colorOfRow = tocolor(10, 10, 10, 75)
                end
                
                
                --if selectedMeal == k then
                --    colorOfRow = tocolor(7, 112, 196, 190)
                --end
                

                dxDrawRectangle(orderRowX, rowY, orderRowW, orderRowH, colorOfRow)

                local mealID = v[1]
                dxDrawText(restaurant["meals"][mealID][2] .. " ", rowX + respc(15), rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "left", "center")
                --dxDrawText("$" .. v[3], rowX, rowY, rowX + rowW - respc(10), rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "right", "center")
                i = i + 1
            end

            local giveButtonW, giveButtonH = panelOrdersW - respc(20), respc(40)
            local giveButtonX, giveButtonY = panelOrdersX + respc(10), panelOrdersY + panelOrdersH - respc(10) - giveButtonH

            dxDrawMetroButtonWithBorder("food:give", "Átadás", giveButtonX, giveButtonY, giveButtonW, giveButtonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)
            --dxDrawMetroButtonWithBorder("food:serve", "Felszolgálás", serveButtonX, serveButtonY, serveButtonW, serveButtonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)
        end

    elseif panelState == "bill" then
    end

    activeButtonChecker()
end)

function startMealMaking()
    panelState = "making"
    startTick = getTickCount()
    setElementFrozen(localPlayer, true)
end

function stopMealMaking()
    panelState = "meals"
    startTick = nil
    if not createdMeals[selectedMeal] then
        createdMeals[selectedMeal] = 0
    end
    createdMeals[selectedMeal] = createdMeals[selectedMeal] + 1
    setElementFrozen(localPlayer, false)
end

function showOrderPanel(orderID)
    selectedOrder = orderID
    panelState = "order"
    showCursor(true)
end

local price = 0

addEventHandler("onClientClick", root, function(button, state)
    if button == "left" and state == "down" then
        local playerInt = getElementInterior(localPlayer)
        local playerDim = getElementInterior(localPlayer)
        local restaurant = restaurants[playerInt]
        
        if panelState == "meals" then
            for k, v in pairs(restaurant["meals"]) do
                local rowY = rowStartY + (rowH * (k - 1))
        
                if cursorInBox(rowX, rowY, rowW, rowH) then
                    --print(k)
                    selectedMeal = k
                    break
                end
            end

            if activeButton == "food:make" then
                startMealMaking()
            elseif activeButton == "food:serve" then
                if createdMeals[selectedMeal] > 0 then
                    if createdDishes[localPlayer] and isElement(createdDishes[localPlayer]) then
                        exports.sarp_hud:showAlert("error", "Már van a kezedben egy tálca")
                        return 
                    end

                    createdMeals[selectedMeal] = createdMeals[selectedMeal] - 1
                    triggerServerEvent("sarp_serverS:attachDish", localPlayer, restaurant["meals"][selectedMeal][1])
                    
                else
                    exports.sarp_hud:showAlert("error", "Nincs ebből a menüből elkészítve")
                end
            end

        elseif panelState == "making" then
        elseif panelState == "order" then
            if activeButton == "food:give" then
                if createdDishes[localPlayer] and isElement(createdDishes[localPlayer]) then
                    local founded = false
                    local dishID = getElementModel(createdDishes[localPlayer])
                    for k, v in pairs(createdOrders[selectedOrder]) do
                        if dishID == restaurant["meals"][v[1]][1] then
                            price = price + restaurant["meals"][v[1]][3]
                            print(price)
                            createdOrders[selectedOrder][k] = nil
                            triggerServerEvent("sarp_serverS:dettachDish", localPlayer)
                            founded = true
                            if table.size(createdOrders[selectedOrder]) <= 0 then
                                local tip = math.random(5, price)
                                exports.sarp_hud:showAlert("info", "Sikeresen kiszolgáltad a vevőt", "" .. price .. "$-t kerestél és " .. tip .. "$ borravalót kaptál")
                                exports.sarp_core:giveMoney(localPlayer, price + tip)
                                deleteOrderPed(selectedOrder)
                                panelState = nil
                                showCursor(false)
                            end
                            break
                        else
                            founded = false
                        end
                    end

                    if not founded then
                        exports.sarp_hud:showAlert("error", "A vevő nem rendelt ilyen menüt")
                        triggerServerEvent("sarp_serverS:dettachDish", localPlayer)
                    end
                else
                    exports.sarp_hud:showAlert("error", "Nincs nálad tálca")
                end
            end
        end
    end
end)

