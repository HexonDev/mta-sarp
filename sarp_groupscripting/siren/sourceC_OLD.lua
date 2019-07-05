local sirenSounds = {}
local airhornSounds = {}

addCommandHandler("siren",
    function (command, id)
        id = tonumber(id)

        if not id or id < 0 or id > 3 then
            outputChatBox("Használat: #ffffff/" .. command .. " [0-3 (0 == kikapcsolás)]", 50, 179, 239, true)
            return
        end

        if (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) and allowedVehicles[getElementModel(getPedOccupiedVehicle(localPlayer))] then
            if id == 0 then
                triggerSirenFunctions("sound", false)
            else
                triggerSirenFunctions("sound", id)
            end
        end
    end
)

addCommandHandler("lights",
    function (command, id)
        id = tonumber(id)

        if not id or id < 0 or id > 3 then
            outputChatBox("Használat: #ffffff/" .. command .. " [0-3 (0 == kikapcsolás)]", 50, 179, 239, true)
            return
        end

        if (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) and allowedVehicles[getElementModel(getPedOccupiedVehicle(localPlayer))] then
            if id == 0 then
                triggerSirenFunctions("lights", false)
            else
                triggerSirenFunctions("lights", id)
            end
        end
    end
)

function triggerSirenFunctions(type, id)
    local vehicleElement = getPedOccupiedVehicle(localPlayer)

    if type == "sound" then
        local sirenData = getElementData(vehicleElement, "vehicle.siren") or {sound = false, light = false, strobe = false}

        if sirenData.sound ~= id then
            sirenData.sound = id
            triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, id)
        elseif not id or sirenData.sound == id then
            sirenData.sound = false
            triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, false)
        end

        setElementData(vehicleElement, "vehicle.siren", sirenData)
    elseif type == "lights" then
        local sirenData = getElementData(vehicleElement, "vehicle.siren") or {sound = false, light = false, strobe = false}

        if sirenData.light ~= id then
            sirenData.light = id
            triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, id)
        elseif not id or sirenData.light == id then
            sirenData.light = false
            triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, false)
        end

        setElementData(vehicleElement, "vehicle.siren", sirenData)
   end
end

addEvent("sarp_sirenC:toggleSirenSound", true)
addEventHandler("sarp_sirenC:toggleSirenSound", root, function(soundID)
    if source == localPlayer and not isPedInVehicle(source) then
        return
    end

    local vehicle = getPedOccupiedVehicle(source)
    local modelID = getElementModel(vehicle) 
    if soundID and tonumber(soundID) then
        if allowedVehicles[modelID] and vehiclesSiren[modelID] then

            if isElement(sirenSounds[vehicle]) then
                destroyElement(sirenSounds[vehicle])
            end

            local x, y, z = getElementPosition(vehicle)
            if vehiclesSiren[modelID][soundID] then
                sirenSounds[vehicle] = playSound3D("siren/sounds/" .. vehiclesSiren[modelID][soundID], x, y, z, true)
                setSoundMaxDistance(sirenSounds[vehicle], 200)
                attachElements(sirenSounds[vehicle], vehicle)
                setSoundVolume(sirenSounds[vehicle], 0.5)
            else
                exports.sarp_alert:showAlert("error", "Nincs beállítva megkülönböztető hangjelzés erre a gombra")
            end
        end
    else
        if isElement(sirenSounds[vehicle]) then
            destroyElement(sirenSounds[vehicle])
        end
    end
end)

addEvent("sarp_sirenC:useAirhorn", true)
addEventHandler("sarp_sirenC:useAirhorn", root, function(state)
    if source == localPlayer and not isPedInVehicle(source) then
        return
    end

    local vehicle = getPedOccupiedVehicle(source)
    local modelID = getElementModel(vehicle) 
    if state then
        if allowedVehicles[modelID] and vehiclesSiren[modelID] then
            if isElement(airhornSounds[vehicle]) then
                destroyElement(airhornSounds[vehicle])
            end

            local x, y, z = getElementPosition(vehicle)
            if vehiclesSiren[modelID]["horn"] then
                airhornSounds[vehicle] = playSound3D("siren/sounds/" .. vehiclesSiren[modelID]["horn"], x, y, z, true)
                setSoundMaxDistance(airhornSounds[vehicle], 200)
                attachElements(airhornSounds[vehicle], vehicle)
            else
                exports.sarp_alert:showAlert("error", "Nincs beállítva légkürt ezen a járművön")
            end
        end
    else
        if isElement(airhornSounds[vehicle]) then
            destroyElement(airhornSounds[vehicle])
        end
    end
end)

addEventHandler("onClientRender", root, function()
    --if getElementData(localPlayer, "groupDuty") then
        local pX, pY, pZ = getElementPosition(localPlayer)
        for k, v in pairs(getElementsByType("vehicle")) do
            if v ~= getPedOccupiedVehicle(localPlayer) then
                if getElementData(v, "siren.unit") then
                    if isElement(v) then
                        local vX, vY, vZ = getElementPosition(v)
                        if getDistanceBetweenPoints3D(vX, vY, vZ, pX, pY, pZ) <= 10 then
                            local cX, cY, cZ = getVehicleComponentPosition(v, "wheel_lb_dummy", "world")
                            local worldX, worldY = getScreenFromWorldPosition(cX, cY, cZ, 10)
                            if worldX then
                                local cameraX, cameraY, cameraZ = getCameraMatrix()
                                if isLineOfSightClear(cameraX, cameraY, cameraZ, cX, cY, cZ, true, false, false, true, false, true, false) then
                                    exports.sarp_UI:dxDrawBorderedText(getElementData(v, "siren.unit"), worldX, worldY, worldX, worldY, tocolor(255, 255, 255), 1, fonts.Roboto11)
                                end
                            end
                        end
                    end
                end
            end
        end
    --end
end)

addEventHandler("onClientPlayerSpawn", getLocalPlayer(), function()
    setTimer(function()
        local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)

        for k, v in ipairs(getElementsByType("vehicle")) do
            if playerGroups[getElementData(v, "vehicle.group")] and getElementData(v, "siren.status") then
                local status = getElementData(v, "siren.status")
                if status == 1 then -- Nem elérhető
                    local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                    if gpsBlips[v] then
                        destroyElement(gpsBlips[v])
                    end
                    if playerGroups[getElementData(v, "vehicle.group")] then
                        gpsBlips[v] = createBlip(0, 0, 0)
                        setElementData(gpsBlips[v], "blipIcon", "cp")
                        --setElementData(gpsBlips[v], "blipSize", 30)
                        setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                        attachElements(gpsBlips[v], v)
                        setElementData(gpsBlips[v], "blipColor", tocolor(255, 182, 0))
                        setElementData(gpsBlips[v], "blipFarShow", true)
                    end
                elseif status == 2 then -- Elérhető
                    local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                    if playerGroups[getElementData(v, "vehicle.group")] then
                        if gpsBlips[v] then
                            destroyElement(gpsBlips[v])
                        end
                        if playerGroups[getElementData(v, "vehicle.group")] then
                            gpsBlips[v] = createBlip(0, 0, 0)
                            setElementData(gpsBlips[v], "blipIcon", "cp")
                            --setElementData(gpsBlips[v], "blipSize", 30)
                            setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                            attachElements(gpsBlips[v], v)
                            setElementData(gpsBlips[v], "blipColor", tocolor(50, 179, 239))
                            setElementData(gpsBlips[v], "blipFarShow", true)
                        end
                    end
                elseif status == 3 then -- Erősítés
                    local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                    if playerGroups[getElementData(v, "vehicle.group")] then
                        if gpsBlips[v] then
                            destroyElement(gpsBlips[v])
                        end
                        if playerGroups[getElementData(v, "vehicle.group")] then
                            gpsBlips[v] = createBlip(0, 0, 0)
                            setElementData(gpsBlips[v], "blipIcon", "cp")
                            --setElementData(gpsBlips[v], "blipSize", 30)
                            setElementData(gpsBlips[v], "blipTooltipText", "[ERŐSÍTÉS][" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                            attachElements(gpsBlips[v], v)
                            setElementData(gpsBlips[v], "blipColor", tocolor(255, 66, 66))
                            setElementData(gpsBlips[v], "blipFarShow", true)
                            playSound("siren/sounds/backup.mp3" )
                            outputChatBox("#32b3ef[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "]#ffffff " .. getElementData(v, "siren.unit") .. " #ff4646erősítést #ffffffkért.", 0, 0, 0, true)
                        end
                    end
                end
            end
        end
    end, 7000, 1)
end)

addEventHandler("onClientElementDataChange", root, function(dataName, oldValue, newValue)
    if getElementType(source) == "vehicle" and dataName == "siren.status" then
        if newValue == 0 then
            if gpsBlips[source] then
                destroyElement(gpsBlips[source])
            end
        elseif newValue == 1 then -- Nem elérhető
            local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
            if gpsBlips[source] then
                destroyElement(gpsBlips[source])
            end
            if playerGroups[getElementData(source, "vehicle.group")] then
                gpsBlips[source] = createBlip(0, 0, 0)
                setElementData(gpsBlips[source], "blipIcon", "cp")
                --setElementData(gpsBlips[source], "blipSize", 30)
                setElementData(gpsBlips[source], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(source, "vehicle.group")) .. "] " .. getElementData(source, "siren.unit") or "Ismeretlen")
                attachElements(gpsBlips[source], source)
                setElementData(gpsBlips[source], "blipColor", tocolor(255, 182, 0))
                setElementData(gpsBlips[source], "blipFarShow", true)
            end
        elseif newValue == 2 then -- Elérhető
            local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
            if playerGroups[getElementData(source, "vehicle.group")] then
                if gpsBlips[source] then
                    destroyElement(gpsBlips[source])
                end
                if playerGroups[getElementData(source, "vehicle.group")] then
                    gpsBlips[source] = createBlip(0, 0, 0)
                    setElementData(gpsBlips[source], "blipIcon", "cp")
                    --setElementData(gpsBlips[source], "blipSize", 30)
                    setElementData(gpsBlips[source], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(source, "vehicle.group")) .. "] " .. getElementData(source, "siren.unit") or "Ismeretlen")
                    attachElements(gpsBlips[source], source)
                    setElementData(gpsBlips[source], "blipColor", tocolor(50, 179, 239))
                    setElementData(gpsBlips[source], "blipFarShow", true)
                end
            end
        elseif newValue == 3 then -- Erősítés
            local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
            if playerGroups[getElementData(source, "vehicle.group")] then
                if gpsBlips[source] then
                    destroyElement(gpsBlips[source])
                end
                if playerGroups[getElementData(source, "vehicle.group")] then
                    gpsBlips[source] = createBlip(0, 0, 0)
                    setElementData(gpsBlips[source], "blipIcon", "cp")
                    --setElementData(gpsBlips[source], "blipSize", 30)
                    setElementData(gpsBlips[source], "blipTooltipText", "[ERŐSÍTÉS][" .. exports.sarp_groups:getGroupPrefix(getElementData(source, "vehicle.group")) .. "] " .. getElementData(source, "siren.unit") or "Ismeretlen")
                    attachElements(gpsBlips[source], source)
                    setElementData(gpsBlips[source], "blipColor", tocolor(255, 66, 66))
                    setElementData(gpsBlips[source], "blipFarShow", true)
                    playSound("siren/sounds/backup.mp3" )
                    outputChatBox("#32b3ef[" .. exports.sarp_groups:getGroupPrefix(getElementData(source, "vehicle.group")) .. "]#ffffff " .. getElementData(source, "siren.unit") .. " #ff4646erősítést #ffffffkért.", 0, 0, 0, true)
                end
            end
        end

        if oldValue == 3 then
            outputChatBox("#32b3ef[" .. exports.sarp_groups:getGroupPrefix(getElementData(source, "vehicle.group")) .. "]#ffffff " .. getElementData(source, "siren.unit") .. " #7cc576lemondta#ffffff az erősítést.", 0, 0, 0, true)
        end
    end

    if getElementType(source) == "player" and dataName == "player.groups" then
        local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)

        if oldValue then
            if table.length(playerGroups) < table.length(oldValue) then
                for k, v in pairs(gpsBlips) do
                    if not playerGroups[getElementData(k, "vehicle.group")] then
                        destroyElement(gpsBlips[k])    
                    end
                end
            elseif table.length(playerGroups) > table.length(oldValue) then
                for k, v in ipairs(getElementsByType("vehicle")) do
                    if playerGroups[getElementData(v, "vehicle.group")] and getElementData(v, "siren.gps") then
                        gpsBlips[v] = createBlip(0, 0, 0)
                        setElementData(gpsBlips[v], "blipIcon", "cp")
                        --setElementData(gpsBlips[v], "blipSize", 30)
                        setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                        attachElements(gpsBlips[v], v)
                        setElementData(gpsBlips[v], "blipColor", tocolor(0, 0, 200))
                    end
                end
            end
        end
    end

    if getElementType(source) == "player" and dataName == "loggedIn" then
        if newValue == true then

        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        local playerGroups = exports.sarp_groups:getPlayerGroups(player)
        for k, v in ipairs(getElementsByType("vehicle")) do
            local status = getElementData(v, "siren.status")
            if status == 1 then -- Nem elérhető
                local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                if gpsBlips[v] then
                    destroyElement(gpsBlips[v])
                end
                if playerGroups[getElementData(v, "vehicle.group")] then
                    gpsBlips[v] = createBlip(0, 0, 0)
                    setElementData(gpsBlips[v], "blipIcon", "cp")
                    --setElementData(gpsBlips[v], "blipSize", 30)
                    setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                    attachElements(gpsBlips[v], v)
                    setElementData(gpsBlips[v], "blipColor", tocolor(255, 182, 0))
                    setElementData(gpsBlips[v], "blipFarShow", true)
                end
            elseif status == 2 then -- Elérhető
                local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                if playerGroups[getElementData(v, "vehicle.group")] then
                    if gpsBlips[v] then
                        destroyElement(gpsBlips[v])
                    end
                    if playerGroups[getElementData(v, "vehicle.group")] then
                        gpsBlips[v] = createBlip(0, 0, 0)
                        setElementData(gpsBlips[v], "blipIcon", "cp")
                        --setElementData(gpsBlips[v], "blipSize", 30)
                        setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                        attachElements(gpsBlips[v], v)
                        setElementData(gpsBlips[v], "blipColor", tocolor(50, 179, 239))
                        setElementData(gpsBlips[v], "blipFarShow", true)
                    end
                end
            elseif status == 3 then -- Erősítés
                local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)
                if playerGroups[getElementData(v, "vehicle.group")] then
                    if gpsBlips[v] then
                        destroyElement(gpsBlips[v])
                    end
                    if playerGroups[getElementData(v, "vehicle.group")] then
                        gpsBlips[v] = createBlip(0, 0, 0)
                        setElementData(gpsBlips[v], "blipIcon", "cp")
                        --setElementData(gpsBlips[v], "blipSize", 30)
                        setElementData(gpsBlips[v], "blipTooltipText", "[ERŐSÍTÉS][" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
                        attachElements(gpsBlips[v], v)
                        setElementData(gpsBlips[v], "blipColor", tocolor(255, 66, 66))
                        setElementData(gpsBlips[v], "blipFarShow", true)
                        playSound("siren/sounds/backup.mp3" )
                        outputChatBox("#32b3ef[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "]#ffffff " .. getElementData(v, "siren.unit") .. " #ff4646erősítést #ffffffkért.", 0, 0, 0, true)
                    end
                end
            end
        end
    end
end)

table.length = function (tbl)
	local count = 0

	for _ in pairs(tbl) do
		count = count + 1
	end

	return count
end

local statusColors = {
    [1] = tocolor(255, 182, 0),
    [2] = tocolor(50, 179, 239),
    [3] = tocolor(255, 66, 66),
}

function refreshBackupBlip(vehicle, status)

end

function createBackupBlip(vehicle, player, status)
    if isElement(vehicle) and player then
        local currentStatus = getElementData(vehicle, "siren.status")
        local playerGroups = exports.sarp_groups:getPlayerGroups(player)

        local v = vehicle
        if playerGroups[getElementData(v, "vehicle.group")] then
            if gpsBlips[v] then
                destroyElement(gpsBlips[v])
            end

            gpsBlips[v] = createBlip(0, 0, 0)
            setElementData(gpsBlips[v], "blipIcon", "cp")
            --setElementData(gpsBlips[v], "blipSize", 30)
            setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. getElementData(v, "siren.unit") or "Ismeretlen")
            attachElements(gpsBlips[v], v)
            setElementData(gpsBlips[v], "blipColor", statusColors[currentStatus])
            setElementData(gpsBlips[v], "blipFarShow", true)
        end
    end
end