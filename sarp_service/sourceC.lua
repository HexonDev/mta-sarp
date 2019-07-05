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

local boxCols = {}

boxCols[1] = createColRectangle(1611.9886474609, -2184.1232910156, 8, 12)
boxCols[2] = createColRectangle(1598.1882324219, -2184.076171875, 8, 12)
boxCols[3] = createColRectangle(1584.5158691406, -2184.208984375, 8, 12)
boxCols[4] = createColRectangle(1584.4818115234, -2155.44140625, 8, 12)
boxCols[5] = createColRectangle(1598.2395019531, -2155.44140625, 8, 12)
boxCols[6] = createColRectangle(1612.0655517578, -2155.44140625, 8, 12)

function isElementInServiceZone(element)
    if isElement(element) then
        for k, v in pairs(boxCols) do 
            if isElementWithinColShape(element, v) then
                return true
            end
        end
    end

    return false
end

local serviceTime = 10
local startTick = nil
local selectedVehicle = nil
local isServicing = false
local barW, barH = 251, 10
local barX, barY = (screenX - barW) / 2, screenY - 5 - 46 - barH - 5

function startService(component)
    --selectedVehicle = source
    selectedComponent = component
    startTick = getTickCount()
    addEventHandler("onClientRender", root, renderService)
    isServicing = true
end
addEvent("sarp_serviceC:startService", true)
addEventHandler("sarp_serviceC:startService", root, startService)

addEvent("sarp_serviceC:showService", true)
addEventHandler("sarp_serviceC:showService", root, function()
    print("ok")
    selectedVehicle = source
    print(selectedVehicle, source)
end)

local imageS = 22

function renderService()
    if startTick then
        dxDrawRectangle(barX, barY, barW, barH, tocolor(31, 31, 31, 240))
        dxDrawImage(barX, barY-imageS, imageS, imageS, "files/wrench.png")
        dxDrawText("A szerelés állapota:", barX+imageS+5, barY-imageS+2, imageS, imageS,tocolor(255,255,255), 1, fonts.Roboto11)
        local currentTick = getTickCount()
        local elapsedTick = currentTick - startTick
        local endTick = startTick + serviceTime * 1000
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
            removeEventHandler("onClientRender", root, renderService)
            triggerServerEvent("sarp_serviceS:repairComponent", localPlayer, selectedVehicle, selectedComponent)
            isServicing = false
        end
    end
end

local panelW, panelH = respc(300), respc(400)
local panelX, panelY = 10, (screenY - panelH) *0.5
local buttonW, buttonH = respc(150), respc(30)

addEventHandler("onClientRender", root, function()
    if selectedVehicle then
        if isElementInServiceZone(selectedVehicle) then
            buttons = {}
            local wheels = {}

            if exports.sarp_core:inDistance3D(localPlayer, selectedVehicle, 4) and not isServicing then
                for k, v in pairs(getVehicleComponents(selectedVehicle)) do
                    local cX, cY, cZ = getVehicleComponentPosition(selectedVehicle, k, "world")
                    local pX, pY, pZ = getElementPosition(localPlayer)
                    if getDistanceBetweenPoints3D(cX, cY, cZ, pX, pY, pZ) <= 2 then
                        local x, y = getScreenFromWorldPosition(cX, cY, cZ)
                        local cameraX, cameraY, cameraZ = getCameraMatrix()
                        if x then
                            if isLineOfSightClear(cameraX, cameraY, cameraZ, cX, cY, cZ, true, false, false, true, false, true, false) then
                                if components[k] then
                                    local boxW, boxH = respc(150), respc(30)
                                    local boxX, boxY = x - boxW/2, y
                                
                                    if doors[k] then
                                        if getVehicleDoorState(selectedVehicle, doors[k]) > 1 then 
                                            dxDrawMetroButtonWithBorder("component:" .. k, components[k], boxX, boxY, boxW, boxH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                
                                        end
                                    end

                                    if panels[k] then
                                        if getVehiclePanelState(selectedVehicle, panels[k]) ~= 0 then 
                                            dxDrawMetroButtonWithBorder("component:" .. k, components[k], boxX, boxY, boxW, boxH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                                        end
                                    end
                                    --local frontLeftWheel, rearLeftWheel, frontRightWheel, rearRightWheel = getVehicleWheelStates(selectedVehicle)
                                    wheels["wheel_lf_dummy"], wheels["wheel_lb_dummy"], wheels["wheel_rf_dummy"], wheels["wheel_rb_dummy"] = getVehicleWheelStates(selectedVehicle)
                                    if wheels[k] then
                                        if wheels[k] > 0 then
                                            dxDrawMetroButtonWithBorder("component:" .. k, components[k], boxX, boxY, boxW, boxH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                --> Háttér
                dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(31, 31, 31, 240))

                --> Fejléc
                dxDrawRectangle(panelX, panelY, panelW, 30, tocolor(31, 31, 31, 240))
                dxDrawImage(math.floor(panelX + 3), math.floor(panelY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
                dxDrawText("Sérült alkatrészek", panelX + 30, panelY, 0, panelY + 30, tocolor(255, 255, 255), 1, fonts.RobotoL, "left", "center")

                --> Tartalom

                local num = 0

                if getElementHealth(selectedVehicle) < 800 then
                    dxDrawMetroButtonWithBorder("component:engine", "Motor", panelX + (panelW-buttonW)*0.5, (panelY + 40) + (buttonH + 10) * num, buttonW, buttonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                    num = num + 1
                end

                if getVehicleLightState(selectedVehicle, 0) == 1 then
                    dxDrawMetroButtonWithBorder("component:left_light", "Bal első lámpa", panelX + (panelW-buttonW)*0.5, (panelY + 40) + (buttonH + 10) * num, buttonW, buttonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                    num = num + 1
                end

                if getVehicleLightState(selectedVehicle, 1) == 1 then
                    dxDrawMetroButtonWithBorder("component:right_light", "Jobb első lámpa", panelX + (panelW-buttonW)*0.5, (panelY + 40) + (buttonH + 10) * num, buttonW, buttonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                    num = num + 1
                end

                local lastOilChange = getElementData(selectedVehicle, "lastOilChange") or 0
                local kilometersToChangeOil = 500 - math.floor(math.floor(lastOilChange or 0) / 1000)
                
                if kilometersToChangeOil <= 0 then
                    dxDrawMetroButtonWithBorder("component:oil", "Olajcsere", panelX + (panelW-buttonW)*0.5, (panelY + 40) + (buttonH + 10) * num, buttonW, buttonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto11, "center", "center", nil, nil, nil, nil)
                end
                
            end
            activeButtonChecker()
        else
            if isElement(selectedVehicle) then
                selectedVehicle = nil
            end
        end
    end
end)

addEventHandler("onClientClick", root, function(button, state)
    if state == "down" and button == "left" then
        if selectedVehicle then
            for k, v in pairs(getVehicleComponents(selectedVehicle)) do
                if components[k] then
                    if activeButton == "component:" .. k then
                        --triggerServerEvent("sarp_serviceS:repairComponent", localPlayer, selectedVehicle, k)
                        triggerServerEvent("sarp_serviceS:startService", localPlayer, selectedVehicle, k)
                    end
                end
            end

            for k, v in pairs(others) do
                if activeButton == "component:" .. k then
                    triggerServerEvent("sarp_serviceS:startService", localPlayer, selectedVehicle, k)
                end
            end
        end
    end
end)

local sounds = {}

addEvent("repairSound", true)
addEventHandler("repairSound", root, function(x, y, z, state)
    if not state then
        if isElement(sounds[source]) then
            stopSound(sounds[source])
        end

        return
    end 
    sounds[source] = playSound3D("files/repair.mp3", x, y, z, true)
end)
