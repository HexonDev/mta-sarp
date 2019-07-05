--[[

CREATE TABLE `vehicles` (
	`vehicleID` INT(22) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`owner` INT(22) NOT NULL DEFAULT '0',
	`model` INT(3) NOT NULL DEFAULT '400',
	`groupID` INT(3) NOT NULL DEFAULT '0',
	`position` TEXT,
	`parkedPosition` TEXT,
	`health` INT(4) NOT NULL DEFAULT '1000',
	`fuel` INT(4) NOT NULL DEFAULT '50',
	`maxFuel` INT(4) NOT NULL DEFAULT '50',
	`engine` INT(1) NOT NULL DEFAULT '0',
	`light` INT(1) NOT NULL DEFAULT '0',
	`locked` INT(1) NOT NULL DEFAULT '0',
	`handBrake` INT(1) NOT NULL DEFAULT '0',
	`color` TEXT,
	`headLightColor` TEXT,
	`wheels` VARCHAR(7) NULL,
	`panels` VARCHAR(13) NULL,
	`doors` VARCHAR(11) NULL,
	`tunings` TEXT,
	`distance` INT(11) NOT NULL DEFAULT '0',
	`lastOilChange` INT(5) NOT NULL DEFAULT '0',
	`licensePlate` VARCHAR(8) NULL,
	`unit` VARCHAR(200) NULL,
	`impound` TEXT,
	`sirenPanel` INT(1) NOT NULL DEFAULT '0',
	`paintjobId` INT(3) NOT NULL DEFAULT '0',
	`theTicket` TEXT,
	`wheelClamp` ENUM('N', 'Y') NOT NULL DEFAULT 'N'
) DEFAULT CHARSET=utf8_hungarian_ci;

]]

local connection = false

local vehiclesCache = {}
local loadedVehicles = {}
local explodedVehicles = {}

addEventHandler("onElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if dataName == "vehicle.wheelClamp" then
			if getElementData(source, dataName) then
				setElementFrozen(source, true)
			elseif oldValue then
				setElementFrozen(source, false)
			end
		end
	end)

exports.sarp_admin:addAdminCommand("deletevehicles", 9, "Összes jármű törlése")
addCommandHandler("deletevehicles",
	function (player, cmd, state)
		if getElementData(player, "acc.adminLevel") >= 9 then
			if not state then
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Biztos vagy benne, hogy törlöd az összes járművet? Ha igen, használd az #ffa600/" .. cmd .. " yes #ffffffparancsot.", player, 0, 0, 0, true)
			elseif state == "yes" then
				deleteVehicles("all")

				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az összes jármű sikeresen törölve.", player, 0, 0, 0, true)
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setvehgroup", 6, "Jármű frakcióba tétele/kivétele")
addCommandHandler("setvehgroup",
	function (player, cmd, vehId, groupId)
		if getElementData(player, "acc.adminLevel") >= 6 then
			if not tonumber(vehId) or not tonumber(groupId) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Jármű ID] [Csoport ID]", player, 0, 0, 0, true)
			else
				vehId = tonumber(vehId)
				groupId = tonumber(groupId)

				if loadedVehicles[vehId] then
					local groups = exports.sarp_groups:getGroups()

					if groups[groupId] or groupId == 0 then
						dbQuery(
							function (qh)
								setElementData(loadedVehicles[vehId], "vehicle.group", groupId)

								if isElement(player) then
									if groupId == 0 then
										outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott jármű sikeresen eltávolítva a kiválasztott frakcióból.", player, 0, 0, 0, true)
									else
										outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott jármű sikeresen hozzáadva a kiválasztott frakcióhoz. #ffff99(" .. groups[groupId].name .. ")", player, 0, 0, 0, true)
									end
								end

								dbFree(qh)
							end, connection, "UPDATE vehicles SET groupID = ? WHERE vehicleID = ?", groupId, vehId
						)
					else
						outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott frakció nem létezik!", player, 0, 0, 0, true)
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott jármű nem létezik vagy nincs lespawnolva!", player, 0, 0, 0, true)
				end
			end
		end
	end
)

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_inventory" then
			for k, v in pairs(loadedVehicles) do
				exports.sarp_inventory:loadItems(v, k)
			end
		elseif startedResource == getThisResource() then
			connection = exports.sarp_database:getConnection()

			loadGroupVehicles()

			for k, v in ipairs(getElementsByType("player")) do
				if getElementData(v, "loggedIn") then
					local characterId = getElementData(v, "char.ID") or 0

					if characterId > 0 then
						loadPlayerVehicles(characterId, v)
					end
				end
			end

			setTimer(processExplodedVehicles, 5000, 0)
		end
	end
)

addEventHandler("onResourceStop", getResourceRootElement(),
	function (stoppedResource)
		saveAllVehicles()
	end
)

addEvent("loadPlayerVehicles", true)
addEventHandler("loadPlayerVehicles", getRootElement(),
	function (charID)
		loadPlayerVehicles(charID, source)
	end
)

function loadGroupVehicles()
	dbQuery(
		function (qh)
			local result, rows = dbPoll(qh, 0)

			if rows > 0 then
				for _, row in pairs(result) do
					loadVehicle(row)
				end
			end
		end, connection, "SELECT * FROM vehicles WHERE groupID > 0"
	)
end

function loadPlayerVehicles(charID, playerElement)
	if not charID then
		return
	end

	charID = tonumber(charID)

	dbQuery(
		function (qh, charID, sourcePlayer)
			if isElement(sourcePlayer) then
				local result, rows = dbPoll(qh, 0)

				if rows > 0 then
					local impoundVehicles = {}

					vehiclesCache[charID] = {}

					for _, row in pairs(result) do
						if row.impound and utfLen(row.impound) > 0 and row.impound ~= "NULL" then
							local data = split(row.impound, "/")

							if tonumber(data[4]) ~= tonumber(data[5]) and tonumber(data[5]) > getRealTime().timestamp then
								row.impound = ""

								dbExec(connection, "UPDATE vehicles SET impound = '' WHERE vehicleID = ?", row.vehicleID)
							else
								table.insert(impoundVehicles, row)
							end
						end

						table.insert(vehiclesCache[charID], row.vehicleID)

						loadVehicle(row)
					end

					if #impoundVehicles > 0 and isElement(sourcePlayer) then
						outputChatBox(exports.sarp_core:getServerTag("info") .. "Neked #ffff99" .. #impoundVehicles .. "#ffffff db lefoglalt járműved van.", sourcePlayer, 0, 0, 0, true)

						for i = 1, #impoundVehicles do
							local vehData = impoundVehicles[i]

							outputChatBox(" - Rendszám: #ffff99" .. vehData.licensePlate .. "#ffffff, Típus: #ffff99" .. exports.sarp_mods_veh:getVehicleNameFromModel(vehData.model), sourcePlayer, 255, 255, 255, true)
						end

						outputChatBox(exports.sarp_core:getServerTag("info") .. "További információkért látogasson el a kapitányságunkra.", sourcePlayer, 0, 0, 0, true)
					end
				end
			else
				dbFree(qh)
			end
		end, {charID, playerElement}, connection, "SELECT * FROM vehicles WHERE owner = ? AND groupID = '0'", charID
	)
end

function loadVehicle(data)
	if data then
		local vehicleID = data.vehicleID

		if isElement(loadedVehicles[vehicleID]) then
			return
		end

		local licensePlate = data.licensePlate
		if not licensePlate or utfLen(licensePlate) <= 0 then
			licensePlate = processLicensePlate(vehicleID)

			dbExec(connection, "UPDATE vehicles SET licensePlate = ? WHERE vehicleID = ?", licensePlate, vehicleID)
		end

		local position = fromJSON(data.position)
		local vehicle = createVehicle(data.model, position[1], position[2], position[3], position[4], position[5], position[6], licensePlate, false)

		if vehicle then
			triggerClientEvent("vehicleSpawnProtect", vehicle, vehicle)

			setVehicleRespawnPosition(vehicle, position[1], position[2], position[3], position[4], position[5], position[6])
			setElementData(vehicle, "vehicle.parkedPosition", position)

			print("Load vehicle [" .. vehicleID .. "] for characterId: " .. data.owner)

			setElementData(vehicle, "vehicle.dbID", vehicleID)
			setElementData(vehicle, "vehicle.owner", data.owner)
			setElementData(vehicle, "vehicle.group", data.groupID)

			setElementData(vehicle, "vehicle.engine", data.engine == 1)
			setElementData(vehicle, "vehicle.locked", data.locked == 1)
			setElementData(vehicle, "vehicle.light", data.light == 1)
			setElementData(vehicle, "vehicle.handBrake", data.handBrake == 1)

			setVehicleEngineState(vehicle, data.engine == 1)
			setVehicleLocked(vehicle, data.locked == 1)
			setVehicleOverrideLights(vehicle, data.light == 1 and 2 or 1)
			setElementFrozen(vehicle, data.handBrake == 1)

			setVehiclePlateText(vehicle, licensePlate)

			if data.doors and utf8.len(data.doors) > 0 then
				local doors = split(data.doors, "/")

				for i = 1, #doors do
					setVehicleDoorState(vehicle, i - 1, tonumber(doors[i]))
				end
			end

			if data.panels and utf8.len(data.panels) > 0 then
				local panels = split(data.panels, "/")

				for i = 1, #panels do
					setVehiclePanelState(vehicle, i - 1, tonumber(panels[i]))
				end
			end

			if data.wheels and utf8.len(data.wheels) > 0 then
				local wheels = split(data.wheels, "/")

				setVehicleWheelStates(vehicle, tonumber(wheels[1]), tonumber(wheels[2]), tonumber(wheels[3]), tonumber(wheels[4]))
			end

			if data.headLightColor then
				setVehicleHeadLightColor(vehicle, unpack(fromJSON(data.headLightColor)))
			end

			setVehicleFuelTankExplodable(vehicle, false)
			setVehicleColor(vehicle, unpack(fromJSON(data.color)))
			setElementHealth(vehicle, data.health or 1000)
			setElementInterior(vehicle, position[7])

			if data.impound and utfLen(data.impound) > 0 and data.impound ~= "NULL" then
				setElementData(vehicle, "vehicle.impound", data.impound)
				setElementData(vehicle, "vehicle.engine", false)

				setVehicleEngineState(vehicle, false)
				setElementDimension(vehicle, 6500)
			else
				setElementDimension(vehicle, position[8])
			end

			setElementData(vehicle, "vehicle.fuel", data.fuel or 0)
			setElementData(vehicle, "vehicle.distance", data.distance or 0)
			setElementData(vehicle, "lastOilChange", data.lastOilChange or 0)

			if data.unit and string.len(data.unit) > 0 then
				setElementData(vehicle, "siren.unit", data.unit)
			end

			if data.sirenPanel and data.sirenPanel == 1 then
				setElementData(vehicle, "vehicle.sirenPanel", true)
			end

			setElementData(vehicle, "siren.status", 1)
			setElementData(vehicle, "vehicle.paintjob", data.paintjobId or 0)

			if data.theTicket and utfLen(data.theTicket) > 10 and data.owner > 0 then
				local json_data = fromJSON(data.theTicket)
				
				if json_data and type(json_data) == "table" then
					local currentTime = getRealTime().timestamp
					local elapsedTime = json_data.elapsedTime or 0

					json_data.autoPayOut = currentTime + 172800 - elapsedTime

					data.theTicket = toJSON(json_data)
				end

				setElementData(vehicle, "vehicleTicket", data.theTicket)
			end

			setElementData(vehicle, "vehicle.wheelClamp", data.wheelClamp == "Y")

			if data.wheelClamp == "Y" then
				setElementFrozen(vehicle, true)
			end

			exports.sarp_inventory:loadItems(vehicle, vehicleID)

			loadedVehicles[vehicleID] = vehicle
		end
	end
end

function saveAllVehicles()
	for k, v in pairs(loadedVehicles) do
		saveVehicle(v)
	end
end

function getLoadedVehicles()
	return loadedVehicles
end

function saveVehicle(vehicle)
	if not isElement(vehicle) then
		return
	end

	local vehicleID = getElementData(vehicle, "vehicle.dbID") or 0

	if vehicleID > 0 then
		do
			local x, y, z = getElementPosition(vehicle)
			local rx, ry, rz = getElementRotation(vehicle)
			local model = getElementModel(vehicle)

			local doors = {}
			for i = 0, 5 do
				table.insert(doors, getVehicleDoorState(vehicle, i))
			end

			local panels = {}
			for i = 0, 6 do
				table.insert(panels, getVehiclePanelState(vehicle, i))
			end

			local frontLeft, rearLeft, frontRight, rearRight = getVehicleWheelStates(vehicle)
			local ticketData = getElementData(vehicle, "vehicleTicket")

			if ticketData then
				local json_data = fromJSON(ticketData)

				if json_data and type(json_data) == "table" then
					json_data.elapsedTime = json_data.autoPayOut - getRealTime().timestamp

					ticketData = toJSON(ticketData)
				else
					ticketData = ""
				end
			else
				ticketData = ""
			end

			local haveWheelClamp = getElementData(vehicle, "vehicle.wheelClamp") and "Y" or "N"

			local datas = {
				position = toJSON({x, y, z, rx, ry, rz, getElementInterior(vehicle), getElementDimension(vehicle)}),
				engine = getElementData(vehicle, "vehicle.engine") and 1 or 0,
				locked = getElementData(vehicle, "vehicle.locked") and 1 or 0,
				light = getElementData(vehicle, "vehicle.light") and 1 or 0,
				handBrake = getElementData(vehicle, "vehicle.handBrake") and 1 or 0,
				fuel = getElementData(vehicle, "vehicle.fuel") or 0,
				maxFuel = getElementData(vehicle, "vehicle.maxFuel") or exports.sarp_hud:getTheFuelTankSizeOfVehicle(model),
				distance = getElementData(vehicle, "vehicle.distance") or 0,
				lastOilChange = getElementData(vehicle, "lastOilChange") or 0,
				doors = table.concat(doors, "/"),
				panels = table.concat(panels, "/"),
				wheels = frontLeft .. "/" .. rearLeft .. "/" .. frontRight .. "/" .. rearRight,
				color = toJSON({getVehicleColor(vehicle, true)}),
				headLightColor = toJSON({getVehicleHeadLightColor(vehicle)}),
				health = math.max(320, math.min(getElementHealth(vehicle), 1000)),
				groupID = getElementData(vehicle, "vehicle.group") or 0,
				unit = getElementData(vehicle, "siren.unit") or "",
				sirenPanel = getElementData(vehicle, "vehicle.sirenPanel") and 1 or 0,
				paintjobId = getElementData(vehicle, "vehicle.paintjob") or 0,
				theTicket = ticketData,
				wheelClamp = haveWheelClamp
			}

			local columns = {}
			local columnValues = {}

			for k,v in pairs(datas) do
				table.insert(columns, k .. " = ?")
				table.insert(columnValues, v)
			end
			table.insert(columnValues, vehicleID)

			dbExec(connection, "UPDATE vehicles SET " .. table.concat(columns, ", ") .. " WHERE vehicleID = ?", unpack(columnValues))
		end
	end
end

function makeVehicle(model, owner, group, position, r, g, b)
	if not (model and isElement(owner)) then
		return
	end

	local charID = getElementData(owner, "char.ID") or 0

	group = group or 0

	if group < 0 then
		group = 0
	end

	if model < 400 or model > 611 then
		model = 400
	end

	r = r or 255
	g = g or 255
	b = b or 255

	position = position or {}

	for i = 1, 8 do
		position[i] = position[i] or 0
	end

	position = toJSON(position)

	local fuelCapacity = exports.sarp_hud:getTheFuelTankSizeOfVehicle(model)

	dbExec(connection, "INSERT INTO vehicles (model, owner, groupID, position, parkedPosition, color, health, fuel, maxFuel, unit, handBrake) VALUES(?,?,?,?,?,?,?,?,?,?,?)", model, charID, group, position, position, toJSON({r, g, b}), 1000, fuelCapacity, fuelCapacity, "", 0)
	dbQuery(
		function (qh, targetPlayer)
			local result, rows = dbPoll(qh, 0)[1]

			if result then
				loadVehicle(result)

				if isElement(targetPlayer) then
					exports.sarp_inventory:giveItem(targetPlayer, 2, 1, result.vehicleID)
				end
			end
		end, {owner}, connection, "SELECT * FROM vehicles WHERE vehicleID = LAST_INSERT_ID()"
	)
end

function deleteGroupVehicles(groupID)
	if not groupID then
		return
	end

	groupID = tonumber(groupID)

	local removableVehicles = {}

	for vehicleID, vehicleElement in pairs(loadedVehicles) do
		if getElementData(vehicleElement, "vehicle.group") == groupID then
			table.insert(removableVehicles, vehicleID)
		end
	end

	deleteVehicles(removableVehicles)
end

function deleteVehicles(vehicleIds)
	if vehicleIds == "all" then
		dbExec(connection, "TRUNCATE TABLE vehicles; DELETE FROM items WHERE itemId = '2'")

		for k, v in ipairs(getElementsByType("player")) do
			if getElementData(v, "char.ID") then
				exports.sarp_inventory:removeAllItem(v, "itemId", 2)
			end
		end

		for k, v in pairs(loadedVehicles) do
			if isElement(loadedVehicles[k]) then
				destroyElement(loadedVehicles[k])
			end
		end

		loadedVehicles = {}
	else
		if not vehicleIds or type(vehicleIds) ~= "table" then
			return
		end

		if #vehicleIds > 0 then
			for i = 1, #vehicleIds do
				local vehicleID = vehicleIds[i]

				if loadedVehicles[vehicleID] then
					local ownerID = getElementData(loadedVehicles[vehicleID], "vehicle.owner")

					if ownerID and vehiclesCache[ownerID] then
						table.remove(vehiclesCache[ownerID], vehicleID)

						for k, v in ipairs(getElementsByType("player")) do
							if getElementData(v, "char.ID") == ownerID then
								exports.sarp_inventory:removeItemByData(v, 2, "data1", vehicleID)
							end
						end
					end

					if isElement(loadedVehicles[vehicleID]) then
						destroyElement(loadedVehicles[vehicleID])
					end

					loadedVehicles[vehicleID] = nil
				end
			end

			dbExec(connection, "DELETE FROM vehicles WHERE vehicleID IN (" .. table.concat(vehicleIds, ",") .. "); DELETE FROM items WHERE ownerId IN (" .. table.concat(vehicleIds, ",") .. ") AND ownerType = 'vehicle'")
		end
	end
end

function deleteVehicle(vehicleID)
	if not vehicleID then
		return
	end

	vehicleID = tonumber(vehicleID)

	if loadedVehicles[vehicleID] then
		local ownerID = getElementData(loadedVehicles[vehicleID], "vehicle.owner")

		if ownerID and vehiclesCache[ownerID] then
			table.remove(vehiclesCache[ownerID], vehicleID)

			for k, v in ipairs(getElementsByType("player")) do
				if getElementData(v, "loggedIn") and getElementData(v, "char.ID") == ownerID then
					exports.sarp_inventory:removeItemByData(v, 2, "data1", vehicleID)
				end
			end
		end

		if isElement(loadedVehicles[vehicleID]) then
			destroyElement(loadedVehicles[vehicleID])
		end

		loadedVehicles[vehicleID] = nil
	end

	dbExec(connection, "DELETE FROM items WHERE ownerId = ? AND ownerType = 'vehicle'; DELETE FROM vehicles WHERE vehicleID = ?", vehicleID, vehicleID)
end

function unloadPlayerVehicles(charID)
	if not charID then
		return
	end

	charID = tonumber(charID)

	if vehiclesCache[charID] then
		for _, vehicleID in pairs(vehiclesCache[charID]) do
			if loadedVehicles[vehicleID] then
				saveVehicle(loadedVehicles[vehicleID])

				if isElement(loadedVehicles[vehicleID]) then
					destroyElement(loadedVehicles[vehicleID])
				end

				loadedVehicles[vehicleID] = nil
			end
		end
	end
end

addEventHandler("onPlayerQuit", getRootElement(),
	function ()
		local characterId = getElementData(source, "char.ID") or 0

		if characterId > 0 then
			unloadPlayerVehicles(characterId)
		end
	end
)

addEventHandler("onElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if dataName == "loggedIn" then
			if oldValue then
				local characterId = getElementData(source, "char.ID") or 0

				if characterId > 0 then
					unloadPlayerVehicles(characterId)
				end
			end
		end
	end
)

addEvent("updateVehicle", true)
addEventHandler("updateVehicle", getRootElement(),
	function (vehicleElement, dbID, saveToDatabase, fuel, distance, kilometersToChangeOil)
		if isElement(vehicleElement) then
			fuel = tonumber(fuel)
			distance = tonumber(distance)
			kilometersToChangeOil = tonumber(kilometersToChangeOil)

			setElementData(vehicleElement, "vehicle.fuel", fuel)
			setElementData(vehicleElement, "vehicle.distance", distance)
			setElementData(vehicleElement, "lastOilChange", kilometersToChangeOil)

			if saveToDatabase then
				saveVehicle(loadedVehicles[dbID])
			end
		end
	end
)

addEvent("ranOutOfFuel", true)
addEventHandler("ranOutOfFuel", getRootElement(),
	function (vehicleElement)
		if isElement(vehicleElement) then
			setElementData(vehicleElement, "vehicle.fuel", 0)
			setElementData(vehicleElement, "vehicle.engine", false)
			setVehicleEngineState(vehicleElement, false)
		end
	end
)

addEvent("setVehicleHealthSync", true)
addEventHandler("setVehicleHealthSync", getRootElement(),
	function (vehicleElement, health)
		if isElement(vehicleElement) then
			setVehicleDamageProof(source, false) 
			setElementHealth(vehicleElement, health)
		end
	end
)

addEventHandler("onVehicleEnter", getRootElement(),
	function ()
		if getVehicleType(source) ~= "BMX" then
			setVehicleEngineState(source, getElementData(source, "vehicle.engine"))
			setVehicleDamageProof(source, false) 
		end

		if getVehicleType(source) == "BMX" or getVehicleType(source) == "Bike" or getVehicleType(source) == "Boat" then
			setElementData(source, "vehicle.windowState", true)
		end
	end
)

addEventHandler("onVehicleStartExit", getRootElement(),
	function (player)
		if getElementData(player, "player.seatBelt") then
			cancelEvent()
			exports.sarp_hud:showAlert(player, "error", "Előbb csatold ki a biztonsági öved!")
		elseif getVehicleType(source) ~= "Bike" and getVehicleType(source) ~= "BMX" and getVehicleType(source) ~= "Boat" then
			if getElementData(source, "vehicle.locked") then
				cancelEvent()
				exports.sarp_hud:showAlert(player, "error", "Nem szállhatsz ki amíg az ajtók zárva vannak!")
			elseif getElementData(player, "player.Cuffed") then
				cancelEvent()
				exports.sarp_hud:showAlert(player, "error", "Nem szállhatsz ki amíg bilincs van a kezeden!")
			end
		end
	end
)

addEventHandler("onVehicleExplode", getRootElement(),
	function ()
		table.insert(explodedVehicles, source)
	end
)

function processExplodedVehicles()
	if #explodedVehicles > 0 then
		for i = 1, #explodedVehicles do
			local vehicle = explodedVehicles[i]

			if isElement(vehicle) then
				fixVehicle(vehicle)
				respawnVehicle(vehicle)
				setVehicleDamageProof(vehicle, false)
				setElementData(vehicle, "vehicle.engine", false)

				local parkedPosition = getElementData(vehicle, "vehicle.parkedPosition") or {}
				if #parkedPosition > 0 then
					setElementInterior(vehicle, parkedPosition[7] or 0)
					setElementDimension(vehicle, parkedPosition[8] or 0)
				end
			end
		end

		explodedVehicles = {}
	end
end

addEventHandler("onVehicleDamage", getRootElement(),
	function (loss)
		local health = getElementHealth(source)

		if health < 320 or (health - loss) < 320 then
			setElementHealth(source, 320)
			setVehicleDamageProof(source, true) 
			setElementData(source, "vehicle.engine", false)
			setVehicleEngineState(source, false)

			local theDriver = getVehicleController(source)
			if isElement(theDriver) then
				exports.sarp_hud:showAlert(theDriver, "error", "Lerobbant a járműved!")
			end
		else
			setVehicleDamageProof(source, false) 
		end
	end
)

addEvent("toggleVehicleLock", true)
addEventHandler("toggleVehicleLock", getRootElement(),
	function (vehicle, players, task)
		if isElement(source) then
			if isElement(vehicle) then
				local vehicleID = tonumber(getElementData(vehicle, "vehicle.dbID")) or -65535

				if not (exports.sarp_inventory:hasItemWithData(source, 2, "data1", vehicleID) or getElementData(source, "adminDuty")) then
					exports.sarp_hud:showAlert(source, "error", "Nincs kulcsod ehhez a járműhöz!")
					return
				end

				if getElementData(vehicle, "vehicle.locked") then
					setElementData(vehicle, "vehicle.locked", false)
					setVehicleLocked(vehicle, false)

					if getVehicleOccupant(vehicle) == source and not task[1] then
						exports.sarp_chat:sendLocalMeAction(source, "kinyit belülről egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú járművet.")
						triggerClientEvent(getVehicleOccupants(vehicle), "playVehicleSound", vehicle, "simple", ":sarp_assets/audio/vehicles/lockin.ogg")
						return
					end

					triggerClientEvent(players, "onVehicleLockEffect", vehicle)
					exports.sarp_chat:sendLocalMeAction(source, "kinyit egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú járművet.")
				else
					setElementData(vehicle, "vehicle.locked", true)
					setVehicleLocked(vehicle, true)

					if getVehicleOccupant(vehicle) == source and not task[1] then
						exports.sarp_chat:sendLocalMeAction(source, "bezár belülről egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú járművet.")
						triggerClientEvent(getVehicleOccupants(vehicle), "playVehicleSound", vehicle, "simple", ":sarp_assets/audio/vehicles/lockin.ogg")
						return
					end

					triggerClientEvent(players, "onVehicleLockEffect", vehicle)
					exports.sarp_chat:sendLocalMeAction(source, "bezár egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú járművet.")
				end

				triggerClientEvent(players, "playVehicleSound", vehicle, "3d", ":sarp_assets/audio/vehicles/lockout.ogg")
			end
		end
	end
)

addEvent("syncVehicleSound", true)
addEventHandler("syncVehicleSound", getRootElement(),
	function (typ, path, players)
		if isElement(source) then
			if typ and path then
				triggerClientEvent(players, "playVehicleSound", source, typ, path)
			end
		end
	end
)

addEvent("toggleVehicleEngine", true)
addEventHandler("toggleVehicleEngine", getRootElement(),
	function (vehicle, toggle)
		if isElement(source) then
			if isElement(vehicle) then
				local vehicleID = tonumber(getElementData(vehicle, "vehicle.dbID")) or -65535

				if not (exports.sarp_inventory:hasItemWithData(source, 2, "data1", vehicleID) or not getElementData(vehicle, "vehicle.job") ~= 0 or getElementData(source, "adminDuty")) then
					exports.sarp_hud:showAlert(source, "error", "Nincs kulcsod ehhez a járműhöz!")
					return
				end

				local sarp_mods_veh = getResourceFromName("sarp_mods_veh")
				local vehicleNames = sarp_mods_veh and getResourceState(sarp_mods_veh) == "running"

				if toggle then
					if getElementHealth(vehicle) <= 320 then
						exports.sarp_hud:showAlert(source, "error", "A jármű motorja túlságosan sérült.")
						exports.sarp_chat:sendLocalMeAction(source, "megpróbálja beindítani a jármű motorját, de nem sikerül neki.")
						return
					elseif getElementData(vehicle, "vehicle.fuel") <= 0 then
						exports.sarp_hud:showAlert(source, "error", "A járműből kifogyott az üzemanyag.")
						exports.sarp_chat:sendLocalMeAction(source, "megpróbálja beindítani a jármű motorját, de nem sikerül neki.")
						return
					elseif getElementData(vehicle, "vehicle.impound") then
						exports.sarp_hud:showAlert(source, "error", "Ez a jármű le van foglalva, ezért nem tudod beindítani!")
						return
					end

					if vehicleNames then
						exports.sarp_chat:sendLocalMeAction(source, "beindítja egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú jármű motorját.")
					else
						exports.sarp_chat:sendLocalMeAction(source, "beindítja egy jármű motorját.")
					end

					setVehicleEngineState(vehicle, toggle)
					setElementData(vehicle, "vehicle.engine", toggle)
				else
					if vehicleNames then
						exports.sarp_chat:sendLocalMeAction(source, "leállítja egy " .. exports.sarp_mods_veh:getVehicleName(vehicle) .. " típusú jármű motorját.")
					else
						exports.sarp_chat:sendLocalMeAction(source, "leállítja egy jármű motorját.")
					end

					setVehicleEngineState(vehicle, toggle)
					setElementData(vehicle, "vehicle.engine", toggle)
				end
			end
		end
	end
)

addEvent("toggleVehicleLights", true)
addEventHandler("toggleVehicleLights", getRootElement(),
	function (vehicle)
		if getElementData(vehicle, "vehicle.light") then
			setVehicleOverrideLights(vehicle, 1)
			setElementData(vehicle, "vehicle.light", false)
			exports.sarp_chat:sendLocalMeAction(source, "lekapcsolja a jármű lámpáit.")
		else
			setVehicleOverrideLights(vehicle, 2)
			setElementData(vehicle, "vehicle.light", true)
			exports.sarp_chat:sendLocalMeAction(source, "felkapcsolja a jármű lámpáit.")
		end

		triggerClientEvent(getVehicleOccupants(vehicle), "playVehicleSound", vehicle, "simple", ":sarp_assets/audio/vehicles/lightswitch.ogg")
	end
)

addEvent("playVehicleSound", true)
addEventHandler("playVehicleSound", getRootElement(),
	function (sendTo, sourceElement, ...)
		sendTo = sendTo or getRootElement()

		triggerClientEvent(sendTo, "playVehicleSound", sourceElement, ...)
	end
)

addCommandHandler("park",
	function (player)
		local vehicle = getPedOccupiedVehicle(player)

		if not isElement(vehicle) then
			exports.sarp_hud:showAlert(player, "error", "Nem ülsz járműben!")
			return
		end

		local vehicleID = tonumber(getElementData(vehicle, "vehicle.dbID")) or -65535

		if not (exports.sarp_inventory:hasItemWithData(player, 2, "data1", vehicleID) or getElementData(player, "adminDuty")) then
			exports.sarp_hud:showAlert(player, "error", "Nincs kulcsod ehhez a járműhöz!")
			return
		end

		local x, y, z = getElementPosition(vehicle)
		local rx, ry, rz = getElementRotation(vehicle)
		local interior = getElementInterior(vehicle)
		local dimension = getElementDimension(vehicle)
		local currentPosition = {x, y, z, rx, ry, rz, interior, dimension}

		if dbExec(connection, "UPDATE vehicles SET parkedPosition = ? WHERE vehicleID = ? ", toJSON(currentPosition), vehicleID) then
			setVehicleRespawnPosition(vehicle, x, y, z, rx, ry, rz)
			setElementData(vehicle, "vehicle.parkedPosition", currentPosition)
			exports.sarp_hud:showAlert(player, "success", "Járműved sikeresen leparkolva.")
		end
	end
)

addEvent("onVehicleHandbrakeStateChange", true)
addEventHandler("onVehicleHandbrakeStateChange", getRootElement(),
	function (state, normalBrakeMode)
		if isElement(source) then
			if state then
				if not normalBrakeMode then
					setElementFrozen(source, true)
				end

				setElementData(source, "vehicle.handBrake", true)
			else
				setElementFrozen(source, false)
				setElementData(source, "vehicle.handBrake", false)
			end
		end
	end
)

function getPlayerVehiclesCount(charID)
	if not charID then
		return 0
	end

	charID = tonumber(charID)
	local count = 0

	if vehiclesCache[charID] then
		for _, vehicleID in pairs(vehiclesCache[charID]) do
			if loadedVehicles[vehicleID] then
				count = count + 1
			end
		end
	end

	return count
end