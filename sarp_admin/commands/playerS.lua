local jailPosX = 154.46096801758
local jailPosY = -1951.6784667969
local jailPosZ = 47.875
local jailInterior = 0

function ucpAction(action, ...)
	local args = {...}

	if action == "kick" then
		local accountId = tonumber(args[1])
		local reason = args[2]
		local adminName = args[3]
		local playerElement = false

		for k, v in ipairs(getElementsByType("player")) do
			if accountId == getElementData(v, "acc.dbID") then
				playerElement = v
				break
			end
		end

		if isElement(playerElement) then
			local targetName = getPlayerVisibleName(playerElement)

			dbExec(connection, "INSERT INTO kicks (playerAccountId, adminName, kickReason) VALUES (?,?,?)", accountId, adminName, reason)

			exports.sarp_hud:showAlert(root, "kick", adminName .. " kirúgta " .. targetName .. " játékost.", "Indok: " .. reason)
			exports.sarp_logs:toLog("adminaction", adminName .. " kirúgta " .. targetName .. " játékost: " .. reason .. " | OfflineKick")

			kickPlayer(playerElement, adminName, reason)

			return "ok"
		else
			return "A kiválasztott játékos nincs fent a szerveren!"
		end
	elseif action == "jail" then
		local accountId = tonumber(args[1])
		local reason = args[2]
		local adminName = args[3]
		local duration = tonumber(args[4])
		local now = getRealTime().timestamp
		local playerElement = false
		local jailInfo = now .. "/" .. utf8.gsub(reason, "/", ";") .. "/" .. duration .. "/" .. adminName

		dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?; INSERT INTO adminjails (accountID, jailTimestamp, reason, duration, adminName) VALUES (?,?,?,?,?)", jailInfo, duration, accountId, accountId, now, reason, duration, adminName)

		for k, v in ipairs(getElementsByType("player")) do
			if accountId == getElementData(v, "acc.dbID") then
				playerElement = v
				break
			end
		end

		if isElement(playerElement) then
			local playerName = getPlayerVisibleName(playerElement)
			
			removePedFromVehicle(playerElement)
			setElementPosition(playerElement, jailPosX, jailPosY, jailPosZ)
			setElementInterior(playerElement, jailInterior)
			setElementDimension(playerElement, accountId + math.random(1, 100))

			setElementData(playerElement, "acc.adminJail", jailInfo)
			setElementData(playerElement, "acc.adminJailTime", duration)

			exports.sarp_hud:showAlert(root, "jail", adminName .. " bebörtönözte " .. playerName .. " játékost", "Időtartam: " .. duration .. " perc, Indok: " .. reason)
		end

		return "ok"
	elseif action == "ban" then
		local accountId = tonumber(args[1])
		local reason = args[2]
		local adminName = args[3]
		local duration = tonumber(args[4])
		local serial = args[5]
		local username = args[6]

		local currentTime = getRealTime().timestamp
		local expireTime = currentTime

		if duration == 0 then
			expireTime = currentTime + 31536000 * 100
		else
			expireTime = currentTime + duration * 3600
		end

		dbExec(connection, "INSERT INTO bans (playerSerial, playerName, playerAccountId, banReason, adminName, banTimestamp, expireTimestamp, isActive) VALUES (?,?,?,?,?,?,?,'Y'); UPDATE accounts SET suspended = 'Y' WHERE accountID = ?", serial, username, accountId, reason, adminName, currentTime, expireTime, accountId)

		local playerElement = false

		for k, v in ipairs(getElementsByType("player")) do
			if accountId == getElementData(v, "acc.dbID") then
				playerElement = v
				break
			end
		end

		if isElement(playerElement) then
			local playerName = getPlayerVisibleName(playerElement)

			exports.sarp_hud:showAlert(root, "ban", adminName .. " kitiltotta " .. playerName .. " játékost.", "Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason)

			kickPlayer(playerElement, adminName, reason)

			exports.sarp_logs:toLog("adminaction", adminName .. " kitiltotta " .. playerName .. " játékost (Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason .. ") | OfflineBan")
		end

		return "ok"
	end
end

addEvent("getPlayerOutOfJail", true)
addEventHandler("getPlayerOutOfJail", getRootElement(),
	function()
		if isElement(source) then
			setElementPosition(source, 1478.8834228516, -1739.0384521484, 13.546875)
			setElementInterior(source, 0)
			setElementDimension(source, 0)
		end
	end)

addEvent("movePlayerBackToAdminJail", true)
addEventHandler("movePlayerBackToAdminJail", getRootElement(),
	function()
		if isElement(source) then
			local accountId = getElementData(source, "acc.dbID")

			if accountId then
				spawnPlayer(source, jailPosX, jailPosY, jailPosZ, 0, playerSkin, jailInterior, accountId + math.random(100))
				setCameraTarget(source, source)
			end
		end
	end)

addAdminCommand("unajail", 1, "Játékos kivétele az admin börtönből")
addCommandHandler("unajail",
	function(sourcePlayer, commandName, targetPlayer, ...)
		if havePermission(sourcePlayer, commandName, true) then
			if not (targetPlayer and (...)) then
				outputUsageText(commandName, "[Játékos név / ID] [Indok]", sourcePlayer)
			else
				targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

				if targetPlayer then
					local accountId = getElementData(targetPlayer, "acc.dbID") or 0
					if accountId > 0 then
						if (getElementData(targetPlayer, "acc.adminJail") or 0) ~= 0 then
							local reason = table.concat({...}, " ")
							if utf8.len(reason) > 0 then
								local adminName = getPlayerAdminNick(sourcePlayer)
								local targetPlayerName = getPlayerVisibleName(targetPlayer)

								dbQuery(
									function(qh, sourcePlayer, targetPlayer, adminName, targetPlayerName, reason)
										dbFree(qh)

										if isElement(targetPlayer) then
											setElementData(targetPlayer, "acc.adminJail", 0)
											setElementData(targetPlayer, "acc.adminJailTime", 0)

											triggerEvent("getPlayerOutOfJail", targetPlayer)
										end

										exports.sarp_core:sendMessageToAdmins(adminName .. " kivette " .. targetPlayerName .. " játékost az adminbörtönből. Indok: " .. reason)
										exports.sarp_logs:toLog("adminaction", adminName .. " kivette " .. targetPlayerName .. " játékost az adminbörtönből. Indok: " .. reason)

									end, {sourcePlayer, targetPlayer, adminName, targetPlayerName, reason}, connection, "UPDATE accounts SET adminJail = 'N', adminJailTime = '0' WHERE accountID = ?", accountId)
							else
								outputErrorText("Nem adtad meg a börtönből kivétel okát!", sourcePlayer)
							end
						else
							outputErrorText("A kiválasztott játékos nincs adminbörtönben!", sourcePlayer)
						end
					end
				end
			end
		end
	end)

addAdminCommand("ajail", 1, "Játékos adminbörtönzése")
addCommandHandler("ajail",
	function(sourcePlayer, commandName, targetPlayer, duration, ...)
		if havePermission(sourcePlayer, commandName, true) then
			duration = tonumber(duration)

			if not (targetPlayer and duration and (...)) then
				outputUsageText(commandName, "[Játékos név / ID] [Perc] [Indok]", sourcePlayer)
			else
				targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

				if targetPlayer then
					duration = math.floor(duration)

					if duration > 0 then
						local accountId = getElementData(targetPlayer, "acc.dbID") or 0
						if accountId > 0 then
							local reason = table.concat({...}, " ")
							if utf8.len(reason) > 0 then
								local now = getRealTime().timestamp
								local adminName = getPlayerAdminNick(sourcePlayer)
								local targetPlayerName = getPlayerVisibleName(targetPlayer)
								local jailInfo = now .. "/" .. utf8.gsub(reason, "/", ";") .. "/" .. duration .. "/" .. adminName

								dbQuery(
									function(qh, targetPlayer, jailInfo, duration, accountId, adminName, targetPlayerName, reason)
										dbFree(qh)
										dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", jailInfo, duration, accountId)

										if isElement(targetPlayer) then
											removePedFromVehicle(targetPlayer)
											setElementPosition(targetPlayer, jailPosX, jailPosY, jailPosZ)
											setElementInterior(targetPlayer, jailInterior)
											setElementDimension(targetPlayer, accountId + math.random(1, 100))

											setElementData(targetPlayer, "acc.adminJail", jailInfo)
											setElementData(targetPlayer, "acc.adminJailTime", duration)
										end

										exports.sarp_hud:showAlert(root, "jail", adminName .. " bebörtönözte " .. targetPlayerName .. " játékost", "Időtartam: " .. duration .. " perc, Indok: " .. reason)

									end, {targetPlayer, jailInfo, duration, accountId, adminName, targetPlayerName, reason}, connection, "INSERT INTO adminjails (accountID, jailTimestamp, reason, duration, adminName) VALUES (?,?,?,?,?)", accountId, now, reason, duration, adminName)
							else
								outputErrorText("Nem adtad meg a börtönzés okát!", sourcePlayer)
							end
						end
					else
						outputErrorText("Az időtartamnak nagyobbnak kell lennie nullánál!", sourcePlayer)
					end
				end
			end
		end
	end)

addAdminCommand("giveitem", 6, "Tárgy adás")
addCommandHandler("giveitem", function(sourcePlayer, commandName, targetPlayer, itemId, amount, data1, data2, data3)
	if havePermission(sourcePlayer, commandName, true) then
		if not (targetPlayer and itemId) then
			outputUsageText(commandName, "[Játékos név / ID] [Item ID] [Mennyiség] [ < Data 1 | Data 2 | Data 3 > ]", sourcePlayer)
		else
			itemId = tonumber(itemId)
			amount = tonumber(amount)

			if itemId and amount then
				targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

				if targetPlayer then
					local state = exports.sarp_inventory:addItem(targetPlayer, itemId, amount, false, data1, data2, data3)

					if state then
						local itemName = exports.sarp_inventory:getItemName(itemId)
						local adminNick = getPlayerAdminNick(sourcePlayer)
						local targetName = getPlayerVisibleName(targetPlayer)

						outputInfoText("#32b3ef" .. adminNick .. " #ffffffadott neked egy #32b3ef" .. itemName .. " #ffffffnevű tárgyat.", targetPlayer)
						outputInfoText("Sikeresen adtál #32b3ef" .. targetName .. " #ffffffjátékosnak egy #32b3ef" .. itemName .. " #ffffffnevű tárgyat. #4aabd0(Mennyiség: " .. amount .. " | data1: " .. tostring(data1) .. " | data2: " .. tostring(data2) .. " | data3: " .. tostring(data3) .. ")", sourcePlayer)
					
						exports.sarp_logs:toLog("adminaction", adminNick .. " (" .. getElementData(sourcePlayer, "acc.ID") .. ") - itemId: " .. itemId .. " | mennyiség: " .. amount .. " | data1: " .. tostring(data1) .. " | data2: " .. tostring(data2) .. " | data3: " .. tostring(data3))
					else
						outputErrorText("Az item odaadás meghiúsult.", sourcePlayer)
					end
				end
			end
		end
	end
end)

addAdminCommand("setmoney", 6, "Játékos pénz beállítása")
addCommandHandler("setmoney", function(sourcePlayer, commandName, targetPlayer, value)
	if havePermission(sourcePlayer, commandName, true) then
		value = tonumber(value)

		if not (targetPlayer and value) then
			outputUsageText(commandName, "[Játékos név / ID] [Összeg]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				value = math.floor(value)

				exports.sarp_core:setMoney(targetPlayer, value)

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				outputInfoText("Átállítottad #32b3ef" .. targetName .. " #ffffffjátékos pénz összegét #d75959" .. value .. "$#ffffff-ra", sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffátállította a pénz összegedet #32b3ef" .. value .. "$#ffffff-ra", targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .. " átállította " .. targetName .. " játékos pénz összegét " .. value .. "$-ra")
				exports.sarp_logs:toLog("adminaction", adminNick .. " átállította " .. targetName .. " játékos pénz összegét " .. value .. "$-ra")
			end
		end
	end
end)

addAdminCommand("takemoney", 6, "Játékostól pénz elvétel")
addCommandHandler("takemoney", function(sourcePlayer, commandName, targetPlayer, value)
	if havePermission(sourcePlayer, commandName, true) then
		value = tonumber(value)

		if not (targetPlayer and value) then
			outputUsageText(commandName, "[Játékos név / ID] [Összeg]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				value = math.floor(value)

				exports.sarp_core:takeMoneyEx(targetPlayer, value, "admin-takeEx")

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)
				
				outputInfoText("Elvettél #32b3ef" .. targetName .. " #ffffffjátékostól #d75959" .. value .. "$#ffffff-t", sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffelvett tőled #32b3ef" .. value .. "$#ffffff-t", targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .. " elvett " .. targetName .. " játékostól " .. value .. "$-t")
				exports.sarp_logs:toLog("adminaction", adminNick .. " elvett " .. targetName .. " játékostól " .. value .. "$-t")
			end
		end
	end
end)

addAdminCommand("givemoney", 6, "Játékosnak pénz adás")
addCommandHandler("givemoney", function(sourcePlayer, commandName, targetPlayer, value)
	if havePermission(sourcePlayer, commandName, true) then
		value = tonumber(value)

		if not (targetPlayer and value) then
			outputUsageText(commandName, "[Játékos név / ID] [Összeg]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				value = math.floor(value)

				exports.sarp_core:giveMoney(targetPlayer, value, "admin-give")

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)
				
				outputInfoText("Adtál #32b3ef" .. targetName .. " #ffffffjátékosnak #d75959" .. value .. "$#ffffff-t", sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffadott neked #32b3ef" .. value .. "$#ffffff-t", targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .. " adott " .. targetName .. " játékosnak " .. value .. "$-t")
				exports.sarp_logs:toLog("adminaction", adminNick .. " adott " .. targetName .. " játékosnak " .. value .. "$-t")
			end
		end
	end
end)

addAdminCommand("changename", 6, "Játékos nevének megváltoztatása")
addCommandHandler("changename", function(sourcePlayer, commandName, targetPlayer, newName)
	if havePermission(sourcePlayer, commandName, true) then
		if not (targetPlayer and newName) then
			outputUsageText(commandName, "[Játékos név / ID] [Név]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local accountId = getElementData(targetPlayer, "char.ID") or 0
				if accountId > 0 then
					if not getElementData(targetPlayer, "adminDuty") then
						local adminName = getPlayerAdminNick(sourcePlayer)
						local currentName = getPlayerVisibleName(targetPlayer)

						newName = newName:gsub(" ", "_")

						dbQuery(
							function(qh, sourcePlayer, targetPlayer)
								local result, numAffectedRows = dbPoll(qh, 0)

								if numAffectedRows > 0 then
									outputErrorText("A kiválasztott név már foglalt!", sourcePlayer)
								else
									dbExec(connection, "UPDATE characters SET name = ? WHERE charID = ?", newName, accountId)

									if isElement(targetPlayer) then
										setPlayerName(targetPlayer, newName)
										setPlayerNametagText(targetPlayer, newName)
										setElementData(targetPlayer, "visibleName", newName)
										setElementData(targetPlayer, "char.Name", newName)

										outputInfoText("#32b3ef" .. adminName .." megváltoztatta nevedet a következőre: #32b3ef" .. newName:gsub("_", " "), targetPlayer)
									end

									if isElement(sourcePlayer) then
										outputInfoText("Sikeresen megváltoztattad #32b3ef" .. currentName .. " #ffffffnevét a következőre: #32b3ef" .. newName:gsub("_", " "), sourcePlayer)
									end

									exports.sarp_core:sendMessageToAdmins(adminName .. " megváltoztatta " .. currentName .. " nevét a következőre: " .. newName:gsub("_", " "))
									exports.sarp_logs:toLog("adminaction", adminName .." megváltoztatta " .. currentName .. " nevét a következőre: " .. newName:gsub("_", " ") .. ".")
								end
							end, {sourcePlayer, targetPlayer}, connection, "SELECT name FROM characters WHERE name = ? LIMIT 1", newName)
					else
						outputErrorText("A kiválasztott játékos adminszolgálatban van!", sourcePlayer)
					end
				end
			end
		end
	end
end)

addAdminCommand("setarmor", 1, "Játékos páncél szintjének beállítása")
addCommandHandler("setarmor", function(sourcePlayer, commandName, targetPlayer, Armor)
	if havePermission(sourcePlayer, commandName, true) then
		Armor = tonumber(Armor)

		if not (targetPlayer and Armor) then
			outputUsageText(commandName, "[Játékos név / ID] [Érték]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				Armor = math.floor(Armor)

				if Armor < 0 or Armor > 100 then
					outputErrorText("A páncélzat nem lehet kisebb mint 0 és nem lehet nagyobb mint 100!", sourcePlayer)
					return
				end

				setPedArmor(targetPlayer, Armor)

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				outputInfoText("Átállítottad #32b3ef" .. targetName .. " #ffffffpáncélzatát a következőre: #32b3ef" .. Armor, sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffátállította a páncélzatod a következőre: #32b3ef" .. Armor, targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .." átállította " .. targetName .. " páncélzatát a következőre: " .. Armor .. ".")
				exports.sarp_logs:toLog("adminaction", adminNick .." átállította " .. targetName .. " páncélzatát a következőre: " .. Armor .. ".")
			end
		end
	end
end)

addAdminCommand("setskin", 1, "Játékos kinézetének beállítása")
addCommandHandler("setskin", function(sourcePlayer, commandName, targetPlayer, skin)
	if havePermission(sourcePlayer, commandName, true) then
		skin = tonumber(skin)

		if not (targetPlayer and skin) then
			outputUsageText(commandName, "[Játékos név / ID] [Skin ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				skin = math.floor(skin)

				if setElementModel(targetPlayer, skin) then
					local adminNick = getPlayerAdminNick(sourcePlayer)
					local targetName = getPlayerVisibleName(targetPlayer)

					outputInfoText("Átállítottad #32b3ef" .. targetName .. " #ffffffkinézetét a következőre: #32b3ef" .. skin, sourcePlayer)
					outputInfoText("#32b3ef" .. adminNick .. " #ffffffátállította a kinézeted a következőre: #32b3ef" .. skin, targetPlayer)
					
					exports.sarp_core:sendMessageToAdmins(adminNick .." átállította " .. targetName .. " kinézetét a következőre: " .. skin .. ".")
					exports.sarp_logs:toLog("adminaction", adminNick .." átállította " .. targetName .. " kinézetét a következőre: " .. skin .. ".")
				else
					outputErrorText("A kiválasztott skin nem létezik!", sourcePlayer)
				end
			end
		end
	end
end)

addAdminCommand("makehelper", 4, "Játékos adminsegéd szintjének beállítása")
addCommandHandler("makehelper", function(sourcePlayer, commandName, targetPlayer, helperLevel)
	if havePermission(sourcePlayer, commandName, true) then
		helperLevel = tonumber(helperLevel)

		if not (targetPlayer and helperLevel) then
			outputUsageText(commandName, "[Játékos név / ID] [Szint | 1 = Ideiglenes | 2 = Végleges]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				helperLevel = math.floor(helperLevel)

				if helperLevel < 0 or helperLevel > 2 then
					outputErrorText("A szint nem lehet kisebb mint 0 és nem lehet nagyobb mint 2!", sourcePlayer)
					return
				end

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				setElementData(targetPlayer, "acc.helperLevel", helperLevel)
				
				dbExec(connection, "UPDATE accounts SET helperLevel = ? WHERE accountID = ?", helperLevel, getElementData(targetPlayer, "acc.dbID"))
				
				outputInfoText("Megváltoztattad #32b3ef" .. targetName .. " #ffffffadminsegéd szintjét a következőre: #32b3ef" .. helperLevel, sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffmegváltoztatta az adminsegéd szinted a következőre: #32b3ef" .. helperLevel, targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .." megváltoztatta " .. targetName .. " adminsegéd szintjét a következőre: " .. helperLevel .. ".")
				exports.sarp_logs:toLog("adminaction", adminNick .." megváltoztatta " .. targetName .. " adminsegéd szintjét a következőre: " .. helperLevel .. ".")
			end
		end
	end
end)

addAdminCommand("makeadmin", 7, "Játékos adminszintjének beállítása")
addCommandHandler("makeadmin", function(sourcePlayer, commandName, targetPlayer, adminLevel)
	if havePermission(sourcePlayer, commandName, true) then
		adminLevel = tonumber(adminLevel)

		if not (targetPlayer and adminLevel) then
			outputUsageText(commandName, "[Játékos név / ID] [Szint]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				adminLevel = math.floor(adminLevel)

				if adminLevel < 0 or adminLevel > 11 then
					outputErrorText("A szint nem lehet kisebb mint 0 és nem lehet nagyobb mint 11!", sourcePlayer)
					return
				end

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				if adminLevel == 0 then
					local charName = getPlayerCharacterName(targetPlayer):gsub(" ", "_")

					setElementData(targetPlayer, "adminDuty", false)
					setPlayerName(targetPlayer, charName)
					setPlayerNametagText(targetPlayer, charName)
					setElementData(targetPlayer, "visibleName", charName)
				end

				setElementData(targetPlayer, "acc.adminLevel", adminLevel)
				
				dbExec(connection, "UPDATE accounts SET adminLevel = ? WHERE accountID = ?", adminLevel, getElementData(targetPlayer, "acc.dbID"))
				
				outputInfoText("Megváltoztattad #32b3ef" .. targetName .. " #ffffffadminszintjét a következőre: #32b3ef" .. adminLevel, sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffmegváltoztatta az adminszinted a következőre: #32b3ef" .. adminLevel, targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .." megváltoztatta " .. targetName .. " adminszintjét a következőre: " .. adminLevel .. ".")
				exports.sarp_logs:toLog("adminaction", adminNick .." megváltoztatta " .. targetName .. " adminszintjét a következőre: " .. adminLevel .. ".")
			end
		end
	end
end)

addAdminCommand("sethp", 1, "Játékos életerejének beállítása")
addCommandHandler("sethp", function(sourcePlayer, commandName, targetPlayer, HP)
	if havePermission(sourcePlayer, commandName, true) then
		HP = tonumber(HP)

		if not (targetPlayer and HP) then
			outputUsageText(commandName, "[Játékos név / ID] [Érték]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				HP = math.floor(HP)

				if HP < 0 or HP > 100 then
					outputErrorText("Az életerő nem lehet kisebb mint 0 és nem lehet nagyobb mint 100!", sourcePlayer)
					return
				end

				setElementHealth(targetPlayer, HP)

				triggerEvent("removeAllInjuries", targetPlayer, targetPlayer)

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				outputInfoText("Megváltoztattad #32b3ef" .. targetName .. " #fffffféleterejét a következőre: #32b3ef" .. HP, sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffmegváltoztatta az életerődet a következőre: #32b3ef" .. HP, targetPlayer)
				
				exports.sarp_core:sendMessageToAdmins(adminNick .." megváltoztatta " .. targetName .. " életerejét a következőre: " .. HP .. ".")
				exports.sarp_logs:toLog("adminaction", adminNick .." megváltoztatta " .. targetName .. " életerejét a következőre: " .. HP .. ".")
			end
		end
	end
end)

addAdminCommand("setadminnick", 6, "Adminisztrátori név módosítása")
addCommandHandler("setadminnick", function(sourcePlayer, commandName, targetPlayer, adminName)
	if havePermission(sourcePlayer, commandName, true) then
		if not (targetPlayer and adminName) then
			outputUsageText(commandName, "[Játékos név / ID] [Admin nick]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				dbExec(connection, "UPDATE accounts SET adminNick = ? WHERE accountID = ?", adminName, getElementData(targetPlayer, "acc.dbID"))
				
				setElementData(targetPlayer, "acc.adminNick", adminName)

				if getElementData(targetPlayer, "adminDuty") then
					setElementData(targetPlayer, "visibleName", adminName)
				end

				outputInfoText("Megváltoztattad #32b3ef" .. targetName .. " #ffffffadmin nevét a következőre: #32b3ef" .. adminName, sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #ffffffmegváltoztatta az adminneved a következőre: #32b3ef" .. adminName, targetPlayer)
			   
				exports.sarp_core:sendMessageToAdmins(adminNick .. " megváltoztatta " .. targetName .. " admin becenevét a következőre: " .. adminName .. ".")
				exports.sarp_logs:toLog("adminaction", adminNick .. " megváltoztatta " .. targetName .. " admin becenevét a következőre: " .. adminName .. ".")
			end
		end
	end
end)

addAdminCommand("unfreeze", 1, "Játékos kifagyasztása")
addCommandHandler("unfreeze", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local pedveh = getPedOccupiedVehicle(targetPlayer)

				if pedveh then
					setElementFrozen(pedveh, false)
				end

				setElementFrozen(targetPlayer, false)

				exports.sarp_controls:toggleControl(targetPlayer, "all", true)

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				outputInfoText("Levetted a fagyasztást #32b3ef" .. targetName .. " #ffffffjátékosról.", sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #fffffflevette rólad a fagyasztást.", targetPlayer)
			end
		end
	end
end)

addAdminCommand("freeze", 1, "Játékos lefagyasztása")
addCommandHandler("freeze", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local pedveh = getPedOccupiedVehicle(targetPlayer)

				if pedveh then
					setElementFrozen(pedveh, true)
				end

				setElementFrozen(targetPlayer, true)

				exports.sarp_controls:toggleControl(targetPlayer, "all", false)

				local adminNick = getPlayerAdminNick(sourcePlayer)
				local targetName = getPlayerVisibleName(targetPlayer)

				outputInfoText("Sikeresen lefagyasztottad #32b3ef" .. targetName .. " #ffffffjátékost.", sourcePlayer)
				outputInfoText("#32b3ef" .. adminNick .. " #fffffflefagyasztott téged.", targetPlayer)
			end
		end
	end
end)

addAdminCommand("freconnect", 5, "Játékos újracsatlakoztatása")
addCommandHandler("freconnect", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				if sourcePlayer ~= targetPlayer then
					if not getElementData(targetPlayer, "adminDuty") or getElementData(sourcePlayer, "acc.adminLevel") >= 9 then
						local adminNick = getPlayerAdminNick(sourcePlayer)
						local targetName = getPlayerVisibleName(targetPlayer)

						redirectPlayer(targetPlayer)

						outputInfoText("#32b3ef" .. targetName .. " #ffffffjátékos újracsatlakoztatva.", sourcePlayer)
						
						exports.sarp_core:sendMessageToAdmins(sourcePlayer .. " újracsatlakoztatta " .. targetName .. " játékost")
						exports.sarp_logs:toLog("adminaction", sourcePlayer .. " újracsatlakoztatta " .. targetName .. " játékost")
					else
						outputErrorText("Szolgálatban lévő admint nem kényszerítheted az újracsatlakozásra.", sourcePlayer)
					end
				else
					outputErrorText("Magadat nem csatlakoztathatod újra.", sourcePlayer)
				end
			end
		end
	end
end)

addAdminCommand("vá", 1, "Válasz a játékosnak")
addCommandHandler("vá", function(sourcePlayer, commandName, targetPlayer, ...)
	if havePermission(sourcePlayer, commandName, true) then
		if not (targetPlayer and (...)) then
			outputUsageText(commandName, "[Játékos név / ID] [Üzenet]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				if sourcePlayer ~= targetPlayer then
					if not getElementData(targetPlayer, "adminDuty") then
						local text = table.concat({...}, " ")

						if utf8.len(text) > 0 then
							local adminNick = getPlayerAdminNick(sourcePlayer)
							local targetName = getPlayerVisibleName(targetPlayer)

							outputInfoText("Válaszod #32b3ef" .. targetName .. " #ffffffszámára: " .. text, sourcePlayer)
							outputInfoText("#32b3ef" .. adminNick .. " #ffffffválasza: " .. text, targetPlayer)

							triggerClientEvent(sourcePlayer, "playClientSound", sourcePlayer, ":sarp_assets/audio/admin/outmsg.ogg")
							triggerClientEvent(targetPlayer, "playClientSound", targetPlayer, ":sarp_assets/audio/admin/inmsg.ogg")

							exports.sarp_core:sendMessageToAdmins(adminNick .. " válaszolt " .. targetName .. " játékosnak: " .. text)
							exports.sarp_logs:toLog("adminmsg", adminNick .. " üzenete " .. targetName .. " játékosnak: " .. text)
						end
					else
						outputErrorText("Szolgálatban lévő adminnak nem válaszolhatsz.", sourcePlayer)
					end
				else
					outputErrorText("Magadnak nem válaszolhatsz.", sourcePlayer)
				end
			end
		end
	end
end)

addAdminCommand("goto", 1, "Teleportálás egy játékoshoz")
addCommandHandler("goto", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local x, y, z = getElementPosition(targetPlayer)
				local interior = getElementInterior(targetPlayer)
				local dimension = getElementDimension(targetPlayer)
				local rotation = getPedRotation(targetPlayer)

				x = x + math.cos(math.rad(rotation)) * 2
				y = y + math.sin(math.rad(rotation)) * 2
			
				local customInterior = tonumber(getElementData(targetPlayer, "currentCustomInterior") or 0)
				if customInterior and customInterior > 0 then
					triggerClientEvent(sourcePlayer, "loadCustomInterior", sourcePlayer, customInterior)
				end
				
				if isPedInVehicle(sourcePlayer) then
					local pedveh = getPedOccupiedVehicle(sourcePlayer)

					setVehicleTurnVelocity(pedveh, 0, 0, 0)
					setElementInterior(pedveh, interior)
					setElementDimension(pedveh, dimension)
					setElementPosition(pedveh, x, y, z + 1)

					setElementInterior(sourcePlayer, interior)
					setElementDimension(sourcePlayer, dimension)
					setCameraInterior(sourcePlayer, interior)

					warpPedIntoVehicle(sourcePlayer, pedveh)
					setTimer(setVehicleTurnVelocity, 50, 20, pedveh, 0, 0, 0)
				else
					setElementPosition(sourcePlayer, x, y, z)
					setElementInterior(sourcePlayer, interior)
					setElementDimension(sourcePlayer, dimension)
					setCameraInterior(sourcePlayer, interior)
				end

				outputInfoText("#32b3ef" .. getPlayerAdminNick(sourcePlayer) .. " #ffffffhozzád teleportált.", targetPlayer)
				outputInfoText("Sikeresen elteleportáltál #32b3ef" .. getPlayerVisibleName(targetPlayer) .. " #ffffffjátékoshoz.", sourcePlayer)
			end
		end
	end
end)

addAdminCommand("gethere", 1, "Játékos magadhoz teleportálása")
addCommandHandler("gethere", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local x, y, z = getElementPosition(sourcePlayer)
				local interior = getElementInterior(sourcePlayer)
				local dimension = getElementDimension(sourcePlayer)
				local rotation = getPedRotation(sourcePlayer)

				x = x + math.cos(math.rad(rotation)) * 2
				y = y + math.sin(math.rad(rotation)) * 2

				setElementFrozen(targetPlayer, true)
			
				local customInterior = tonumber(getElementData(sourcePlayer, "currentCustomInterior") or 0)
				if customInterior and customInterior > 0 then
					triggerClientEvent(targetPlayer, "loadCustomInterior", targetPlayer, customInterior)
				end
				
				if isPedInVehicle(targetPlayer) then
					local pedveh = getPedOccupiedVehicle(targetPlayer)

					setVehicleTurnVelocity(pedveh, 0, 0, 0)
					setElementInterior(pedveh, interior)
					setElementDimension(pedveh, dimension)
					setElementPosition(pedveh, x, y, z + 1)

					setTimer(setVehicleTurnVelocity, 50, 20, pedveh, 0, 0, 0)
				else
					setElementPosition(targetPlayer, x, y, z)
					setElementInterior(targetPlayer, interior)
					setElementDimension(targetPlayer, dimension)
				end

				setElementFrozen(targetPlayer, false)

				outputInfoText("#32b3ef" .. getPlayerAdminNick(sourcePlayer) .. " #ffffffmagához teleportált.", targetPlayer)
				outputInfoText("Sikeresen magadhoz teleportáltad #32b3ef" .. getPlayerVisibleName(targetPlayer) .. " #ffffffjátékost.", sourcePlayer)
			end
		end
	end
end)

addEvent("updateSpectatePosition", true)
addEventHandler("updateSpectatePosition", getRootElement(),
	function (interior, dimension, customInterior)
		if isElement(source) then
			setElementInterior(source, interior)
			setElementDimension(source, dimension)
			setCameraInterior(source, interior)

			if customInterior and customInterior > 0 then
				triggerClientEvent(source, "loadCustomInterior", source, customInterior)
			end
		end
	end
)
	
addAdminCommand("spec", 6, "Játékos figyelése")
addCommandHandler("spec", function(sourcePlayer, commandName, targetPlayer)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer then
			outputUsageText(commandName, "[Játékos név / ID]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				local adminNick = getPlayerAdminNick(sourcePlayer)

				if targetPlayer == sourcePlayer then -- ha a célszemély saját maga, kapcsolja ki a nézelődést
					local playerLastPos = getElementData(sourcePlayer, "playerLastPos")

					if playerLastPos then -- ha tényleg nézelődött
						local currentTarget = getElementData(sourcePlayer, "spectateTarget") -- nézett játékos lekérése
						local spectatingPlayers = getElementData(currentTarget, "spectatingPlayers") or {} -- nézett játékos nézelődőinek lekérése

						spectatingPlayers[sourcePlayer] = nil -- kivesszük a parancs használóját a nézett játékos nézelődői közül
						setElementData(currentTarget, "spectatingPlayers", spectatingPlayers) -- elmentjük az úrnak

						setElementAlpha(sourcePlayer, 255)
						setElementInterior(sourcePlayer, playerLastPos[4])
						setElementDimension(sourcePlayer, playerLastPos[5])
						setCameraInterior(sourcePlayer, playerLastPos[4])
						setCameraTarget(sourcePlayer, sourcePlayer)
						setElementFrozen(sourcePlayer, false)
						setElementCollisionsEnabled(sourcePlayer, true)
						setElementPosition(sourcePlayer, playerLastPos[1], playerLastPos[2], playerLastPos[3])
						setElementRotation(sourcePlayer, 0, 0, playerLastPos[6])

						removeElementData(sourcePlayer, "spectateTarget")
						removeElementData(sourcePlayer, "playerLastPos")

						local targetName = getPlayerVisibleName(currentTarget)

						outputInfoText("Kikapcsoltad #32b3ef" .. targetName .. " #ffffffjátékos nézését.", sourcePlayer)
						exports.sarp_core:sendMessageToAdmins("#32b3ef" .. adminNick .. " #ffffffbefejezte #32b3ef" .. targetName .. " #ffffffjátékos nézését.")
					end
				else
					local targetInterior = getElementInterior(targetPlayer)
					local targetDimension = getElementDimension(targetPlayer)
					local currentTarget = getElementData(sourcePlayer, "spectateTarget")
					local playerLastPos = getElementData(sourcePlayer, "playerLastPos")

					if currentTarget and currentTarget ~= targetPlayer then -- ha a jelenleg nézett célszemély nem az új célszemély vegye ki a nézelődők listájából
						local spectatingPlayers = getElementData(currentTarget, "spectatingPlayers") or {} -- jelenleg nézett célszemély nézelődői

						spectatingPlayers[sourcePlayer] = nil -- eltávolítjuk az eddig nézett játékos nézelődői közül
						setElementData(currentTarget, "spectatingPlayers", spectatingPlayers) -- elmentjük a változásokat
					end

					if not playerLastPos then -- ha eddig nem volt nézelődő módban, mentse el a jelenlegi pozícióját
						local localX, localY, localZ = getElementPosition(sourcePlayer)
						local localRotX, localRotY, localRotZ = getElementPosition(sourcePlayer)
						local localInterior = getElementInterior(sourcePlayer)
						local localDimension = getElementDimension(sourcePlayer)

						setElementData(sourcePlayer, "playerLastPos", {localX, localY, localZ, localInterior, localDimension, localRotZ}, false)
					end

					setElementAlpha(sourcePlayer, 0)
					setPedWeaponSlot(sourcePlayer, 0)
					setElementInterior(sourcePlayer, targetInterior)
					setElementDimension(sourcePlayer, targetDimension)
					setCameraInterior(sourcePlayer, targetInterior)
					setCameraTarget(sourcePlayer, targetPlayer)
					setElementFrozen(sourcePlayer, true)
					setElementCollisionsEnabled(sourcePlayer, false)

					local spectatingPlayers = getElementData(targetPlayer, "spectatingPlayers") or {} -- lekérjük az új úrfi jelenlegi nézelődőit

					spectatingPlayers[sourcePlayer] = true -- hozzáadjuk az úrfi nézelődőihez a parancs használóját
					setElementData(targetPlayer, "spectatingPlayers", spectatingPlayers) -- elmentjük az úrfinak a változásokat

					setElementData(sourcePlayer, "spectateTarget", targetPlayer)

					local targetName = getPlayerVisibleName(targetPlayer)

					outputInfoText("Elkezdted nézni #32b3ef" .. targetName .. " #ffffffjátékost.", sourcePlayer)
					exports.sarp_core:sendMessageToAdmins("#32b3ef" .. adminNick .. " #ffffffelkezdte nézni #32b3ef" .. targetName .. " #ffffffjátékost.")
				end
			end
		end
	end
end)

addAdminCommand("kick", 1, "A játékos kirúgása")
addCommandHandler("kick", function(sourcePlayer, commandName, targetPlayer, ...)
	if havePermission(sourcePlayer, commandName, true) then
		if not targetPlayer or not ... then
			outputUsageText(commandName, "[Játékos név / ID] [Indok]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				if sourcePlayer ~= targetPlayer then
					if not getElementData(targetPlayer, "adminDuty") or getElementData(sourcePlayer, "acc.adminLevel") >= 9 then
						local reason = table.concat({...}, " ")

						if utf8.len(reason) > 0 then
							local adminNick = getPlayerAdminNick(sourcePlayer)
							local targetName = getPlayerVisibleName(targetPlayer)
							local targetAccountId = getElementData(targetPlayer, "acc.ID") or 0

							kickPlayer(targetPlayer, sourcePlayer, reason)

							exports.sarp_hud:showAlert(root, "kick", adminNick .. " kirúgta " .. targetName .. " játékost.", "Indok: " .. reason)
							exports.sarp_logs:toLog("adminaction", adminNick .. " kirúgta " .. targetName .. " játékost: " .. reason)

							dbExec(connection, "INSERT INTO kicks (playerAccountId, adminName, kickReason) VALUES (?,?,?)", targetAccountId, adminNick, reason)
						else
							outputErrorText("Előbb add meg a kirúgás okát!", sourcePlayer)
						end
					else
						outputErrorText("Szolgálatban lévő admint nem rúghatsz ki.", sourcePlayer)
					end
				else
					outputErrorText("Magadat nem rúghatod ki.", sourcePlayer)
				end
			end
		end
	end
end)

addAdminCommand("ban", 2, "A játékos kitiltása")
addCommandHandler("ban",
	function(sourcePlayer, commandName, targetPlayer, duration, ...)
		duration = tonumber(duration)

		if not (targetPlayer and duration and (...)) then
			outputUsageText(commandName, "[Játékos név / ID] [Óra | 0 = örök] [Indok]", sourcePlayer)
		else
			targetPlayer = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				if sourcePlayer ~= targetPlayer then
					local targetSerial = getPlayerSerial(targetPlayer)

					if not protectedSerials[targetSerial] or getElementData(sourcePlayer, "acc.adminLevel") >= 8 then
						local reason = table.concat({...}, " ")

						duration = math.floor(math.abs(duration))

						local adminNick = getPlayerAdminNick(sourcePlayer)
						local targetName = getPlayerVisibleName(targetPlayer)
						local accountName = getElementData(targetPlayer, "acc.Name")
						local accountId = getElementData(targetPlayer, "acc.ID")

						local currentTime = getRealTime().timestamp
						local expireTime = currentTime

						if duration == 0 then
							expireTime = currentTime + 31536000 * 100
						else
							expireTime = currentTime + duration * 3600
						end

						dbQuery(
							function(qh, targetPlayer)
								exports.sarp_hud:showAlert(root, "ban", adminNick .. " kitiltotta " .. targetName .. " játékost.", "Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason)

								if isElement(targetPlayer) then
									kickPlayer(targetPlayer, adminNick, reason)
								end

								exports.sarp_logs:toLog("adminaction", adminNick .. " kitiltotta " .. targetName .. " játékost (Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason .. ")")

								dbFree(qh)
							end, {targetPlayer}, connection, "INSERT INTO bans (playerSerial, playerName, playerAccountId, banReason, adminName, banTimestamp, expireTimestamp, isActive) VALUES (?,?,?,?,?,?,?,'Y'); UPDATE accounts SET suspended = 'Y' WHERE accountID = ?", targetSerial, accountName, accountId, reason, adminNick, currentTime, expireTime, accountId
						)
					else
						outputErrorText("Védett személyt nem tudsz kitiltani!", sourcePlayer)
					end
				else
					outputErrorText("Magadat nem tilthatod ki.", sourcePlayer)
				end
			end
		end
	end)

addAdminCommand("unban", 2, "A játékos kitiltásának feloldása")
addCommandHandler("unban",
	function(sourcePlayer, commandName, targetData)
		if not targetData then
			outputUsageText(commandName, "[Account ID / Serial]", sourcePlayer)
		else
			local adminNick = getPlayerAdminNick(sourcePlayer)
			local unbanType = "playerAccountId"

			if tonumber(targetData) then
				targetData = tonumber(targetData)
			elseif string.len(targetData) == 32 then
				unbanType = "playerSerial"
			else
				return false
			end

			dbQuery(
				function(qh, sourcePlayer)
					local result, numAffectedRows = dbPoll(qh, 0)

					if numAffectedRows > 0 and result then
						local accountId = false

						for k, v in ipairs(result) do
							if not accountId then
								accountId = v.playerAccountId
							end

							dbExec(connection, "UPDATE bans SET isActive = 'N' WHERE dbID = ?", v.dbID)
						end

						dbExec(connection, "UPDATE accounts SET suspended = 'N' WHERE accountID = ?", accountId)

						if isElement(sourcePlayer) then
							outputInfoText("Sikeresen feloldottad a kiválasztott játékosról a tiltást.", sourcePlayer)
						end

						exports.sarp_logs:toLog("adminaction", adminNick .. " feloldott egy tiltást. (AccountID: " .. accountId .. " | Timestamp: " .. getRealTime().timestamp .. ")")
					elseif isElement(sourcePlayer) then
						outputErrorText("A kiválasztott Account ID-n nincs kitiltás!", sourcePlayer)
					end
				end, {sourcePlayer}, connection, "SELECT * FROM bans WHERE ?? = ? AND isActive = 'Y'", unbanType, targetData
			)
		end
	end)