local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
            end
        end
    end
)

function registerEvent(eventName, element, ...)
	addEvent(eventName, true)
	addEventHandler(eventName, element, ...)
end

function impoundVehicle(player, vehicle, reason, price, canGet, impoundedDate, expiredDate, impoundedBy)
    local impoundText = reason .. "/" .. price .. "/" .. tostring(canGet) .. "/" .. impoundedDate .. "/" .. expiredDate .. "/" .. impoundedBy
    dbExec(connection, "UPDATE vehicles SET impound = ? WHERE vehicleID = ?", impoundText, getElementData(vehicle, "vehicle.dbID"))
    setElementData(vehicle, "vehicle.impound", impoundText)
    exports.sarp_alert:showAlert(player, "info", "Sikeresen lefoglaltad a járművet")

    for k, v in pairs(getVehicleOccupants(vehicle)) do
        removePedFromVehicle(v)
    end

    setElementDimension(vehicle, 65000)
end
registerEvent("sarp_impoundS:impoundVehicle", root, impoundVehicle)

local spawnPositions = {
    {2243.0205078125, -2016.5523681641, 13.546875, 88},
    {2248.5263671875, -2022.4353027344, 13.546875, 88},
}

function getVehicle(player, vehicle, price)
    --outputChatBox(price .. " " .. tostring(player) .. " " .. tostring(vehicle))
    if exports.sarp_core:takeMoney(player, price) then
        print("Kiváltva")
        removeElementData(vehicle, "vehicle.impound")
        dbExec(connection, "UPDATE vehicles SET impound = NULL WHERE vehicleID = ?", getElementData(vehicle, "vehicle.dbID"))
        local rnd = math.random(1, #spawnPositions)
        setElementPosition(vehicle, spawnPositions[rnd][1], spawnPositions[rnd][2], spawnPositions[rnd][3])
        setElementRotation(vehicle, 0, 0, spawnPositions[rnd][4])
        setElementDimension(vehicle, 0)
        setElementInterior(vehicle, 0)
    else
        print("No")
        exports.sarp_alert:showAlert(player, "error", "Nincs elég pénzed a kiváltáshoz")
    end
end
registerEvent("sarp_impoundS:getVehicle", root, getVehicle)
