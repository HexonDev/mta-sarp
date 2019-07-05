local adminTitles = {
	[1] = "Admin[1]",
	[2] = "Admin[2]",
	[3] = "Admin[3]",
	[4] = "Admin[4]",
	[5] = "Admin[5]",
	[6] = "Főadmin",
	[7] = "Szuper Admin",
	[8] = "Rendszergazda",
	[9] = "Tulajdonos",
	[10] = "Fejlesztő"
}

local adminRankColors = {
	[0] = "#ffffff",
	default = "#95aab2",
	[6] = "#3cff00",
	[7] = "#fc8f00",
	[9] = "#ff2c2c",
	[10] = "#32b3ef"
}

local helperTitles = {
	[1] = "Ideiglenes Adminsegéd",
	[2] = "Adminsegéd"
}

local helperRankColors = {
	[1] = "#acd373",
	[2] = "#7cc576"
}

function getPlayerHelperLevel(player)
	return isElement(player) and tonumber(getElementData(player, "acc.helperLevel")) or 0
end

function getPlayerHelperTitle(player)
	return helperTitles[getPlayerHelperLevel(player)] or ""
end

function getPlayerHelperTitleByLevel(level)
	return helperTitles[level] or ""
end

function getHelperLevelColor(level)
	return helperRankColors[level] or "#ffffff"
end

function getPlayerAdminLevel(player)
	return isElement(player) and tonumber(getElementData(player, "acc.adminLevel")) or 0
end

function getPlayerAdminTitle(player)
	return adminTitles[getPlayerAdminLevel(player)] or ""
end

function getPlayerAdminTitleByLevel(level)
	return adminTitles[level] or ""
end

function getAdminLevelColor(level)
	return adminRankColors[level] or adminRankColors.default
end

function getLevel(player)
	if isElement(player) then
		local playedMinutes = getElementData(player, "char.playedMinutes") or 0
		
		return math.ceil(playedMinutes * 0.25 / 60) + 1
	end
end

function findPlayer(player, partialNick)
	if not partialNick and not isElement(player) and type(player) == "string" then
		partialNick = player
		player = nil
	end
	
	local candidates = {}
	local matchPlayer = nil
	local matchNick = nil
	local matchNickAccuracy = -1
	local partialNick = string.lower(partialNick)
	
	if player and partialNick == "*" then
		return player, string.gsub(getPlayerName(player), "_", " ")
	elseif tonumber(partialNick) then
		for k, v in ipairs(getElementsByType("player")) do
			if getElementData(v, "loggedIn") and getElementData(v, "playerID") == tonumber(partialNick) then
				matchPlayer = v
				break
			end
		end
		candidates = {matchPlayer}
	else
		partialNick = string.gsub(partialNick, "-", "%%-")
		
		for k, v in ipairs(getElementsByType("player")) do
			if isElement(v) then
				local playerName = string.lower(string.gsub(getElementData(v, "visibleName") or getPlayerName(v), "_", " "))

				if playerName and string.find(playerName, tostring(partialNick)) then
					local posStart, posEnd = string.find(playerName, tostring(partialNick))
					
					if posEnd - posStart > matchNickAccuracy then
						matchNickAccuracy = posEnd - posStart
						matchNick = playerName
						matchPlayer = v
						candidates = {v}
					elseif posEnd - posStart == matchNickAccuracy then
						matchNick = nil
						matchPlayer = nil
						table.insert(candidates, v)
					end
				end
			end
		end
	end
	
	if not matchPlayer or not isElement(matchPlayer) then
		if isElement(player) then
			if #candidates == 0 then
				outputChatBox("#32b3ef>> SARP: #FFFFFFA kiválasztott játékos #d75959nem található.", player, 255, 255, 255, true)
			else
				outputChatBox("#32b3ef>> SARP: #d75959" .. #candidates .. " #FFFFFFjátékos található ezzel a névrészlettel:", player, 255, 255, 255, true)
			
				for k = 1, #candidates do
					local v = candidates[k]

					if isElement(v) then
						outputChatBox("#cdcdcd>> #32b3ef(" .. tostring(getElementData(v, "playerID")) .. ") #fffffff" .. string.gsub(getPlayerName(v), "_", " "), player, 255, 255, 255, true)
					end
				end
			end
		end
		
		return false
	else
		if getElementData(matchPlayer, "loggedIn") then
			return matchPlayer, string.gsub(getElementData(matchPlayer, "visibleName") or getPlayerName(matchPlayer), "_", " ")
		else
			outputChatBox("#32b3ef>> SARP: #FFFFFFA kiválasztott játékos #d75959nincs bejelentkezve.", player, 255, 255, 255, true)
			return false
		end
	end
end

local weekDays = {"Vasárnap", "Hétfő", "Kedd", "Szerda", "Csütörtök", "Péntek", "Szombat"}

function formatDate(format, escaper, timestamp)
	escaper = escaper or "'"
	escaper = string.sub(escaper, 1, 1)

	local time = getRealTime(timestamp)
	local formattedDate = ""
	local escaped = false

	time.year = time.year + 1900
	time.month = time.month + 1
	
	local datetime = {
		d = string.format("%02d", time.monthday),
		h = string.format("%02d", time.hour),
		i = string.format("%02d", time.minute),
		m = string.format("%02d", time.month),
		s = string.format("%02d", time.second),
		w = string.sub(weekDays[time.weekday + 1], 1, 2),
		W = weekDays[time.weekday + 1],
		y = string.sub(tostring(time.year), -2),
		Y = time.year
	}
	
	for char in string.gmatch(format, ".") do
		if char == escaper then
			escaped = not escaped
		else
			formattedDate = formattedDate .. (not escaped and datetime[char] or char)
		end
	end
	
	return formattedDate
end

function getMoney(player)
	return getElementData(player, "char.Money") or 0
end

function setMoney(player, amount)
	if amount then
		setElementData(player, "char.Money", tonumber(amount), true)
	end
end

function takeMoney(player, amount, saveLog)
	if amount then
		if getElementData(player, "char.Money") - tonumber(amount) >= 0 then
			setElementData(player, "char.Money", getElementData(player, "char.Money") - tonumber(amount), true)

			if saveLog then
				exports.sarp_logs:logEconomy(player, "take:" .. saveLog, -amount)
			end

			return true
		else
			return false
		end
	end
end

function takeMoneyEx(player, amount, saveLog)
	if amount then
		setElementData(player, "char.Money", getElementData(player, "char.Money") - tonumber(amount), true)

		if saveLog then
			exports.sarp_logs:logEconomy(player, "takeex:" .. saveLog, -amount)
		end
	end
end

function giveMoney(player, amount, saveLog)
	if amount then
		setElementData(player, "char.Money", getElementData(player, "char.Money") + tonumber(amount), true)

		if saveLog then
			exports.sarp_logs:logEconomy(player, "give:" .. saveLog, amount)
        end
        
        return true 
    end
    
    return false
end

function findVehicleByID(vehicleId)
	if vehicleId then
		vehicleId = tonumber(vehicleId)

		local vehicles = getElementsByType("vehicle")

		for k = 1, #vehicles do
			local v = vehicles[k]

			if isElement(v) then
				local databaseId = getElementData(v, "vehicle.dbID") or 0

				if databaseId == vehicleId then
					return v
				end
			end
		end
	end

	return false
end

function toboolean(value)
	if value == 1 or value == "true" then
		return true
	else
		return false
	end
end

function inDistance3D(element1, element2, distance)
	if isElement(element1) and isElement(element2) then
	    local x1, y1, z1 = getElementPosition(element1)
	    local x2, y2, z2 = getElementPosition(element2)
	    local distance2 = getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)

	    if distance2 <= distance then
	        return true, distance2
	    end
	end

    return false, 99999
end

function inDistance2D(element1, element2, distance)
	if isElement(element1) and isElement(element2) then
	    local x1, y1, z1 = getElementPosition(element1)
	    local x2, y2, z2 = getElementPosition(element2)
	    local distance2 = getDistanceBetweenPoints2D(x1, y1, x2, y2)

	    if distance2 <= distance then
	        return true, distance2
	    end
	end
	
    return false, 99999
end

local serverTags = {
	["info"] = "#cdcdcd>> Információ: #ffffff",
	["error"] = "#ff4646>> Hiba: #ffffff",
	["admin"] = "#ff4646>> Adminisztráció: #ffffff",
	["usage"] = "#32b3ef>> Használat: #ffffff",
	["sarp"] = "#32b3ef>> SA-RP: #ffffff",
	["tip"] = "#ff9428>> Tipp: #ffffff",
 }

function getServerTag(type)
	return serverTags[type] or serverTags["sarp"]
end