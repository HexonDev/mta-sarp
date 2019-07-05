screenX, screenY = guiGetScreenSize()
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
        Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
        Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(16), false, "cleartype"),
        Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
        RobotoL = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
        RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
        RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
        RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
    }
end

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
	loadFonts()
end)

local selectButtons = {
    {"select:faction", "Vásárlás szervezet részére"},
    {"select:private", "Vásárlás magánszemélyként"}
}

local playerGroups = {}
local selectedFaction = {}
local selectedBrand = "notSelected"
local page = nil
local currentVehicle = 1

VehicleShop = {}

local selectPanelW, selectPanelH = respc(400), respc(500)
local selectPanelX, selectPanelY = (screenX - selectPanelW) * 0.5, (screenY - selectPanelH) * 0.5

local selectButtonW, selectButtonH = selectPanelW - respc(20), respc(40)

VehicleShop.FactionSelectPanel = function()
    buttons = {}

    dxDrawRectangle(selectPanelX, selectPanelY, selectPanelW, selectPanelH, tocolor(31, 31, 31, 240))

    -- Gombok
    local buttonX = selectPanelX + respc(10)
    for k, v in pairs(selectButtons) do
        local buttonY = (selectPanelY + selectPanelH) - selectButtonH - respc(10) - ((selectButtonH + respc(10)) * (k - 1))
        dxDrawMetroButton(v[1], v[2], buttonX, buttonY, selectButtonW, selectButtonH, {7, 112, 196}, nil, fonts.Roboto14, nil, 1, nil)
    end

    local factions = playerGroups


    local rowW, rowH = selectPanelW - respc(20), respc(40)
    local rowX = selectPanelX + respc(10)
    for i = 1, 8 do
        local rowY = selectPanelY + respc(20) + (rowH * (i - 1))

        if selectedFaction[1] == i then
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(7, 112, 196, 255))
        elseif i % 2 == 0 then
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(53, 53, 53, 50))
        else
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(53, 53, 53, 100))
        end
        
        if factions[i] then
            local data = factions[i] -- {Fraki ID, Duty Skin, Leader jog}
            dxDrawText(data[2] .. "", rowX, rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto14, "center", "center")
        end
    end

    activeButtonChecker()
end

local shopPanelW, shopPanelH = respc(900), respc(600)
local shopPanelX, shopPanelY = (screenX - shopPanelW) * 0.5, (screenY - shopPanelH) * 0.5

VehicleShop.ShopPanel = function()
    buttons = {}

    local cursorX, cursorY = getCursorPosition()
    local absX, absY = -1, -1
    if isCursorShowing() then
        absX, absY = cursorX * screenX, cursorY * screenY
    elseif cursorIsMoving then
        cursorIsMoving = false
    end

    dxDrawRectangle(shopPanelX, shopPanelY, shopPanelW, shopPanelH, tocolor(31, 31, 31, 240))

    dxDrawImage(shopPanelX + 5, shopPanelY + 5, respc(403 * 0.075), respc(459 * 0.075), ":sarp_assets/images/sarplogo_big.png", 0, 0, 0, tocolor(50, 179, 239))
    if cursorInBox(shopPanelX + shopPanelW - respc(24) - 10, shopPanelY + 5 + (respc(34.425) - respc(24)) / 2, respc(24), respc(24)) then
        dxDrawImage(shopPanelX + shopPanelW - respc(24) - 10, shopPanelY + 5 + (respc(34.425) - respc(24)) / 2, respc(24), respc(24), ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(215, 89, 89))
    else
        dxDrawImage(shopPanelX + shopPanelW - respc(24) - 10, shopPanelY + 5 + (respc(34.425) - respc(24)) / 2, respc(24), respc(24), ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(255, 255, 255))
    end

    if selectedFaction[1] and selectedFaction[2] then
        dxDrawText("Vásárlás " .. selectedFaction[2][2] .. " részére", shopPanelX + 5 + respc(403 * 0.075) + 10, shopPanelY + 10, shopPanelX + 5 + respc(403 * 0.075), shopPanelY, tocolor(255, 255, 255), 1, fonts.Roboto14)
    else
        dxDrawText("Vásárlás magánszemlyéként", shopPanelX + 5 + respc(403 * 0.075) + 10, shopPanelY + 10, shopPanelX + 5 + respc(403 * 0.075), shopPanelY, tocolor(255, 255, 255), 1, fonts.Roboto14)
    end


    local rowW, rowH = respc(200), respc(40)
    local rowX = shopPanelX + shopPanelW - rowW - respc(10)
    for i = 1, 10 do
        local rowY = shopPanelY + respc(60) + (rowH * (i - 1))
        if selectedBrand[1] == i then
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(7, 112, 196, 255))
        elseif i % 2 == 0 then
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(53, 53, 53, 50))
        else
            dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(53, 53, 53, 100))
        end
        
        if vehicleBrands[i] then
            dxDrawText(vehicleBrands[i], rowX + respc(10), rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255), 1, fonts.Roboto14, "left", "center")
        end
    end

    local vehicleW, vehicleH = respc(600), respc(400)
    local vehicleX, vehicleY = shopPanelX + respc(50), shopPanelY + respc(60)

    local buttonW, buttonH = respc(200), respc(75)
    local buttonX, buttonY = shopPanelX + shopPanelW - buttonW - respc(10), shopPanelY + shopPanelH - buttonH - respc(10)

    if vehiclesInShop[selectedBrand[2]] then
        --dxDrawRectangle(vehicleX, vehicleY, vehicleW, vehicleH)
        exports["sarp_3dview"]:setVehicleProjection(vehicleX, vehicleY, vehicleW, vehicleH, 255)

        dxDrawText(exports.sarp_mods_veh:getVehicleNameFromModel(vehiclesInShop[selectedBrand[2]][currentVehicle][1]), vehicleX, vehicleY + vehicleH + respc(20), vehicleX + vehicleW, vehicleH, tocolor(255, 255, 255), 1, fonts.Roboto16, "center")
        dxDrawText("Ár: " .. vehiclesInShop[selectedBrand[2]][currentVehicle][2] .. "$", vehicleX, vehicleY + vehicleH + respc(20) + dxGetFontHeight(1, fonts.Roboto16), vehicleX + vehicleW, vehicleH, tocolor(255, 255, 255), 1, fonts.Roboto14, "center")
    
        dxDrawMetroButton("purchase:buy", "Megvesz", buttonX, buttonY, buttonW, buttonH, {7, 112, 196}, nil, fonts.Roboto14, nil, 1, nil)

        if cursorIsMoving then
            exports["sarp_3dview"]:rotateVehicle(cursorX)
            setCursorPosition(screenX * 0.5, screenY * 0.5)
            
            if not getKeyState("mouse1") then
                cursorIsMoving = false
                setCursorAlpha(255)
            end
        elseif cursorInBox(vehicleX, vehicleY, vehicleW, vehicleH) and getKeyState("mouse1") then
            cursorIsMoving = true
            setCursorAlpha(0)
            setCursorPosition(screenX * 0.5, screenY * 0.5)
        end
        
        if cursorInBox(vehicleX, vehicleY, vehicleW, vehicleH) then
            carHoveredForRotation = true
        end
    elseif selectedBrand == "notSelected" then
        dxDrawText("Válasz ki egy márkát", vehicleX, vehicleY, vehicleX + vehicleW, vehicleY + vehicleH, tocolor(255, 255, 255), 1, fonts.Roboto14, "center", "center")
    else
        dxDrawText("Sajnos nincs ebből a márkából elérhető jármű", vehicleX, vehicleY, vehicleX + vehicleW, vehicleY + vehicleH, tocolor(255, 255, 255), 1, fonts.Roboto14, "center", "center")
    end

    activeButtonChecker()
end

VehicleShop.ChangeVehicle = function(vehID)
    print(vehID)
    exports["sarp_3dview"]:processVehiclePreview()

    if isElement(vehicleElement) then
        destroyElement(vehicleElement)
        print(" destroy")
    end

    vehicleElement = createVehicle(tonumber(vehID), 0, 0, -100, 0, 0, 0, "SARP")
    setVehicleColor(vehicleElement, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255)
    setElementFrozen(vehicleElement, true)
    print("element create")

    exports["sarp_3dview"]:processVehiclePreview(vehicleElement, 0, 0, 0, 0, false) -- utolsó érték a karosszéria sérülések ki- és bekapcsolása, a többi nulla, a render majd úgy is beállítja
    exports["sarp_3dview"]:setVehicleAlpha(0)
end

VehicleShop.ProcessPlayerGroups = function()
    local factions = exports.sarp_groups:getPlayerGroups(localPlayer)
    playerGroups = {}

    for id, group in pairs(factions) do
        if group[3] == "Y" then
            table.insert(playerGroups, {id, exports.sarp_groups:getGroupName(id)})
        end
    end
end

VehicleShop.ClickHandler = function(button, state)
    if button == "left" and state == "down" then
        if page == "select" then
            local factions = playerGroups

            local rowW, rowH = selectPanelW - respc(20), respc(40)
            local rowX = selectPanelX + respc(10)

            for i = 1, 8 do
                local rowY = selectPanelY + respc(20) + (rowH * (i - 1))
                
                if factions[i] then
                    local data = factions[i] -- {Fraki ID, Duty Skin, Leader jog}
                    
                    if cursorInBox(rowX, rowY, rowW, rowH) then
                        selectedFaction = {i, data}
                        --outputChatBox(tostring(data) .. " " .. inspect(data))
                    end
                end
            end

            if activeButton == "select:faction" then
                if selectedFaction[1] and selectedFaction[2] then
                    removeEventHandler("onClientRender", root, VehicleShop.FactionSelectPanel)
                    addEventHandler("onClientRender", root, VehicleShop.ShopPanel)
                    page = "purchase"
                elseif #selectedFaction == 0 then
                    exports.sarp_alert:showAlert("error", "A tovább lépéshez válasz ki egy frakciót!")
                end
            elseif activeButton == "select:private" then
                removeEventHandler("onClientRender", root, VehicleShop.FactionSelectPanel)
                addEventHandler("onClientRender", root, VehicleShop.ShopPanel)
                selectedFaction = {}
                page = "purchase"
            end
        elseif page == "purchase" then

            if cursorInBox(shopPanelX + shopPanelW - respc(24) - 10, shopPanelY + 5 + (respc(34.425) - respc(24)) / 2, respc(24), respc(24)) then
                VehicleShop.Close()
            end

            local rowW, rowH = respc(200), respc(40)
            local rowX = shopPanelX + shopPanelW - rowW - respc(10)
            for i = 1, 10 do
                local rowY = shopPanelY + respc(60) + (rowH * (i - 1))
                if vehicleBrands[i] then
                    if cursorInBox(rowX, rowY, rowW, rowH) then
                        selectedBrand = {i, vehicleBrands[i]}
                        if vehiclesInShop[selectedBrand[2]] then
                            --outputChatBox(inspect(vehiclesInShop[selectedBrand[2]][1][1]))
                            VehicleShop.ChangeVehicle(vehiclesInShop[selectedBrand[2]][1][1])
                            currentVehicle = 1
                        end
                    end
                end
            end

            if activeButton == "purchase:buy" then
                local selectedVehicle = vehiclesInShop[selectedBrand[2]][currentVehicle]
                if selectedFaction[1] and selectedFaction[2] then
                    triggerServerEvent("sarp_carshopS:buyVehicle", localPlayer, localPlayer, selectedVehicle[1], selectedVehicle[2], selectedFaction[2][1])
                else
                    if selectedVehicle[3] then
                        exports.sarp_alert:showAlert("error", "Ezt a járművet csak frakció vezetők vehetik meg!")
                        return
                    end

                    triggerServerEvent("sarp_carshopS:buyVehicle", localPlayer, localPlayer, selectedVehicle[1], selectedVehicle[2])
                end
            end
        end
    end
end

VehicleShop.ButtonHandler = function(button, press)
    if press then
        if selectedBrand[1] and selectedBrand[2] then
            local vehicles = vehiclesInShop[selectedBrand[2]]
            if button == "arrow_l" then
                currentVehicle = currentVehicle - 1
                if currentVehicle <= 1 then
                    currentVehicle = 1
                end
                VehicleShop.ChangeVehicle(vehiclesInShop[selectedBrand[2]][currentVehicle][1])
            elseif button == "arrow_r" then
                currentVehicle = currentVehicle + 1
                if currentVehicle >= #vehicles then
                    currentVehicle = #vehicles
                end
                VehicleShop.ChangeVehicle(vehiclesInShop[selectedBrand[2]][currentVehicle][1])
            end
        end
    end
end


VehicleShop.Open = function()
    VehicleShop.ProcessPlayerGroups()
    selectedBrand = {}
    if table.empty(playerGroups) then
        page = "purchase"
        addEventHandler("onClientRender", root, VehicleShop.ShopPanel)
    else
        page = "select"
        addEventHandler("onClientRender", root, VehicleShop.FactionSelectPanel)
    end
    addEventHandler("onClientClick", root, VehicleShop.ClickHandler)
    addEventHandler("onClientKey", root, VehicleShop.ButtonHandler)
    exports["sarp_3dview"]:processVehiclePreview()
end

VehicleShop.Close = function()
    page = nil
    removeEventHandler("onClientRender", root, VehicleShop.ShopPanel)
    removeEventHandler("onClientKey", root, VehicleShop.ButtonHandler)
    removeEventHandler("onClientClick", root, VehicleShop.ClickHandler)
    exports["sarp_3dview"]:processVehiclePreview()
end

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if button == "left" and state == "down" then
        if clickedElement and isElement(clickedElement) then
            if getElementData(clickedElement, "ped.type") == 3 then
                if exports.sarp_core:inDistance3D(getLocalPlayer(), clickedElement, 5) then
                    if page == nil then
                        shopType = getElementData(clickedElement, "ped.subtype") or 1
                        VehicleShop.Open()
                    end
                end
            end
        end 
    end
end)

