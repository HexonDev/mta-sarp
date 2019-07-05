maxGroupRank = 40

groupTypes = {
	law_enforcement = "Rendvédelem",
	government = "Önkormányzat",
	mafia = "Maffia",
	gang = "Banda",
	organisation = "Szervezet",
	other = "Egyéb"
}

groupTypesEx = {}

for k, v in pairs(groupTypes) do
	table.insert(groupTypesEx, v)
end

availablePermissions = {
	jail = "Börtönbe zárás", -- Kész
	ticket = "Csekk kiadás", -- Kész
	megaPhone = "Megafon", -- Kész
	roadBlock = "Útzár",
	wheelClamp = "Kerékbilincs", -- Kész
	cuff = "Bilincselés", -- Kész
	doorRammer = "Faltörő kos",
	heal = "Gyógyítás",
	reanimation = "Újraélesztés",
	hiddenName = "Rejtett név",
	trackPhone = "Telefon lenyomozás",
	impoundVehicle = "Jármű lefoglalás", -- Kész
	unlockVehicle = "Jármű kinyitás",
	departmentRadio = "Sürgősségi rádió (/d)" -- Kész
}

availablePermissionsEx = {}

for k, v in pairs(availablePermissions) do
	table.insert(availablePermissionsEx, k)
end

availableGroups = {}
availableGroupsCount = 0

table.length = function (tbl)
	local count = 0

	for _ in pairs(tbl) do
		count = count + 1
	end

	return count
end

function getGroups()
	return availableGroups
end

function getGroupTypes()
	return groupTypes
end

function addPlayerGroup(player, groupId, dutySkin)
	if isElement(player) and tonumber(groupId) then
		groupId = tonumber(groupId)

		if availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and not playerGroups[groupId] then
				playerGroups[groupId] = {1, (dutySkin or availableGroups[groupId].duty.skins[1]), "N"}

				setElementData(player, "player.groups", playerGroups)

				return true
			end
		end
	end
	
	return false
end

function removePlayerGroup(player, groupId)
	if isElement(player) and groupId then
		groupId = tonumber(groupId)

		if groupId and availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and playerGroups[groupId] then
				playerGroups[groupId] = nil

				setElementData(player, "player.groups", playerGroups)

				return true
			end
		end
	end
	
	return false
end

function setPlayerLeader(player, groupId, state)
	if isElement(player) and groupId then
		groupId = tonumber(groupId)

		if groupId and availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and playerGroups[groupId] then
				playerGroups[groupId][3] = state

				setElementData(player, "player.groups", playerGroups)

				return true
			end
		end
	end
	
	return false
end

function isPlayerLeaderInGroup(player, groupId)
	if isElement(player) and groupId then
		groupId = tonumber(groupId)

		if groupId and availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and playerGroups[groupId] and utf8.lower(playerGroups[groupId][3]) == "y" then
				return true
			end
		end
	end

	return false
end

function isPlayerInGroup(player, groupId)
	if isElement(player) and groupId then
		groupId = tonumber(groupId)

		if groupId and availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and playerGroups[groupId] then
				return true
			end
		end
	end

	return false
end

function getPlayerGroups(player)
	if isElement(player) then
		local playerGroups = getElementData(player, "player.groups") or {}
		
		if playerGroups then
			return playerGroups
		end
	end
	
	return false
end

function setPlayerRank(player, groupId, rankId)
	if isElement(player) then
		groupId = tonumber(groupId)
		rankId = tonumber(rankId)

		if groupId and rankId and availableGroups[groupId] then
			local playerGroups = getElementData(player, "player.groups") or {}
			
			if playerGroups and playerGroups[groupId] then
				playerGroups[groupId][1] = rankId

				setElementData(player, "player.groups", playerGroups)

				return true
			end
		end
	end
	
	return false
end

function getPlayerRank(player, groupId)
	if isElement(player) and groupId then
		groupId = tonumber(groupId)

		if availableGroups[groupId] then
			local rankId = (getElementData(player, "player.groups") or {})[groupId][1]
			
			if rankId and availableGroups[groupId].ranks[rankId] then
				return rankId, availableGroups[groupId].ranks[rankId].name, availableGroups[groupId].ranks[rankId].pay
			end
		end
	end

	return false
end

function getGroupPrefix(groupId)
	if groupId and availableGroups[groupId] then
		return availableGroups[groupId].prefix
	end
	
	return false
end

function getGroupName(groupId)
	if groupId and availableGroups[groupId] then
		return availableGroups[groupId].name
	end
	
	return false
end

function isPlayerHavePermission(player, permission)
	if isElement(player) and permission then
		local playerGroups = getElementData(player, "player.groups") or {}

		if playerGroups then
			for k, v in pairs(playerGroups) do
				if availableGroups[k] and availableGroups[k].permissions[permission] then
					return k
				end
			end
		end
	end

	return false
end

function thousandsStepper(amount, stepper)
	local left, center, right = string.match(math.floor(amount), "^([^%d]*%d)(%d*)(.-)$")
	return left .. string.reverse(string.gsub(string.reverse(center), "(%d%d%d)", "%1" .. (stepper or " "))) .. right
end