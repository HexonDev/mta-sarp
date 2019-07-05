--[[

CREATE TABLE `items` (
	`dbID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`itemId` INT(3) NOT NULL,
	`slot` INT(11) NOT NULL DEFAULT '0',
	`amount` INT(10) NOT NULL DEFAULT '1',
	`data1` TEXT NULL,
	`data2` TEXT NULL,
	`data3` TEXT NULL
	`ownerType` VARCHAR(8) NOT NULL,
	`ownerId` INT(11) NOT NULL,
) ENGINE=MyISAM;

CREATE TABLE `trashes` (
	`trashID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`x` FLOAT NOT NULL,
	`y` FLOAT NOT NULL,
	`z` FLOAT NOT NULL,
	`rotation` FLOAT NOT NULL,
	`interior` INT(3) NOT NULL,
	`dimension` INT(5) NOT NULL
) ENGINE=InnoDB;

]]

local connection = exports.sarp_database:getConnection()

local itemsTable = {}
local inventoryInUse = {}
local perishableTimer = false

local playerAttachments = {}
local storedTrashes = {}

-- bírság
addEvent("ticketPerishableEvent2", true)
addEventHandler("ticketPerishableEvent2", getRootElement(),
	function(itemId)
		if isElement(source) and itemsTable[source] then
			local theItem = false

			for k, v in pairs(itemsTable[source]) do
				if v.dbID == itemId then
					theItem = v
					break
				end
			end

			if theItem then
				dbQuery(
					function(qh, sourcePlayer)
						dbFree(qh)

						if isElement(sourcePlayer) then
							local json_data = fromJSON(theItem.data1)

							if json_data then
								local fineAmount = tonumber(json_data.fine)

								exports.sarp_core:takeMoneyEx(sourcePlayer, fineAmount * 10, "autoticket")

								exports.sarp_hud:showInfobox(sourcePlayer, "error", "Nem fizetted be a bírságot ezért a tízszeresét azaz " .. fineAmount * 10 .. " $-t vontunk le.")
							end

							itemsTable[sourcePlayer][theItem.slot] = nil

							triggerItemEvent(sourcePlayer, "deleteItem", "player", {theItem.dbID})
						end
					end, {source}, connection, "DELETE FROM items WHERE dbID = ?", theItem.dbID
				)
			end
		end
	end)

-- parkolási bírság
addEvent("ticketPerishableEvent", true)
addEventHandler("ticketPerishableEvent", getRootElement(),
	function(itemId)
		if isElement(source) and itemsTable[source] then
			local theItem = false

			for k, v in pairs(itemsTable[source]) do
				if v.dbID == itemId then
					theItem = v
					break
				end
			end

			if theItem then
				dbQuery(
					function(qh, sourcePlayer)
						dbFree(qh)

						if isElement(sourcePlayer) then
							local json_data = fromJSON(theItem.data1)

							if json_data then
								local fineAmount = tonumber(json_data.fine)

								exports.sarp_core:takeMoneyEx(sourcePlayer, fineAmount * 10, "autoticket")

								exports.sarp_hud:showInfobox(sourcePlayer, "error", "Nem fizetted be a parkolási bírságot ezért a tízszeresét azaz " .. fineAmount * 10 .. " $-t vontunk le.")
							end

							itemsTable[sourcePlayer][theItem.slot] = nil

							triggerItemEvent(sourcePlayer, "deleteItem", "player", {theItem.dbID})
						end
					end, {source}, connection, "DELETE FROM items WHERE dbID = ?", theItem.dbID
				)
			end
		end
	end)

addEvent("requestVehicleTicket", true)
addEventHandler("requestVehicleTicket", getRootElement(),
	function(theVehicle, data)
		if isElement(source) then
			if data then
				local vehicleId = getElementData(theVehicle, "vehicle.dbID") or 0

				if vehicleId > 0 then
					dbQuery(
						function(qh, sourcePlayer)
							dbFree(qh)

							setElementData(theVehicle, "vehicleTicket", false)

							if isElement(sourcePlayer) then
								local currentTime = getRealTime().timestamp
								local elapsedMinute = (data.autoPayOut - currentTime) / 60

								addItem(sourcePlayer, 118, 1, false, toJSON(data), false, math.floor(perishableItems[118] - elapsedMinute))
							end
						end, {source}, connection, "UPDATE vehicles SET theTicket = '' WHERE vehicleID = ?", vehicleId
					)
				end
			end
		end
	end)

function processVehicleTickets()
	local currentTime = getRealTime().timestamp
	local vehicles = getElementsByType("vehicle")
	local notify = {}

	for k = 1, #vehicles do
		local v = vehicles[k]

		if v then	
			local theTicket = getElementData(v, "vehicleTicket")

			if theTicket then
				local json_data = fromJSON(theTicket)
				local vehicleOwnerId = getElementData(v, "vehicle.owner") or 0

				if json_data and type(json_data) == "table" and vehicleOwnerId > 0 then
					local vehicleOwnerSource = exports.sarp_accounts:getPlayerFromCharacterID(vehicleOwnerId)

					if isElement(vehicleOwnerSource) then
						if currentTime >= (json_data.autoPayOut or 0) then
							local fineAmount = tonumber(json_data.fine)

							exports.sarp_core:takeMoneyEx(vehicleOwnerSource, fineAmount * 10, "autoticket")

							exports.sarp_hud:showInfobox(vehicleOwnerSource, "error", "Nem fizetted be a parkolási bírságot ezért a tízszeresét azaz " .. fineAmount * 10 .. " $-t vontunk le.")
						
							setElementData(v, "vehicleTicket", false)

							local vehicleId = getElementData(v, "vehicle.dbID") or 0

							if vehicleId > 0 then
								dbExec(connection, "UPDATE vehicles SET theTicket = '' WHERE vehicleID = ?", vehicleId)
							end
						else
							if not notify[vehicleOwnerSource] then
								notify[vehicleOwnerSource] = {}
							end

							table.insert(notify[vehicleOwnerSource], json_data)
						end
					end
				end
			end
		end
	end

	local players = getElementsByType("player")

	for k = 1, #players do
		local v = players[k]

		if v and notify[v] then
			outputChatBox("#d75959<< FIGYELMEZTETÉS >> #ffffffTájékoztatjuk, hogy önnek #d75959" .. #notify[v] .. " db #ffffffintézetlen csekkje van az alábbi járművein:", v, 0, 0, 0, true)

			for k2, v2 in ipairs(notify[v]) do
				local remaining = math.floor((v2.autoPayOut - currentTime) % 172800 / 3600) + 1

				outputChatBox(" - Rendszám: #d75959" .. v2.numberplate .. " #ffffff| Lejáratig hátralévő idő: #d75959kb. " .. remaining .. " #ffffffóra.", v, 255, 255, 255, true)
			end
		end
	end
end

addEvent("ticketTheVehicle", true)
addEventHandler("ticketTheVehicle", getRootElement(),
	function(theVehicle, data)
		if isElement(source) then
			if isElement(theVehicle) and data then
				local vehicleId = getElementData(theVehicle, "vehicle.dbID") or 0

				if vehicleId > 0 then
					local vehicleOwnerId = getElementData(theVehicle, "vehicle.owner") or 0

					if vehicleOwnerId > 0 then
						data.autoPayOut = getRealTime().timestamp + 172800 -- (60 * 60 * 48) = 48 óra
						data = toJSON(data)

						dbQuery(
							function(qh, sourcePlayer)
								dbFree(qh)

								setElementData(theVehicle, "vehicleTicket", data)

								if isElement(sourcePlayer) then

								end
							end, {source}, connection, "UPDATE vehicles SET theTicket = ? WHERE vehicleID = ?", data, vehicleId
						)
					else
						exports.sarp_hud:showInfobox(source, "e", "Erre a járműre nem állíthatsz ki csekket!")
					end
				else
					exports.sarp_hud:showInfobox(source, "e", "Erre a járműre nem állíthatsz ki csekket!")
				end
			end
		end
	end)

addEventHandler("onResourceStart", getRootElement(),
	function(startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			local sarp_database = getResourceFromName("sarp_database")

			if sarp_database and getResourceState(sarp_database) == "running" then
				connection = exports.sarp_database:getConnection()
			end

			for k, v in ipairs(getElementsByType("player")) do
				takeAllWeapons(v)
			end

			dbQuery(loadTrashes, connection, "SELECT * FROM trashes")

			if isTimer(perishableTimer) then
				killTimer(perishableTimer)
			end

			perishableTimer = setTimer(processPerishableItems, 60000, 0)

			setTimer(processVehicleTickets, 1800000, 0)
		end
	end)

function processPerishableItems()
	for k, v in pairs(itemsTable) do
		if isElement(k) then
			if getElementType(k) == "vehicle" or getElementType(k) == "object" then
				for k2, v2 in pairs(itemsTable[k]) do
					if perishableItems[v2.itemId] then
						local perishableAmount = (tonumber(v2.data3) or 0) + 1

						if perishableAmount - 1 > perishableItems[v2.itemId] then
							triggerEvent("updateItemData3", k, k, v2.dbID, perishableItems[v2.itemId], true)
						end

						if perishableAmount <= perishableItems[v2.itemId] then
							triggerEvent("updateItemData3", k, k, v2.dbID, perishableAmount, true)
						elseif perishableEvent[v2.itemId] then
							triggerEvent(perishableEvent[v2.itemId], k, v2.dbID)
						end
					end
				end
			end
		else
			itemsTable[k] = nil
		end
	end
end

addCommandHandler("reloadmyweapon",
	function(sourcePlayer, commandName)
		reloadPedWeapon(sourcePlayer)
	end)

addEvent("requestTrashes", true)
addEventHandler("requestTrashes", getRootElement(),
	function()
		if isElement(source) then
			triggerClientEvent(source, "receiveTrashes", source, storedTrashes)
		end
	end)

function loadTrashes(qh)
	local result = dbPoll(qh, 0)

	if result then
		for k, v in pairs(result) do
			loadTrash(v)
		end
	end
end

function loadTrash(data)
	local objectElement = createObject(1359, data.x, data.y, data.z - 0.3, 0, 0, data.rotation)

	if isElement(objectElement) then
		local trashId = data.trashID

		setElementInterior(objectElement, data.interior)
		setElementDimension(objectElement, data.dimension)

		storedTrashes[trashId] = {}
		storedTrashes[trashId].trashId = trashId
		storedTrashes[trashId].objectElement = objectElement
		storedTrashes[trashId].interior = data.interior
		storedTrashes[trashId].dimension = data.dimension

		return true
	end

	return false
end

exports.sarp_admin:addAdminCommand("createtrash", 6, "Szemetes létrehozása")
addCommandHandler("createtrash",
	function(localPlayer)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
			local playerInterior = getElementInterior(localPlayer)
			local playerDimension = getElementDimension(localPlayer)

			dbQuery(
				function (qh, sourcePlayer)
					local result = dbPoll(qh, 0, true)[2][1][1]

					if result then
						if loadTrash(result) then
							triggerClientEvent("createTrash", resourceRoot, result.trashID, result)

							if isElement(sourcePlayer) then
								outputChatBox(exports.sarp_core:getServerTag("info") .. "Szemetes sikeresen létrehozva. ID: #acd373" .. result.trashID, sourcePlayer, 255, 255, 255, true)
							end
						end
					end
				end, {localPlayer}, connection, "INSERT INTO trashes (x, y, z, rotation, interior, dimension) VALUES (?,?,?,?,?,?); SELECT * FROM trashes ORDER BY trashID DESC LIMIT 1", playerPosX, playerPosY, playerPosZ, playerRotZ, playerInterior, playerDimension
			)
		end
	end)

exports.sarp_admin:addAdminCommand("deletetrash", 6, "Szemetes törlése")
addCommandHandler("deletetrash",
	function(localPlayer, cmd, trashId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not trashId then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Szemetes Azonosító]", localPlayer, 255, 255, 255, true)
			else
				trashId = tonumber(trashId)

				if trashId and storedTrashes[trashId] then
					triggerClientEvent("destroyTrash", localPlayer, trashId)

					destroyElement(storedTrashes[trashId].objectElement)

					storedTrashes[trashId] = nil

					dbExec(connection, "DELETE FROM trashes WHERE trashID = ?", trashId)

					outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott szemetes sikeresen törölve.", localPlayer, 255, 255, 255, true)
				else
					outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott szemetes nem létezik.", localPlayer, 255, 255, 255, true)
				end
			end
		end
	end)

addEvent("showTheItem", true)
addEventHandler("showTheItem", getRootElement(),
	function(item, players)
		if isElement(source) and item then
			triggerClientEvent(players, "showTheItem", source, item)
		end
	end)

function friskCommand(localPlayer, command, target)
	if getElementData(localPlayer, "loggedIn") then
		if not target then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Játékos név / ID]", localPlayer, 255, 255, 255, true)
		else
			local targetPlayer = exports.sarp_core:findPlayer(localPlayer, target)

			if targetPlayer and getElementData(targetPlayer, "loggedIn") then
				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local playerInterior = getElementInterior(localPlayer)
				local playerDimension = getElementDimension(localPlayer)

				local targetPosX, targetPosY, targetPosZ = getElementPosition(targetPlayer)
				local targetInterior = getElementInterior(targetPlayer)
				local targetDimension = getElementDimension(targetPlayer)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ) <= 3 and playerInterior == targetInterior and playerDimension == targetDimension then
					local playerName = getElementData(targetPlayer, "visibleName"):gsub("_", " ")
					local charMoney = getElementData(targetPlayer, "char.Money") or 0

					triggerClientEvent(localPlayer, "bodySearchGetDatas", localPlayer, itemsTable[targetPlayer] or {}, playerName, charMoney)

					exports.sarp_chat:sendLocalMeAction(localPlayer, "megmotozott valakit. ((" .. playerName .. "))")
				end
			end
		end
	end
end
addCommandHandler("motozas", friskCommand)
addCommandHandler("motozás", friskCommand)
addCommandHandler("motoz", friskCommand)
addCommandHandler("frisk", friskCommand)

addEvent("friskPlayer", true)
addEventHandler("friskPlayer", getRootElement(),
	function(targetPlayer)
		if isElement(source) and isElement(targetPlayer) then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(source)
			local playerInterior = getElementInterior(source)
			local playerDimension = getElementDimension(source)

			local targetPosX, targetPosY, targetPosZ = getElementPosition(targetPlayer)
			local targetInterior = getElementInterior(targetPlayer)
			local targetDimension = getElementDimension(targetPlayer)

			if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ) <= 3 and playerInterior == targetInterior and playerDimension == targetDimension then
				local playerName = getElementData(targetPlayer, "visibleName"):gsub("_", " ")
				local charMoney = getElementData(targetPlayer, "char.Money") or 0

				triggerClientEvent(source, "bodySearchGetDatas", source, itemsTable[targetPlayer] or {}, playerName, charMoney)

				exports.sarp_chat:sendLocalMeAction(source, "megmotozott valakit. ((" .. playerName .. "))")
			end
		end
	end)

addEventHandler("onPlayerQuit", getRootElement(),
	function()
		if itemsTable[source] then
			itemsTable[source] = nil
		end

		if isElement(playerAttachments[source]) then
			destroyElement(playerAttachments[source])
			playerAttachments[source] = nil
		end
	end)

addEventHandler("onElementDestroy", getRootElement(),
	function()
		if itemsTable[source] then
			itemsTable[source] = nil
		end

		if isElement(playerAttachments[source]) then
			destroyElement(playerAttachments[source])
			playerAttachments[source] = nil
		end
	end)

addEvent("takeWeapon", true)
addEventHandler("takeWeapon", getRootElement(),
	function()
		if isElement(source) then
			takeAllWeapons(source)
		end
	end)

addEvent("giveWeapon", true)
addEventHandler("giveWeapon", getRootElement(),
	function(itemId, weaponId, ammo)
		if isElement(source) then
			takeAllWeapons(source)

			giveWeapon(source, weaponId, ammo, true)

			reloadPedWeapon(source)
		end
	end)

addEventHandler("onElementDataChange", getRootElement(),
	function(dataName, oldValue)
		if dataName == "canUseMegaphone" then
			if getElementData(source, dataName) then
				local playerInterior = getElementInterior(source)
				local playerDimension = getElementDimension(source)

				if isElement(playerAttachments[source]) then
					destroyElement(playerAttachments[source])
				end

				local obj = createObject(3090, 0, 0, 0)
						
				if isElement(obj) then
					setElementInterior(obj, playerInterior)
					setElementDimension(obj, playerDimension)
					setElementCollisionsEnabled(obj, false)
					setElementDoubleSided(obj, true)

					exports.sarp_boneattach:attachElementToBone(obj, source, 12, 0.05, 0, 0.05, 0, 0, 0)

					playerAttachments[source] = obj
				end
			elseif oldValue then
				if isElement(playerAttachments[source]) then
					destroyElement(playerAttachments[source])
				end

				playerAttachments[source] = nil
			end
		end
	end)

local availableObjectAttachments = {
	[1] = {
		model = 2703,
		pos = {12, 0, 0.0375, 0, 0, -90, 0}
	},
	[2] = {
		model = 2769,
		pos = {12, 0, 0.0375, 0.0375, 0, -180, 0}
	},
	[3] = {
		model = 1546,
		pos = {11, 0, 0.0375, 0.0375, -90, 0, -90}
	},
	[4] = {
		model = 1544,
		pos = {11, 0, 0.0375, 0.0375, -90, 0, -90},
		scale = 0.5
	},
	[5] = {
		model = 1509,
		pos = {11, 0, 0.0375, 0.0375, -90, 0, -90}
	},
	[6] = {
		model = 1485,
		pos = {11, -0.075, 0, 0.05, 0, 0, 0}
	}
}

addEvent("useItem", true)
addEventHandler("useItem", getRootElement(),
	function(dbID, use)
		if isElement(source) and dbID then
			local item = false

			for k, v in pairs(itemsTable[source]) do
				if v.dbID == dbID then
					item = v
					break
				end
			end

			if item then
				local playerInterior = getElementInterior(source)
				local playerDimension = getElementDimension(source)
				local itemId = item.itemId

				if itemId == 71 then -- telefon
					if use then
						if not item.data1 or not tonumber(item.data1) then
							local x, y, z = getElementPosition(source)
							local city = getZoneName(x, y, z, true)
							local prenum = "202"

							if city == "San Fierro" then
								city = "203"
							else
								city = "20" .. math.random(4, 9)
							end

							itemsTable[source][item.slot].data1 = tonumber(prenum .. math.random(1000000, 9999999)) -- telefonszám
							itemsTable[source][item.slot].data2 = "-" -- adatok / üzenetek / hívásnapló stb
							itemsTable[source][item.slot].data3 = 0	-- egyenleg

							dbExec(connection, "UPDATE items SET data1 = ?, data2 = '-', data3 = '0' WHERE dbID = ?", itemsTable[source][item.slot].data1, item.dbID)

							triggerClientEvent(source, "updateItemData1", source, "player", item.dbID, itemsTable[source][item.slot].data1)
						end

						triggerClientEvent(source, "openPhone", source, item.dbID, tonumber(item.data1), item.data2, item.data3)
					else
						triggerClientEvent(source, "openPhone", source, false)
					end
				elseif itemId == 122 then -- kötszer
					if (getElementData(source, "bloodLevel") or 100) < 100 then
						if not getElementData(source, "usingBandage") then
							setElementData(source, "usingBandage", true)

							triggerEvent("takeItem", source, source, "dbID", item.dbID, 1)

							exports.sarp_hud:showAlert(source, "info", "Sikeresen felraktál egy kötést, ezzel lassítva a vérzést.")
						else
							exports.sarp_hud:showAlert(source, "error", "Már van fent egy kötés!")
						end
					else
						exports.sarp_hud:showAlert(source, "error", "Nem vérzel!")
					end
				elseif itemId == 86 then -- jelvény
					if use then
						setElementData(source, "badgeData", tostring(item.data1) .. " - " .. tostring(item.data2))

						exports.sarp_chat:sendLocalMeAction(source, "felrakja a jelvényét.")
					else
						setElementData(source, "badgeData", false)

						exports.sarp_chat:sendLocalMeAction(source, "leveszi a jelvényét.")
					end
				elseif itemId == 106 then -- Vitamin
					local health = getElementHealth(source)

					if health + 25 >= 100 then
						health = 100
					end

					setElementHealth(source, health)
				elseif itemId == 105 then -- Gyógyszer
					local health = getElementHealth(source)

					if health + 45 >= 100 then
						health = 100
					end

					setElementHealth(source, health)
				elseif isSpecialItem(itemId) then
					if isElement(playerAttachments[source]) then
						destroyElement(playerAttachments[source])
					end

					local animationTime = 0

					if isFoodItem(itemId) then
						animationTime = 3000
						setPedAnimation(source, "food", "eat_burger", animationTime, false, false, false, false)
					elseif isDrinkItem(itemId) then
						animationTime = 1375
						setPedAnimation(source, "VENDING", "VEND_Drink2_P", animationTime, false, false, false, false)
					elseif itemId == 97 or itemId == 98 then
						animationTime = 5000
						setPedAnimation(source, "smoking", "m_smkstnd_loop", animationTime, false, false, false, false)
					end

					setTimer(
						function (player)
							if isElement(player) then
								setPedAnimation(player, false)

								if isElement(playerAttachments[player]) then
									destroyElement(playerAttachments[player])
								end
							end
						end,
					animationTime + 200, 1, source)

					if itemId == 97 or itemId == 98 then
						exports.sarp_chat:sendLocalMeAction(source, "szívott egy slukkot.")
					elseif availableItems[itemId] then
						if isFoodItem(itemId) then
							exports.sarp_chat:sendLocalMeAction(source, "evett valamiből. ((" .. getItemName(itemId) .. "))")
						elseif isDrinkItem(itemId) then
							exports.sarp_chat:sendLocalMeAction(source, "ivott valamiből. ((" .. getItemName(itemId) .. "))")
						end
					elseif isFoodItem(itemId) then
						exports.sarp_chat:sendLocalMeAction(source, "evett valamiből.")
					elseif isDrinkItem(itemId) then
						exports.sarp_chat:sendLocalMeAction(source, "ivott valamit.")
					end

					local attachment = false

					if itemId == 45 or itemId == 47 then -- Hamburger/Szendvics
						attachment = availableObjectAttachments[1]
					elseif itemId == 46 or itemId == 48 then -- Hot-Dog/Taco
						attachment = availableObjectAttachments[2]
					elseif (itemId >= 52 and itemId <= 59) or itemId == 70 then -- Dobozos üdítők/Kávé
						attachment = availableObjectAttachments[3]
					elseif itemId >= 60 and itemId <= 63 then -- Ásványvíz/Sörök
						attachment = availableObjectAttachments[4]
					elseif itemId >= 64 and itemId <= 69 then -- Vodka/Whiskey
						attachment = availableObjectAttachments[5]
					elseif itemId == 97 or itemId == 98 then -- Cigaretta
						attachment = availableObjectAttachments[6]
					end

					if attachment then
						local obj = createObject(attachment.model, 0, 0, 0)
						
						if isElement(obj) then
							setElementInterior(obj, playerInterior)
							setElementDimension(obj, playerDimension)
							setElementCollisionsEnabled(obj, false)
							setElementDoubleSided(obj, true)
							setObjectScale(obj, attachment.scale or 0.75)

							exports.sarp_boneattach:attachElementToBone(obj, source, unpack(attachment.pos))

							playerAttachments[source] = obj
						end
					end

					if tonumber(item.data3) and isFoodItem(itemId) then
						if math.floor(100 - item.data3 / perishableItems[itemId] * 100) <= 65 then
							triggerClientEvent(source, "rottenEffect", source, item.data3 / (perishableItems[itemId] * 0.75))

							local health = getElementHealth(source) - math.random(3500, 7500) / item.data3

							if health <= 0 then
								health = 0
								setElementData(source, "customDeath", "ételmérgezés")
							end

							setElementHealth(source, health)
						end
					end
				end
			end
		end
	end)

function removePlayerDutyItems(playerElement)
	if isElement(playerElement) then
		local deletedItems = {}

		if not itemsTable[playerElement] then
			return
		end

		for k, v in pairs(itemsTable[playerElement]) do
			if v.data3 == "duty" and v.itemId ~= 86 then -- ha duty item, de nem jelvény (jelvényt off-dutyban is lehessen használni)
				table.insert(deletedItems, v.dbID)
				itemsTable[playerElement][v.slot] = nil
			end
		end

		if #deletedItems > 0 then
			dbExec(connection, "DELETE FROM items WHERE dbID IN (" .. table.concat(deletedItems, ",") .. ")")

			triggerItemEvent(playerElement, "deleteItem", "player", deletedItems)
		end
	end
end

function removeAllItem(sourceElement, dataType, data)
	if sourceElement then
		local elementType = getElementType(sourceElement)
		local dbID = getElementDatabaseId(sourceElement)

		if dbID and itemsTable[sourceElement] then
			local deletedItems = {}

			for k, v in pairs(itemsTable[sourceElement]) do
				if (tonumber(v[dataType]) or v[dataType]) == data then
					table.insert(deletedItems, v.dbID)
					itemsTable[sourceElement][v.slot] = nil
				end
			end

			if #deletedItems > 0 then
				triggerItemEvent(sourceElement, "deleteItem", elementType, deletedItems)
			end
		end
	end

	return false
end

function removeItemByData(sourceElement, itemId, dataType, data)
	if sourceElement then
		local elementType = getElementType(sourceElement)
		local dbID = getElementDatabaseId(sourceElement)

		if dbID and itemsTable[sourceElement] then
			local deletedItems = {}

			for k, v in pairs(itemsTable[sourceElement]) do
				if v.itemId == itemId and (tonumber(v[dataType]) or v[dataType]) == data then
					table.insert(deletedItems, v.dbID)
					itemsTable[sourceElement][v.slot] = nil
				end
			end

			if #deletedItems > 0 then
				dbExec(connection, "DELETE FROM items WHERE dbID IN (" .. table.concat(deletedItems, ",") .. ")")

				triggerItemEvent(sourceElement, "deleteItem", elementType, deletedItems)

				exports.sarp_logs:logItemAction(sourceElement, itemId, false, "removeItemByData")
			end
			
			return true
		end
	end
	
	return false
end

function removeItemFromCharacter(characterId, itemId, dataType, data)
	if characterId and itemId and dataType and data then
		dbExec(connection, "DELETE FROM items WHERE itemId = ? AND ?? = ? AND ownerId = ? AND ownerType = 'player'", tonumber(itemId), dataType, data, characterId)

		local playerElement = exports.sarp_accounts:getPlayerFromCharacterID(characterId)
		local deletedItems = {}

		if itemsTable[playerElement] then
			for k, v in pairs(itemsTable[playerElement]) do
				if v.itemId == itemId and (tonumber(v[dataType]) or v[dataType]) == data then
					table.insert(deletedItems, v.dbID)
					itemsTable[playerElement][v.slot] = nil
				end
			end
		else
			print("playerSource with characterId [" .. characterId .. "] not assigned.", playerElement)
		end

		if #deletedItems > 0 then
			if isElement(playerElement) then
				triggerItemEvent(playerElement, "deleteItem", "player", deletedItems)

				exports.sarp_logs:logItemAction(playerElement, itemId, false, "removeItemFromCharacter")
			end
		end

		return true
	end

	return false
end

addEvent("takeItem", true)
addEventHandler("takeItem", getRootElement(),
	function(sourceElement, itemKey, itemValue, amount)
		if isElement(source) then
			if isElement(sourceElement) then
				if itemKey and itemValue then
					amount = tonumber(amount)

					local deletedItems = {}

					for k, v in pairs(itemsTable[sourceElement]) do
						if v[itemKey] and v[itemKey] == itemValue then
							if amount and itemsTable[sourceElement][v.slot].amount - amount > 0 then
								itemsTable[sourceElement][v.slot].amount = itemsTable[sourceElement][v.slot].amount - amount

								dbExec(connection, "UPDATE items SET amount = ? WHERE ?? = ?", itemsTable[sourceElement][v.slot].amount, itemKey, itemValue)

								triggerItemEvent(sourceElement, "updateItemAmount", getElementType(sourceElement), v.dbID, itemsTable[sourceElement][v.slot].amount)

								exports.sarp_logs:logItemAction(sourceElement, itemsTable[sourceElement][v.slot].itemId, itemsTable[sourceElement][v.slot].amount, "updateAmount")
							else
								exports.sarp_logs:logItemAction(sourceElement, itemsTable[sourceElement][v.slot].itemId, amount, "takeItem")

								table.insert(deletedItems, itemsTable[sourceElement][v.slot].dbID)

								itemsTable[sourceElement][v.slot] = nil
							end
						end
					end

					if #deletedItems > 0 then
						dbExec(connection, "DELETE FROM items WHERE dbID IN (" .. table.concat(deletedItems, ",") .. ")")

						triggerItemEvent(sourceElement, "deleteItem", getElementType(sourceElement), deletedItems)
					end
				end
			end
		end
	end)

addEvent("updateItemData3", true)
addEventHandler("updateItemData3", getRootElement(),
	function(sourceElement, dbID, newData, sync)
		if isElement(sourceElement) then
			dbID = tonumber(dbID)

			if dbID and newData then
				for k, v in pairs(itemsTable[sourceElement]) do
					if v.dbID == dbID then
						itemsTable[sourceElement][v.slot].data3 = newData
						dbExec(connection, "UPDATE items SET data3 = ? WHERE dbID = ?", newData, dbID)

						if sync then
							if getElementType(source) ~= "player" then
								triggerItemEvent(sourceElement, "loadItems", itemsTable[sourceElement], getElementType(source))
							end
						end

						break
					end
				end
			end
		end
	end)

addEvent("updateItemData2", true)
addEventHandler("updateItemData2", getRootElement(),
	function(sourceElement, dbID, newData, sync)
		if isElement(sourceElement) then
			dbID = tonumber(dbID)

			if dbID and newData then
				for k, v in pairs(itemsTable[sourceElement]) do
					if v.dbID == dbID then
						itemsTable[sourceElement][v.slot].data2 = newData
						dbExec(connection, "UPDATE items SET data2 = ? WHERE dbID = ?", newData, dbID)

						if sync then
							if getElementType(source) ~= "player" then
								triggerItemEvent(sourceElement, "loadItems", itemsTable[sourceElement], getElementType(source))
							end
						end

						break
					end
				end
			end
		end
	end)

addEvent("updateItemData1", true)
addEventHandler("updateItemData1", getRootElement(),
	function(sourceElement, dbID, newData, sync)
		if isElement(sourceElement) then
			dbID = tonumber(dbID)

			if dbID and newData then
				for k, v in pairs(itemsTable[sourceElement]) do
					if v.dbID == dbID then
						itemsTable[sourceElement][v.slot].data1 = newData
						dbExec(connection, "UPDATE items SET data1 = ? WHERE dbID = ?", newData, dbID)

						if sync then
							if getElementType(source) ~= "player" then
								triggerItemEvent(sourceElement, "loadItems", itemsTable[sourceElement], getElementType(source))
							end
						end

						break
					end
				end
			end
		end
	end)

addEvent("updateItemAmount", true)
addEventHandler("updateItemAmount", getRootElement(),
	function(sourceElement, dbID, newAmount)
		if isElement(source) then
			if isElement(sourceElement) then
				dbID = tonumber(dbID)
				newAmount = tonumber(newAmount)

				if dbID and newAmount then
					for k, v in pairs(itemsTable[sourceElement]) do
						if v.dbID == dbID then
							itemsTable[sourceElement][v.slot].amount = newAmount
							dbExec(connection, "UPDATE items SET amount = ? WHERE dbID = ?", newAmount, dbID)
							break
						end
					end
				end
			end
		end
	end)

addEvent("moveItem", true)
addEventHandler("moveItem", getRootElement(),
	function(dbID, itemId, sourceSlot, targetSlot, stackAmount, sourceElement, targetElement)
		if isElement(source) then
			dbID = tonumber(dbID)

			if dbID then
				local sourceType = getElementType(sourceElement)
				local sourceDbId = getElementDatabaseId(sourceElement)

				-- mozgatás/stackelés a megnyitott inventoryban
				if sourceElement == targetElement then
					if itemsTable[sourceElement][sourceSlot] and dbID == itemsTable[sourceElement][sourceSlot].dbID then
						if not itemsTable[sourceElement][targetSlot] then
							-- mozgatás
							if stackAmount >= itemsTable[sourceElement][sourceSlot].amount or stackAmount <= 0 then
								dbExec(connection, "UPDATE items SET ownerType = ?, ownerId = ?, slot = ? WHERE dbID = ?", sourceType, sourceDbId, targetSlot, dbID)

								itemsTable[sourceElement][targetSlot] = itemsTable[sourceElement][sourceSlot]
								itemsTable[sourceElement][targetSlot].slot = targetSlot
								itemsTable[sourceElement][sourceSlot] = nil
								
								if sourceType == "player" and getElementType(targetElement) == "player" then
									triggerClientEvent(source, "movedItemInInventory", source, true)
								end
							-- stackelés
							elseif stackAmount > 0 then
								itemsTable[sourceElement][sourceSlot].amount = itemsTable[sourceElement][sourceSlot].amount - stackAmount

								dbExec(connection, "UPDATE items SET amount = ? WHERE dbID = ?", itemsTable[sourceElement][sourceSlot].amount, dbID)

								addItem(sourceElement, itemId, stackAmount, targetSlot, itemsTable[sourceElement][sourceSlot].data1, itemsTable[sourceElement][sourceSlot].data2, itemsTable[sourceElement][sourceSlot].data3)
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("info") .. "A kiválasztott slot foglalt.", source, 255, 255, 255, true)

							triggerClientEvent(source, "failedToMoveItem", source, targetSlot, sourceSlot, stackAmount)
						end
					end
				-- átmozgatás egy másik inventoryba
				else
					local targetType = getElementType(targetElement)
					local targetDbId = getElementDatabaseId(targetElement)
					local canTransfer = true

					if targetType == "vehicle" and isVehicleLocked(targetElement) then
						canTransfer = false
						exports.sarp_hud:showInfobox(source, "error", "A kiválasztott jármű csomagtartója zárva van.")
					end

					if canTransfer then
						if itemsTable[sourceElement][sourceSlot] and dbID == itemsTable[sourceElement][sourceSlot].dbID then
							if not itemsTable[targetElement] then
								itemsTable[targetElement] = {}
							end

							targetSlot = findEmptySlot(targetElement, itemId)

							if targetSlot then
								local statement = false

								if stackAmount >= itemsTable[sourceElement][sourceSlot].amount or stackAmount <= 0 then
									statement = "move"
									stackAmount = itemsTable[sourceElement][sourceSlot].amount
								elseif stackAmount > 0 then
									statement = "split"
								end

								if getInventoryWeight(targetElement) + (getItemWeight(itemId) * stackAmount) < getWeightLimit(targetType, targetElement) then
									if statement == "move" then
										dbExec(connection, "UPDATE items SET ownerType = ?, ownerId = ?, slot = ? WHERE dbID = ?", targetType, targetDbId, targetSlot, dbID)

										itemsTable[targetElement][targetSlot] = itemsTable[sourceElement][sourceSlot]
										itemsTable[targetElement][targetSlot].slot = targetSlot
										itemsTable[sourceElement][sourceSlot] = nil

										triggerItemEvent(targetElement, "addItem", targetType, itemsTable[targetElement][targetSlot])
										triggerItemEvent(sourceElement, "deleteItem", sourceType, {dbID})

										exports.sarp_logs:logItemAction(source, itemId, stackAmount, "moveItem:move")
									elseif statement == "split" then
										dbExec(connection, "UPDATE items SET amount = ? WHERE dbID = ?", itemsTable[sourceElement][sourceSlot].amount - stackAmount, dbID)

										itemsTable[sourceElement][sourceSlot].amount = itemsTable[sourceElement][sourceSlot].amount - stackAmount

										addItem(targetElement, itemId, stackAmount, targetSlot, itemsTable[sourceElement][sourceSlot].data1, itemsTable[sourceElement][sourceSlot].data2, itemsTable[sourceElement][sourceSlot].data3)

										triggerItemEvent(sourceElement, "updateItemAmount", sourceType, dbID, itemsTable[sourceElement][sourceSlot].amount)

										exports.sarp_logs:logItemAction(source, itemId, stackAmount, "moveItem:split")
									end

									transferItemMessage(itemsTable[targetElement][targetSlot], sourceElement, targetElement, sourceType, targetType)
								else
									exports.sarp_hud:showInfobox(source, "error", "A kiválasztott inventory nem bír el több tárgyat!")
								end
							else
								exports.sarp_hud:showInfobox(source, "error", "Nincs szabad slot a kiválasztott inventoryban!")
							end
						end
					end

					triggerClientEvent(source, "unLockItem", source, sourceType, sourceSlot)
				end
			end
		end
	end)

function transferItemMessage(item, fromElement, toElement, fromElementType, toElementType)
	local itemName = ""

	if availableItems[item.itemId] then
		itemName = " (" .. getItemName(item.itemId) .. ")"
	end

	if fromElementType == "player" and toElementType == "player" then
		exports.sarp_chat:sendLocalMeAction(fromElement, "átadott egy tárgyat " .. getElementData(toElement, "visibleName"):gsub("_", " ") .. "-nak/nek." .. itemName)

		setPedAnimation(fromElement, "DEALER", "DEALER_DEAL", 3000, false, false, false, false)
		setPedAnimation(toElement, "DEALER", "DEALER_DEAL", 3000, false, false, false, false)
	elseif fromElementType == "player" and toElementType == "vehicle" then
		exports.sarp_chat:sendLocalMeAction(fromElement, "berakott egy tárgyat a jármű csomagtartójába." .. itemName)
	elseif fromElementType == "player" and toElementType == "object" then
		exports.sarp_chat:sendLocalMeAction(fromElement, "berakott egy tárgyat a széfbe." .. itemName)
	elseif fromElementType == "vehicle" then
		exports.sarp_chat:sendLocalMeAction(toElement, "kivett egy tárgyat a jármű csomagtartójából." .. itemName)
	elseif fromElementType == "object" then
		exports.sarp_chat:sendLocalMeAction(toElement, "kivett egy tárgyat a széfből." .. itemName)
	end
end

function countItemsByItemID(sourceElement, itemId, countAmount)
	local x = 0

	if itemsTable[sourceElement] then
		for k, v in pairs(itemsTable[sourceElement]) do
			if v.itemId == itemId then
				if countAmount then
					x = x + v.amount
				else
					x = x + 1
				end
			end
		end
	end
	
	return x
end

function hasItemWithData(sourceElement, itemId, dataType, data)
	if itemsTable[sourceElement] then
		data = tonumber(data) or data

		for k, v in pairs(itemsTable[sourceElement]) do
			if v.itemId == itemId and  (tonumber(v[dataType]) or v[dataType]) == data then
				return v
			end
		end
	end

	return false
end

function hasItem(sourceElement, itemId)
	if itemsTable[sourceElement] then
		for k, v in pairs(itemsTable[sourceElement]) do
			if v.itemId == itemId then
				return v
			end
		end
	end

	return false
end

addEvent("closeInventory", true)
addEventHandler("closeInventory", getRootElement(),
	function(sourceElement, streamedPlayers)
		if isElement(sourceElement) then
			inventoryInUse[sourceElement] = nil
			
			if getElementType(sourceElement) == "vehicle" then
				setVehicleDoorOpenRatio(sourceElement, 1, 0, 350)
			end
		end
	end)

addEvent("requestItems", true)
addEventHandler("requestItems", getRootElement(),
	function(sourceElement, ownerId, ownerType, streamedPlayers)
		if isElement(source) then
			local gotRequest = true

			if ownerType == "vehicle" and isVehicleLocked(sourceElement) then
				gotRequest = false
			end

			if not gotRequest then
				exports.sarp_hud:showInfobox(source, "error", "A kiválasztott inventory zárva van, esetleg nincs kulcsod hozzá.")
				return
			end

			if isElement(inventoryInUse[sourceElement]) then
				exports.sarp_hud:showInfobox(source, "error", "A kiválasztott inventory már használatban van!")
				return
			end

			inventoryInUse[sourceElement] = source

			if itemsTable[sourceElement] then
				triggerClientEvent(source, "loadItems", source, itemsTable[sourceElement], ownerType, sourceElement, true)
			else
				loadItems(sourceElement, ownerId)
			end

			if ownerType == "vehicle" then
				setVehicleDoorOpenRatio(sourceElement, 1, 1, 500)

				exports.sarp_chat:sendLocalMeAction(source, "belenézett egy jármű csomagtartójába.")
			end
		end
	end)

function triggerItemEvent(sourceElement, eventName, ...)
	local sourcePlayer = sourceElement

	if getElementType(sourceElement) == "player" then
		triggerClientEvent(sourceElement, eventName, sourceElement, ...)
	elseif isElement(inventoryInUse[sourceElement]) then
		sourcePlayer = inventoryInUse[sourceElement]

		triggerClientEvent(inventoryInUse[sourceElement], eventName, inventoryInUse[sourceElement], ...)
	end

	if eventName == "addItem" or eventName == "deleteItem" or eventName == "updateItemAmount" then
		if isElement(sourcePlayer) and getElementType(sourceElement) == "player" then
			triggerClientEvent(sourcePlayer, "movedItemInInventory", sourcePlayer, eventName ~= "updateItemAmount")
		end
	end
end

function loadItems(sourceElement, ownerId)
	if isElement(sourceElement) then
		local ownerType = getElementType(sourceElement)

		if itemsTable[sourceElement] then
			if ownerType == "player" then
				triggerClientEvent(sourceElement, "loadItems", sourceElement, itemsTable[sourceElement], ownerType)
			elseif isElement(inventoryInUse[sourceElement]) then
				triggerClientEvent(inventoryInUse[sourceElement], "loadItems", inventoryInUse[sourceElement], itemsTable[sourceElement], ownerType, sourceElement, true)
			end

			--outputDebugString("Request items cache from - " .. tostring(sourceElement))
		else
			itemsTable[sourceElement] = {}

			--outputDebugString("Request items from - " .. tostring(sourceElement))

			dbQuery(
				function (query, sourceElement)
					local result = dbPoll(query, 0)

					if isElement(sourceElement) then
						local lost, restored = 0, 0

						for k, v in pairs(result) do
							if not itemsTable[sourceElement][v.slot] then
								addItemEx(sourceElement, v.dbID, v.slot, v.itemId, v.amount, v.data1, v.data2, v.data3)
							else
								local emptySlot = findEmptySlot(sourceElement, v.itemId)

								if emptySlot then
									addItemEx(sourceElement, v.dbID, emptySlot, v.itemId, v.amount, v.data1, v.data2, v.data3)

									dbExec(connection, "UPDATE items SET slot = ? WHERE dbID = ?", emptySlot, v.dbID)
									
									restored = restored + 1
								end

								lost = lost + 1
							end
						end

						if ownerType == "player" then
							triggerClientEvent(sourceElement, "loadItems", sourceElement, itemsTable[sourceElement], ownerType)

							if lost > 0 then
								outputChatBox(exports.sarp_core:getServerTag("info") .. "#32b3ef" .. lost .. " #ffffffdarab elveszett tárggyal rendelkezel.", sourceElement, 255, 255, 255, true)
								
								if restored > 0 then
									outputChatBox(exports.sarp_core:getServerTag("info") .. "Ebből #32b3ef" .. restored .. " #ffffffdarab lett visszaállítva.", sourceElement, 255, 255, 255, true)
								end
								
								if lost - restored > 0 then
									outputChatBox(exports.sarp_core:getServerTag("info") .. "Nem sikerült visszaállítani #32b3ef" .. lost - restored .. " #ffffffdarab tárgyad, mert nincs szabad slot az inventorydban.", sourceElement, 255, 255, 255, true)
									outputChatBox(exports.sarp_core:getServerTag("info") .. "A következő bejelentkezésedkor ismét megpróbáljuk.", sourceElement, 255, 255, 255, true)
								end

								if lost == restored then
									outputChatBox(exports.sarp_core:getServerTag("info") .. "Az összes hibás tárgyadat sikeresen visszaállítottuk. Kellemes játékot kívánunk! :).", sourceElement, 255, 255, 255, true)
								end
							end
						elseif isElement(inventoryInUse[sourceElement]) then
							triggerClientEvent(inventoryInUse[sourceElement], "loadItems", inventoryInUse[sourceElement], itemsTable[sourceElement], ownerType, sourceElement, true)
						end
					end
				end, {sourceElement}, connection, "SELECT * FROM items WHERE ownerId = ? AND ownerType = ? ORDER BY slot", ownerId, ownerType
			)
		end
	end
end

addEvent("requestCache", true)
addEventHandler("requestCache", getRootElement(),
	function()
		if isElement(source) then
			local ownerId = getElementDatabaseId(source)

			if tonumber(ownerId) then
				loadItems(source, ownerId)
			end
		end
	end)

function getInventoryItemsCount(sourceElement)
	local items = 0

	if itemsTable[sourceElement] then
		for k, v in pairs(itemsTable[sourceElement]) do
			items = items + 1
		end
	end

	return items
end

function getInventoryWeight(sourceElement)
	local weight = 0

	if itemsTable[sourceElement] then
		for k, v in pairs(itemsTable[sourceElement]) do
			weight = weight + getItemWeight(v.itemId) * v.amount
		end
	end

	return weight
end

function findEmptySlot(sourceElement, itemId)
	if getElementType(sourceElement) == "player" and isKeyItem(itemId) then
		return findEmptySlotOfKeys(sourceElement)
	elseif getElementType(sourceElement) == "player" and isPaperItem(itemId) then
		return findEmptySlotOfPapers(sourceElement)
	else
		local emptySlot = false

		for i = 0, defaultSettings.slotLimit - 1 do
			if not itemsTable[sourceElement][i] then
				emptySlot = tonumber(i)
				break
			end
		end

		if emptySlot then
			if emptySlot <= defaultSettings.slotLimit then
				return emptySlot
			else
				return false
			end
		else
			return false
		end
	end
end

function findEmptySlotOfKeys(sourceElement)
	local emptySlot = false

	for i = defaultSettings.slotLimit, defaultSettings.slotLimit * 2 - 1 do
		if not itemsTable[sourceElement][i] then
			emptySlot = tonumber(i)
			break
		end
	end

	if emptySlot then
		if emptySlot <= defaultSettings.slotLimit * 2 then
			return emptySlot
		else
			return false
		end
	else
		return false
	end
end

function findEmptySlotOfPapers(sourceElement)
	local emptySlot = false

	for i = defaultSettings.slotLimit * 2, defaultSettings.slotLimit * 3 - 1 do
		if not itemsTable[sourceElement][i] then
			emptySlot = tonumber(i)
			break
		end
	end

	if emptySlot then
		if emptySlot <= defaultSettings.slotLimit * 3 then
			return emptySlot
		else
			return false
		end
	else
		return false
	end
end

function addItemEx(sourceElement, dbID, slot, itemId, amount, data1, data2, data3)
	itemsTable[sourceElement][slot] = {}
	itemsTable[sourceElement][slot].dbID = dbID
	itemsTable[sourceElement][slot].slot = slot
	itemsTable[sourceElement][slot].itemId = itemId
	itemsTable[sourceElement][slot].amount = amount
	itemsTable[sourceElement][slot].data1 = data1
	itemsTable[sourceElement][slot].data2 = data2
	itemsTable[sourceElement][slot].data3 = data3
	itemsTable[sourceElement][slot].inUse = false
	itemsTable[sourceElement][slot].locked = false
end

function giveItem(sourceElement, itemId, amount, data1, data2, data3)
	addItem(sourceElement, itemId, amount, false, data1, data2, data3)
end

function addItem(sourceElement, itemId, amount, slotId, data1, data2, data3)
	if isElement(sourceElement) and itemId and amount then
		itemId = tonumber(itemId)
		amount = tonumber(amount)

		if not itemsTable[sourceElement] then
			itemsTable[sourceElement] = {}
		end

		if not slotId then
			slotId = findEmptySlot(sourceElement, itemId)
		elseif tonumber(slotId) then
			if itemsTable[sourceElement][slotId] then
				slotId = findEmptySlot(sourceElement, itemId)
			end
		end

		if slotId then
			local ownerType = getElementType(sourceElement)
			local ownerId = getElementDatabaseId(sourceElement)

			if tonumber(ownerId) then
				itemsTable[sourceElement][slotId] = {}
				itemsTable[sourceElement][slotId].locked = true

				dbQuery(
					function (qh, sourceElement)
						if isElement(sourceElement) then
							local result = dbPoll(qh, 0, true)[2][1][1]

							if result then
								addItemEx(sourceElement, result.dbID, result.slot, result.itemId, result.amount, result.data1, result.data2, result.data3)

								triggerItemEvent(sourceElement, "addItem", getElementType(sourceElement), result)
							end
						end
					end, {sourceElement}, connection, "INSERT INTO items (itemId, slot, amount, data1, data2, data3, ownerType, ownerId) VALUES (?,?,?,?,?,?,?,?); SELECT * FROM items ORDER BY dbID DESC LIMIT 1", itemId, slotId, amount, data1, data2, data3, ownerType, ownerId
				)

				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
addEvent("addItem", true)
addEventHandler("addItem", getRootElement(), addItem)

addCommandHandler("additem",
	function(sourcePlayer, commandName, targetPlayer, itemId, amount, data1, data2, data3)
		if getElementData(sourcePlayer, "acc.adminLevel") >= 10 then
			if not (targetPlayer and itemId) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Játékos név / ID] [Item ID] [Mennyiség] [ < Data 1 | Data 2 | Data 3 > ]", sourcePlayer, 255, 255, 255, true)
			else
				itemId = tonumber(itemId)
				amount = tonumber(amount)

				if itemId and amount then
					targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

					if targetPlayer then
						local state = addItem(targetPlayer, itemId, amount, false, data1, data2, data3)

						if state then
							outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az item sikeresen odaadva.", sourcePlayer, 255, 255, 255, true)
						else
							outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az item odaadás meghiúsult.", sourcePlayer, 255, 255, 255, true)
						end
					end
				end
			end
		end
	end)