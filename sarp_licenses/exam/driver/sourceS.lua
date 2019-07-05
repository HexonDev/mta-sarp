local spawnPos = {
    {995.94732666016, -1438.3024902344, 13.546875, 180},
    {982.38635253906, -1438.1578369141, 13.546875, 180},
    {998.33581542969, -1457.1022949219, 13.546875, 0},
    {1005.2133789063, -1456.8875732422, 13.546875, 0},
    {1013.080078125, -1456.9223632813, 13.546875, 0},
}

local testVehicles = {}
local vehID = 426

function registerEvent(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

function createTestVehicle(player)
    local random = math.random(1, #spawnPos) 
    local x, y, z, r = spawnPos[random][1], spawnPos[random][2], spawnPos[random][3], spawnPos[random][4]
    testVehicles[player] = createVehicle(vehID, x, y, z, 0, 0, r)

    setVehicleColor(testVehicles[player], 54, 81, 94)

    setElementData(testVehicles[player], "vehicle.light", false)
    setVehicleOverrideLights(testVehicles[player], 1)

    setElementData(testVehicles[player], "vehicle.engine", false)
    setVehicleEngineState(testVehicles[player], false)

    setElementData(testVehicles[player], "vehicle.fuel", 100)
    setElementData(testVehicles[player], "vehicle.test", true)
    setElementData(testVehicles[player], "vehicle.testOwner", player)
    setVehicleFuelTankExplodable(testVehicles[player], false)
    setElementHealth(testVehicles[player], 1000)
    setVehiclePlateText(testVehicles[player], "SARP-" .. getElementData(source, "char.ID")) 
    warpPedIntoVehicle(player, testVehicles[player])

    triggerClientEvent("vehicleSpawnProtect", source, testVehicles[player])
end
registerEvent("sarp_licenesesS:createTestVehicle", root, createTestVehicle)

function destroyTestVehicle(player)
    if isElement(testVehicles[player]) then
        destroyElement(testVehicles[player])
    end
end
registerEvent("sarp_licenesesS:destroyTestVehicle", root, destroyTestVehicle)