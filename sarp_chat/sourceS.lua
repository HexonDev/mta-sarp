local connection = false

local payTimers = {}

local tradeContractDatas = {}

function formatNumber(amount, stepper)
	local left, center, right = string.match(math.floor(amount), "^([^%d]*%d)(%d*)(.-)$")
	return left .. string.reverse(string.gsub(string.reverse(center), "(%d%d%d)", "%1" .. (stepper or " "))) .. right
end

addEvent("acceptInteriorBuy", true)
addEventHandler("acceptInteriorBuy", getRootElement(),
	function(seller, interiorId, price)
		if isElement(source) and isElement(seller) and interiorId then
			local currentTime = getRealTime().timestamp

			if tradeContractDatas[source] then
				if currentTime <= tradeContractDatas[source]["tradeEnd"] then
					local currentMoney = getElementData(source, "char.Money") or 0

					if currentMoney - price >= 0 then
						local characterId = getElementData(source, "char.ID") or 0

						exports.sarp_core:takeMoney(source, price, "buyInterior")
						exports.sarp_core:giveMoney(seller, price, "sellInterior")

						sendLocalMeAction(source, "aláír egy adásvételi szerződést.")

						dbQuery(
							function(qh, player, oldowner)
								exports.sarp_interiors:changeInteriorOwner(interiorId, characterId)

								triggerClientEvent("changeInteriorOwner", resourceRoot, interiorId, characterId)

								if isElement(player) then
									exports.sarp_hud:showInfobox(player, "success", "Sikeresen megvásároltad az ingatlant " .. formatNumber(price) .. " $-ért.")
								end

								if isElement(oldowner) then
									exports.sarp_hud:showInfobox(oldowner, "success", "Sikeresen eladtad az ingatlant " .. formatNumber(price) .. " $-ért.")
								end

								dbFree(qh)
							end, {source, seller}, connection, "UPDATE interiors SET ownerId = ? WHERE interiorId = ?", characterId, interiorId
						)
					else
						exports.sarp_hud:showInfobox(source, "error", "Nincs nálad elegendő pénz!")

						outputChatBox(exports.sarp_core:getServerTag("info") .. "Nincs nálad elegendő pénz az ingatlan megvételéhez!", source, 0, 0, 0, true)
						outputChatBox(exports.sarp_core:getServerTag("info") .. "Az adásvételi szerződés automatikusan visszavonva.", source, 0, 0, 0, true)
					end
				else
					exports.sarp_hud:showInfobox(source, "error", "Nincs folyamatban adásvételi szerződés!")
				end
			else
				exports.sarp_hud:showInfobox(source, "error", "Nincs folyamatban adásvételi szerződés!")
			end

			tradeContractDatas[source] = nil
		end
	end)

addEvent("tryToSellInterior", true)
addEventHandler("tryToSellInterior", getRootElement(),
	function(targetPlayer, interiorId, interiorData, price)
		if isElement(source) and isElement(targetPlayer) then
			local characterId = getElementData(source, "char.ID") or 0
			local targetId = getElementData(targetPlayer, "char.ID") or 0

			if characterId > 0 and targetId > 0 then
				local currentTime = getRealTime().timestamp

				if tradeContractDatas[targetPlayer] and currentTime >= tradeContractDatas[targetPlayer]["tradeEnd"] then
					tradeContractDatas[targetPlayer] = nil
				end

				if not tradeContractDatas[targetPlayer] then
					dbQuery(
						function(qh, theSeller, thePerson, intiId, thePrice, intiData)
							local result = dbPoll(qh, 0)

							if result then
								local interiorSlot = getElementData(thePerson, "char.interiorLimit") or 0

								result = result[1]["COUNT(interiorId)"]

								if result < interiorSlot then
									tradeContractDatas[thePerson] = {}
									tradeContractDatas[thePerson]["tradeEnd"] = getRealTime().timestamp + 300 -- 5 perc
									tradeContractDatas[thePerson]["theSeller"] = theSeller
									tradeContractDatas[thePerson]["interiorId"] = intiId

									triggerClientEvent(thePerson, "sellInteriorNotification", thePerson, theSeller, intiId, thePrice, intiData)
									triggerClientEvent(theSeller, "failedToSell", theSeller) -- adásvételi kioffolása

									local personName = getElementData(thePerson, "visibleName"):gsub("_", " ")

									sendLocalMeAction(theSeller, "átnyújt egy adásvételi szerződést " .. personName .. "-nak/nek.")

									exports.sarp_hud:showInfobox(theSeller, "info", "Átnyújtottál egy adásvételi szerződést.")
								else
									triggerClientEvent(theSeller, "failedToSell", theSeller, "A kiválasztott játékosnak nincs több interior slotja!")
								end
							end
						end, {source, targetPlayer, interiorId, price, interiorData}, connection, "SELECT COUNT(interiorId) FROM interiors WHERE ownerId = ?", personId
					)
				else
					triggerClientEvent(source, "failedToSell", source, "A kiválasztott játékosnak már folyamatban van egy adásvételi szerződés!")
				end
			end
		end
	end)

addEvent("acceptVehicleBuy", true)
addEventHandler("acceptVehicleBuy", getRootElement(),
	function(seller, veh, price)
		if isElement(source) and isElement(seller) and isElement(veh) then
			local currentTime = getRealTime().timestamp

			if tradeContractDatas[source] then
				if currentTime <= tradeContractDatas[source]["tradeEnd"] then
					local currentMoney = getElementData(source, "char.Money") or 0

					if currentMoney - price >= 0 then
						local characterId = getElementData(source, "char.ID") or 0

						exports.sarp_core:takeMoney(source, price, "buyVehicle")
						exports.sarp_core:giveMoney(seller, price, "sellVehicle")

						sendLocalMeAction(source, "aláír egy adásvételi szerződést.")

						dbQuery(
							function(qh, player, oldowner)
								setElementData(veh, "vehicle.owner", characterId)

								if isElement(player) then
									exports.sarp_hud:showInfobox(player, "success", "Sikeresen megvásároltad a járművet " .. formatNumber(price) .. " $-ért.")
								end

								if isElement(oldowner) then
									exports.sarp_hud:showInfobox(oldowner, "success", "Sikeresen eladtad a járművet " .. formatNumber(price) .. " $-ért.")
								end

								dbFree(qh)
							end, {source, seller}, connection, "UPDATE vehicles SET owner = ? WHERE vehicleID = ?", characterId, getElementData(veh, "vehicle.dbID")
						)
					else
						exports.sarp_hud:showInfobox(source, "error", "Nincs nálad elegendő pénz!")

						outputChatBox(exports.sarp_core:getServerTag("info") .. "Nincs nálad elegendő pénz a jármű megvételéhez!", source, 0, 0, 0, true)
						outputChatBox(exports.sarp_core:getServerTag("info") .. "Az adásvételi szerződés automatikusan visszavonva.", source, 0, 0, 0, true)
					end
				else
					exports.sarp_hud:showInfobox(source, "error", "Nincs folyamatban adásvételi szerződés!")
				end
			else
				exports.sarp_hud:showInfobox(source, "error", "Nincs folyamatban adásvételi szerződés!")
			end

			tradeContractDatas[source] = nil
		end
	end)

addEvent("tryToSellVehicle", true)
addEventHandler("tryToSellVehicle", getRootElement(),
	function(personElement, vehicleElement, price)
		if isElement(source) and isElement(personElement) and isElement(vehicleElement) then
			local characterId = getElementData(source, "char.ID") or 0
			local personId = getElementData(personElement, "char.ID") or 0

			if characterId > 0 and personId > 0 then
				local ownerId = getElementData(vehicleElement, "vehicle.owner") or 0

				if ownerId == characterId then
					local groupId = getElementData(vehicleElement, "vehicle.group") or 0

					if groupId == 0 then
						local currentTime = getRealTime().timestamp

						if tradeContractDatas[personElement] and currentTime >= tradeContractDatas[personElement]["tradeEnd"] then
							tradeContractDatas[personElement] = nil
						end

						if not tradeContractDatas[personElement] then
							dbQuery(
								function(qh, theSeller, thePerson, theVeh, thePrice)
									local result = dbPoll(qh, 0)

									if result then
										local vehicleSlot = getElementData(thePerson, "char.vehicleLimit") or 0

										result = result[1]["COUNT(vehicleID)"]

										if result < vehicleSlot then
											tradeContractDatas[thePerson] = {}
											tradeContractDatas[thePerson]["tradeEnd"] = getRealTime().timestamp + 300 -- 5 perc
											tradeContractDatas[thePerson]["theSeller"] = theSeller
											tradeContractDatas[thePerson]["vehicleId"] = getElementData(theVeh, "vehicle.dbID")

											triggerClientEvent(thePerson, "sellVehicleNotification", thePerson, theSeller, theVeh, thePrice)
											triggerClientEvent(theSeller, "failedToSell", theSeller) -- adásvételi kioffolása

											local personName = getElementData(thePerson, "visibleName"):gsub("_", " ")

											sendLocalMeAction(theSeller, "átnyújt egy adásvételi szerződést " .. personName .. "-nak/nek.")

											exports.sarp_hud:showInfobox(theSeller, "info", "Átnyújtottál egy adásvételi szerződést.")
										else
											triggerClientEvent(theSeller, "failedToSell", theSeller, "A kiválasztott játékosnak nincs több jármű slotja!")
										end
									end
								end, {source, personElement, vehicleElement, price}, connection, "SELECT COUNT(vehicleID) FROM vehicles WHERE owner = ? AND groupID = '0'", personId
							)
						else
							triggerClientEvent(source, "failedToSell", source, "A kiválasztott játékosnak már folyamatban van egy adásvételi szerződés!")
						end
					else
						triggerClientEvent(source, "failedToSell", source, "Frakció járművet nem tudsz eladni!")
					end
				else
					triggerClientEvent(source, "failedToSell", source, "Ez a jármű nem a tiéd!")
				end
			else
				triggerClientEvent(source, "failedToSell", source, "Hiba történt.")
			end
		end
	end)

addEventHandler("onResourceStart", getResourceRootElement(),
	function()
		connection = exports.sarp_database:getConnection()
	end)

addEventHandler("onPlayerQuit", getRootElement(),
	function()
		if isTimer(payTimers[source]) then
			killTimer(payTimers[source])
		end

		payTimers[source] = nil

		if tradeContractDatas[source] then
			if isElement(tradeContractDatas[source]["theSeller"]) then
				triggerClientEvent(tradeContractDatas[source]["theSeller"], "failedToSell", tradeContractDatas[source]["theSeller"])
			end

			tradeContractDatas[source] = nil
		end
	end)

function payTheMoney(sourcePlayer, targetPlayer, amount)
	if isElement(sourcePlayer) and isElement(targetPlayer) then
		local playerName = getElementData(sourcePlayer, "visibleName"):gsub("_", " ")
		local targetName = getElementData(targetPlayer, "visibleName"):gsub("_", " ")

		sendLocalMeAction(sourcePlayer, "átad valamennyi összegű pénzt " .. targetName .. "-nak/nek.")

		exports.sarp_core:takeMoney(sourcePlayer, amount, "pay")

		exports.sarp_core:giveMoney(targetPlayer, amount, "pay")

		outputChatBox(exports.sarp_core:getServerTag("info") .. "A pénz átadása #7cc576sikeresen #ffffffmegtörtént. Összeg: #32b3ef" .. amount .. " $", sourcePlayer, 0, 0, 0, true)
		outputChatBox(exports.sarp_core:getServerTag("info") .. "#ffa600" .. playerName .. " #ffffffadott neked #32b3ef" .. amount .. " $#ffffff-t.", targetPlayer, 0, 0, 0, true)
	end

	payTimers[sourcePlayer] = nil
end

addCommandHandler("pay",
	function(sourcePlayer, cmd, targetPlayer, amount)
		amount = tonumber(amount)

		if not (targetPlayer and amount) then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Játékos név / ID] [Összeg]", sourcePlayer, 0, 0, 0, true)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				if targetPlayer ~= sourcePlayer then
					local px, py, pz = getElementPosition(sourcePlayer)
					local tx, ty, tz = getElementPosition(targetPlayer)

					local pi = getElementInterior(sourcePlayer)
					local ti = getElementInterior(targetPlayer)

					local pd = getElementDimension(sourcePlayer)
					local td = getElementDimension(targetPlayer)

					local dist = getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz)

					if dist <= 5 and pi == ti and pd == td then
						amount = math.ceil(amount)

						if amount > 0 then
							local currentMoney = getElementData(sourcePlayer, "char.Money") or 0

							if currentMoney - amount >= 0 then
								if not payTimers[sourcePlayer] then
									payTimers[sourcePlayer] = setTimer(payTheMoney, 5000, 1, sourcePlayer, targetPlayer, amount)

									outputChatBox(exports.sarp_core:getServerTag("info") .. "A pénz átadása #ffa6005 #ffffffmásodpercen belül megkezdődik.", sourcePlayer, 0, 0, 0, true)
								else
									outputChatBox(exports.sarp_core:getServerTag("error") .. "Még az előző pénzt sem adtad át, hova ilyen gyorsan?!", sourcePlayer, 0, 0, 0, true)
								end
							else
								outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs nálad ennyi pénz!", sourcePlayer, 0, 0, 0, true)
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("error") .. "Maradjunk a nullánál nagyobb egész számoknál.", sourcePlayer, 0, 0, 0, true)
						end
					else
						outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled.", sourcePlayer, 0, 0, 0, true)
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "Magadnak nem tudsz pénzt adni!", sourcePlayer, 0, 0, 0, true)
				end
			end
		end
	end)

addEventHandler("onPlayerCommand", getRootElement(),
	function (command)
		if command == "say" or command == "me" then
			cancelEvent()
		end
	end
)

function outputErrorText(text, element)
    triggerClientEvent(element, "playClientSound", element, ":sarp_assets/audio/admin/error.ogg")
    assert(type(text) == "string", "Bad argument @ 'outputErrorText' [expected string at argument 1, got "..type(text).."]")
    outputChatBox(exports.sarp_core:getServerTag("error") .. text, element, 0, 0, 0, true)
end

function outputInfoText(text, element)
    assert(type(text) == "string", "Bad argument @ 'outputInfoText' [expected string at argument 1, got "..type(text).."]")
    outputChatBox(exports.sarp_core:getServerTag("info") .. text, element, 0, 0, 0, true)
end

function sendLocalMessage(player, message)
	triggerClientEvent(player, "onClientPlayerLocalMessage", player, player, message)
end

function sendLocalMeAction(player, message)
	triggerClientEvent(player, "onClientPlayerLocalMe", player, player, message)
end

function sendLocalDoAction(player, message)
	triggerClientEvent(player, "onClientPlayerLocalDo", player, player, message)
end

function sendLocalAmeAction(player, message)
	triggerClientEvent(player, "onClientPlayerLocalAme", player, player, message)
end

addEvent("onLocalMessage", true)
addEventHandler("onLocalMessage", getRootElement(),
	function (pendingPlayers, visibleName, message, additionalStr, adminLevel, adminTitle, adminTitleColor, adminDuty)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i][1]) then
				if not adminDuty then
					outputChatBox(pendingPlayers[i][2] .. visibleName .. " mondja" .. additionalStr .. ": " .. message, pendingPlayers[i][1], 16, 16, 16, true)
				else
					outputChatBox(adminTitleColor .. "[" .. adminTitle .. "] " .. visibleName .. " mondja" .. additionalStr .. ": " .. message, pendingPlayers[i][1], 16, 16, 16, true)
				end
			end
 		end
	end
)

addEvent("onActionMessage", true)
addEventHandler("onActionMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i]) then
				outputChatBox("#C2A2DA*** " .. visibleName .. " #C2A2DA" .. message, pendingPlayers[i], 32, 32, 32, true)
			end
		end
	end
)

addEvent("laughAnim", true)
addEventHandler("laughAnim", getRootElement(),
	function ()
		if isElement(source) then
			setPedAnimation(source, "rapping", "laugh_01", 3500, true, false, false, false)
		end
	end
)

addEvent("onDoMessage", true)
addEventHandler("onDoMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i]) then
				outputChatBox("#FF2850* " .. message .. " ((#FF2850" .. visibleName .. "))", pendingPlayers[i], 64, 64, 64, true)
			end
		end
	end
)

addEvent("onWhisperMessage", true)
addEventHandler("onWhisperMessage", getRootElement(),
	function (pendingPlayers, visibleName, message, additionalStr)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i][1]) then
				outputChatBox(pendingPlayers[i][2] .. visibleName .. " mondja" .. additionalStr .. ": " .. message, pendingPlayers[i][1], 128, 128, 128, true)
			end
		end
	end
)

addEvent("onShoutMessage", true)
addEventHandler("onShoutMessage", getRootElement(),
	function (pendingPlayers, visibleName, message, additionalStr)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i][1]) then
				outputChatBox(pendingPlayers[i][2] .. visibleName .. " ordítja" .. additionalStr .. ": " .. message, pendingPlayers[i][1], 128, 128, 128, true)
			end
		end
	end
)

addEvent("shoutAnim", true)
addEventHandler("shoutAnim", getRootElement(),
	function ()
		if isElement(source) then
			setPedAnimation(source, "RIOT", "RIOT_shout", 750, true, false, false, false)
		end
	end
)

addEvent("megaphoneAnim", true)
addEventHandler("megaphoneAnim", getRootElement(),
	function (players)
		if isElement(source) then
			triggerClientEvent(players, "megaphoneAnim", source)
		end
	end
)

addEvent("onTryMessage", true)
addEventHandler("onTryMessage", getRootElement(),
	function (pendingPlayers, visibleName, message, tryResult, command)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i]) then
				if command == "megprobal" or command == "megpróbál" then
					if tryResult == 1 then
						outputChatBox(" *** " .. visibleName .. " megpróbál " .. message .. " és sikerül neki.", pendingPlayers[i], 91, 193, 65, true)
					elseif tryResult == 2 then
						outputChatBox(" *** " .. visibleName .. " megpróbál " .. message .. " de sajnos nem sikerül neki.", pendingPlayers[i], 193, 65, 65, true)
					end
				elseif command == "megprobalja" or command == "megpróbálja" then
					if tryResult == 1 then
						outputChatBox(" *** " .. visibleName .. " megpróbálja " .. message .. " és sikerül neki.", pendingPlayers[i], 91, 193, 65, true)
					elseif tryResult == 2 then
						outputChatBox(" *** " .. visibleName .. " megpróbálja " .. message .. " de sajnos nem sikerül neki.", pendingPlayers[i], 193, 65, 65, true)
					end
				end
			end
		end
	end
)

addEvent("onOOCMessage", true)
addEventHandler("onOOCMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		if isElement(source) then
			triggerClientEvent(pendingPlayers, "onClientRecieveOOCMessage", source, message, visibleName)
		end
	end
)

addEvent("onVisualDescriptionMessage", true)
addEventHandler("onVisualDescriptionMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i]) then
				outputChatBox("#a2b7da> " .. visibleName .. " #a2b7da" .. message, pendingPlayers[i], 164, 164, 164, true)
			end
		end
	end
)

addEvent("onMegaPhoneMessage", true)
addEventHandler("onMegaPhoneMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i][1]) then
				outputChatBox("((" .. visibleName .. ")) Megaphone <O: " .. message, pendingPlayers[i][1], 255 * pendingPlayers[i][2], 150 * pendingPlayers[i][2], 0, true)
			end
		end
	end
)

addEvent("localRadioMessage", true)
addEventHandler("localRadioMessage", getRootElement(),
	function (pendingPlayers, visibleName, message)
		for i = 1, #pendingPlayers do
			if isElement(pendingPlayers[i][1]) then
				outputChatBox(pendingPlayers[i][2] .. visibleName .. " mondja (rádióba): " .. message, pendingPlayers[i][1], 255, 255, 255, true)
			end
		end
	end
)

function trunklateText(text, level)
	level = math.ceil(level * #text / 2)

	for i = 1, level do
		x = math.random(1, #text)

		if text:sub(x, x) == " " then
			i = i - 1
		else
			local a = text:sub(1, x - 1) or ""
			local b = text:sub(x + 1) or ""
			local c = ""

			if math.random(6) == 1 then
				c = string.char(math.random(65, 90))
			else
				c = string.char(math.random(97, 122))
			end

			text = a .. c .. b
		end
	end

	return text
end

function onRadioMessage(player, command, ...)
	if not getElementData(player, "loggedIn") then
		return
	end

	if exports.sarp_inventory:hasItem(player, 79) then
		local radioTune = getElementData(player, "currentRadioTune")

		if not radioTune then
			outputChatBox(exports.sarp_core:getServerTag("info") .. "Előbb vegyél elő egy walkie-talkiet!", player, 200, 50, 50, true)
		elseif not radioTune[1] or radioTune[1] == 0 then
			outputChatBox(exports.sarp_core:getServerTag("info") .. "Előbb állíts be egy frekvenciát!", player, 200, 50, 50, true)
		elseif radioTune[2] ~= "Y" then
			outputChatBox(exports.sarp_core:getServerTag("info") .. "A Walkie-Talkie beállított frekvenciája némítva van!", player, 200, 50, 50, true)
		elseif radioTune[3] then
			outputChatBox(exports.sarp_core:getServerTag("info") .. "Nincs jogosultságod a beállított frekvencia használatához!", player, 200, 50, 50, true)
		else
			local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")
		
			if #message > 0 and utf8.len(message) > 0 and utf8.len(message) <= 128 then
				local playerX, playerY, playerZ = getElementPosition(player)
				local visibleName = getElementData(player, "visibleName"):gsub("_", " ")

				local pendingPlayers = {}
				local pendingCount = 1

				local groups = exports.sarp_groups:getGroups()
				local channelGroup = false

				for k, v in pairs(groups) do
					if v.tuneRadio and v.tuneRadio > 0 and v.tuneRadio == radioTune[1] then
						channelGroup = k
						break
					end
				end

				table.insert(pendingPlayers, player)

				for k, v in ipairs(getElementsByType("player")) do
					if v ~= player then
						local radioData = exports.sarp_inventory:hasItemWithData(v, 79, "data1", radioTune[1])

						if radioData and radioData.data2 == "Y" then
							if not channelGroup then
								outputChatBox("[Rádió (CH-" .. radioTune[1] .. ")] - " .. visibleName .. ": " .. message, v, 92, 142, 206, true)
							else
								local playerGroups = getElementData(v, "player.groups") or {}

								if playerGroups[channelGroup] then
									outputChatBox("[Rádió (CH-" .. radioTune[1] .. ")] - " .. visibleName .. ": " .. message, v, 92, 142, 206, true)
								else
									outputChatBox("[Rádió (CH-" .. radioTune[1] .. ")] - GYENGE JEL: " .. trunklateText(message, 10), v, 92, 142, 206, true)
								end
							end

							table.insert(pendingPlayers, v)
							pendingCount = pendingCount + 1
						end
					end
				end

				outputChatBox("[Rádió (CH-" .. radioTune[1] .. ")] - " .. visibleName .. ": " .. message, player, 92, 142, 206, true)
				--triggerClientEvent("playRadioSound", player)
				triggerClientEvent(player, "localRadioMessage", player, message)
		
				if pendingCount > 0 then
					--triggerClientEvent(pendingPlayers, "playRadioSound", player)
					triggerClientEvent("playRadioSound", player, pendingPlayers)
				end
			end
		end
	else
		outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs nálad rádió!", player, 200, 50, 50, true)
	end
end
addCommandHandler("r", onRadioMessage)
addCommandHandler("Rádió", onRadioMessage)

addCommandHandler("d",
	function (player, command, ...)
		if not getElementData(player, "loggedIn") then
			return
		end

		if exports.sarp_inventory:hasItem(player, 79) then
			local radioTune = getElementData(player, "currentRadioTune")

			if not radioTune then
				outputChatBox(exports.sarp_core:getServerTag("info") .. "Előbb vegyél elő egy walkie-talkiet!", player, 200, 50, 50, true)
			elseif not exports.sarp_groups:isPlayerHavePermission(player, "departmentRadio") then
				outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs jogosultságod használni ezt a frekvenciát!", player, 200, 50, 50, true)
			else
				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")
			
				if #message > 0 and utf8.len(message) > 0 and utf8.len(message) <= 128 then
					local playerX, playerY, playerZ = getElementPosition(player)
					local visibleName = getElementData(player, "visibleName"):gsub("_", " ")

					local pendingPlayers = {}
					local pendingCount = 1

					table.insert(pendingPlayers, player)

					for k,v in ipairs(getElementsByType("player")) do
						if v ~= player then
							local havePermission = exports.sarp_groups:isPlayerHavePermission(v, "departmentRadio")

							if havePermission then
								outputChatBox("[Sürgősségi Rádió] - " .. visibleName .. ": " .. message, v, 215, 89, 89, true)

								table.insert(pendingPlayers, v)
								pendingCount = pendingCount + 1
							end
						end
					end

					outputChatBox("[Sürgősségi Rádió] - " .. visibleName .. ": " .. message, player, 215, 89, 89, true)
					--triggerClientEvent(player, "playRadioSound", player)
					triggerClientEvent(player, "localRadioMessage", player, message)
			
					if pendingCount > 0 then
						--triggerClientEvent(pendingPlayers, "playRadioSound", player)
						triggerClientEvent("playRadioSound", player, pendingPlayers)
					end
				end
			end
		else
			outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs nálad rádió!", player, 200, 50, 50, true)
		end
	end
)

exports.sarp_admin:addAdminCommand("a", 1, "Admin chat")
addCommandHandler("a",
	function (player, command, ...)
		if getElementData(player, "acc.adminLevel") >= 1 then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", player, 255, 255, 255, true)
			else
				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

				if #message > 0 and utf8.len(message) > 0 then
					if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
						exports.sarp_core:sendMessageToAdmins("[AdminChat] " .. exports.sarp_core:getAdminLevelColor(getElementData(player, "acc.adminLevel")) .. exports.sarp_core:getPlayerAdminTitle(player) .. " " .. (getElementData(player, "acc.adminNick") or "Admin") .. ": #ffffff" .. message)
					end
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("as", -2, "Adminsegéd chat")
addCommandHandler("as",
	function (player, command, ...)
		if getElementData(player, "acc.helperLevel") >= 1 and getElementData(player, "acc.adminLevel") ~= 0 then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", player, 255, 255, 255, true)
			else
				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

				if #message > 0 and utf8.len(message) > 0 then
					if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
						exports.sarp_core:sendMessageToAdmins("[AS Chat] " .. exports.sarp_core:getHelperLevelColor(getElementData(player, "acc.helperLevel")) .. exports.sarp_core:getPlayerHelperTitle(player) .. " " .. getElementData(player, "visibleName") .. ": #ffffff" .. message, 2)
					end
				end
			end
		end
	end
)

addCommandHandler("pm",
	function (player, command, target, ...)
		--if getElementData(player, "acc.adminLevel") >= 1 then
			if not (...) or not target then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [ID] [Üzenet]", player, 255, 255, 255, true)
			else
                local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")
                local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)
                
                if targetPlayer then
                    if getElementData(targetPlayer, "loggedIn") then
                        if #message > 0 and utf8.len(message) > 0 then
                            if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
                                if getElementData(targetPlayer, "adminDuty") then
                                    if getElementData(player, "acc.helperLevel") >= 1 and getElementData(element, "acc.adminLevel") ~= 0 then
                                        --executeCommandHandler("vá", player, target, message) -- /vá ID Üzenet
                                        outputErrorText("Használd a /vá-t", player)
                                    else
                                        triggerClientEvent(targetPlayer, "playClientSound", targetPlayer, ":sarp_assets/audio/admin/inmsg.ogg")
                                        outputInfoText(getPlayerName(player):gsub("_", " ") .. " (" .. getElementData(player, "playerID") .. ") üzenete: " .. message, targetPlayer)
                                        outputInfoText(getElementData(targetPlayer, "visibleName") .. " (" .. getElementData(targetPlayer, "playerID") .. ") számára üzenet: " .. message, player)
                                        logs:toLog("playerpm", getPlayerName(player):gsub("_", " ") .. " üzenete " .. getPlayerName(targetPlayer):gsub("_", " ") .. " játékosnak: " .. message)
                                    end
                                else
                                    outputErrorText("Csak szolgálatban lévő adminnak írhatsz!", player)
                                end
                            end
                        end
                    else
                        outputErrorText("A játékos nincs bejelentkezve", player)
                    end
                end
			end
		--end
	end
)