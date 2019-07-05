local jailPosX = 154.46096801758
local jailPosY = -1951.6784667969
local jailPosZ = 47.875
local jailInterior = 0

addEvent("getPlayerOutOfJail", true)
addEventHandler("getPlayerOutOfJail", getRootElement(),
	function ()
		if isElement(source) then
			setElementPosition(source, 1478.8834228516, -1739.0384521484, 13.546875)
			setElementInterior(source, 0)
			setElementDimension(source, 0)
		end
	end
)

addEvent("movePlayerBackToAdminJail", true)
addEventHandler("movePlayerBackToAdminJail", getRootElement(),
	function ()
		if isElement(source) then
			local accountId = getElementData(source, "acc.dbID")

			if accountId then
				spawnPlayer(source, jailPosX, jailPosY, jailPosZ, 0, playerSkin, jailInterior, accountId + math.random(100))
				setCameraTarget(source, source)
			end
		end
	end
)

function processPlayerAdminJail(sourcePlayer, command, target, duration, ...)
	if hasPermission(command, sourcePlayer, true) then
		if not target or not duration or not (...) then
			outputUsageText(command, sourcePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(sourcePlayer, target)

			if targetPlayer then
				duration = tonumber(duration)

				if duration < 1 then
					outputErrorText("A jail időtartamának nagyobbnak kell lennie 0-nál!", sourcePlayer)
					exports.sarp_hud:showAlert(sourcePlayer, "error", "A jail időtartamának nagyobbnak kell lennie 0-nál!")
				else
					local accountId = getElementData(targetPlayer, "acc.dbID")

					if accountId then
						local now = getRealTime().timestamp
						local reason = table.concat({...}, " ")
						local adminName = getElementData(sourcePlayer, "acc.adminNick") or getPlayerName(sourcePlayer, true)
						local jailInfo = now .. "/" .. utf8.gsub(reason, "/", ";") .. "/" .. duration .. "/" .. adminName

						dbQuery(
							function (qh)
								dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", jailInfo, duration, accountId)

								removePedFromVehicle(targetPlayer)
								setElementPosition(targetPlayer, jailPosX, jailPosY, jailPosZ)
								setElementInterior(targetPlayer, jailInterior)
								setElementDimension(targetPlayer, accountId + math.random(1, 100))

								setElementData(targetPlayer, "acc.adminJail", jailInfo)
								setElementData(targetPlayer, "acc.adminJailTime", duration)

								exports.sarp_hud:showAlert(root, "jail", adminName .. " bebörtönözte " .. targetPlayerName .. " játékost", "Időtartam: " .. duration .. " perc, Indok: " .. reason)
								
								logs:toLog("adminaction", adminName .. " bebörtönözte " .. targetPlayerName .. " játékost (Időtartam: " .. duration .. " perc, Indok: " .. reason .. ")")

								dbFree(qh)
							end, connection, "INSERT INTO adminjails (accountID, jailTimestamp, reason, duration, adminName) VALUES (?,?,?,?,?)", accountId, now, reason, duration, adminName
						)
					end
				end
			end
		end
	end
end
addAdminCommand("ajail", processPlayerAdminJail, "Játékos (admin)bebörtönzése")

function processPlayerAdminUnJail(sourcePlayer, command, target, ...)
	if hasPermission(command, sourcePlayer, true) then
		if not target or not (...) then
			outputUsageText(command, sourcePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(sourcePlayer, target)

			if targetPlayer then
				if (getElementData(targetPlayer, "acc.adminJail") or 0) ~= 0 then
					local reason = table.concat({...}, " ")
					local adminName = getElementData(sourcePlayer, "acc.adminNick") or getPlayerName(sourcePlayer, true)
					local accountId = getElementData(targetPlayer, "acc.dbID")

					dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", "N", 0, accountId)

					setElementData(targetPlayer, "acc.adminJail", 0)
					setElementData(targetPlayer, "acc.adminJailTime", 0)

					triggerEvent("getPlayerOutOfJail", targetPlayer)

					exports.sarp_core:sendMessageToAdmins(adminName .. " kivette " .. targetPlayerName .. " játékost az adminbörtönből. Indok: " .. reason)
					logs:toLog("adminaction", adminName .. " kivette " .. targetPlayerName .. " játékost az adminbörtönből. Indok: " .. reason)
				else
					outputErrorText("A kiválasztott játékos nincs adminbörtönben!", sourcePlayer)
					exports.sarp_hud:showAlert(sourcePlayer, "error", "A kiválasztott játékos nincs adminbörtönben!")
				end
			end
		end
	end
end
addAdminCommand("unajail", processPlayerAdminUnJail, "Játékos kivétele az adminbörtönből")

function processPlayerOfflineAdminJail(sourcePlayer, command, data, duration, ...)
	if hasPermission(command, sourcePlayer, true) then
		if not data or not duration or not (...) then
			outputUsageText(command, sourcePlayer)
		else
			duration = tonumber(duration)

			if duration < 1 then
				outputErrorText("A jail időtartamának nagyobbnak kell lennie 0-nál!", sourcePlayer)
				exports.sarp_hud:showAlert(sourcePlayer, "error", "A jail időtartamának nagyobbnak kell lennie 0-nál!")
			else
				local now = getRealTime().timestamp
				local reason = table.concat({...}, " ")
				local adminName = getElementData(sourcePlayer, "acc.adminNick") or getPlayerName(sourcePlayer, true)

				local jailInfo = now .. "/" .. utf8.gsub(reason, "/", ";") .. "/" .. duration .. "/" .. adminName

				local query = "SELECT * FROM accounts WHERE serial = ? LIMIT 1"
				if tonumber(data) then
					data = tonumber(data)
					query = "SELECT * FROM accounts WHERE accountID = ? LIMIT 1"
				end

				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						if result and result[1] then
							local accountId = result[1].accountID

							dbQuery(
								function (qh)
									dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", jailInfo, duration, accountId)

									exports.sarp_hud:showAlert(root, "jail", adminName .. " bebörtönözte " .. result[1].username .. " felhasználót", "Időtartam: " .. duration .. " perc, Indok: " .. reason)
									
									logs:toLog("adminaction", adminName .. " bebörtönözte " .. result[1].username .. " felhasználót (Időtartam: " .. duration .. " perc, Indok: " .. reason .. ")")

									dbFree(qh)
								end, connection, "INSERT INTO adminjails (accountID, jailTimestamp, reason, duration, adminName) VALUES (?,?,?,?,?)", accountId, now, reason, duration, adminName
							)
						else
							outputErrorText("A kiválasztott felhasználó nincs regisztrálva a szerveren!", player)
							exports.sarp_hud:showAlert(player, "error", "A kiválasztott felhasználó nincs regisztrálva a szerveren!")
						end
					end, connection, query, data
				)
			end
		end
	end
end
addAdminCommand("oajail", processPlayerOfflineAdminJail, "Játékos offline adminbörtönzése")

function processPlayerOfflineAdminUnJail(sourcePlayer, command, data, ...)
	if hasPermission(command, sourcePlayer, true) then
		if not data or not (...) then
			outputUsageText(command, sourcePlayer)
		else
			local reason = table.concat({...}, " ")
			local adminName = getElementData(sourcePlayer, "acc.adminNick") or getPlayerName(sourcePlayer, true)

			if tonumber(data) then -- account id alapján
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						if result and result[1] then
							dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", "N", 0, result[1].accountID)

							exports.sarp_core:sendMessageToAdmins(adminName .. " kivette " .. result[1].username .. " felhasználót az adminbörtönből. Indok: " .. reason)
							logs:toLog("adminaction", adminName .. " kivette " .. result[1].username .. " felhasználót az adminbörtönből. Indok: " .. reason)

							exports.sarp_hud:showAlert(sourcePlayer, "success", "A felhasználó sikeresen kivéve az adminbörtönből!")
						else
							outputErrorText("Ez a felhasználó nincs adminbörtönben!", sourcePlayer)
							exports.sarp_hud:showAlert(sourcePlayer, "error", "Ez a felhasználó nincs adminbörtönben!")
						end
					end, connection, "SELECT accountID, username FROM accounts WHERE accountID = ? AND adminJail <> 'N' LIMIT 1", tonumber(data)
				)
			else -- serial alapján
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						if result and result[1] then
							dbExec(connection, "UPDATE accounts SET adminJail = ?, adminJailTime = ? WHERE accountID = ?", "N", 0, result[1].accountID)

							exports.sarp_core:sendMessageToAdmins(adminName .. " kivette " .. result[1].username .. " felhasználót az adminbörtönből. Indok: " .. reason)
							logs:toLog("adminaction", adminName .. " kivette " .. result[1].username .. " felhasználót az adminbörtönből. Indok: " .. reason)

							exports.sarp_hud:showAlert(sourcePlayer, "success", "A felhasználó sikeresen kivéve az adminbörtönből!")
						else
							outputErrorText("Ez a felhasználó nincs adminbörtönben!", sourcePlayer)
							exports.sarp_hud:showAlert(sourcePlayer, "error", "Ez a felhasználó nincs adminbörtönben!")
						end
					end, connection, "SELECT accountID, username FROM accounts WHERE serial = ? AND adminJail <> 'N' LIMIT 1", data
				)
			end
		end
	end
end
addAdminCommand("oaujail", processPlayerOfflineAdminUnJail, "Offline játékos kivétele az adminbörtönből")