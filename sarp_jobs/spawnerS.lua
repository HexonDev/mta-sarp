function registerEvent(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

local spawnedJobVehicles = {}

registerEvent("sarp_jobsS:spawnJobVehicle", root, function(jobID, vehID, vehColor)
    if getPedOccupiedVehicle(source) then
        return 
    end

    if spawnedJobVehicles[source] and isElement(spawnedJobVehicles[source]) then
        exports.sarp_hud:showAlert(source, "error", "Már van egy lehívott munka járműved")
        return 
    end

    local x, y, z = getElementPosition(source)
    local rx, ry, rz = getElementRotation(source)

    spawnedJobVehicles[source] = createVehicle(vehID, x, y, z, rx, ry, rz)

    setVehicleColor(spawnedJobVehicles[source], vehColor[1], vehColor[2], vehColor[3])

    setElementData(spawnedJobVehicles[source], "vehicle.light", false)
    setVehicleOverrideLights(spawnedJobVehicles[source], 1)

    setElementData(spawnedJobVehicles[source], "vehicle.engine", false)
    setVehicleEngineState(spawnedJobVehicles[source], false)

    setElementData(spawnedJobVehicles[source], "vehicle.fuel", 100)
    setElementData(spawnedJobVehicles[source], "vehicle.ownerJob", source)
    setElementData(spawnedJobVehicles[source], "vehicle.job", jobID)
    setVehicleFuelTankExplodable(spawnedJobVehicles[source], false)
    setElementHealth(spawnedJobVehicles[source], 1000)
    setVehiclePlateText(spawnedJobVehicles[source], "SARP-" .. getElementData(source, "char.ID"))
    warpPedIntoVehicle(source, spawnedJobVehicles[source])

    triggerClientEvent("vehicleSpawnProtect", source, spawnedJobVehicles[source])
end)

registerEvent("sarp_jobsS:destroyJobVehicle", root, function()
    if spawnedJobVehicles[source] and isElement(spawnedJobVehicles[source]) then
        destroyElement(spawnedJobVehicles[source])
    end
end)

addEventHandler("onPlayerQuit", root, function()
    triggerEvent("sarp_jobsS:destroyJobVehicle", source)
end)
