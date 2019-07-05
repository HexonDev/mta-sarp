local Elements = Dashboard.Elements
local Handlers = Dashboard.Handlers

local infoTiles = {
    {"Készpénz", "files/icons/coins.png", "Betöltés...", "$"},
    {"Számla egyenleg", "files/icons/bank.png", "Betöltés...", "$"},
    {"Járművek", "files/icons/car.png", "Betöltés...", " db"},
    {"Ingatlanok", "files/icons/home.png", "Betöltés...", " db"}
}

local selectedTab = "vehicle"
local selectedElement = {nil, nil}
local tabColors = {
    ["vehicle"] = {7, 112, 196},
    ["interior"] = {200, 50, 50},
}

local tileColors = {
    ["vehicle"] = {7, 112, 196},
    ["interior"] = {200, 50, 50},
}

local interiorTypes = {
    building = "Középület",
    house = "Ház",
    garage = "Garázs",
    rentable = "Albérlet",
    passageway = "Átjáró" 
}

addEventHandler("onClientKey", getRootElement(),
    function (key, press)
        if press then
            if activePage == "Property" then
                if selectedTab == "vehicle" then
                    local offset = scrollData["vehiclesOffset"] or 0

                    if key == "mouse_wheel_down" and offset < #ProcessPlayerVehicles() - maxVisibleTile then
                        offset = offset + 1
                    elseif key == "mouse_wheel_up" and offset > 0 then
                        offset = offset - 1
                    end

                    scrollData["vehiclesOffset"] = offset
                elseif selectedTab == "interior" then
                    local offset = scrollData["interiorsOffset"] or 0

                    if key == "mouse_wheel_down" and offset < #ProcessPlayerInteriors() - maxVisibleTile then
                        offset = offset + 1
                    elseif key == "mouse_wheel_up" and offset > 0 then
                        offset = offset - 1
                    end

                    scrollData["interiorsOffset"] = offset
                end
            end
        end
    end
)

Elements.Property = function(x, y, w, h)
    --buttons = {}
    local alphaMul = tabPanelAlphas["Property"]

    local cursorX, cursorY = getCursorPosition()
    local absX, absY = -1, -1
    if isCursorShowing() then
        absX, absY = cursorX * screenX, cursorY * screenY
    elseif cursorIsMoving then
        cursorIsMoving = false
    end

    local offsetFromLeftRightSide = respc(20)
    local tileMarginOffset = respc(15)
    local rightSideAreaWidth = screenX - respc(300) - offsetFromLeftRightSide*4

    local visibleTiles = math.ceil((screenX / rightSideAreaWidth) + 2)
    local tileWidth = rightSideAreaWidth / visibleTiles
    local tileHeight = respc(200)
    
    local offsetX = x + offsetFromLeftRightSide
    local offsetY = y + respc(20)

    for i = 1, #infoTiles do
        local tile = infoTiles[i]

        dxDrawMetroBox(offsetX, offsetY, tileWidth, tileHeight, tocolor(43, 87, 151, 175 * alphaMul), tile[2], respc(100), respc(100), nil, "center", tile[1], tocolor(255, 255, 255, 255), fonts.RobotoL, nil, tile[3] .. tile[4], tocolor(255, 255, 255, 255 * alphaMul), fonts.Roboto18L, nil)
        --drawtile("btn" .. i, "Label?", offsetX, offsetY, tileWidth, tileHeight, {43, 87, 151}, nil, fonts.Roboto14)
        --if activetile == tile[1] then
        --    dxDrawRectangle(offsetX, offsetY + tileHeight, tileWidth, respc(50), tocolor(0, 0, 0, 50 * alphaMul))
        --    dxDrawText(tile[3], offsetX, offsetY + tileHeight, offsetX + tileWidth,(offsetY + tileHeight) + respc(50), tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14, "center", "center")
        --end

        if i % visibleTiles == 0 then
            offsetX = x + offsetFromLeftRightSide
            offsetY = offsetY + tileHeight + tileMarginOffset
        else
            offsetX = offsetX + tileWidth + tileMarginOffset
        end
    end

    local vehicles = ProcessPlayerVehicles()
    local interiors = ProcessPlayerInteriors()

    local listPanelX, listPanelY = x + respc(20), y + respc(320) 
    local listPanelW, listPanelH = respc(400), h - listPanelY - respc(20)

    local tabButtonW, tabButtonH = (listPanelW * 0.5), respc(50)
    local tabButtonX, tabButtonY = listPanelX, listPanelY - tabButtonH

    dxDrawMetroTileWithoutBorder("tab:vehicle", "Jármű", tabButtonX, tabButtonY, tabButtonW, tabButtonH, tabColors["vehicle"], nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Járművek", nil, nil, "center")
    dxDrawMetroTileWithoutBorder("tab:interior", "Interior", tabButtonX + tabButtonW, tabButtonY, tabButtonW, tabButtonH, tabColors["interior"], nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Ingatlanok", nil, nil, "center")
    --dxDrawMetroTileWithEffect("tab:" .. selectedTab, "Jármű", listPanelX, listPanelY, listPanelW, listPanelH, tabColors[selectedTab])
    --dxDrawRectangle(listPanelX, listPanelY, listPanelW, listPanelH, tocolor(0, 0, 0, 100))
    dxDrawMetroTilePanel("tab:panel", "Panel", listPanelX, listPanelY, listPanelW, listPanelH, {tabColors[selectedTab][1], tabColors[selectedTab][2], tabColors[selectedTab][3], 100})

    local tileW, tileH = listPanelW - respc(20), respc(75)
    local tileX = listPanelX + respc(10)

    maxVisibleTile = math.floor(listPanelH / (tileH + tileMarginOffset))
    --outputDebugString(maxVisibleTile)

    if selectedTab == "vehicle" then
        local vehiclesOffset = scrollData["vehiclesOffset"] or 0

        for i = 1, maxVisibleTile do
            local vehicle = vehicles[i + vehiclesOffset]

            if vehicle then
                local tileY = (listPanelY + respc(15)) + ((tileH + tileMarginOffset) * (i - 1))

                dxDrawMetroTileWithEffect("jármű:" .. i + vehiclesOffset, "Jármű", tileX, tileY, tileW, tileH, tileColors[selectedTab], ":sarp_groups/files/vehicleTypes/" .. getVehicleType(vehicle) .. ".png", respc(50), respc(50), {255, 255, 255, 255}, "left", nil, nil, nil, nil, nil, nil, nil, nil, exports.sarp_mods_veh:getVehicleName(vehicle))
            end
        end

        if #vehicles > maxVisibleTile then
            drawScrollbar("vehicles", tileX + tileW + respc(10), listPanelY, respc(12), listPanelH, maxVisibleTile, #vehicles)
        end
    elseif selectedTab == "interior" then
        local interiorsOffset = scrollData["interiorsOffset"] or 0

        for i = 1, maxVisibleTile do
            local interior = interiors[i + interiorsOffset]

            if interior then
                local tileY = (listPanelY + respc(15)) + ((tileH + tileMarginOffset) * (i - 1))

                dxDrawMetroTileWithEffect("ingatlan:" .. i + interiorsOffset, "Ingatlan", tileX, tileY, tileW, tileH, tileColors[selectedTab], ":sarp_interiors/files/icons/" .. interior.data.type .. ".png", respc(50), respc(50), {255, 255, 255, 255}, "left", nil, nil, nil, nil, nil, nil, nil, nil, interior.data.name)
            end
        end

        if #interiors > maxVisibleTile then
            drawScrollbar("interiors", tileX + tileW + respc(10), listPanelY, respc(12), listPanelH, interiorsOffset, #interiors)
        end
    end

    local infoTextX, infoTextY = listPanelX + listPanelW + respc(20), listPanelY

    if selectedElement[1] == "interior" then
        local interior = selectedElement[2]

        dxDrawText(interior.name, infoTextX, infoTextY, infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto18)
        
        local place = getZoneName(unpack(interior.entrance.position))
        local type = interiorTypes[interior.type]
        local door = "Zárva"
        if interior.locked == "N" then
            door = "Nyitva"
        end

        dxDrawText("Azonosító: " .. selectedElement[3], infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 0), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Típus: " .. exports.sarp_interiors:getInteriorType(selectedElement[3]), infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 1), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Elhelyezkedés: " .. place, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 2), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Ajtó: " .. door, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 3), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        
        if interior.type == "rentable" then
            local time = getRealTime(interior.renewalTime)
            local year, month, day, hour, minute = time.year + 1900, time.month + 1, time.monthday, time.hour, time.minute

            dxDrawText("Lejárat: " .. string.format("%04d. %02d. %02d. %02d:%02d", year, month, day, hour, minute) , infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 4), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        end
    
    elseif selectedElement[1] == "vehicle" then
        local vehicle = selectedElement[2]

        dxDrawText(exports.sarp_mods_veh:getVehicleName(vehicle), infoTextX, infoTextY, infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto18)
        
        local id = getElementData(vehicle, "vehicle.dbID")
        local engine = "Leállítva"
        if getElementData(vehicle, "vehicle.engine") then
            engine = "Beindítva"
        end

        local locked = "Kinyitva"
        if getElementData(vehicle, "vehicle.locked") then
            locked = "Bezárva"
        end

        local lights = "Lekapcsolva"
        if getElementData(vehicle, "vehicle.light") then
            lights = "Felkapcsolva"
        end

        local handbrake = "Kiengedve"
        if getElementData(vehicle, "vehicle.handBrake") then
            handbrake = "Behúzva"
        end
        
        local fuel = getElementData(vehicle, "vehicle.fuel")
        local miles = getElementData(vehicle, "vehicle.distance")

        dxDrawText("Azonosító: " .. id, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 0), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Motor: " .. engine, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 1), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Lámpák: " .. lights, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 2), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Kézifék: " .. handbrake, infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 3), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Üzemanyag: " .. math.floor(fuel) .. "%", infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 4), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Mérföldek: " .. math.floor(miles), infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 5), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
        dxDrawText("Állapot: " .. math.floor(getElementHealth(vehicle) / 10) .. "%", infoTextX, (infoTextY + dxGetFontHeight(1, fonts.Roboto18)) + (dxGetFontHeight(1, fonts.Roboto14) * 6), infoTextX, infoTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14)
    
        local vehicleSize = listPanelH
        local vehicleX, vehicleY = screenX - respc(40) - vehicleSize, infoTextY 

        exports["sarp_3dview"]:setVehicleProjection(vehicleX, vehicleY, vehicleSize, vehicleSize, 255 * alphaMul)
        --dxDrawRectangle(vehicleX, vehicleY, vehicleSize, vehicleSize)
        
        if cursorIsMoving then
            exports["sarp_3dview"]:rotateVehicle(cursorX)
            setCursorPosition(screenX * 0.5, screenY * 0.5)
            
            if not getKeyState("mouse1") then
                cursorIsMoving = false
                setCursorAlpha(255)
            end
        elseif cursorInBox(vehicleX, vehicleY, vehicleSize, vehicleSize) and getKeyState("mouse1") then
            cursorIsMoving = true
            setCursorAlpha(0)
            setCursorPosition(screenX * 0.5, screenY * 0.5)
        end
        
        if cursorInBox(vehicleX, vehicleY, vehicleSize, vehicleSize) then
            carHoveredForRotation = true
        end
    
    end

    activeButtonChecker()
end

Handlers.Property = {}
Handlers.Property.ProcessPlayerInfo = {function()

    infoTiles[1][3] = getElementData(localPlayer, "char.Money")
    infoTiles[2][3] = getElementData(localPlayer, "char.bankMoney")
    infoTiles[3][3] = #ProcessPlayerVehicles()
    infoTiles[4][3] = #ProcessPlayerInteriors()
end, "function"}

Handlers.Property.ResetSelectedElement = {function()
    selectedElement = {}
end, "function"}

function ProcessPlayerVehicles()
    local playerVehicles = {}
    for k, v in ipairs(getElementsByType("vehicle")) do
        if getElementData(v, "vehicle.dbID") and getElementData(v, "vehicle.owner") == getElementData(localPlayer, "char.ID") then
            table.insert(playerVehicles, v)
        end
    end

    return playerVehicles
end

function ProcessPlayerInteriors()
    local playerInteriors = exports.sarp_interiors:requestInteriors(localPlayer)
    return playerInteriors
end

Handlers.Property.Click = {function(button, state)
    if button == "left" and state == "down" then
        if activeButton == "tab:vehicle" then
            selectedTab = "vehicle"
        elseif activeButton == "tab:interior" then
            selectedTab = "interior"
        end

        local vehicles = ProcessPlayerVehicles()
        local interiors = ProcessPlayerInteriors()

        if selectedTab == "vehicle" then
            for k, v in pairs(vehicles) do
                if activeButton == "jármű:" .. k then
                    selectedElement = {"vehicle", v}

                    exports["sarp_3dview"]:processVehiclePreview()
                    exports["sarp_3dview"]:processVehiclePreview(selectedElement[2], 0, 0, 0, 0, false) -- utolsó érték a karosszéria sérülések ki- és bekapcsolása, a többi nulla, a render majd úgy is beállítja
					exports["sarp_3dview"]:setVehicleAlpha(0)
                end
            end
        elseif selectedTab == "interior" then
            for k, v in pairs(interiors) do
                if activeButton == "ingatlan:" .. k then
                    selectedElement = {"interior", v.data, v.interiorId}
                end
            end
        end

        --outputDebugString(selectedElement)
    end
end, "onClientClick"}