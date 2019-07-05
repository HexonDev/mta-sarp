local protected = true
local whitelist = {}

addEventHandler("onResourceStart", getResourceRootElement(),
	function()
		local file = fileOpen("whitelist.json")

		if file then
			local json_data = fileRead(file, fileGetSize(file))

			fileClose(file)

			json_data = fromJSON(json_data)

			if json_data then
				protected = json_data.state == "on"
				whitelist = json_data.list

				table.sort(whitelist,
					function(a, b)
						return a[1] < b[1]
					end)
			end
		end
	end)

addEventHandler("onPlayerConnect", getRootElement(),
	function(playerNick, playerIP, playerUsername, playerSerial, playerVersionNumber, playerVersionString)
		if protected then
			if whitelist[playerSerial] and whitelist[playerSerial][2] then
				for k, v in pairs(getElementsByType("player")) do
					if v ~= source then
						outputChatBox("#dc143c>> SARP - WhiteList: #4aabd0" .. playerNick .. " (" .. whitelist[playerSerial][1] .. ") #FFFFFFcsatlakozott a szerverre.", v, 0, 0, 0, true)
					end
				end
			else
				for k, v in pairs(getElementsByType("player")) do
					if v ~= source then
						outputChatBox("#dc143c>> SARP - WhiteList: #ffa600" .. playerNick .. " #FFFFFFmegpróbált csatlakozni a szerverre.", v, 0, 0, 0, true)
					end
				end

				cancelEvent(true, "Nem vagy fent az engedélyezettek listáján! ~SARP")
			end
		end
	end)

addCommandHandler("checkserial",
	function(player, command, serial)
		if getElementData(player, "acc.adminLevel") >= 8 then
			outputChatBox("Whitelist védelem: " .. (protected and "#7cc576aktív" or "#dc143ckikapcsolva"), player, 255, 255, 255, true)

			if serial then
				if not whitelist[serial] then
					outputChatBox("A kiválasztott serial nincs benne a whitelistben!", player, 215, 89, 89, true)
				else
					outputChatBox("A kiválasztott serial adatai:", player, 215, 89, 89, true)
					outputChatBox("    * Név: #4aabd0" .. whitelist[serial][1], player, 255, 255, 255, true)
					outputChatBox("    * Állapot: " .. (whitelist[serial][2] and "#7cc576aktiválva" or "#d75959deaktiválva"), player, 255, 255, 255, true)
				end
			end
		end
	end)

function getList()
	if whitelist then
		return protected, whitelist
	end

	return true, false
end

function toggleMode(state)
	if state then
		protected = state == "on"

		saveList()
	end

	return false
end

function toggleUser(serial, request)
	if serial and request then
		if whitelist[serial] then
			if request == "remove" then
				whitelist[serial] = nil
			elseif request == "deactivate" then
				whitelist[serial][2] = false
			elseif request == "activate" then
				whitelist[serial][2] = true
			end

			saveList()
		end

		return true
	end

	return false
end

function addUser(serial, name)
	if serial and name then
		if not whitelist[serial] then
			whitelist[serial] = {name, true}

			saveList()

			return true
		else
			return false, "A kiválasztott serial már hozzá lett adva!"
		end
	end

	return false, "Hiba történt a felhasználó hozzáadása során!"
end

function saveList()
	if fileExists("whitelist.json") then
		fileDelete("whitelist.json")
	end

	local file = fileCreate("whitelist.json")

	if file then
		local temp = {}

		temp.state = protected and "on" or "off"
		temp.list = whitelist

		fileWrite(file, toJSON(temp))
		fileFlush(file)
		fileClose(file)

		return true
	end
end