--[[

CREATE TABLE `interiors` (
	`interiorId` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`flag` enum('static','dynamic') NOT NULL DEFAULT 'dynamic',
	`ownerId` int(22) NOT NULL DEFAULT '0',
	`price` int(22) NOT NULL DEFAULT '0',
	`type` enum('building','house','garage','rentable','door') NOT NULL DEFAULT 'building',
	`name` varchar(255) NOT NULL,
	`gameInterior` int(22) NOT NULL DEFAULT '1',
	`entrance_position` text NOT NULL,
	`entrance_rotation` text NOT NULL,
	`entrance_interior` int(22) NOT NULL,
	`entrance_dimension` int(22) NOT NULL,
	`exit_position` text NOT NULL,
	`exit_rotation` text NOT NULL,
	`exit_interior` int(22) NOT NULL,
	`exit_dimension` int(22) NOT NULL,
	`locked` enum('Y', 'N') NOT NULL DEFAULT 'N',
	`dummy` enum('Y', 'N') NOT NULL DEFAULT 'N',
	`renewalTime` int(22) DEFAULT '0'
);

]]

local connection = false

local rentTimeDuration = 60 * 60 * 24 * 7 -- 7 nap

local dayTimeDuration = 60 * 60 * 24 -- 24 óra

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		connection = exports.sarp_database:getConnection()

		dbQuery(
			function(qh)
				local result, numAffectedRows = dbPoll(qh, 0)

				if numAffectedRows > 0 then
					for k, v in ipairs(result) do
						loadInterior(v)
					end

					setTimer(processRentedInteriors, 1800000, 0)
				end
			end, connection, "SELECT * FROM interiors"
		)
	end
)

function loadInterior(array)
	local interiorId = array.interiorId

	availableInteriors[interiorId] = array
	availableInteriors[interiorId].interiorId = nil

	if array.renewalTime > 0 and getRealTime().timestamp > array.renewalTime then
		resetInterior(interiorId)
	end
end

exports.sarp_admin:addAdminCommand("setinteriorflag", 9, "Interior jelölésének módosítása (statikus/dinamikus)")
addCommandHandler("setinteriorflag",
	function (thePlayer, commandName, interiorId, flag)
		if getElementData(thePlayer, "acc.adminLevel") >= 9 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. commandName .. " [Interior ID] [< static | dynamic >]", thePlayer, 0, 0, 0, true)
				outputChatBox("#32b3ef>> Interior: #ffffffStatic: #ffff99fix interior (nem törölhető) #ffffff| Dynamic: #ffff99törölhető interior", thePlayer, 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					flag = flag:lower()

					if flag == "static" or flag == "dynamic" then
						if flag == "static" and availableInteriors[interiorId].flag == "static" then
							outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior már statikus!", thePlayer, 0, 0, 0, true)
						elseif flag == "dynamic" and availableInteriors[interiorId].flag == "dynamic" then
							outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior már dinamikus!", thePlayer, 0, 0, 0, true)
						else
							dbQuery(
								function(qh, intiId, newFlag, sourcePlayer)
									dbFree(qh)

									availableInteriors[intiId].flag = newFlag

									if isElement(sourcePlayer) then
										outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior sikeresen megváltoztatva. #ffff99(Új flag: #ffa600" .. newFlag .. "#ffff99)", sourcePlayer, 0, 0, 0, true)
									end
								end, {interiorId, flag, thePlayer}, connection, "UPDATE interiors SET flag = ? WHERE interiorId = ?", flag, interiorId
							)
						end
					else
						outputChatBox("#ff4646>> Interior: #ffff99Az interior jelölés nem megfelelő! #ffa600(static / dynamic)", thePlayer, 0, 0, 0, true)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", thePlayer, 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("requestInteriors", true)
addEventHandler("requestInteriors", getRootElement(),
	function ()
		if isElement(source) then
			triggerClientEvent(source, "requestInteriors", source, availableInteriors)
		end
	end
)

addEvent("createInterior", true)
addEventHandler("createInterior", getRootElement(),
	function (data)
		if isElement(source) then
			local locked = "Y"

			if data.type == "building" or data.type == "door" then
				locked = "N"
			end

			dbQuery(
				function (qh, sourcePlayer)
					local result = dbPoll(qh, 0, true)[2][1][1]

					if result then
						local interiorId = result.interiorId

						dbExec(connection, "UPDATE interiors SET exit_dimension = interiorId WHERE interiorId = ?", interiorId)

						loadInterior(result)

						availableInteriors[interiorId].exit_dimension = interiorId

						triggerClientEvent("createInterior", resourceRoot, interiorId, availableInteriors[interiorId])

						if isElement(sourcePlayer) then
							if result.type == "door" then
								outputChatBox("#cdcdcd>> Interior: #ffff99Átjáró sikeresen létehozva. ID: #ffa600" .. interiorId, sourcePlayer, 0, 0, 0, true)
								outputChatBox("#cdcdcd>> Interior: #ffff99Az ajtó kijáratánák beállításához használd az #ffa600/setinteriorexit #ffff99parancsot.", sourcePlayer, 0, 0, 0, true)
							else
								outputChatBox("#cdcdcd>> Interior: #ffff99Interior sikeresen létrehozva. ID: #ffa600" .. interiorId, sourcePlayer, 0, 0, 0, true)
							end
						end
					end
				end, {source}, connection, "INSERT INTO interiors (price, type, name, gameInterior, entrance_position, entrance_rotation, entrance_interior, entrance_dimension, exit_position, exit_rotation, exit_interior, exit_dimension, locked, dummy) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?); SELECT * FROM interiors ORDER BY interiorId DESC LIMIT 1", data.price, data.type, data.name, data.gameInterior, data.entrance_position, data.entrance_rotation, data.entrance_interior, data.entrance_dimension, data.exit_position, data.exit_rotation, data.exit_interior, data.exit_dimension, locked, data.dummy
			)
		end
	end
)

addEvent("warpPlayer", true)
addEventHandler("warpPlayer", getRootElement(),
	function (interiorId, colShapeType, data, adminWarp)
		if isElement(source) and availableInteriors[interiorId] then
			if availableInteriors[interiorId].locked == "N" or adminWarp then
				local warpedElements = {}
				local sourceVehicle = getPedOccupiedVehicle(source)

				if sourceVehicle then
					local occupants = getVehicleOccupants(sourceVehicle) or {}

					table.insert(warpedElements, sourceVehicle)

					for seat, occupant in pairs(occupants) do
						if isElement(occupant) then
							warpPedIntoVehicle(occupant, sourceVehicle, seat)

							table.insert(warpedElements, occupant)
						end
					end

					setElementVelocity(sourceVehicle, 0, 0, 0)
					setElementAngularVelocity(sourceVehicle, 0, 0, 0)
					setElementFrozen(sourceVehicle, true)
					setElementPosition(sourceVehicle, data.posX, data.posY, data.posZ)
				else
					table.insert(warpedElements, source)
				end

				setTimer(
					function ()
						for k, v in ipairs(warpedElements) do
							if colShapeType == "enter" and data.customInterior then
								setElementData(v, "currentCustomInterior", interiorId)
							else
								setElementData(v, "currentCustomInterior", false)
							end

							if isElement(v) then
								if getElementType(v) == "player" then
									setElementData(v, "player.currentInterior", data.dimension)

									if colShapeType == "enter" and data.customInterior then
										if not sourceVehicle then
											setElementFrozen(v, true)
										else
											setElementFrozen(sourceVehicle, true)
										end

										triggerClientEvent(v, "loadCustomInterior", v, interiorId, sourceVehicle)
									elseif sourceVehicle then
										setElementFrozen(v, false)
									end

									triggerClientEvent(v, "playInteriorSound", v, "interiorenter.wav")
								elseif colShapeType == "exit" or not data.customInterior then
									setElementFrozen(v, false)
								end

								setElementPosition(v, data.posX, data.posY, data.posZ)
								setElementRotation(v, data.rotX, data.rotY, data.rotZ)
								setElementInterior(v, data.interior)
								setElementDimension(v, data.dimension)
								setCameraInterior(v, data.interior)
							end
						end

						warpedElements = nil
					end,
				250, 1)
			else
				exports.sarp_hud:showAlert(source, "error", "Az ingatlan ajtaja zárva van.")
				triggerClientEvent(source, "playInteriorSound", source, "locked.mp3")
			end
		end
	end
)

addEvent("deleteInterior", true)
addEventHandler("deleteInterior", getRootElement(),
	function (interiorId)
		if interiorId and availableInteriors[interiorId] then
			if availableInteriors[interiorId].flag == "dynamic" then
				dbQuery(
					function (qh, sourcePlayer)
						for k, v in ipairs(getElementsByType("player")) do
							if isElement(v) then
								if availableInteriors[interiorId].ownerId == getElementData(v, "char.ID") then
									exports.sarp_inventory:removeItemByData(playerSource, 1, "data1", interiorId)
									break
								end
							end
						end

						availableInteriors[interiorId] = nil

						triggerClientEvent("deleteInterior", resourceRoot, interiorId)

						if isElement(sourcePlayer) then
							outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior sikeresen törölve. #ffff99(" .. interiorId .. ")", sourcePlayer, 0, 0, 0, true)
						end

						dbFree(qh)
					end, {source}, connection, "DELETE FROM interiors WHERE interiorId = ?", interiorId
				)
			else
				outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior egy statikus (fix) interior. A törlése következményekkel járhatnak (előfordulhat, hogy egy resource használja).", source, 0, 0, 0, true)
				outputChatBox("#ff4646>> Adminisztráció: #ffffffAmennyiben mégis törölnéd, bizonyosodj meg róla, hogy a törlés nem jár hibával majd használd a #d75959/setinteriorflag #ffffffparancsot.", source, 0, 0, 0, true)
				outputChatBox("#ff4646>> Adminisztráció: #ffffffAz interior átállítása után a kiválasztott interior törölhető lesz, ugyanakkor lehetséges, hogy a sourceG fájlban is benne van a gyorsabb betöltés érdekében.", source, 0, 0, 0, true)
			end
		end
	end
)

addEvent("resetInterior", true)
addEventHandler("resetInterior", getRootElement(),
	function (interiorId)
		if interiorId and availableInteriors[interiorId] then
			exports.sarp_inventory:removeItemFromCharacter(availableInteriors[interiorId].ownerId, 1, "data1", interiorId)

			resetInterior(interiorId)
			triggerClientEvent("resetInterior", resourceRoot, interiorId)

			if isElement(source) then
				outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior sikeresen visszaállítva. #ffff99(" .. interiorId .. ")", source, 0, 0, 0, true)
			end
		end
	end
)

addEvent("setInteriorName", true)
addEventHandler("setInteriorName", getRootElement(),
	function (interiorId, name)
		if interiorId and availableInteriors[interiorId] and name then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].name = name

					triggerClientEvent("setInteriorName", resourceRoot, interiorId, name)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior sikeresen átnevezve. #ffff99(Új név: #ffa600" .. name .. "#ffff99)", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET name = ? WHERE interiorId = ?", name, interiorId
			)
		end
	end
)

addEvent("setInteriorPrice", true)
addEventHandler("setInteriorPrice", getRootElement(),
	function (interiorId, price)
		if interiorId and availableInteriors[interiorId] and price then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].price = price

					triggerClientEvent("setInteriorPrice", resourceRoot, interiorId, price)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior ára sikeresen módosítva. #ffff99(Új ár: #ffa600" .. formatNumber(price) .. "$#ffff99)", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET price = ? WHERE interiorId = ?", price, interiorId
			)
		end
	end
)

addEvent("setInteriorType", true)
addEventHandler("setInteriorType", getRootElement(),
	function (interiorId, type)
		if interiorId and availableInteriors[interiorId] and type then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].type = type

					triggerClientEvent("setInteriorType", resourceRoot, interiorId, type)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior típusa sikeresen módosítva. #ffff99(" .. interiorId .. ")", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET type = ? WHERE interiorId = ?", type, interiorId
			)
		end
	end
)

addEvent("setInteriorEntrance", true)
addEventHandler("setInteriorEntrance", getRootElement(),
	function (interiorId, data)
		if interiorId and availableInteriors[interiorId] and data then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].entrance_position = data.entrance_position
					availableInteriors[interiorId].entrance_rotation = data.entrance_rotation
					availableInteriors[interiorId].entrance_interior = data.entrance_interior
					availableInteriors[interiorId].entrance_dimension = data.entrance_dimension

					triggerClientEvent("setInteriorEntrance", resourceRoot, interiorId, data)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior bejárata sikeresen áthelyezve.", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET entrance_position = ?, entrance_rotation = ?, entrance_interior = ?, entrance_dimension = ? WHERE interiorId = ?", data.entrance_position, data.entrance_rotation, data.entrance_interior, data.entrance_dimension, interiorId
			)
		end
	end
)

addEvent("setInteriorExit", true)
addEventHandler("setInteriorExit", getRootElement(),
	function (interiorId, data)
		if interiorId and availableInteriors[interiorId] and data then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].exit_position = data.exit_position
					availableInteriors[interiorId].exit_rotation = data.exit_rotation
					availableInteriors[interiorId].exit_interior = data.exit_interior
					availableInteriors[interiorId].exit_dimension = data.exit_dimension
					availableInteriors[interiorId].dummy = "N"

					triggerClientEvent("setInteriorExit", resourceRoot, interiorId, data)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior kijárata sikeresen áthelyezve.", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET exit_position = ?, exit_rotation = ?, exit_interior = ?, exit_dimension = ?, dummy = 'N' WHERE interiorId = ?", data.exit_position, data.exit_rotation, data.exit_interior, data.exit_dimension, interiorId
			)
		end
	end
)

addEvent("setInteriorId", true)
addEventHandler("setInteriorId", getRootElement(),
	function (interiorId, data)
		if interiorId and availableInteriors[interiorId] and data then
			if not data.dummy then
				data.dummy = "N"
			end

			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].exit_position = data.exit_position
					availableInteriors[interiorId].exit_rotation = data.exit_rotation
					availableInteriors[interiorId].exit_interior = data.exit_interior
					availableInteriors[interiorId].exit_dimension = data.exit_dimension
					availableInteriors[interiorId].gameInterior = data.gameInterior
					availableInteriors[interiorId].dummy = data.dummy

					triggerClientEvent("setInteriorExit", resourceRoot, interiorId, data)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior belsője sikeresen módosítva. #ffff99(Új interior: #ffa600" .. data.gameInterior .. "#ffff99)", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET gameInterior = ?, exit_position = ?, exit_rotation = ?, exit_interior = ?, exit_dimension = ?, dummy = ? WHERE interiorId = ?", data.gameInterior, data.exit_position, data.exit_rotation, data.exit_interior, data.exit_dimension, data.dummy, interiorId
			)
		end
	end
)

addEvent("changeInteriorOwner", true)
addEventHandler("changeInteriorOwner", getRootElement(),
	function (interiorId, ownerId)
		if interiorId and ownerId and availableInteriors[interiorId] then
			dbQuery(
				function (qh, sourcePlayer)
					availableInteriors[interiorId].ownerId = ownerId

					triggerClientEvent("changeInteriorOwner", resourceRoot, interiorId, ownerId)

					if isElement(sourcePlayer) then
						outputChatBox("#ff4646>> Adminisztráció: #ffffffA kiválasztott interior tulajdonosa sikeresen módosítva.", sourcePlayer, 0, 0, 0, true)
					end

					dbFree(qh)
				end, {source}, connection, "UPDATE interiors SET ownerId = ? WHERE interiorId = ?", ownerId, interiorId
			)
		end
	end
)

function changeInteriorOwner(interiorId, ownerId)
	interiorId = tonumber(interiorId)
	ownerId = tonumber(ownerId)

	if interiorId and availableInteriors[interiorId] then
		availableInteriors[interiorId].ownerId = ownerId

		return true
	end

	return false
end

addEvent("buyInterior", true)
addEventHandler("buyInterior", getRootElement(),
	function (interiorId)
		if isElement(source) then
			local characterId = getElementData(source, "char.ID")

			if characterId then
				dbQuery(
					function (qh, sourceElement)
						availableInteriors[interiorId].ownerId = characterId

						triggerClientEvent("buyInterior", resourceRoot, interiorId, characterId)

						if isElement(sourceElement) then
							exports.sarp_core:takeMoney(sourceElement, availableInteriors[interiorId].price, "buyInterior")

							exports.sarp_hud:showAlert(sourceElement, "success", "Sikeresen megvásároltad a kiválasztott ingatlant.")

							if not exports.sarp_inventory:hasItemWithData(sourceElement, 1, "data1", interiorId) then
								exports.sarp_inventory:giveItem(sourceElement, 1, 1, interiorId)
							end
						end

						dbFree(qh)
					end, {source}, connection, "UPDATE interiors SET ownerId = ? WHERE interiorId = ?", characterId, interiorId
				)
			end
		end
	end
)

addEvent("rentInterior", true)
addEventHandler("rentInterior", getRootElement(),
	function (interiorId)
		if isElement(source) then
			local characterId = getElementData(source, "char.ID")

			if characterId then
				local canRent = true
				local rentedInterior = false

				for k, v in pairs(availableInteriors) do
					if v.ownerId > 0 and v.renewalTime > 0 then
						if v.ownerId == characterId then
							canRent = false
							rentedInterior = k
							break
						end
					end
				end

				if canRent then
					local renewalTime = getRealTime().timestamp + rentTimeDuration

					dbQuery(
						function (qh, sourceElement)
							availableInteriors[interiorId].ownerId = characterId
							availableInteriors[interiorId].renewalTime = renewalTime

							triggerClientEvent("buyInterior", resourceRoot, interiorId, characterId)

							if isElement(sourceElement) then
								exports.sarp_core:takeMoney(sourceElement, availableInteriors[interiorId].price * 5, "rentInterior")

								exports.sarp_hud:showAlert(sourceElement, "success", "Sikeresen kibérelted a kiválasztott ingatlant.")

								if not exports.sarp_inventory:hasItemWithData(sourceElement, 1, "data1", interiorId, "rent") then
									exports.sarp_inventory:giveItem(sourceElement, 1, 1, interiorId, "rent")
								end
							end

							dbFree(qh)
						end, {source}, connection, "UPDATE interiors SET ownerId = ?, renewalTime = ? WHERE interiorId = ?", characterId, renewalTime, interiorId
					)
				else
					exports.sarp_hud:showAlert(source, "warning", "Már rendelkezel egy kibérelt ingatlannal! (ID: " .. rentedInterior .. ")")
				end
			end
		end
	end
)

addEvent("tryToRenewalRent", true)
addEventHandler("tryToRenewalRent", getRootElement(),
	function (interiorId)
		if isElement(source) then
			local characterId = getElementData(source, "char.ID")

			if characterId then
				local currentTime = getRealTime()

				if availableInteriors[interiorId].renewalTime - dayTimeDuration >= currentTime.timestamp then
					exports.sarp_hud:showAlert(source, "warning", "Még nem tudod megújítani az albérletet. (Maximum 24 órával a lejárta előtt lehet)")
				else
					local renewalTime = currentTime.timestamp + rentTimeDuration

					dbQuery(
						function (qh, sourceElement)
							availableInteriors[interiorId].renewalTime = renewalTime

							if isElement(sourceElement) then
								exports.sarp_core:takeMoney(sourceElement, availableInteriors[interiorId].price, "renewalRent")

								exports.sarp_hud:showAlert(sourceElement, "success", "Sikeresen megújítottad az albérletet.")

								if not exports.sarp_inventory:hasItemWithData(sourceElement, 1, "data1", interiorId, "rent") then
									exports.sarp_inventory:giveItem(sourceElement, 1, 1, interiorId, "rent")
								end
							end

							dbFree(qh)
						end, {source}, connection, "UPDATE interiors SET renewalTime = ? WHERE interiorId = ?", renewalTime, characterId
					)
				end
			end
		end
	end
)

addEvent("unRentInterior", true)
addEventHandler("unRentInterior", getRootElement(),
	function (interiorId)
		if isElement(source) then
			local characterId = getElementData(source, "char.ID")

			if characterId then
				exports.sarp_inventory:removeItemFromCharacter(availableInteriors[interiorId].ownerId, 1, "data1", interiorId)
				exports.sarp_core:giveMoney(source, availableInteriors[interiorId].price * 4)

				resetInterior(interiorId)
				triggerClientEvent("resetInterior", resourceRoot, interiorId)

				exports.sarp_hud:showAlert(source, "success", "Sikeresen felmondtad az ingatlan bérlését!")
			end
		end
	end
)

addEvent("lockInterior", true)
addEventHandler("lockInterior", getRootElement(),
	function (interiorId)
		if isElement(source) then
			local characterId = getElementData(source, "char.ID")

			if characterId and availableInteriors[interiorId] then
				local havePermission = false

				if availableInteriors[interiorId].type == "building" and availableInteriors[interiorId].ownerId == characterId then
					havePermission = true
				elseif exports.sarp_inventory:hasItemWithData(source, 1, "data1", interiorId) then
					havePermission = true
				elseif (getElementData(source, "acc.adminLevel") or 0) >= 3 and getElementData(source, "adminDuty") then
					havePermission = true
				end

				if havePermission then
					local locked = availableInteriors[interiorId].locked

					if locked == "N" then
						locked = "Y"
					else
						locked = "N"
					end

					availableInteriors[interiorId].locked = locked

					dbExec(connection, "UPDATE interiors SET locked = ? WHERE interiorId = ?", locked, interiorId)

					if locked == "N" then
						exports.sarp_hud:showAlert(source, "info", "Sikeresen kinyitottad az ingatlan ajtaját.")
					else
						exports.sarp_hud:showAlert(source, "info", "Sikeresen bezártad az ingatlan ajtaját.")
					end

					triggerClientEvent("lockInterior", resourceRoot, interiorId, availableInteriors[interiorId].locked)
					triggerClientEvent(source, "playInteriorSound", source, "openclose.mp3")
				else
					exports.sarp_hud:showAlert(source, "error", "Nincs kulcsod ehhez az ingatlanhoz.")
				end
			end
		end
	end
)

function resetInterior(interiorId)
	if availableInteriors[interiorId] then
		dbExec(connection, "UPDATE interiors SET ownerId = '0', renewalTime = '0' WHERE interiorId = ?; DELETE FROM items WHERE itemId = '1' AND data1 = ? AND ownerId = ?", interiorId, interiorId, availableInteriors[interiorId].ownerId)

		availableInteriors[interiorId].ownerId = 0
		availableInteriors[interiorId].renewalTime = 0
		availableInteriors[interiorId].locked = "Y"

		if availableInteriors[interiorId].type == "building" or availableInteriors[interiorId].type == "door" then
			availableInteriors[interiorId].locked = "N"
		end
	end
end

function processRentedInteriors()
	local currentTime = getRealTime().timestamp

	for k, v in pairs(availableInteriors) do
		if v.ownerId > 0 and v.renewalTime > 0 then
			local playerSource = false

			for k2, v2 in ipairs(getElementsByType("player")) do
				if isElement(v2) then
					if v.ownerId == getElementData(v2, "char.ID") then
						playerSource = v2
						break
					end
				end
			end

			if currentTime >= v.renewalTime then
				resetInterior(k)

				triggerClientEvent("resetInterior", resourceRoot, k)

				if isElement(playerSource) then
					exports.sarp_hud:showAlert(playerSource, "error", "Albérlet", "Nem fizetted ki az albérleted, ezért lejárt!")

					exports.sarp_inventory:removeItemFromCharacter(v.ownerId, 1, "data1", k)
				end
			elseif v.renewalTime - dayTimeDuration <= currentTime then
				if isElement(playerSource) then
					local remaining = math.floor((v.renewalTime - currentTime) % dayTimeDuration / 3600) + 1

					exports.sarp_hud:showAlert(playerSource, "warning", "Hamarosan lejár az albérleted, részletek a chatboxban!")

					outputChatBox("#ffa600>> Albérlet: #ffff99Hamarosan lejár az albérleted! (Még #ff4646kb. " .. remaining .. " óra#ffff99)", playerSource, 0, 0, 0, true)

					outputChatBox("#ffa600>> Albérlet: #ffff99Menj az ingatlanhoz, és írd be a #ffa600/rent#ffff99 parancsot, hogy meghosszabítsd, vagy mondd le az albérletet a #ff4646/unrent#ffff99 paranccsal. (InteriorID: #ffa600" .. k .. "#ffff99)", playerSource, 0, 0, 0, true)			
				end
			end
		end
	end
end

function requestInteriors(player)
	if isElement(player) then
		local characterId = getElementData(player, "char.ID")

		if characterId then
			local interiors = {}
			
			for k,v in pairs(availableInteriors) do
				if v.ownerId == characterId then
					table.insert(interiors, {interiorId = k, data = v})
				end
			end
			
			return interiors
		end
	end
	
	return false
end

addEvent("useDoorKnocking", true)
addEventHandler("useDoorKnocking", getRootElement(),
	function (interiorId)
		if isElement(source) and availableInteriors[interiorId] then
			triggerClientEvent("playKnocking", source, interiorId)
		end
	end
)

addEvent("useDoorBell", true)
addEventHandler("useDoorBell", getRootElement(),
	function (interiorId)
		if isElement(source) and availableInteriors[interiorId] then
			triggerClientEvent("playBell", source, interiorId)
		end
	end
)