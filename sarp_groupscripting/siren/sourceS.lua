
addEvent("sarp_sirenS:toggleSirenSound", true)
addEventHandler("sarp_sirenS:toggleSirenSound", root, function(soundID)
    local modelID = getElementModel(getPedOccupiedVehicle(source)) 
    if allowedVehicles[modelID] then
        triggerClientEvent("sarp_sirenC:toggleSirenSound", source, soundID)
    end
end)

addEvent("sarp_sirenS:toggleSirenLights", true)
addEventHandler("sarp_sirenS:toggleSirenLights", root, function(lightID)
    local vehicle = getPedOccupiedVehicle(source)
    local modelID = getElementModel(vehicle)
    if allowedVehicles[modelID] and sirenPos[modelID] then
        if lightID and tonumber(lightID) then
            addVehicleSirens(vehicle, #sirenPos[modelID][lightID], 2, false, false, true, true)
            for k, v in ipairs(sirenPos[modelID][lightID]) do
                setVehicleSirens(vehicle, k, unpack(v))
            end
            setVehicleSirensOn(vehicle, false)
            setVehicleSirensOn(vehicle, true)
        else
            setVehicleSirensOn(vehicle, false)
        end
    end
end)

addEventHandler("onVehicleEnter", root, function(player, seat)
    if allowedVehicles[getElementModel(source)] then
        bindAirhorn(player)
    end
end)

function bindAirhorn(player)
    bindKey(player, "lctrl", "down", playAirhorn, player)
    bindKey(player, "lctrl", "up", stopAirhorn, player)
end

function playAirhorn(player)
    if isPedInVehicle(player) and allowedVehicles[getElementModel(getPedOccupiedVehicle(player))] then
        triggerClientEvent("sarp_sirenC:useAirhorn", player, true)
    end
end

function stopAirhorn(player)
    if isPedInVehicle(player) and allowedVehicles[getElementModel(getPedOccupiedVehicle(player))] then
        triggerClientEvent("sarp_sirenC:useAirhorn", player, false)
    end
end

--[[
function toggleGPSTracker(state)
    local vehicle = getPedOccupiedVehicle(source)
    if exports.sarp_groups:isPlayerInGroup(player, getElementData(vehicle, "vehicle.group")) then
        if vehicle and isElement(vehicle) then
            if state then
                gpsBlips[vehicle] = {}
                gpsBlips[vehicle]["blip"] = createBlip(0, 0, 0)
                gpsBlips[vehicle]["group"] = getElementData(vehicle, "vehicle.group")

                setElementData(gpsBlips[vehicle]["blip"], "blipIcon", "cp")

                attachElements(gpsBlips[vehicle]["blip"], vehicle)
            else
                if isElement(gpsBlips[vehicle]["blip"]) then
                    destroyElement(gpsBlips[vehicle]["blip"])
                    gpsBlips[vehicle] = nil
                end
            end
        end
    end

    for k, v in pairs(getElementsByType("player")) do
        if exports.sarp_groups:isPlayerInGroup(v, getElementData(vehicle, "vehicle.group")) then
            if vehicle and isElement(vehicle) then
                if state then
                    if not gpsBlips[vehicle] then
                        gpsBlips[vehicle] = {}
                        gpsBlips[vehicle]["blip"] = createBlip(0, 0, 0)
                        gpsBlips[vehicle]["group"] = getElementData(vehicle, "vehicle.group")
        
                        setElementData(gpsBlips[vehicle]["blip"], "blipIcon", "cp")
        
                        attachElements(gpsBlips[vehicle]["blip"], vehicle)
                    end
                else
                    if isElement(gpsBlips[vehicle]["blip"]) then
                        destroyElement(gpsBlips[vehicle]["blip"])
                        gpsBlips[vehicle] = nil
                    end
                end
            end
        end
    end
end
addEvent("sarp_sirenS:toggleGPS", true)
addEventHandler("sarp_sirenS:toggleGPS", root, toggleGPSTracker)--]]