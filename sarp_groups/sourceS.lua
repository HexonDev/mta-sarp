--[[

CREATE TABLE `groups` (
	`groupID` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`name` TINYTEXT,
	`prefix` TINYTEXT,
	`type` TINYTEXT,
	`description` TINYTEXT,
	`balance` INT(11) DEFAULT '0',
	`permissions` TEXT,
	`duty_skins` TEXT,
	`duty_positions` TEXT,
	`duty_armor` INT(3) DEFAULT '0',
	`duty_items` TEXT,
	`mainLeader` INT(11) DEFAULT '0',
	`tuneRadio` INT(11) DEFAULT '0'
) DEFAULT CHARSET=utf8mb4;

CREATE TABLE `groupRanks` (
	`index` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`groupID` INT(11) NOT NULL,
	`rankID` INT(11) NOT NULL DEFAULT '1',
	`rankName` TINYTEXT,
	`rankPayment` INT(11) DEFAULT '0'
) DEFAULT CHARSET=utf8mb4;

CREATE TABLE `groupMembers` (
	`index` INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`groupID` INT(11) NOT NULL,
	`characterID` INT(11) NOT NULL,
	`rank` INT(11) DEFAULT '1',
	`isLeader` VARCHAR(1) DEFAULT 'N',
	`dutySkin` INT(3) NOT NULL DEFAULT '0'
) DEFAULT CHARSET=utf8mb4;

]]

local connection = false
local debugging = true

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			local sarp_database = getResourceFromName("sarp_database")

			if sarp_database and getResourceState(sarp_database) == "running" then
				connection = exports.sarp_database:getConnection()
			end

			loadAllGroups()
		end
	end, true, "high+99"
)

function loadAllGroups()
	local startTick = getTickCount()

	dbQuery(
		function (qh)
			local result, rows = dbPoll(qh, 0)

			if rows > 0 then
				local loadedGroups = {}
				local loaded = 0

				for k, v in ipairs(result) do
					local id = v.groupID

					if not availableGroups[id] then
						availableGroups[id] = {}
					end

					if not loadedGroups[id] then
						loadedGroups[id] = true
						loaded = loaded + 1

						availableGroups[id].groupID = id
						availableGroups[id].mainLeader = v.mainLeader
						availableGroups[id].tuneRadio = v.tuneRadio
						availableGroups[id].name = v.name
						availableGroups[id].prefix = v.prefix or utf8.upper(utf8.sub(v.name, 1, 3))
						availableGroups[id].type = v.type
						availableGroups[id].description = v.description
						availableGroups[id].balance = v.balance
						availableGroups[id].permissions = {}
						availableGroups[id].duty = {
							skins = {},
							positions = {},
							items = {},
							armor = v.duty_armor
						}

						if v.duty_items then
							local items = split(v.duty_items, "/")
							for i = 1, #items do
								local data = split(items[i], ",")

								if data[3] then
									table.insert(availableGroups[id].duty.items, {tonumber(data[1]), tonumber(data[2]), data[3]})
								else
									table.insert(availableGroups[id].duty.items, {tonumber(data[1]), tonumber(data[2])})
								end
							end
						end

						if v.duty_positions then
							local positions = split(v.duty_positions, "/")
							for i = 1, #positions do
								local coords = split(positions[i], ",")

								table.insert(availableGroups[id].duty.positions, {tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]), tonumber(coords[4]), tonumber(coords[5])})
							end
						end

						if v.duty_skins then
							local skins = split(v.duty_skins, ",")
							for i = 1, #skins do
								table.insert(availableGroups[id].duty.skins, tonumber(skins[i]))
							end
						end

						if v.permissions then
							local permissions = split(v.permissions, ",")
							for i = 1, #permissions do
								availableGroups[id].permissions[permissions[i]] = true
							end
						end

						if not availableGroups[id].ranks then
							availableGroups[id].ranks = {}
						end
					end

					availableGroups[id].ranks[v.rankID] = {
						name = v.rankName,
						pay = v.rankPayment
					}
				end

				if debugging then
					print("@loadAllGroups: " .. loaded .. " frakció betöltve " .. getTickCount() - startTick .. " ms alatt.")
				end
			end
		end, connection, "SELECT groups.*, groupRanks.* FROM groups INNER JOIN groupRanks ON groups.groupID = groupRanks.groupID ORDER BY groups.groupID, groupRanks.groupID, groupRanks.rankID"
	)
end

addEvent("requestGroups", true)
addEventHandler("requestGroups", getRootElement(),
	function ()
		if isElement(source) then
			loadPlayerGroups(source)
			triggerClientEvent(source, "receiveGroups", source, availableGroups)
		end
	end
)

function loadPlayerGroups(player)
	if isElement(player) then
		local characterID = getElementData(player, "char.ID")

		if characterID then
			dbQuery(
				function (qh)
					local result, rows = dbPoll(qh, 0)
					local groups = {}

					if rows > 0 then
						for k, v in ipairs(result) do
							groups[v.groupID] = {v.rank, v.dutySkin, v.isLeader}
						end
					end

					setElementData(player, "player.groups", groups)
				end, connection, "SELECT * FROM groupMembers WHERE characterID = ?", characterID
			)
		end
	end
end

function requestGroupData(groups, sourcePlayer, playerID, groupID)
	sourcePlayer = sourcePlayer or source

	if type(groups) == "table" then
		local groupIds = {}
		
		for k,v in pairs(groups) do
			table.insert(groupIds, k)
		end

		if #groupIds > 0 then
			local members = {}

			dbQuery(
				function (qh, player)
					local result, rows = dbPoll(qh, 0)
					
					for k, row in ipairs(result) do
						if row.characterName then
							local group = row.groupId

							if not members[group] then
								members[group] = {}
							end

							table.insert(members[group], row)
						end
					end

					triggerClientEvent(player, "receiveGroupMembers", player, members, groupID, playerID)
				end, {sourcePlayer}, connection, "SELECT groupMembers.groupID AS groupId, groupMembers.rank AS rank, groupMembers.isLeader AS isLeader, groupMembers.dutySkin AS dutySkin, characters.name AS characterName, characters.charID AS charID, characters.lastOnline AS lastOnline FROM groupMembers LEFT JOIN characters ON characters.charID = groupMembers.characterID WHERE groupMembers.groupID IN (" .. table.concat(groupIds, ",") .. ") ORDER BY groupMembers.groupID, groupMembers.rank, characters.name"
			)
		end
	end
end
addEvent("requestGroupData", true)
addEventHandler("requestGroupData", getRootElement(), requestGroupData)

function reloadGroupDatasForPlayer(qh, player, sourcePlayer, sourceGroups, playerID, groupID)
	if isElement(player) then
		loadPlayerGroups(player)
	end

	if isElement(sourcePlayer) then
		requestGroupData(sourceGroups, sourcePlayer, playerID, groupID)
	end

	dbFree(qh)
end

addEvent("renameGroupRank", true)
addEventHandler("renameGroupRank", getRootElement(),
	function (groupId, rankId, rankName)
		dbQuery(
			function (qh)
				availableGroups[groupId].ranks[rankId].name = rankName

				triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "rankName", rankId, rankName)

				dbFree(qh)
			end, connection, "UPDATE groupRanks SET rankName = ? WHERE rankID = ? AND groupID = ?", rankName, rankId, groupId
		)
	end
)

addEvent("setGroupRankPayment", true)
addEventHandler("setGroupRankPayment", getRootElement(),
	function (groupId, rankId, payment)
		dbQuery(
			function (qh)
				availableGroups[groupId].ranks[rankId].pay = payment

				triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "rankPayment", rankId, payment)

				dbFree(qh)
			end, connection, "UPDATE groupRanks SET rankPayment = ? WHERE rankID = ? AND groupID = ?", payment, rankId, groupId
		)
	end
)

addEvent("addNewGroupRank", true)
addEventHandler("addNewGroupRank", getRootElement(),
	function (groupId)
		if #availableGroups[groupId].ranks < maxGroupRank then
			local rankId = #availableGroups[groupId].ranks + 1
			local rankName = "Üres"
			local rankPayment = 0

			dbExec(connection, "INSERT INTO groupRanks (groupID, rankID, rankName, rankPayment) VALUES (?,?,?,?)", groupId, rankId, rankName, rankPayment)

			table.insert(availableGroups[groupId].ranks, {
				name = rankName,
				pay = rankPayment
			})

			triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "rank", rankId, availableGroups[groupId].ranks[rankId], source)
		end
	end
)

addEvent("removeGroupRank", true)
addEventHandler("removeGroupRank", getRootElement(),
	function (groupId, rankId, groups)
		if #availableGroups[groupId].ranks > 1 then
			local members = {}

			dbQuery(
				function (qh)
					local result = dbPoll(qh, 0)

					if result then
						local oldRanks = availableGroups[groupId].ranks

						dbExec(connection, "DELETE FROM groupRanks WHERE groupID = ? AND rankID = ?", groupId, rankId)

						local newRanks = {}
						local ranksRestore = ""
						local rankCount = 0

						for k, v in pairs(oldRanks) do
							if k ~= rankId then
								rankCount = rankCount + 1
								table.insert(newRanks, k)
								ranksRestore = ranksRestore .. "WHEN rankID = " .. k .. " THEN " .. rankCount .. " "
							end
						end

						if #newRanks > 0 then
							dbExec(connection, "UPDATE groupRanks SET rankID = CASE " .. ranksRestore .. " END WHERE rankID IN (" .. table.concat(newRanks, ",") .. ") AND groupID = ?", groupId)
						end
						
						table.remove(availableGroups[groupId].ranks, rankId)

						local charIds = {}
						local charRanks = ""

						for k, row in ipairs(result) do
							if row.characterName then
								local group = row.groupId

								if not members[group] then
									members[group] = {}
								end

								if rankId == row.rank or rankId < row.rank then
									local newRank = row.rank - 1

									if newRank < 1 then
										newRank = 1
									end

									charRanks = charRanks .. "WHEN rank = " .. row.rank .. " THEN " .. newRank .. " "
									row.rank = newRank

									table.insert(charIds, row.charID)
								end

								table.insert(members[group], row)
							end
						end

						if #charIds > 0 then
							dbExec(connection, "UPDATE groupMembers SET rank = CASE " .. charRanks .. " END WHERE characterID IN (" .. table.concat(charIds, ",") .. ") AND groupID = ?", groupId)
						end

						triggerClientEvent("removeGroupRank", getResourceRootElement(), groupId, availableGroups[groupId].ranks, members)
					end
				end, connection, "SELECT groupMembers.groupID AS groupId, groupMembers.rank AS rank, groupMembers.isLeader AS isLeader, groupMembers.dutySkin AS dutySkin, characters.name AS characterName, characters.charID AS charID, characters.lastOnline AS lastOnline FROM groupMembers LEFT JOIN characters ON characters.charID = groupMembers.characterID WHERE groupMembers.groupID = ? ORDER BY groupMembers.groupID, groupMembers.rank, characters.name", groupId
			)
		end
	end
)

addEvent("invitePlayerToGroup", true)
addEventHandler("invitePlayerToGroup", getRootElement(),
	function (groupId, sourceGroups, charID, playerOrIsOnline)
		if groupId and sourceGroups and charID then
			dbQuery(reloadGroupDatasForPlayer, {playerOrIsOnline, source, sourceGroups, charID, groupId}, connection, "INSERT INTO groupMembers (groupID, characterID, dutySkin) VALUES (?,?,?)", groupId, charID, availableGroups[groupId].duty.skins[1] or 0)
		end
	end
)

addEvent("setGroupMemberLeader", true)
addEventHandler("setGroupMemberLeader", getRootElement(),
	function (groupId, sourceGroups, haveLeader, charID, playerOrIsOnline)
		if groupId and sourceGroups and haveLeader and charID then
			dbQuery(reloadGroupDatasForPlayer, {playerOrIsOnline, source, sourceGroups, charID, groupId}, connection, "UPDATE groupMembers SET isLeader = ? WHERE characterID = ? AND groupID = ?", haveLeader, charID, groupId)
		end
	end
)

addEvent("modifyGroupMemberRank", true)
addEventHandler("modifyGroupMemberRank", getRootElement(),
	function (groupId, sourceGroups, state, charID, playerOrIsOnline, currentRank)
		if groupId and sourceGroups and state and charID and currentRank then
			if state == "up" then
				if currentRank < #availableGroups[groupId].ranks then
					dbQuery(reloadGroupDatasForPlayer, {playerOrIsOnline, source, sourceGroups, charID, groupId}, connection, "UPDATE groupMembers SET rank = ? WHERE characterID = ? AND groupID = ?", currentRank + 1, charID, groupId)
				end
			elseif state == "down" then
				if currentRank > 1 then
					dbQuery(reloadGroupDatasForPlayer, {playerOrIsOnline, source, sourceGroups, charID, groupId}, connection, "UPDATE groupMembers SET rank = ? WHERE characterID = ? AND groupID = ?", currentRank - 1, charID, groupId)
				end
			end
		end
	end
)

addEvent("removePlayerFromGroup", true)
addEventHandler("removePlayerFromGroup", getRootElement(),
	function (groupId, sourceGroups, charID, playerOrIsOnline)
		if groupId and sourceGroups and charID then
			dbQuery(reloadGroupDatasForPlayer, {playerOrIsOnline, source, sourceGroups, charID, groupId}, connection, "DELETE FROM groupMembers WHERE characterID = ? AND groupID = ?", charID, groupId)
		end
	end
)

addEvent("rewriteGroupDescription", true)
addEventHandler("rewriteGroupDescription", getRootElement(),
	function (groupId, description)
		if groupId and description then
			dbQuery(
				function (qh)
					availableGroups[groupId].description = description

					triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "description", false, description)

					dbFree(qh)
				end, connection, "UPDATE groups SET description = ? WHERE groupID = ?", description, groupId
			)
		end
	end
)

addEvent("setGroupBalance", true)
addEventHandler("setGroupBalance", getRootElement(),
	function (groupId, amount)
		if groupId and amount then
			local currentBalance = availableGroups[groupId].balance

			currentBalance = currentBalance + amount

			local currentMoney = getElementData(source, "char.Money") or 0

			if currentBalance < 0 then
				triggerClientEvent(source, "setErrorDisplay", source, "error", "groupBalance", "#d75959Nincs elegendő pénz a számlán!")
			else
				if amount > 0 and currentMoney < amount then
					triggerClientEvent(source, "setErrorDisplay", source, "error", "groupBalance", "#d75959Nincs nálad ennyi pénz!")
				else
					setElementData(source, "char.Money", currentMoney - amount)

					availableGroups[groupId].balance = currentBalance

					dbQuery(
						function (qh, player)
							triggerClientEvent(player, "setErrorDisplay", player, "notify", "groupBalance", "#7cc576A tranzakció sikeres!")
							triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "balance", false, currentBalance)

							dbFree(qh)
						end, {source}, connection, "UPDATE groups SET balance = ? WHERE groupID = ?", currentBalance, groupId
					)
				end
			end
		end
	end
)

addEvent("createGroup", true)
addEventHandler("createGroup", getRootElement(),
	function (datas, mainLeaderElement)
		local permissions = {}
		local duty_skins = {}
		local duty_positions = {}
		local duty_items = {}

		for k,v in pairs(datas.permissions) do
			table.insert(permissions, k)
		end

		for i = 1, #datas.duty.skins do
			table.insert(duty_skins, datas.duty.skins[i])
		end

		for i = 1, #datas.duty.positions do
			local coords = {}

			for j = 1, #datas.duty.positions[i] do
				table.insert(coords, datas.duty.positions[i][j])
			end

			table.insert(duty_positions, table.concat(coords, ","))
		end

		for i = 1, #datas.duty.items do
			local itemDatas = {}

			for j = 1, #datas.duty.items[i] do
				table.insert(itemDatas, datas.duty.items[i][j])
			end

			table.insert(duty_items, table.concat(itemDatas, ","))
		end

		permissions = table.concat(permissions, ",")
		duty_skins = table.concat(duty_skins, ",")
		duty_positions = table.concat(duty_positions, "/")
		duty_items = table.concat(duty_items, "/")

		datas.mainLeader = datas.mainLeader or 0
		datas.tuneRadio = datas.tuneRadio or 0

		dbQuery(
			function (qh, creator)
				local result, rows, id = dbPoll(qh, 0)

				availableGroups[id] = {
					groupID = id,
					mainLeader = datas.mainLeader,
					tuneRadio = datas.tuneRadio,
					name = datas.name,
					prefix = datas.prefix,
					type = datas.type,
					description = datas.description,
					balance = datas.balance,
					permissions = datas.permissions,
					duty = {
						skins = datas.duty.skins,
						positions = datas.duty.positions,
						items = datas.duty.items,
						armor = datas.duty.armor
					},
					ranks = {
						{name = "Üres", pay = 0}
					}
				}

				dbExec(connection, "INSERT INTO groupRanks (groupID, rankID, rankName, rankPayment) VALUES (?,?,?,?)", id, 1, "Üres", 0)

				if datas.mainLeader > 0 then
					dbExec(connection, "INSERT INTO groupMembers (groupID, characterID, isLeader, dutySkin) VALUES (?,?,?,?)", id, datas.mainLeader, "Y", datas.duty.skins[1] or 0)
				end

				triggerClientEvent("receiveGroups", getResourceRootElement(), availableGroups)

				if isElement(mainLeaderElement) then
					local playerGroups = getElementData(mainLeaderElement, "player.groups") or {}

					playerGroups[id] = {1, datas.duty.skins[1] or 0, "Y"}

					setElementData(mainLeaderElement, "player.groups", playerGroups)

					requestGroupData(playerGroups, mainLeaderElement)
				end

				if debugging then
					print("@createGroup: Csoport [" .. id .. "] sikeresen létrehozva. (" .. datas.name .. ")")
				end

				exports.sarp_hud:showInfobox(creator, "success", "Frakció sikeresen létrehozva!")
			end, {source}, connection, "INSERT INTO groups (name, prefix, type, description, balance, permissions, duty_skins, duty_positions, duty_armor, duty_items, mainLeader, tuneRadio) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", datas.name, datas.prefix, datas.type, datas.description, datas.balance, permissions, duty_skins, duty_positions, datas.duty.armor, duty_items, datas.mainLeader, datas.tuneRadio
		)
	end
)

addEvent("modifyGroup", true)
addEventHandler("modifyGroup", getRootElement(),
	function (groupID, datas, mainLeaderElement, oldLeaderElement)
		local permissions = {}
		local duty_skins = {}
		local duty_positions = {}
		local duty_items = {}

		for k,v in pairs(datas.permissions) do
			table.insert(permissions, k)
		end

		for i = 1, #datas.duty.skins do
			table.insert(duty_skins, datas.duty.skins[i])
		end

		for i = 1, #datas.duty.positions do
			local coords = {}

			for j = 1, #datas.duty.positions[i] do
				table.insert(coords, datas.duty.positions[i][j])
			end

			table.insert(duty_positions, table.concat(coords, ","))
		end

		for i = 1, #datas.duty.items do
			local itemDatas = {}

			for j = 1, #datas.duty.items[i] do
				table.insert(itemDatas, datas.duty.items[i][j])
			end

			table.insert(duty_items, table.concat(itemDatas, ","))
		end

		permissions = table.concat(permissions, ",")
		duty_skins = table.concat(duty_skins, ",")
		duty_positions = table.concat(duty_positions, "/")
		duty_items = table.concat(duty_items, "/")

		local oldLeader = availableGroups[groupID].mainLeader

		datas.mainLeader = datas.mainLeader or 0
		datas.tuneRadio = datas.tuneRadio or 0

		dbQuery(
			function (qh, creator)
				availableGroups[groupID].mainLeader = datas.mainLeader
				availableGroups[groupID].tuneRadio = datas.tuneRadio
				availableGroups[groupID].name = datas.name
				availableGroups[groupID].prefix = datas.prefix
				availableGroups[groupID].type = datas.type
				availableGroups[groupID].permissions = datas.permissions
				availableGroups[groupID].duty = {
					skins = datas.duty.skins,
					positions = datas.duty.positions,
					items = datas.duty.items,
					armor = datas.duty.armor
				}

				triggerClientEvent("receiveGroups", getResourceRootElement(), availableGroups)

				if datas.mainLeader ~= oldLeader then
					local inTheGroup = false

					if isElement(mainLeaderElement) then
						local playerGroups = getElementData(mainLeaderElement, "player.groups") or {}

						if playerGroups[groupID] then
							inTheGroup = true
						end
					end

					if oldLeader > 0 then
						dbExec(connection, "DELETE FROM groupMembers WHERE groupID = ? AND characterID = ?", groupID, oldLeader)
					end

					if datas.mainLeader > 0 then
						if inTheGroup then
							dbExec(connection, "UPDATE groupMembers SET isLeader = 'Y' WHERE groupID = ? AND characterID = ?", groupID, datas.mainLeader)
						else
							dbExec(connection, "INSERT INTO groupMembers (groupID, characterID, isLeader) VALUES (?,?,?)", groupID, datas.mainLeader, "Y")
						end
					end

					if isElement(oldLeaderElement) then
						local playerGroups = getElementData(oldLeaderElement, "player.groups") or {}

						playerGroups[groupID] = nil

						setElementData(oldLeaderElement, "player.groups", playerGroups)

						requestGroupData(playerGroups, oldLeaderElement)
					end

					if isElement(mainLeaderElement) then
						local playerGroups = getElementData(mainLeaderElement, "player.groups") or {}

						playerGroups[groupID] = {1, datas.duty.skins[1] or 0, "Y"}

						setElementData(mainLeaderElement, "player.groups", playerGroups)

						requestGroupData(playerGroups, mainLeaderElement)
					end
				end

				if debugging then
					print("@modifyGroup: Csoport [" .. groupID .. "] sikeresen módosítva. (" .. datas.name .. ")")
				end

				exports.sarp_hud:showInfobox(creator, "success", "Frakció sikeresen módosítva!")

				dbFree(qh)
			end, {source}, connection, "UPDATE groups SET mainLeader = ?, name = ?, prefix = ?, type = ?, permissions = ?, duty_skins = ?, duty_positions = ?, duty_armor = ?, duty_items = ?, tuneRadio = ? WHERE groupID = ?", datas.mainLeader, datas.name, datas.prefix, datas.type, permissions, duty_skins, duty_positions, datas.duty.armor, duty_items, datas.tuneRadio, groupID
		)
	end
)

addEvent("deleteGroup", true)
addEventHandler("deleteGroup", getRootElement(),
	function (groupID)
		if groupID then
			availableGroups[groupID] = nil

			dbExec(connection, "DELETE FROM groups WHERE groupID = ?; DELETE FROM groupRanks WHERE groupID = ?; DELETE FROM groupMembers WHERE groupID = ?", groupID, groupID, groupID)

			exports.sarp_vehicles:deleteGroupVehicles(groupID)

			for k,v in ipairs(getElementsByType("player")) do
				if getElementData(v, "loggedIn") then
					local playerGroups = getElementData(v, "player.groups") or {}
					
					if playerGroups[groupID] then
						playerGroups[groupID] = nil

						setElementData(v, "player.groups", playerGroups)

						requestGroupData(playerGroups, v)
					end
				end
			end

			triggerClientEvent("deleteGroup", getResourceRootElement(), groupID)

			exports.sarp_hud:showInfobox(source, "success", "Frakció sikeresen törölve!")
		end
	end
)

function encodeBadge(groupId, characterId)
	local num = characterId % 10

	characterId = (characterId - num) / 10

	local num2 = characterId % 10

	characterId = (characterId - num2) / 10

	local num3 = characterId % 10

	characterId = (characterId - num3) / 10

	local num4 = groupId % 10

	groupId = (groupId - num4) / 10

	local num5 = groupId % 10

	groupId = (groupId - num5) / 10

	local num6 = groupId % 10

	groupId = (groupId - num6) / 10

	return string.format("%c%c%c%c%c%c", num5 + string.byte("0"), num4 + string.byte("0"), num6 + string.byte("0"), num3 + string.byte("0"), num2 + string.byte("0"), num + string.byte("0"))
end

addEvent("requestDuty", true)
addEventHandler("requestDuty", getRootElement(),
	function (groupId)
		if groupId and availableGroups[groupId] then
			local group = availableGroups[groupId]
			
			if group then
				local characterId = getElementData(source, "char.ID")

				if characterId then
					exports.sarp_inventory:removePlayerDutyItems(source)

					if not getElementData(source, "groupDuty") then
						local playerGroups = getPlayerGroups(source)[groupId]
						local playerRank = playerGroups[1]
						local dutySkin = playerGroups[2]

						setElementData(source, "char.defaultSkin", getElementModel(source))
						setElementModel(source, tonumber(dutySkin))

						if group.duty.armor and group.duty.armor > 0 then
							setElementData(source, "char.defaultArmor", getPedArmor(source))
							setPedArmor(source, group.duty.armor)
						end

						for k,v in ipairs(group.duty.items) do
							local data1, data2
							local give = true

							if v[1] == 86 then -- jelvény
								local badgeId = encodeBadge(groupId, characterId)

								if not exports.sarp_inventory:hasItemWithData(source, v[1], "data2", badgeId) then
									data1 = group.prefix
									data2 = badgeId
								else
									give = false
								end
							end

							if give then
								exports.sarp_inventory:giveItem(source, v[1], v[2], data1, data2, "duty")
							end
						end

						setElementData(source, "groupDuty", true)
						exports.sarp_hud:showInfobox(source, "success", "Sikeresen felvetted a szolgálatot.")
					else
						setElementModel(source, getElementData(source, "char.defaultSkin"))
						removeElementData(source, "char.defaultSkin")

						if getElementData(source, "char.defaultArmor") then
							setPedArmor(source, getElementData(source, "char.defaultArmor"))
							removeElementData(source, "char.defaultArmor")
						end

						setElementData(source, "groupDuty", false)
						exports.sarp_hud:showInfobox(source, "success", "Sikeresen leadtad a szolgálatot.")
					end
				end
			end
		end
	end
)

addEventHandler("onPlayerQuit", getRootElement(),
	function ()
		if getElementData(source, "loggedIn") then
			--exports.sarp_inventory:removePlayerDutyItems(source)
		end
	end
)

addEventHandler("onPlayerWasted", getRootElement(),
	function ()
		if getElementData(source, "loggedIn") then
			--exports.sarp_inventory:removePlayerDutyItems(source)

			removeElementData(source, "char.defaultArmor")
		end
	end
)

addEventHandler("onElementModelChange", getRootElement(),
	function (oldModel, newModel)
		if getElementType(source) == "player" and not getElementData(source, "adminDuty") then
			local modelEnabled = true

			for k,v in pairs(availableGroups) do
				for k2,v2 in ipairs(v.duty.skins) do
					if v2 == newModel and not isPlayerInGroup(source, k) then
						modelEnabled = false
						break
					end
				end

				if not modelEnabled then
					break
				end
			end

			if not modelEnabled then
				setTimer(
					function (player)
						setElementModel(player, oldModel)
					end,
				500, 1, source)

				exports.sarp_hud:showInfobox(source, "error", "Ez a skint csak az adott frakció tagjai hordhatják!")
			end
		end
	end
)

addEvent("updateDutySkin", true)
addEventHandler("updateDutySkin", getRootElement(),
	function (groupId, selectedSkin, originalSkin)
		if groupId and availableGroups[groupId] then
			local characterId = getElementData(source, "char.ID")

			if characterId then
				if getElementData(source, "groupDuty") then
					setElementModel(source, selectedSkin)
				else
					setElementModel(source, originalSkin)
				end

				dbExec(connection, "UPDATE groupMembers SET dutySkin = ? WHERE groupID = ? AND characterID = ?", selectedSkin, groupId, characterId)
			end
		end
	end
)

function setGroupMoney(groupId, amount)
	if groupId and availableGroups[groupId] and amount and tonumber(amount) then
		amount = tonumber(amount)

		local currentBalance = availableGroups[groupId].balance

		currentBalance = currentBalance + amount

		availableGroups[groupId].balance = currentBalance

		dbQuery(
			function (qh)
				triggerClientEvent("modifyGroupData", getResourceRootElement(), groupId, "balance", false, currentBalance)

				dbFree(qh)
			end, connection, "UPDATE groups SET balance = ? WHERE groupID = ?", currentBalance, groupId
		)
	end
end