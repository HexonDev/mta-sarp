--[[
CREATE TABLE `ucp_graph_players` (
	`dbID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`players` INT(4) NOT NULL DEFAULT '0',
	`date` DATETIME NOT NULL
) Engine=InnoDB;

CREATE TABLE `bans` (
	`dbID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`playerSerial` VARCHAR(512) DEFAULT '0',
	`playerName` VARCHAR(48) NOT NULL DEFAULT '',
	`playerAccountId` INT(11) NOT NULL,
	`banReason` TEXT,
	`adminName` VARCHAR(48) NOT NULL DEFAULT '',
	`banTimestamp` BIGINT(22) DEFAULT '0',
	`expireTimestamp` BIGINT(22) DEFAULT '0',
	`isActive` enum('Y', 'N') NOT NULL DEFAULT 'Y'
);

CREATE TABLE `kicks` (
	`dbID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`playerAccountId` INT(11) NOT NULL,
	`adminName` INT(11) NOT NULL,
	`kickReason` TEXT,
	`date` DATETIME DEFAULT NOW()
);

CREATE TABLE `accounts` (
	`accountID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`serial` VARCHAR(512) DEFAULT '0',
	`suspended` enum('Y', 'N') NOT NULL DEFAULT 'N',
	`username` VARCHAR(48) NOT NULL DEFAULT '',
	`password` TEXT NOT NULL DEFAULT '',
	`email` TEXT NOT NULL DEFAULT '',
	`adminLevel` INT(2) NOT NULL DEFAULT '0',
	`adminNick` VARCHAR(48) NOT NULL DEFAULT '',
	`registerTime` DATETIME DEFAULT NOW(),
	`lastLoggedIn` DATETIME DEFAULT 0,
	`maxCharacter` INT(2) NOT NULL DEFAULT '1',
	`adminJail` VARCHAR(512) NOT NULL DEFAULT 'N',
	`adminJailTime` INT(11) NOT NULL DEFAULT '0',
	`online` ENUM('N', 'Y') NOT NULL DEFAULT 'N',
	`helperLevel` INT(1) NOT NULL DEFAULT '0'
);

CREATE TABLE `characters` (
	`charID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`accID` INT(11) NOT NULL DEFAULT '0',
	`name` VARCHAR(40) NOT NULL DEFAULT '',
	`skin` INT(3) NOT NULL DEFAULT '1',
	`age` INT(2) NOT NULL DEFAULT '24',
	`position` TEXT,
	`rotation` INT(3) NOT NULL DEFAULT '0',
	`interior` INT(11) NOT NULL DEFAULT '0',
	`dimension` INT(11) NOT NULL DEFAULT '0',
	`health` INT(3) NOT NULL DEFAULT '100',
	`armor` INT(3) NOT NULL DEFAULT '100',
	`hunger` INT(3) NOT NULL DEFAULT '100',
	`thirst` INT(3) NOT NULL DEFAULT '100',
	`money` INT(11) NOT NULL DEFAULT '0',
	`bankMoney` INT(11) NOT NULL DEFAULT '0',
	`job` INT(2) NOT NULL DEFAULT '0',
	`injured` INT(1) NOT NULL DEFAULT '0',
	`houseInterior` INT(11) NOT NULL DEFAULT '0',
	`customInterior` INT(11) NOT NULL DEFAULT '0',
	`actionbarItems` TEXT,
	`lastOnline` BIGINT(22) NOT NULL DEFAULT '0',
	`playedMinutes` INT(11) NOT NULL DEFAULT '0',
	`playTimeForPayday` INT(11) NOT NULL DEFAULT '0',
	`vehicleLimit` INT(4) NOT NULL DEFAULT '3',
	`interiorLimit` INT(4) NOT NULL DEFAULT '5',
	`bulletDamages` VARCHAR(512) DEFAULT NULL,
	`lastNameChange` DATETIME DEFAULT NULL
);

CREATE TABLE `adminjails` (
	`dbID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`accountID` INT(11) NOT NULL DEFAULT '0',
	`jailTimestamp` BIGINT(22) NOT NULL DEFAULT '0',
	`reason` TEXT,
	`duration` INT(11) NOT NULL DEFAULT '0',
	`adminName` VARCHAR(100) NOT NULL DEFAULT ''
);
]]

local connection = false
local debugging = false

local taxesCache = {}
local assignedCharacters = {}
local characterDatas = {}

function sendTheHourlyPlayers()
	-- minden 1 nappal ezelőtti rekordot törlünk, ne teljen vele fölöslegesen az adatbázis
	dbExec(connection, "DELETE FROM ucp_graph_players WHERE date < NOW() - INTERVAL 1 DAY")

	-- beszúrjuk a mostani rekordot
	local timeNow = getRealTime()
	
	if timeNow.minute % 5 ~= 0 then
		timeNow.minute = timeNow.minute - timeNow.minute % 5
	end

	timeNow = string.format("%04d-%02d-%02d %02d:%02d:00", timeNow.year + 1900, timeNow.month + 1, timeNow.monthday, timeNow.hour, timeNow.minute)

	dbExec(connection, "INSERT INTO ucp_graph_players (players, date) VALUES (?, ?)", #getElementsByType("player"), timeNow)
end

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			local sarp_database = getResourceFromName("sarp_database")

			if sarp_database and getResourceState(sarp_database) == "running" then
				connection = exports.sarp_database:getConnection()
			end

			if connection then
				dbQuery(
					function (qh)
						local result, rows = dbPoll(qh, 0)

						for k,v in ipairs(result) do
							taxesCache[v.key] = {v.id, v.name, v.value, v.updated, v.created}

							if debugging then
								print(v.name .. ": " .. v.value)
							end
						end
					end, connection, "SELECT * FROM taxes"
				)

				sendTheHourlyPlayers()

				setTimer(sendTheHourlyPlayers, 300000, 0) -- 5 percenként
			end
		end
	end, true, "high+99"
)

addEventHandler("onPlayerJoin", getRootElement(),
	function ()
		if isElement(source) then
			local playerID = getElementData(source, "playerID") or math.random(1, 500)

			setElementDimension(source, 75 + playerID)
			setElementAlpha(source, 0)
			setElementFrozen(source, true)
			setPlayerNametagShowing(source, false)
		end
	end
)

addEvent("checkPlayerBanState", true)
addEventHandler("checkPlayerBanState", getRootElement(),
	function ()
		if isElement(source) then
			local serial = getPlayerSerial(source)

			dbQuery(
				function (qh, sourcePlayer)
					if isElement(sourcePlayer) then
						local result, rows = dbPoll(qh, 0)[1]
						local banState = {isActive = "N"}

						if result then
							if getRealTime().timestamp >= result.expireTimestamp then
								dbExec(connection, "UPDATE accounts SET suspended = 'N' WHERE serial = ?; UPDATE bans SET isActive = 'N' WHERE playerSerial = ? AND dbID = ?", serial, serial, v.dbID)
							else
								banState = result
							end
						end

						triggerClientEvent(sourcePlayer, "receiveBanState", sourcePlayer, banState)

						if getElementData(sourcePlayer, "loggedIn") then
							local characterId = getElementData(sourcePlayer, "char.ID") or 0

							if characterId > 0 then
								assignedCharacters[characterId] = sourcePlayer

								dbExec(connection, "UPDATE accounts SET online = 'Y' WHERE accountID = ?", getElementData(sourcePlayer, "acc.ID"))
							end
						end
					end
				end, {source}, connection, "SELECT * FROM bans WHERE playerSerial = ? AND isActive = 'Y' LIMIT 1", serial
			)
		end
	end
)

addEvent("onClientRegisterRequest", true)
addEventHandler("onClientRegisterRequest", getRootElement(),
	function ()
		if isElement(source) then
			dbQuery(
				function (qh, sourcePlayer)
					if isElement(sourcePlayer) then
						local result, rows = dbPoll(qh, 0)

						triggerClientEvent(sourcePlayer, "onClientRegister", sourcePlayer, rows)
					end
				end, {source}, connection, "SELECT * FROM accounts WHERE serial = ? LIMIT 1", getPlayerSerial(source)
			)
		end
	end
)

addEvent("checkCharacterName", true)
addEventHandler("checkCharacterName", getRootElement(),
	function (name)
		if isElement(source) then
			if not name then
				return
			end
			
			dbQuery(
				function (qh, sourcePlayer)
					if isElement(sourcePlayer) then
						local result, rows = dbPoll(qh, 0)

						triggerClientEvent(sourcePlayer, "checkNameCallback", sourcePlayer, rows)
					end
				end, {source}, connection, "SELECT * FROM characters WHERE name = ? LIMIT 1", name
			)
		end
	end
)

function generateRandomString(chars)
	local str = ""

	for i = 1, chars do 
		str = str .. (string.format("%c", math.random(48, 122)))
	end

	return str
end

function createHash(string, key)
	if not key then
		key = generateRandomString(8)
	end

	return "$" .. key .. "$" .. hash("sha512", "SARP#PW" .. md5(key) .. md5(string))
end

function makeHash(string, old)
	return createHash(string, gettok(old, 1, string.byte("$")))
end

function isEqualHash(string, old)
	return gettok(makeHash(string, old), 2, string.byte("$")) == gettok(old, 2, string.byte("$"))
end

addEvent("onClientTryToCreateAccount", true)
addEventHandler("onClientTryToCreateAccount", getRootElement(),
	function (username, password, email)
		if isElement(source) then
			if client and username and password and email then
				dbQuery(
					function (qh, sourcePlayer)
						if isElement(sourcePlayer) then
							local result = dbPoll(qh, 0)[1]

							if result then
								if result.username == username then
									exports.sarp_hud:showInfobox(sourcePlayer, "error", "Ez a felhasználónév már foglalt!")
								elseif result.email == email then
									exports.sarp_hud:showInfobox(sourcePlayer, "error", "Ez az e-mail cím már használatban van!")
								end
							else
								dbQuery(
									function (qh)
										local result, rows, lastID = dbPoll(qh, 0)

										triggerClientEvent(sourcePlayer, "onRegisterFinish", sourcePlayer, lastID)
									end, connection, "INSERT INTO accounts (username, password, email, serial, adminNick) VALUES (?,?,?,?,?)", username, createHash(password), email, getPlayerSerial(sourcePlayer), username
								)
							end
						end
					end, {source}, connection, "SELECT username, email FROM accounts WHERE username = ? OR email = ? LIMIT 1", username, email
				)
			end
		end
	end
)

function reloadPlayerCharacters(qh, sourcePlayer, accountID)
	if isElement(sourcePlayer) then
		dbQuery(
			function (qh)
				local result, rows = dbPoll(qh, 0)
				local characters = {}

				for k,v in pairs(result) do
					table.insert(characters, v)
				end

				triggerClientEvent(sourcePlayer, "onPlayerCharacterMade", sourcePlayer, characters)
			end, connection, "SELECT * FROM characters WHERE accID = ?", accountID
		)
	end

	dbFree(qh)
end

addEvent("onClientTryToCreateCharacter", true)
addEventHandler("onClientTryToCreateCharacter", getRootElement(),
	function (charName, data)
		if client and charName and data then
			dbQuery(reloadPlayerCharacters, {source, data.accID}, connection, "INSERT INTO characters (accID, name, skin, age, position, rotation, money) VALUES (?,?,?,?,?,?,?)", data.accID, charName, data.skin, data.age, "1483.3148193359,-1739.0212402344,13.546875", 0, 2000)
		end
	end
)

addEvent("onClientPasswordChangeForced", true)
addEventHandler("onClientPasswordChangeForced", getRootElement(),
	function (password)
		if isElement(source) then
			if client and password then
				local accountId = getElementData(source, "acc.dbID") or 0

				if accountId > 0 then
					dbQuery(
						function(qh, sourcePlayer)
							if isElement(sourcePlayer) then
								triggerClientEvent(sourcePlayer, "passwordChangeResult", sourcePlayer, true)
							end

							dbFree(qh)
						end, {source}, connection, "UPDATE accounts SET password = ? WHERE accountID = ?", createHash(password), accountId
					)
				end
			end
		end
	end
)

addEvent("onClientLoginRequest", true)
addEventHandler("onClientLoginRequest", getRootElement(),
	function (username, password)
		if isElement(source) then
			if client and username and password then
				local serial = getPlayerSerial(source)

				dbQuery(
					function(qh, sourcePlayer)
						local result = dbPoll(qh, 0)[1]
						local errno = false
						local forcePasswordChange = "N"

						if not result then
							errno = "Nincs ilyen nevű felhasználó regisztrálva!"
						elseif string.len(result.password) == 32 then -- régi jelszó, jelszóváltás eröltetése
							if result.password == hash("md5", string.reverse(username .. password)) then
								errno = false
								forcePasswordChange = "Y"
							else
								errno = "Hibás jelszó!"
							end
						elseif not isEqualHash(password, result.password) then
							errno = "Hibás jelszó!"
						end

						if not errno then
							if result.serial == "0" then
								dbExec(connection, "UPDATE accounts SET serial = ? WHERE accountID = ?", serial, result.accountID)
								result.serial = serial
							end

							if result.serial ~= serial then
								errno = "Ez a fiók nem a Te gépedhez van társítva!"
							elseif result.suspended == "Y" then
								errno = "Ez a fiók határozatlan ideig fel van függesztve!"
							else
								errno = false
							end
						end

						if errno then
							exports.sarp_hud:showInfobox(sourcePlayer, "error", errno .. "\nVárj 10 másodpercet az újrapróbálkozáshoz.")
						else
							dbQuery(
								function(qh, account)
									local result, rows = dbPoll(qh, 0)
									local characters = {}

									for k, v in pairs(result) do
										table.insert(characters, v)
									end

									setElementData(sourcePlayer, "acc.Name", username)
									setElementData(sourcePlayer, "acc.ID", account.accountID)
									setElementData(sourcePlayer, "acc.dbID", account.accountID)
									setElementData(sourcePlayer, "acc.adminLevel", account.adminLevel)
									setElementData(sourcePlayer, "acc.adminNick", account.adminNick or username)
									setElementData(sourcePlayer, "acc.maxCharacter", account.maxCharacter)
									setElementData(sourcePlayer, "acc.helperLevel", account.helperLevel)

									if account.adminJail == "N" then
										setElementData(sourcePlayer, "acc.adminJail", 0)
										setElementData(sourcePlayer, "acc.adminJailTime", 0)
									else
										setElementData(sourcePlayer, "acc.adminJail", account.adminJail)
										setElementData(sourcePlayer, "acc.adminJailTime", account.adminJailTime)
									end

									dbExec(connection, "UPDATE accounts SET lastLoggedIn = NOW(), online = 'Y' WHERE accountID = ?" , account.accountID)

									triggerClientEvent(sourcePlayer, "onSuccessLogin", sourcePlayer, characters, forcePasswordChange)
								end, {result}, connection, "SELECT * FROM characters WHERE accID = ?", result.accountID
							)
						end
					end, {source}, connection, "SELECT * FROM accounts WHERE username = ? LIMIT 1", username
				)
			end
		end
	end
)

addEvent("onCharacterSelect", true)
addEventHandler("onCharacterSelect", getRootElement(),
	function (player, charID, data)
		if isElement(source) and isElement(player) then
			if player and charID and data then
				assignedCharacters[charID] = source
				characterDatas[charID] = data

				local position = split(data.position, ",")

				spawnPlayer(player, tonumber(position[1]), tonumber(position[2]), tonumber(position[3]), data.rotation, data.skin, data.interior, data.dimension)

				setElementAlpha(player, 255)
				setElementModel(player, data.skin)
				setElementInterior(player, data.interior)
				setElementDimension(player, data.dimension)
				setPedRotation(player, data.rotation)
				setCameraTarget(player, player)

				setElementHealth(player, data.health)
				setPedArmor(player, data.armor)
				setElementData(player, "char.Hunger", data.hunger)
				setElementData(player, "char.Thirst", data.thirst)
				setElementData(player, "char.Injured", data.injured == 1)

				setElementData(player, "char.ID", charID)
				setPlayerName(player, data.name)
				setPlayerNametagText(player, data.name)
				setElementData(player, "visibleName", data.name)
				setElementData(player, "char.Name", data.name)
				setElementData(player, "char.Age", data.age)

				setElementData(player, "char.Money", data.money)
				setElementData(player, "char.bankMoney", data.bankMoney)
				setElementData(player, "char.Job", data.job)

				setElementData(player, "char.playedMinutes", data.playedMinutes)
				setElementData(player, "char.playTimeForPayday", data.playTimeForPayday)

				setElementData(player, "player.currentInterior", data.houseInterior)
				setElementData(player, "currentCustomInterior", data.customInterior)
				
				if data.jailed then
					exports.sarp_groupscripting:loadPlayerJail(player, data.jailed)
				end

				if data.actionbarItems and utfLen(data.actionbarItems) > 0 then
					local items = split(data.actionbarItems, ";")

					for i = 1, 6 do
						local k = i - 1

						if items[i] ~= "-" then
							setElementData(source, "actionBarSlot_" .. k, tonumber(items[i]))
						elseif getElementData(source, "actionBarSlot_" .. k) then
							removeElementData(source, "actionBarSlot_" .. k)
						end
					end
				end

				setElementData(player, "char.vehicleLimit", data.vehicleLimit)
				setElementData(player, "char.interiorLimit", data.interiorLimit)

				if data.bulletDamages and utf8.len(data.bulletDamages) > 0 then
					local damages = split(data.bulletDamages, ";")
					local current = {}

					for i=1,#damages,3 do
						current[damages[i] .. ";" .. damages[i+1]] = tonumber(damages[i+2])
					end

					setElementData(player, "bulletDamages", current)
				end

				setElementData(player, "loggedIn", true) -- ez mindenképpen itt kell, hogy maradjon!!

				setPedStat(player, 69, 200) -- colt
				setPedStat(player, 70, 1000) -- silenced
				setPedStat(player, 71, 1000) -- desert eagle
				setPedStat(player, 72, 1000) -- shotgun
				setPedStat(player, 73, 200) -- sawnoff
				setPedStat(player, 74, 1000) -- spas12
				setPedStat(player, 75, 200) -- uzi
				setPedStat(player, 76, 1000) -- mp5
				setPedStat(player, 77, 1000) -- ak47
				setPedStat(player, 78, 1000) -- m4
				setPedStat(player, 79, 1000) -- sniper

				processClothesOfCJ(player)

				exports.sarp_vehicles:loadPlayerVehicles(charID, player)
				
				exports.sarp_inventory:loadItems(player, charID)

				triggerEvent("requestGroups", player)

				triggerClientEvent(player, "onClientLoggedIn", player)
			end
		end
	end
)

function getPlayerFromCharacterID(characterId)
	if assignedCharacters[characterId] then
		return assignedCharacters[characterId]
	end

	return false
end

function getLastCharacterData(characterId, data) -- spawnkor és a fél órás mentésekkor frissül a tábla!!
	if characterDatas[characterId] then
		if data then
			if characterDatas[characterId][data] then
				return characterDatas[characterId][data]
			end
		else
			return characterDatas[characterId]
		end
	end

	return false
end

exports.sarp_admin:addAdminCommand("triggersave", 10, "Játékosok mentése (debughoz)")
addCommandHandler("triggersave",
	function (player, command)
		if getElementData(player, "acc.adminLevel") == 10 then
			for k, v in ipairs(getElementsByType("player")) do
				autoSavePlayer(v)
			end
		end
	end
)

function autoSavePlayer(player, loggedOut)
	if not player then
		player = source
	end

	if getElementData(player, "loggedIn") then
		local characterId = getElementData(player, "char.ID")

		if loggedOut then
			assignedCharacters[characterId] = nil
			characterDatas[characterId] = nil
		end

		local onDuty = getElementData(player, "groupDuty")

		local actionbarItems = ""
		for i = 0, 5 do
			actionbarItems = actionbarItems .. (getElementData(player, "actionBarSlot_" .. tostring(i)) or "-") .. ";"
		end

		local bulletDamages = getElementData(player, "bulletDamages") or {}
		local damageStr = ""

		for k, v in pairs(bulletDamages) do
			damageStr = damageStr .. k .. ";" .. v .. ";"
		end

		local datas = {
			["skin"] = onDuty and getElementData(player, "char.defaultSkin") or getElementModel(player),
			["position"] = table.concat({getElementPosition(player)}, ","),
			["rotation"] = getPedRotation(player),
			["interior"] = getElementInterior(player),
			["dimension"] = getElementDimension(player),
			["health"] = getElementHealth(player),
			["armor"] = onDuty and getElementData(player, "char.defaultArmor") or getPedArmor(player),
			["hunger"] = getElementData(player, "char.Hunger") or 0,
			["thirst"] = getElementData(player, "char.Thirst") or 0,
			["money"] = getElementData(player, "char.Money") or 0,
			["bankMoney"] = getElementData(player, "char.bankMoney") or 0,
			["job"] = getElementData(player, "char.Job") or 0,
			["injured"] = (getElementData(player, "char.Injured") or getElementData(player, "char.Bleeding")) and 1 or 0,
			["houseInterior"] = getElementData(player, "player.currentInterior") or 0,
			["customInterior"] = getElementData(player, "currentCustomInterior") or 0,
			["actionbarItems"] = actionbarItems,
			["playedMinutes"] = getElementData(player, "char.playedMinutes") or 0,
			["playTimeForPayday"] = getElementData(player, "char.playTimeForPayday") or 0,
			["bulletDamages"] = damageStr
		}

		if not loggedOut then
			characterDatas[characterId] = datas
		end

		local columns = {}
		local columnValues = {}

		for k,v in pairs(datas) do
			table.insert(columns, k .. " = ?")
			table.insert(columnValues, v)
		end
		table.insert(columnValues, characterId)

		if not loggedOut then
			dbExec(connection, "UPDATE accounts SET adminJailTime = ? WHERE accountID = ?; UPDATE characters SET " .. table.concat(columns, ", ") .. " WHERE charID = ?", (getElementData(player, "acc.adminJailTime") or 0), getElementData(player, "acc.dbID"), unpack(columnValues))
		else
			local helperLevel = getElementData(player, "acc.helperLevel") or 0

			if helperLevel == 1 then
				helperLevel = 0
			end

			dbExec(connection, "UPDATE accounts SET adminJailTime = ?, online = 'N', helperLevel = ? WHERE accountID = ?; UPDATE characters SET lastOnline = ?, " .. table.concat(columns, ", ") .. " WHERE charID = ?", (getElementData(player, "acc.adminJailTime") or 0), helperLevel, getElementData(player, "acc.dbID"), getRealTime().timestamp, unpack(columnValues))
		end
	end
end
addEvent("autoSavePlayer", true)
addEventHandler("autoSavePlayer", getRootElement(), autoSavePlayer)

addEventHandler("onResourceStop", getResourceRootElement(),
	function ()
		for k,v in ipairs(getElementsByType("player")) do
			autoSavePlayer(v, true)
		end
	end
)

addEventHandler("onPlayerQuit", getRootElement(),
	function ()
		autoSavePlayer(source, true)
	end
)

exports.sarp_admin:addAdminCommand("payday", 10, "Fizetés/adó kiküldése magunknak (debughoz)")
addCommandHandler("payday",
	function (player, command)
		if getElementData(player, "acc.adminLevel") == 10 then
			triggerEvent("onPayDay", player)
		end
	end
)

addEvent("onPayDay", true)
addEventHandler("onPayDay", getRootElement(),
	function ()
		if getElementData(source, "loggedIn") then
			local charID = getElementData(source, "char.ID")

			-- Bruttó bér
			local grossSalary = 0
			local playerGroups = getElementData(source, "player.groups") or {}

			if #playerGroups > 0 then
				for k,v in pairs(playerGroups) do
					local rankId, rankName, rankPayment = exports.sarp_groups:getPlayerRank(source, k)

					grossSalary = grossSalary + rankPayment
				end
			end

			-- Jövedelem adó
			local incomeTax = getElementData(source, "char.bankMoney") or 0

			if incomeTax > 0 then
				incomeTax = incomeTax * 0.0175

				if incomeTax > 100000000 then
					incomeTax = 100000000
				end
			end

			-- Jármű adó
			local vehicleTax = exports.sarp_vehicles:getPlayerVehiclesCount(charID) * (taxesCache["vehicleTax"] and taxesCache["vehicleTax"][3] or 125)
		
			-- Ingatlan adó
			local interiors = exports.sarp_interiors:requestInteriors(source) or {}
			local propertyTax = #interiors * (taxesCache["propertyTax"] and taxesCache["propertyTax"][3] or 175)

			grossSalary = math.floor(grossSalary)
			incomeTax = math.floor(incomeTax)
			vehicleTax = math.floor(vehicleTax)
			propertyTax = math.floor(propertyTax)

			outputChatBox(exports.sarp_core:getServerTag() .. "Megérkezett a fizetésed.", source, 0, 0, 0, true)
			outputChatBox("#ffffff - Bruttó bér: #acd373" .. grossSalary .. " $", source, 0, 0, 0, true)
			outputChatBox("#ffffff - Jövedelem adó: #acd373" .. incomeTax .. " $", source, 0, 0, 0, true)
			outputChatBox("#ffffff - Jármű adó: #dc143c" .. vehicleTax .. " $", source, 0, 0, 0, true)
			outputChatBox("#ffffff - Ingatlan adó: #dc143c" .. propertyTax .. " $", source, 0, 0, 0, true)

			local currentBankMoney = getElementData(source, "char.bankMoney") or 0
			currentBankMoney = currentBankMoney + incomeTax

			local currentMoney = getElementData(source, "char.Money") or 0
			currentMoney = currentMoney + grossSalary - vehicleTax - propertyTax

			setElementData(source, "char.bankMoney", currentBankMoney)
			setElementData(source, "char.Money", currentMoney)
		end
	end
)

addEventHandler("onElementModelChange", getRootElement(),
	function (oldModel, newModel)
		if getElementType(source) == "player" then
			processClothesOfCJ(source)
		end
	end
)

function processClothesOfCJ(player)
	if getPlayerSerial(player) == "38637680563E8AF8B85FEDC807B24083" and getElementModel(player) == 0 then
		--addPedClothes(player, "hoodyAblue", "hoodyA", 0)
		addPedClothes(player, "beard", "head", 1)
		--addPedClothes(player, "chinosblue", "chinosb", 2)
		addPedClothes(player, "convproblk", "conv", 3)
		--addPedClothes(player, "glasses04dark", "glasses04", 15)
		addPedClothes(player, "bbjackrim", "bbjack", 0)
		addPedClothes(player, "tracktrwhstr", "tracktr", 2)
		addPedClothes(player, "capred", "cap", 16)
		--addPedClothes(player, "sneakerheatwht", "sneaker", 3)
		addPedClothes(player, "neckcross", "neck", 13)
	end
end