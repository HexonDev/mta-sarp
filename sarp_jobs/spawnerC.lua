
local vehiclePickMarker = nil
local vehiclePickBlip = nil
local vehicleTimer = nil
local destroyTime = 5

addEventHandler("onClientMarkerHit", root, function(player)
    if player == localPlayer then
        if isElement(vehiclePickMarker) then
            if source == vehiclePickMarker then
                local veh = getPedOccupiedVehicle(localPlayer)
                if veh and getElementData(veh, "vehicle.job") == getElementData(vehiclePickMarker, "spawnerJobID") then
                    triggerServerEvent("sarp_jobsS:destroyJobVehicle", localPlayer)
                else
                    local vehID = getElementData(vehiclePickMarker, "spawnerVeh")
                    local vehColor = getElementData(vehiclePickMarker, "spawnerVehColor")
                    local jobID = getElementData(vehiclePickMarker, "spawnerJobID")
                    triggerServerEvent("sarp_jobsS:spawnJobVehicle", localPlayer, jobID, vehID, vehColor)
                end
            end
        end
    end
end)

function createVehiclePoint(jobID, x, y, z, vehID, vehColor, deleteTime)
    if jobID and x and y and z and vehColor then
        vehiclePickMarker = createMarker(x, y, z, "checkpoint", 3, 50, 179, 239, 120)
        setElementData(vehiclePickMarker, "spawnerVeh", vehID)
        setElementData(vehiclePickMarker, "spawnerVehColor", vehColor)
        setElementData(vehiclePickMarker, "spawnerJobID", jobID)

        vehiclePickBlip = createBlip(x, y, z)
        setElementData(vehiclePickBlip, "blipIcon", "cp")
        setElementData(vehiclePickBlip, "blipTooltipText", "Munka jármű felvétel/leadás")
        setElementData(vehiclePickBlip, "blipColor", tocolor(50, 179, 239))
        destroyTime = deleteTime or 5
    end
end

function destroyVehiclePoint()
    if isElement(vehiclePickMarker) then
        destroyElement(vehiclePickMarker)
    end

    if isElement(vehiclePickBlip) then
        destroyElement(vehiclePickBlip)
    end

end

addEventHandler("onClientVehicleStartEnter", root, function(player, seat)
    if player == localPlayer then 
        if getElementData(source, "vehicle.job") and getElementData(source, "vehicle.job") > 0 and player ~= getElementData(source, "vehicle.ownerJob") then
            if seat == 0 then
                exports.sarp_hud:showAlert("error", "Ez nem a te munka járműved")
                cancelEvent()
            end
        end
    end
end)

addEventHandler("onClientVehicleExit", getRootElement(), function(player, seat)
    if player == localPlayer then
        if player == getElementData(source, "vehicle.ownerJob") and getElementData(source, "vehicle.job") > 0 then
            exports.sarp_hud:showAlert("info", "A munka járműved törlődni fog.", "Ha nem szálsz vissza a járművedbe, akkor " .. destroyTime .. " perc után törlődik")
            vehicleTimer = setTimer(function()
                triggerServerEvent("sarp_jobsS:destroyJobVehicle", localPlayer)
                exports.sarp_hud:showAlert("info", "A munka járműved törlődött")
            end, destroyTime * 60 * 1000, 1)
        end
    end
end)

addEventHandler("onClientVehicleEnter", getRootElement(), function(player, seat)
    if player == localPlayer then
        if player == getElementData(source, "vehicle.ownerJob") and getElementData(source, "vehicle.job") > 0 then
            if isTimer(vehicleTimer) then
                killTimer(vehicleTimer)
            end
        end
    end
end)

addEventHandler("onClientElementDataChange", getRootElement(), function(dataName, oldValue)
	if source == localPlayer then
        if dataName == "char.Job" then
            if oldValue > 0 then
			    triggerServerEvent("sarp_jobsS:destroyJobVehicle", localPlayer)
                --exports.sarp_hud:showAlert("info", "A munka járműved törlődött", "Mivel a munka viszonyod megszűnt, vagy megváltozott, ezért a járműved törlődött")
            end
		end
	end
end)