local screenX, screenY = guiGetScreenSize()

local page = "result"
local showPanel = false

local driveW, driveH = respc(700), respc(380)
local driveX, driveY = (screenX - driveW) * 0.5, (screenY - driveH) * 0.5

local currentCheckpoint = 0
local myPoint = 0
local neededPoint = 15
local driveSuccess = false

local checkMarker = nil
local checkBlip = nil
local currentSpeedLimit = nil

local warningDelay = 5000 -- 5mp
local lastWarningTick = getTickCount()
local warningPoints = 0

function renderDrivePanel()

    buttons = {}

    absX, absY = 0, 0

    if isCursorShowing() then
        local relX, relY = getCursorPosition()

        absX = screenX * relX
        absY = screenY * relY
    end

    --> Háttér
    dxDrawRectangle(driveX, driveY, driveW, driveH, tocolor(31, 31, 31, 240))

    --> Fejléc
    dxDrawRectangle(driveX, driveY, driveW, 30, tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(driveX + 3), math.floor(driveY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
    dxDrawText("Vizsga", driveX + 30, driveY, 0, driveY + 30, tocolor(255, 255, 255), 1, fonts.RobotoL, "left", "center")
    
    if page == "main" then
        --> Bezárás
        local closeTextWidth = dxGetTextWidth("X", 1, fonts.RobotoL)
        local closeTextPosX = driveX + driveW - closeTextWidth - 5
        local closeColor = tocolor(255, 255, 255)

        if absX >= closeTextPosX and absY >= driveY and absX <= closeTextPosX + closeTextWidth and absY <= driveY + 30 then
            closeColor = tocolor(215, 89, 89)

            if getKeyState("mouse1") then
                showDrivePanel()
                showCursor(false)
                return
            end
        end
        
        dxDrawText("X", closeTextPosX, driveY, 0, driveY + 30, closeColor, 1, fonts.RobotoL, "left", "center")

        --> Tartalom
        dxDrawText("Üdvözöljük", driveX, driveY + 50, driveW + driveX, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto16, "center")

        dxDrawText("Ut feugiat, nunc tincidunt malesuada pharetra, dolor dui dictum enim, at mattis lorem lectus at libero. Etiam non dui sit amet turpis lacinia posuere. Quisque fringilla mollis pulvinar. Curabitur elementum ac ipsum at ornare. Nullam ac diam sit amet orci ullamcorper imperdiet at id nisi. Vivamus malesuada risus nec mollis pretium. Etiam arcu orci, iaculis in neque vitae, euismod posuere nisl.", driveX + 10, driveY + 40, driveW + driveX - 10, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "center", "center", false, true)

        local buttonW, buttonH = respc(220), respc(40)

        dxDrawMetroButtonWithBorder("exam:exercise:start", "Gyakorlati vizsga elkezdése", driveX + (driveW - buttonW) * 0.5, driveY + driveH - 10 - buttonH, buttonW, buttonH, {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto13, "center", "center", nil, nil, nil, nil)
    
    elseif page == "result" then
            --> Bezárás
            local closeTextWidth = dxGetTextWidth("X", 1, fonts.RobotoL)
            local closeTextPosX = driveX + driveW - closeTextWidth - 5
            local closeColor = tocolor(255, 255, 255)
    
            if absX >= closeTextPosX and absY >= driveY and absX <= closeTextPosX + closeTextWidth and absY <= driveY + 30 then
                closeColor = tocolor(215, 89, 89)
    
                if getKeyState("mouse1") then
                    showCursor(false)
                    showDrivePanel()
                    return
                end
            end
            
            dxDrawText("X", closeTextPosX, driveY, 0, driveY + 30, closeColor, 1, fonts.RobotoL, "left", "center")
    
            --> Tartalom
            if driveSuccess then
                dxDrawText("Átment!", driveX, driveY + 50, driveW + driveX, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto16, "center")
        
                dxDrawText("Az ön ponszáma elérte a szükséges pontszámot! Az igazoló papírt átadtuk önnek. A továbbiakban keressen fel egy okatót a gyakorlati vizsga elkezdéséhez.", driveX + 10, driveY + 40, driveW + driveX - 10, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "center", "center", false, true)
            else
                dxDrawText("Megbukott!", driveX, driveY + 50, driveW + driveX, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto16, "center")
        
                dxDrawText("Az ön ponszáma nem érte el a szükséges pontszámot! Az igazoló papírt átadtuk önnek. A továbbiakban felkereshet minket a vizsga újrapróbálásáért.", driveX + 10, driveY + 40, driveW + driveX - 10, driveH + driveY, tocolor(255, 255, 255, 255), 1, fonts.Roboto13, "center", "center", false, true)
            end
    end

    activeButtonChecker()
end

function showDrivePanel(showPage)
    if not showPage then
        showPanel = false
        removeEventHandler("onClientRender", root, renderDrivePanel)
        return
    end

    if not showPanel then
        addEventHandler("onClientRender", root, renderDrivePanel)
    end

    page = showPage
    showPanel = true
end

function startTestDrive()
    -- rigger Kocsi létrehozás
    showDrivePanel()
    warningPoints = 0
    lastWarningTick = getTickCount()
    currentCheckpoint = 0
    createNextCheckpoint()
    exports.sarp_alert:showAlert("info", "Kövesse az útvonalat")
    triggerServerEvent("sarp_licenesesS:createTestVehicle", localPlayer, localPlayer)
end

function createNextCheckpoint()
    currentCheckpoint = currentCheckpoint + 1
    if currentCheckpoint > #drivePositions then
        exports.sarp_alert:showAlert("info", "Visga vége")
        destroyCheckpoint()
        endOfTestDrive()
        return
    end

    local x, y, z = drivePositions[currentCheckpoint]["position"][1], drivePositions[currentCheckpoint]["position"][2], drivePositions[currentCheckpoint]["position"][3]
    local speedlimit = drivePositions[currentCheckpoint]["speedlimit"] or nil
    createCheckpoint(x, y, z, speedlimit)
end

function destroyCheckpoint()
    if isElement(checkMarker) then
        destroyElement(checkMarker)
    end

    if isElement(checkBlip) then
        destroyElement(checkBlip)
    end

    currentSpeedLimit = nil
end

function createCheckpoint(x, y, z, speedlimit)
    destroyCheckpoint()
    
    checkMarker = createMarker(x, y, z, "checkpoint", 3, 50, 179, 239, 120)

    checkBlip = createBlip(x, y, z)
    setElementData(checkBlip, "blipIcon", "cp")
    setElementData(checkBlip, "blipTooltipText", "Vizsga útvonal")
    setElementData(checkBlip, "blipColor", tocolor(50, 179, 239))

    currentSpeedLimit = speedlimit
    if speedlimit then
        outputChatBox(exports.sarp_core:getServerTag("info") .. "Sebesség korlát #ff4646" .. currentSpeedLimit .. "#ffffffmph lett.", 0, 0, 0, true)
    end
end

function endOfTestDrive(failTest)
    if failTest then
        driveSuccess = false
        destroyCheckpoint()
        showDrivePanel("result")
        triggerServerEvent("addItem", localPlayer, localPlayer, 113, 1, false, false, "vezetés-gyakorlat", getElementData(localPlayer, "char.ID"))
        triggerServerEvent("sarp_licenesesS:destroyTestVehicle", localPlayer, localPlayer)
        return
    end

    local result = false

    if isPedInVehicle(localPlayer) then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if vehicle then
            local vehHP = getElementHealth(vehicle)
            local panelsOK = true
            for i = 0, 6 do
                local panel = getVehiclePanelState(vehicle, i)
                if panel ~= 0 then
                    panelsOK = false
                    break
                end
            end

            if vehHP > 850 and panelsOK then
                result = true
            end
        end
    end

    driveSuccess = result
    showDrivePanel("result")
    triggerServerEvent("addItem", localPlayer, localPlayer, 113, 1, false, result, "vezetés-gyakorlat", getElementData(localPlayer, "char.ID"))
    triggerServerEvent("sarp_licenesesS:destroyTestVehicle", localPlayer, localPlayer)
end

addEventHandler("onClientPreRender", root, function()
    if currentSpeedLimit then
        if isPedInVehicle(localPlayer) then
            local vehicle = getPedOccupiedVehicle(localPlayer)
            if vehicle and getElementData(vehicle, "vehicle.test") then
                local vehicleSpeed = getVehicleSpeed(vehicle)
                local vehicleSpeedInMPH = getMilesByKilometers(vehicleSpeed)
                
                if math.floor(vehicleSpeedInMPH) > currentSpeedLimit then
                    if getTickCount() >= lastWarningTick + warningDelay then
                        outputChatBox("Oktató mondja: Tessék lassabban menni, és sebesség korlátot betartani!", 255, 255, 255)
                        warningPoints = warningPoints + 1
                        if warningPoints > 3 then
                            endOfTestDrive(true)
                        end
                        lastWarningTick = getTickCount()
                    end
                end
            end
        end
    end
end)

addEventHandler("onClientMarkerHit", root, function(player, dim)
    if player == localPlayer then
        if source == checkMarker then
            if isPedInVehicle(localPlayer) then
                local vehicle = getPedOccupiedVehicle(localPlayer)
                if getElementData(vehicle, "vehicle.test") then
                    createNextCheckpoint()
                end
            end
        end
    end
end)

addEventHandler("onClientClick", root, function(button, state)
    if button == "left" and state == "down" then
        if page == "main" then
            if activeButton == "exam:exercise:start" then
                startTestDrive()
            end
        end
    end
end)

function getVehicleSpeed(vehicleElement)
    if isElement(vehicleElement) then
        local velX, velY, velZ = getElementVelocity(vehicleElement)
        return math.sqrt(velX * velX + velY * velY + velZ * velZ) * 180
    end
end

function getMilesByKilometers(kilometers)
    return kilometers * 0.621371192
end

local destroyTimer = nil
local destroyTime = 1

addEventHandler("onClientVehicleStartEnter", root, function(player, seat)
    if player == localPlayer then 
        if getElementData(source, "vehicle.test") and player ~= getElementData(source, "vehicle.testOwner") then
            --if seat == 0 then
                exports.sarp_hud:showAlert("error", "Ez nem a te oktató járműved")
                cancelEvent()
            --end
        end
    end
end)

addEventHandler("onClientVehicleExit", getRootElement(), function(player, seat)
    if player == localPlayer then
        if getElementData(source, "vehicle.test") and player == getElementData(source, "vehicle.testOwner") then
            exports.sarp_hud:showAlert("info", "Az oktató járműved törlődni fog.", "Ha nem szálsz vissza a járművedbe, akkor " .. destroyTime .. " perc után törlődik")
            destroyTimer = setTimer(function()
                endOfTestDrive(true)
                exports.sarp_hud:showAlert("info", "A oktató járműved törlődött")
            end, destroyTime * 60 * 1000, 1)
        end
    end
end)

addEventHandler("onClientVehicleEnter", getRootElement(), function(player, seat)
    if player == localPlayer then
        if getElementData(source, "vehicle.test") and player == getElementData(source, "vehicle.testOwner") then
            if isTimer(vehicleTimer) then
                killTimer(vehicleTimer)
            end
        end
    end
end)