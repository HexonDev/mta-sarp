local fuelPrices = {}

local connection = false

local bannedVehicles = {}

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			local sarp_database = getResourceFromName("sarp_database")

			if sarp_database and getResourceState(sarp_database) == "running" then
				connection = exports.sarp_database:getConnection()
			end

			--[[
			if connection then
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						for k, v in pairs(result) do
							local splt = split(v.canUseFuelStations, "/")

							bannedVehicles[v.vehicleID] = {tonumber(splt[1]), tonumber(splt[2])}
						end
					end, connection, "SELECT vehicleID, canUseFuelStations FROM vehicles WHERE canUseFuelStations <> 'Y'"
				)
			end
			]]

			math.randomseed(getTickCount() + math.random(getTickCount()))

			for k, v in pairs(availableStations) do
				v.syncColShape.element = createColSphere(unpack(v.syncColShape.details))

				if isElement(v.syncColShape.element) then
					setElementData(v.syncColShape.element, "syncStationId", k)
				end
			end

			generatePrices()
			setTimer(generatePrices, 600000, 0)
		end
	end
)

function generatePrices()
	fuelPrices = {}

	for k, v in pairs(availableStations) do
		fuelPrices[k] = {
			math.random(3, 10), -- dízel
			math.random(2, 7) -- benzin
		}
	end

	setElementData(resourceRoot, "fuelPrices", fuelPrices)
end

addEvent("payFuel", true)
addEventHandler("payFuel", getRootElement(),
	function (stationId, positionId, amountPrice)
		if isElement(source) and stationId and positionId and amountPrice then
			local currentMoney = getElementData(source, "char.Money") or 0
			local afterMoney = currentMoney - amountPrice

			if afterMoney >= 0 then
				setElementData(source, "char.Money", afterMoney)

				triggerClientEvent(source, "payFuel", source, true)

				setElementData(resourceRoot, "fuelStation_" .. stationId .. "_" .. positionId, false)
				
				triggerClientEvent("resetFuelStation", resourceRoot, stationId, positionId)
			else
				triggerClientEvent(source, "payFuel", source, false)
			end
		end
	end
)

addEvent("reportFuelStealing", true)
addEventHandler("reportFuelStealing", getRootElement(),
	function (vehicleElement, fuelAmount, amountPrice)
		if isElement(source) then
			local vehicleID = getElementData(vehicleElement, "vehicle.dbID")

			if vehicleID then
				if not bannedVehicles[vehicleID] then
					bannedVehicles[vehicleID] = {fuelAmount, amountPrice}
				else
					bannedVehicles[vehicleID][1] = bannedVehicles[vehicleID][1] + fuelAmount
					bannedVehicles[vehicleID][2] = bannedVehicles[vehicleID][2] + amountPrice
				end

				--dbExec(connection, "UPDATE vehicles SET canUseFuelStations = ? WHERE vehicleID = ?", bannedVehicles[vehicleID][1] .. "/" .. bannedVehicles[vehicleID][2], vehicleID)
			end
		end
	end
)

addEvent("requestPumpPistol", true)
addEventHandler("requestPumpPistol", getRootElement(),
	function (stationId, positionId, fuelType)
		if isElement(source) and stationId and positionId and fuelType then
			setElementData(source, "fuelStation", {stationId, positionId})
			setElementData(source, "pistolHolder", {stationId, positionId, fuelType})
		end
	end
)

addEvent("resetPumpPistol", true)
addEventHandler("resetPumpPistol", getRootElement(),
	function (stationId, positionId, fuelType)
		if isElement(source) then
			setElementData(source, "pistolHolder", false)

			triggerClientEvent("resetFuelStation", resourceRoot, stationId, positionId)
		end
	end
)

addEvent("startFuelingProcess", true)
addEventHandler("startFuelingProcess", getRootElement(),
	function (stationId)
		if isElement(source) then
			local players = getElementsWithinColShape(availableStations[stationId].syncColShape.element, "player")
			
			triggerClientEvent(players, "startFuelingProcess", source, station)
		end
	end
)

addEvent("doFuelingProcess", true)
addEventHandler("doFuelingProcess", getRootElement(),
	function (startFill, stationId, positionId, vehicleElement, endFill)
		if isElement(source) then
			local players = getElementsWithinColShape(availableStations[stationId].syncColShape.element, "player")

			triggerClientEvent(players, "doFuelingProcess", source, startFill, stationId, positionId, vehicleElement, endFill)
		end
	end
)