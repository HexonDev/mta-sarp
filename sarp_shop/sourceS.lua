--[[

CREATE TABLE `shop_peds` (
	`pedId` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`posX` float NOT NULL,
	`posY` float NOT NULL,
	`posZ` float NOT NULL,
	`rotZ` float NOT NULL,
	`interior` int(11) NOT NULL,
	`dimension` int(11) NOT NULL,
	`skinId` int(3) NOT NULL,
	`balance` int(11) NOT NULL DEFAULT '0',
	`itemList` longtext NOT NULL
);

]]

local connection = false

local pedsTable = {}

local nonStackableItems = {}

addEvent("buyItemsFromPed", true)
addEventHandler("buyItemsFromPed", getRootElement(),
	function(pedId, items, totalPrice, totalSlot, totalWeight)
		if isElement(source) and pedId and pedsTable[pedId] then
			local currentMoney = getElementData(source, "char.Money") or 0

			if currentMoney - totalPrice >= 0 then
				exports.sarp_core:takeMoney(source, totalPrice, "shopBuyItems")

				for k = 1, #items do
					local v = items[k]
					local itemId = v[1]
					local amount = v[2]

					pedsTable[pedId]["balance"] = pedsTable[pedId]["balance"] + pedsTable[pedId]["items"][itemId][1]

					pedsTable[pedId]["items"][itemId][2] = pedsTable[pedId]["items"][itemId][2] - amount

					if pedsTable[pedId]["items"][itemId][2] <= 0 then
						pedsTable[pedId]["items"][itemId][2] = 0
					end

					if nonStackableItems[itemId] then
						for i = 1, amount do
							exports.sarp_inventory:addItem(source, itemId, 1)
						end
					else
						exports.sarp_inventory:addItem(source, itemId, amount)
					end
				end

				exports.sarp_hud:showInfobox(source, "success", "Sikeres megvásároltad a kiválasztott termékeket!")

				dbExec(connection, "UPDATE shop_peds SET balance = ? WHERE pedId = ?", pedsTable[pedId]["balance"], pedId)
			else
				exports.sarp_hud:showInfobox(source, "error", "Nincs nálad elegendő pénz!")
			end
		end
	end)

addEvent("getOutMoney", true)
addEventHandler("getOutMoney", getRootElement(),
	function(pedId, amount)
		if isElement(source) and pedId and pedsTable[pedId] then
			local currentBalance = pedsTable[pedId]["balance"]

			if currentBalance - amount >= 0 then
				exports.sarp_core:giveMoney(source, amount, "shopGetOutMoney")

				currentBalance = currentBalance - amount

				pedsTable[pedId]["balance"] = currentBalance

				dbQuery(
					function(qh, player)
						if isElement(player) then
							triggerClientEvent(player, "setPedBalance", player, currentBalance)

							exports.sarp_hud:showInfobox(player, "success", "Sikeresen kifizettél a kasszából " .. amount .. " $-t.")
						end

						dbFree(qh)
					end, {source}, connection, "UPDATE shop_peds SET balance = ? WHERE pedId = ?", currentBalance, pedId)
			else
				exports.sarp_hud:showInfobox(source, "error", "Nincs a kasszában ennyi pénz!")
			end
		end
	end)

addEvent("putInMoney", true)
addEventHandler("putInMoney", getRootElement(),
	function(pedId, amount)
		if isElement(source) and pedId and pedsTable[pedId] then
			local currentMoney = getElementData(source, "char.Money") or 0

			if currentMoney - amount >= 0 then
				local currentBalance = pedsTable[pedId]["balance"]

				exports.sarp_core:takeMoney(source, amount, "shopPutInMoney")

				currentBalance = currentBalance + amount

				pedsTable[pedId]["balance"] = currentBalance

				dbQuery(
					function(qh, player)
						if isElement(player) then
							triggerClientEvent(player, "setPedBalance", player, currentBalance)

							exports.sarp_hud:showInfobox(player, "success", "Sikeresen befizettél a kasszába " .. amount .. " $-t.")
						end

						dbFree(qh)
					end, {source}, connection, "UPDATE shop_peds SET balance = ? WHERE pedId = ?", currentBalance, pedId)
			else
				exports.sarp_hud:showInfobox(source, "error", "Nincs nálad ennyi pénz!")
			end
		end
	end)

addEvent("setItemPrice", true)
addEventHandler("setItemPrice", getRootElement(),
	function(pedId, itemId, price)
		if isElement(source) and pedId and pedsTable[pedId] then
			if pedsTable[pedId]["items"] and pedsTable[pedId]["items"][itemId] then
				pedsTable[pedId]["items"][itemId][1] = price

				triggerClientEvent(source, "refreshPedItemPrice", source, itemId, price)
			end
		end
	end)

addEvent("addToPedStock", true)
addEventHandler("addToPedStock", getRootElement(),
	function(pedId, itemId, amount)
		if isElement(source) and pedId and pedsTable[pedId] then
			if pedsTable[pedId]["items"] and pedsTable[pedId]["items"][itemId] then
				local currentBalance = pedsTable[pedId]["balance"]
				local amountPrice = amount * itemBasePrices[itemId]

				currentBalance = currentBalance - amountPrice

				if currentBalance >= 0 then
					local currentAmount = pedsTable[pedId]["items"][itemId][2]

					currentAmount = currentAmount + amount

					exports.sarp_core:takeMoney(source, amountPrice, "shopStock")

					pedsTable[pedId]["items"][itemId][2] = currentAmount
					pedsTable[pedId]["balance"] = currentBalance

					dbQuery(
						function(qh, player)
							if isElement(player) then
								triggerClientEvent(player, "refreshPedItemStock", player, itemId, currentAmount, currentBalance)

								exports.sarp_hud:showInfobox(player, "success", "Sikeresen megrendeltél a kiválasztott tételből " .. amount .. " darabot " .. amountPrice .. " $ értékben.")
							end

							dbFree(qh)
						end, {source}, connection, "UPDATE shop_peds SET balance = ? WHERE pedId = ?", currentBalance, pedId)
				else
					exports.sarp_hud:showInfobox(source, "error", "Nincs elegendő pénz a kasszában! (" .. amountPrice .. " $)")
				end
			end
		end
	end)

addEvent("refreshPedItemList", true)
addEventHandler("refreshPedItemList", getRootElement(),
	function(pedId, items)
		if isElement(source) and pedId and pedsTable[pedId] then
			pedsTable[pedId]["items"] = items
		end
	end)

addEvent("refreshPedCategories", true)
addEventHandler("refreshPedCategories", getRootElement(),
	function(pedId, cats)
		if isElement(source) and pedId and pedsTable[pedId] then
			pedsTable[pedId]["categories"] = cats
		end
	end)

addEvent("requestPedItemList", true)
addEventHandler("requestPedItemList", getRootElement(),
	function(pedId)
		if isElement(source) and pedId and pedsTable[pedId] then
			triggerClientEvent(source, "gotPedItems", source, pedId, pedsTable[pedId]["balance"], pedsTable[pedId]["categories"], pedsTable[pedId]["items"], pedsTable[pedId][3])
		end
	end)

exports.sarp_admin:addAdminCommand("moveshopped", 6, "Bolt NPC átmozgatása")
addCommandHandler("moveshopped",
	function(playerSource, commandName, pedId, skin)
		if getElementData(playerSource, "acc.adminLevel") >= 6 then
			pedId = tonumber(pedId)

			if not pedId then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Ped ID] [ < Skin ID > ]", playerSource, 0, 0, 0, true)
			else
				pedId = math.floor(math.abs(pedId))

				if pedsTable[pedId] then
					local x, y, z = getElementPosition(playerSource)
					local rx, ry, rz = getElementRotation(playerSource)
					local interior = getElementInterior(playerSource)
					local dimension = getElementDimension(playerSource)

					if tonumber(skin) then
						skin = math.floor(math.abs(tonumber(skin)))
					else
						skin = getElementModel(pedsTable[pedId][2])
					end

					setElementPosition(pedsTable[pedId][2], x, y, z)
					setElementRotation(pedsTable[pedId][2], 0, 0, rz)
					setElementInterior(pedsTable[pedId][2], interior)
					setElementDimension(pedsTable[pedId][2], dimension)
					setElementModel(pedsTable[pedId][2], skin)

					setElementPosition(pedsTable[pedId][1], x, y, z)
					setElementInterior(pedsTable[pedId][1], interior)
					setElementDimension(pedsTable[pedId][1], dimension)

					pedsTable[pedId][3] = dimension

					dbExec(connection, "UPDATE shop_peds SET posX = ?, posY = ?, posZ = ?, rotZ = ?, interior = ?, dimension = ?, skinId = ? WHERE pedId = ?", x, y, z, rz, interior, dimension, skin, pedId)
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott ped nem létezik!", playerSource, 0, 0, 0, true)
				end
			end
		end
	end)

exports.sarp_admin:addAdminCommand("delshopped", 6, "Bolt NPC törlése")
addCommandHandler("delshopped",
	function(playerSource, commandName, pedId)
		if getElementData(playerSource, "acc.adminLevel") >= 6 then
			pedId = tonumber(pedId)

			if not pedId then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Ped ID]", playerSource, 0, 0, 0, true)
			else
				pedId = math.floor(math.abs(pedId))

				if pedsTable[pedId] then
					dbQuery(
						function(qh, sourcePlayer, id)
							if isElement(pedsTable[id][1]) then
								destroyElement(pedsTable[id][1])
							end

							if isElement(pedsTable[id][2]) then
								destroyElement(pedsTable[id][2])
							end

							pedsTable[id] = nil

							if isElement(sourcePlayer) then
								outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen törölted a kiválasztott pedet.", playerSource, 0, 0, 0, true)
							end

							dbFree(qh)
						end, {playerSource, pedId}, connection, "DELETE FROM shop_peds WHERE pedId = ?", pedId)
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott ped nem létezik!", playerSource, 0, 0, 0, true)
				end
			end
		end
	end)

function toString(array)
	local str = ""

	-- engedélyezett kategóriák
	if array["categories"] then
		local count = 0

		for k, v in pairs(array["categories"]) do
			str = str .. k .. "/"	-- item id
			count = count + 1
		end

		if count == 0 then
			str = str .. "-"
		end
	else
		str = str .. "-"
	end
	str = str .. ";"

	-- készleten lévő termékek
	if array["items"] then
		local count = 0

		for k, v in pairs(array["items"]) do
			str = str .. k .. "/"		-- item id
			str = str .. v[1] .. "/"	-- ár
			str = str .. v[2] .. "/"	-- készleten (db)
			count = count + 1
		end

		if count == 0 then
			str = str .. "-"
		end
	else
		str = str .. "-"
	end

	return str
end

function fromString(str)
	local array = split(str, ";")
	local data = {}

	-- engedélyezett kategóriák
	data["categories"] = {}

	if array[1] and array[1] ~= "-" then
		local categories = split(array[1], "/")

		for k = 1, #categories do
			local v = tonumber(categories[k])

			data["categories"][v] = true
		end
	end

	-- készleten lévő termékek
	data["items"] = {}

	if array[2] and array[2] ~= "-" then
		local items = split(array[2], "/")

		for k = 1, #items, 3 do
			data["items"][tonumber(items[k])] = {tonumber(items[k+1]), tonumber(items[k+2])}
		end
	end

	return data
end

function loadShop(id, array)
	local ped = createPed(array["skinId"], array["posX"], array["posY"], array["posZ"], array["rotZ"], false)

	if isElement(ped) then
		local colshape = createColSphere(array["posX"], array["posY"], array["posZ"], 3.75)

		if isElement(colshape) then
			setElementInterior(colshape, array["interior"])
			setElementDimension(colshape, array["dimension"])

			setElementInterior(ped, array["interior"])
			setElementDimension(ped, array["dimension"])
			setElementFrozen(ped, true)

			setElementData(ped, "invulnerable", true)
			setElementData(ped, "visibleName", "Eladó")
			setElementData(ped, "pedNameType", "Bolt")

			setElementData(ped, "pedId", id)
			setElementData(ped, "pedColShape", colshape)

			pedsTable[id] = {colshape, ped, array["dimension"]}
			pedsTable[id]["balance"] = array["balance"]

			local savedata = fromString(array["itemList"])

			pedsTable[id]["categories"] = savedata["categories"]
			pedsTable[id]["items"] = savedata["items"]
		else
			destroyElement(ped)
		end
	end
end

function savePeds(pedId)
	if tonumber(pedId) then
		dbExec(connection, "UPDATE shop_peds SET itemList = ? WHERE pedId = ?", toString(pedsTable[pedId]), pedId)
	else
		for k, v in pairs(pedsTable) do
			dbExec(connection, "UPDATE shop_peds SET itemList = ? WHERE pedId = ?", toString(v), k)
		end

		outputDebugString("Save peds")
	end
end
addEventHandler("onResourceStop", getRootElement(), savePeds)

addEventHandler("onResourceStart", getRootElement(),
	function(res)
		if getResourceName(res) == "sarp_inventory" then
			nonStackableItems = exports.sarp_inventory:getNonStackableItems()
		elseif source == getResourceRootElement() then
			connection = exports.sarp_database:getConnection()

			dbQuery(
				function(qh)
					local result, numAffectedRows = dbPoll(qh, 0)

					if numAffectedRows > 0 then
						for k, v in ipairs(result) do
							loadShop(v["pedId"], v)
						end
					end
				end, connection, "SELECT * FROM shop_peds")

			setTimer(savePeds, 1800000, 0)

			local inventory = getResourceFromName("sarp_inventory")

			if getResourceState(inventory) == "running" then
				nonStackableItems = exports.sarp_inventory:getNonStackableItems()
			end
		end
	end)

exports.sarp_admin:addAdminCommand("createshopped", 6, "Bolt NPC létrehozása")
addCommandHandler("createshopped",
	function(playerSource, commandName, skin)
		if getElementData(playerSource, "acc.adminLevel") >= 6 then
			skin = tonumber(skin)

			if not skin then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Skin ID]", playerSource, 0, 0, 0, true)
				outputChatBox(exports.sarp_core:getServerTag("info") .. "#ffff99A ped létrehozása után be kell állítanod a ped item kategóriáit.", playerSource, 0, 0, 0, true)
			else
				local x, y, z = getElementPosition(playerSource)
				local rx, ry, rz = getElementRotation(playerSource)
				local interior = getElementInterior(playerSource)
				local dimension = getElementDimension(playerSource)

				dbExec(connection, "INSERT INTO shop_peds (posX,posY,posZ,rotZ,interior,dimension,skinId,itemList) VALUES (?,?,?,?,?,?,?,'')", x, y, z, rz, interior, dimension, skin)
				dbQuery(
					function(qh, sourcePlayer)
						local result = dbPoll(qh, 0)[1]

						if result then
							loadShop(result["pedId"], result)

							if isElement(sourcePlayer) then
								outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen létrehoztál egy Bolt NPC-t. #32b3ef(PedId: " .. result["pedId"] .. ")", playerSource, 0, 0, 0, true)
							end
						end
					end, {playerSource}, connection, "SELECT * FROM shop_peds WHERE pedId = LAST_INSERT_ID()")
			end
		end
	end)