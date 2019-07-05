local smileyTable = {
	[":D"] = "nevet",
	["xD"] = "szakad a röhögéstől",
	[":$"] = "elpirul",
	[":P"] = "nyelvet ölt",
	[":p"] = "nyelvet ölt",
	[":("] = "szomorú",
	[":-("] = "szomorú",
	["):"] = "szomorú",
	[":)"] = "mosolyog",
	["(:"] = "mosolyog",
	[";-)"] = "kacsint",
	["(-;"] = "kacsint",
	[":@"] = "mérges",
	[";D"] = "nagyot kacsint",
	[";-D"] = "nagyot kacsint",
	["xd"] = "szakad a röhögéstől",
	["XD"] = "szakad a röhögéstől",
	["Xd"] = "szakad a röhögéstől",
	["^^"] = "vihog",
	[":'("] = "sír",
	["-.-"] = "sóhajt",
	[":O"] = "meglepődik",
	[":o"] = "meglepődik",
	["o.O"] = "meglepődik",
	["O.o"] = "meglepődik"
}

addCommandHandler("say",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
			else
				sendLocalMessage(localPlayer, string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", ""))
			end
		end
	end
)

addCommandHandler("me",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Cselekvés]", 255, 255, 255, true)
			else
				sendLocalMeAction(localPlayer, string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", ""))
			end
		end
	end
)

addCommandHandler("do",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Történés]", 255, 255, 255, true)
			else
				sendLocalDoAction(localPlayer, string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", ""))
			end
		end
	end
)

addCommandHandler("ame",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Vizuális leírás]", 255, 255, 255, true)
			else
				sendLocalAmeAction(localPlayer, string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", ""))
			end
		end
	end
)

function literalize(message)
	return message:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]",
		function (character)
			return "%" .. character
		end
	)
end

function firstToUpper(text)
	return (text:gsub("^%l", string.upper))
end

function RGBToHex(r, g, b)
	return string.format("#%.2X%.2X%.2X", r, g, b)
end

function sendLocalMessage(player, message)
	if string.len(message) > 0 then
		local adminDuty = getElementData(player, "adminDuty")
		
		if not adminDuty then
			local canLaugh = false

			for k, v in pairs(smileyTable) do
				if utf8.find(message, k, 1, true) then
					canLaugh = v
					sendLocalMeAction(player, v)
					message = utf8.gsub(message, literalize(k), "")
				end
			end

			if canLaugh == "szakad a röhögéstől" or canLaugh == "nevet" then
				triggerServerEvent("laughAnim", player)
			end
		end

		if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
			local occupiedVehicle = getPedOccupiedVehicle(player)
			local additionalStr = ""

			local pendingPlayers = {}
			local pendingCount = 0

			if occupiedVehicle and not getElementData(occupiedVehicle, "vehicle.windowState") then
				additionalStr = " (járműben)"

				for k, v in pairs(getVehicleOccupants(occupiedVehicle)) do
					if v ~= player then
						table.insert(pendingPlayers, {v, "#FFFFFF"})
						pendingCount = pendingCount + 1
					end
				end
			else
				local playerPosX, playerPosY, playerPosZ = getElementPosition(player)

				for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
					if v ~= localPlayer then
						local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))

						if distance <= 8 then
							table.insert(pendingPlayers, {v, RGBToHex(interpolateBetween(255, 255, 255, 50, 50, 50, distance / 8, "Linear"))})
							pendingCount = pendingCount + 1
						end
					end
				end
			end

			local visibleName = getElementData(player, "visibleName"):gsub("_", " ")
			local adminLevel = getElementData(player, "acc.adminLevel") or 0
			local adminTitle = exports.sarp_core:getPlayerAdminTitleByLevel(adminLevel)
			local adminTitleColor = exports.sarp_core:getAdminLevelColor(adminLevel)

			if not adminDuty or player ~= localPlayer then
				outputChatBox("#FFFFFF" .. visibleName .. " mondja" .. additionalStr .. ": " .. firstToUpper(message), 16, 16, 16, true)
			else
				outputChatBox(adminTitleColor .. "[" .. adminTitle .. "] " .. visibleName .. " mondja" .. additionalStr .. ": " .. firstToUpper(message), 16, 16, 16, true)
			end

			local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
			if spectatingPlayers then
				for k, v in pairs(spectatingPlayers) do
					if isElement(k) then
						table.insert(pendingPlayers, {k, "#FFFFFF"})
						pendingCount = pendingCount + 1
					end
				end
			end

			if pendingCount > 0 then
				triggerServerEvent("onLocalMessage", localPlayer, pendingPlayers, visibleName, firstToUpper(message), additionalStr, adminLevel, adminTitle, adminTitleColor, adminDuty)
			end
		end
	end
end
addEvent("onClientPlayerLocalMessage", true)
addEventHandler("onClientPlayerLocalMessage", getRootElement(), sendLocalMessage)

function sendLocalMeAction(player, message)
	if string.len(message) > 0 then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(player)
		local visibleName = getElementData(player, "visibleName"):gsub("_", " ")

		local pendingPlayers = {}
		local pendingCount = 0

		for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
			if v ~= (getElementType(player) == "ped" and localPlayer or player) and getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 then
				table.insert(pendingPlayers, v)
				pendingCount = pendingCount + 1
			end
		end

		outputChatBox("#C2A2DA*** " .. visibleName .. " #C2A2DA" .. message, 32, 32, 32, true)

		local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
		if spectatingPlayers then
			for k, v in pairs(spectatingPlayers) do
				if isElement(k) then
					table.insert(pendingPlayers, k)
					pendingCount = pendingCount + 1
				end
			end
		end

		if pendingCount > 0 then
			triggerServerEvent("onActionMessage", getElementType(player) == "ped" and localPlayer or player, pendingPlayers, visibleName, message)
		end
	end
end
addEvent("onClientPlayerLocalMe", true)
addEventHandler("onClientPlayerLocalMe", getRootElement(), sendLocalMeAction)

addCommandHandler("dme",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Cselekvés]", 255, 255, 255, true)
			else
				local currentStandingMarker = exports.sarp_interiors:getCurrentStandingMarker()

				if currentStandingMarker then
					local interiorData = exports.sarp_interiors:getInteriorData(currentStandingMarker)

					if interiorData then
						local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

						if string.len(message) > 0 then
							local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
							local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

							local pendingPlayers = {}
							local pendingCount = 0

							for k, v in ipairs(getElementsByType("player")) do
								if v ~= localPlayer then
									if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 or getElementDimension(v) == interiorData.exit.dimension then
										table.insert(pendingPlayers, v)
										pendingCount = pendingCount + 1
									end
								end
							end

							outputChatBox("#C2A2DA*** " .. visibleName .. " #C2A2DA" .. message, 32, 32, 32, true)

							local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
							if spectatingPlayers then
								for k, v in pairs(spectatingPlayers) do
									if isElement(k) then
										table.insert(pendingPlayers, k)
										pendingCount = pendingCount + 1
									end
								end
							end

							if pendingCount > 0 then
								triggerServerEvent("onActionMessage", localPlayer, pendingPlayers, visibleName, message)
							end
						end
					else
						exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
					end
				else
					exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
				end
			end
		end
	end
)

addCommandHandler("ddo",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Történés]", 255, 255, 255, true)
			else
				local currentStandingMarker = exports.sarp_interiors:getCurrentStandingMarker()

				if currentStandingMarker then
					local interiorData = exports.sarp_interiors:getInteriorData(currentStandingMarker)

					if interiorData then
						local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

						if string.len(message) > 0 then
							local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
							local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

							local pendingPlayers = {}
							local pendingCount = 0

							for k, v in ipairs(getElementsByType("player")) do
								if v ~= localPlayer then
									if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 or getElementDimension(v) == interiorData.exit.dimension then
										table.insert(pendingPlayers, v)
										pendingCount = pendingCount + 1
									end
								end
							end

							outputChatBox("#FF2850* " .. firstToUpper(message) .. " ((#FF2850" .. visibleName .. "))", 64, 64, 64, true)

							local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
							if spectatingPlayers then
								for k, v in pairs(spectatingPlayers) do
									if isElement(k) then
										table.insert(pendingPlayers, k)
										pendingCount = pendingCount + 1
									end
								end
							end

							if pendingCount > 0 then
								triggerServerEvent("onDoMessage", localPlayer, pendingPlayers, visibleName, message)
							end
						end
					else
						exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
					end
				else
					exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
				end
			end
		end
	end
)

function sendLocalDoAction(player, message)
	if string.len(message) > 0 then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(player)
		local visibleName = getElementData(player, "visibleName"):gsub("_", " ")

		local pendingPlayers = {}
		local pendingCount = 0

		for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
			if v ~= (getElementType(player) == "ped" and localPlayer or player) and getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 then
				table.insert(pendingPlayers, v)
				pendingCount = pendingCount + 1
			end
		end

		outputChatBox("#FF2850* " .. firstToUpper(message) .. " ((#FF2850" .. visibleName .. "))", 64, 64, 64, true)

		local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
		if spectatingPlayers then
			for k, v in pairs(spectatingPlayers) do
				if isElement(k) then
					table.insert(pendingPlayers, k)
					pendingCount = pendingCount + 1
				end
			end
		end

		if pendingCount > 0 then
			triggerServerEvent("onDoMessage", getElementType(player) == "ped" and localPlayer or player, pendingPlayers, visibleName, message)
		end
	end
end
addEvent("onClientPlayerLocalDo", true)
addEventHandler("onClientPlayerLocalDo", getRootElement(), sendLocalDoAction)

addCommandHandler("c",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
			else
				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

				if #message > 0 and utf8.len(message) > 0 then
					local canLaugh = false

					for k, v in pairs(smileyTable) do
						if utf8.find(message, k, 1, true) then
							canLaugh = v
							sendLocalMeAction(localPlayer, v)
							message = utf8.gsub(message, literalize(k), "")
						end
					end

					if canLaugh == "szakad a röhögéstől" or canLaugh == "nevet" then
						triggerServerEvent("laughAnim", localPlayer)
					end

					
					if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
						local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
						local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
						local additionalStr = " (suttogva)"

						local pendingPlayers = {}
						local pendingCount = 0

						if occupiedVehicle and not getElementData(occupiedVehicle, "vehicle.windowState") then
							additionalStr = additionalStr .. "(járműben)"
							
							for k, v in pairs(getVehicleOccupants(occupiedVehicle)) do
								if v ~= localPlayer then
									table.insert(pendingPlayers, {v, "#FFFFFF"})
									pendingCount = pendingCount + 1
								end
							end
						else
							local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

							for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
								if v ~= localPlayer then
									local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))
									if distance <= 4 then
										table.insert(pendingPlayers, {v, RGBToHex(interpolateBetween(255, 255, 255, 70, 70, 70, distance / 4, "Linear"))})
										pendingCount = pendingCount + 1
									end
								end
							end
						end
						
						outputChatBox("#FFFFFF" .. visibleName .. " mondja" .. additionalStr .. ": " .. firstToUpper(message), 128, 128, 128, true)
						
						local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
						if spectatingPlayers then
							for k, v in pairs(spectatingPlayers) do
								if isElement(k) then
									table.insert(pendingPlayers, {k, "#FFFFFF"})
									pendingCount = pendingCount + 1
								end
							end
						end

						if pendingCount > 0 then
							triggerServerEvent("onWhisperMessage", localPlayer, pendingPlayers, visibleName, firstToUpper(message), additionalStr)
						end
					end
				end
			end
		end
	end
)

addCommandHandler("ds",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
			else
				local currentStandingMarker = exports.sarp_interiors:getCurrentStandingMarker()

				if currentStandingMarker then
					local interiorData = exports.sarp_interiors:getInteriorData(currentStandingMarker)

					if interiorData then
						if not isPedInVehicle(localPlayer) then
							local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

							if #message > 0 and utf8.len(message) > 0 then
								if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
									triggerServerEvent("shoutAnim", localPlayer)
									
									local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
									local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
									local pendingPlayers = {}
									local pendingCount = 0
									
									for k, v in ipairs(getElementsByType("player")) do
										if v ~= localPlayer then
											local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))
											
											if getElementDimension(v) == interiorData.exit.dimension then
												table.insert(pendingPlayers, {v, "#FFFFFF"})
												pendingCount = pendingCount + 1
											elseif distance <= 20 then
												table.insert(pendingPlayers, {v, RGBToHex(interpolateBetween(255, 255, 255, 70, 70, 70, distance / 20, "Linear"))})
												pendingCount = pendingCount + 1
											end
										end
									end
									
									outputChatBox("#FFFFFF" .. visibleName .. " ordítja: " .. firstToUpper(message), 128, 128, 128, true)
									
									local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
									if spectatingPlayers then
										for k, v in pairs(spectatingPlayers) do
											if isElement(k) then
												table.insert(pendingPlayers, {k, "#FFFFFF"})
												pendingCount = pendingCount + 1
											end
										end
									end

									if pendingCount > 0 then
										triggerServerEvent("onShoutMessage", localPlayer, pendingPlayers, visibleName, firstToUpper(message), "")
									end
								end
							end
						else
							exports.sarp_hud:showInfobox("error", "Járműben ülve nem ordíthatsz be az ingatlanba!")
						end
					else
						exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
					end
				else
					exports.sarp_hud:showInfobox("error", "A parancs használatához egy interior markerben kell lenned!")
				end
			end
		end
	end
)

addCommandHandler("s",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
			else
				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

				if #message > 0 and utf8.len(message) > 0 then
					if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
						triggerServerEvent("shoutAnim", localPlayer)
						
						local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
						local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
						local additionalStr = ""

						local pendingPlayers = {}
						local pendingCount = 0
						
						if occupiedVehicle and not getElementData(occupiedVehicle, "vehicle.windowState") then
							additionalStr = additionalStr .. "(járműben)"
							
							for k, v in pairs(getVehicleOccupants(occupiedVehicle)) do
								if v ~= localPlayer then
									table.insert(pendingPlayers, {v, "#FFFFFF"})
									pendingCount = pendingCount + 1
								end
							end
						else
							local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

							for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
								if v ~= localPlayer then
									local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))
									
									if distance <= 20 then
										table.insert(pendingPlayers, {v, RGBToHex(interpolateBetween(255, 255, 255, 70, 70, 70, distance / 20, "Linear"))})
										pendingCount = pendingCount + 1
									end
								end
							end
						end
						
						outputChatBox("#FFFFFF" .. visibleName .. " ordítja" .. additionalStr .. ": " .. firstToUpper(message), 128, 128, 128, true)
						
						local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
						if spectatingPlayers then
							for k, v in pairs(spectatingPlayers) do
								if isElement(k) then
									table.insert(pendingPlayers, {k, "#FFFFFF"})
									pendingCount = pendingCount + 1
								end
							end
						end

						if pendingCount > 0 then
							triggerServerEvent("onShoutMessage", localPlayer, pendingPlayers, visibleName, firstToUpper(message), additionalStr)
						end
					end
				end
			end
		end
	end
)

function tryCommand(command, ...)
	if getElementData(localPlayer, "loggedIn") then
		if not (...) then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
		else
			local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

			if #message > 0 and utf8.len(message) > 0 then
				local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

				local pendingPlayers = {}
				local pendingCount = 0
				
				for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
					if v ~= localPlayer and getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 then
						table.insert(pendingPlayers, v)
						pendingCount = pendingCount + 1
					end
				end
				
				local tryResult = math.random(1, 2)
				
				if command == "megprobal" or command == "megpróbál" then
					if tryResult == 1 then
						outputChatBox(" *** " .. visibleName .. " megpróbál " .. message .. " és sikerül neki.", 91, 193, 65, true)
					elseif tryResult == 2 then
						outputChatBox(" *** " .. visibleName .. " megpróbál " .. message .. " de sajnos nem sikerül neki.", 193, 65, 65, true)
					end
				elseif command == "megprobalja" or command == "megpróbálja" then
					if tryResult == 1 then
						outputChatBox(" *** " .. visibleName .. " megpróbálja " .. message .. " és sikerül neki.", 91, 193, 65, true)
					elseif tryResult == 2 then
						outputChatBox(" *** " .. visibleName .. " megpróbálja " .. message .. " de sajnos nem sikerül neki.", 193, 65, 65, true)
					end
				end

				local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
				if spectatingPlayers then
					for k, v in pairs(spectatingPlayers) do
						if isElement(k) then
							table.insert(pendingPlayers, k)
							pendingCount = pendingCount + 1
						end
					end
				end
				
				if pendingCount > 0 then
					triggerServerEvent("onTryMessage", localPlayer, pendingPlayers, visibleName, message, tryResult, command)
				end
			end
		end
	end
end
addCommandHandler("megprobal", tryCommand)
addCommandHandler("megpróbál", tryCommand)
addCommandHandler("megprobalja", tryCommand)
addCommandHandler("megpróbálja", tryCommand)

function onOOCChat(command, ...)
	local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")
	
	if #message > 0 and utf8.len(message) > 0 and utf8.len(message) <= 128 then
		local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

		local pendingPlayers = {}
		local pendingCount = 0
		
		for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
			if v ~= localPlayer and getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 then
				table.insert(pendingPlayers, v)
				pendingCount = pendingCount + 1
			end
		end
		
		triggerEvent("onClientRecieveOOCMessage", localPlayer, message, visibleName)

		local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
		if spectatingPlayers then
			for k, v in pairs(spectatingPlayers) do
				if isElement(k) then
					table.insert(pendingPlayers, k)
					pendingCount = pendingCount + 1
				end
			end
		end
		
		if pendingCount > 0 then
			triggerServerEvent("onOOCMessage", localPlayer, pendingPlayers, visibleName, message)
		end
	end
end
addCommandHandler("b", onOOCChat)
addCommandHandler("LocalOOC", onOOCChat)
bindKey("b", "down", "chatbox", "LocalOOC")

function sendLocalAmeAction(player, message)
	if string.len(message) > 0 then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(player)
		local visibleName = getElementData(player, "visibleName"):gsub("_", " ")

		local pendingPlayers = {}
		local pendingCount = 0

		for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
			if v ~= (getElementType(player) == "ped" and localPlayer or player) and getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v)) <= 12 then
				table.insert(pendingPlayers, v)
				pendingCount = pendingCount + 1
			end
		end

		outputChatBox("#a2b7da> " .. visibleName .. " #a2b7da" .. message, 164, 164, 164, true)

		local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
		if spectatingPlayers then
			for k, v in pairs(spectatingPlayers) do
				if isElement(k) then
					table.insert(pendingPlayers, k)
					pendingCount = pendingCount + 1
				end
			end
		end

		if pendingCount > 0 then
			triggerServerEvent("onVisualDescriptionMessage", getElementType(player) == "ped" and localPlayer or player, pendingPlayers, visibleName, message)
		end
	end
end
addEvent("onClientPlayerLocalAme", true)
addEventHandler("onClientPlayerLocalAme", getRootElement(), sendLocalAmeAction)

bindKey("y", "down", "chatbox", "Rádió")

addEvent("localRadioMessage", true)
addEventHandler("localRadioMessage", getRootElement(),
	function (message)
		if message then
			local pendingPlayers = {}
			local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
			local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

			if occupiedVehicle and not getElementData(occupiedVehicle, "vehicle.windowState") then
				for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
					if v ~= localPlayer then
						table.insert(pendingPlayers, {v, "#FFFFFF"})
					end
				end
			else
				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

				for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
					if v ~= localPlayer then
						local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))

						if distance <= 12 then
							table.insert(pendingPlayers, {v, string.format("#%.2X%.2X%.2X", interpolateBetween(255, 255, 255, 50, 50, 50, distance / 12, "Linear"))})
						end
					end
				end
			end
			
			triggerServerEvent("localRadioMessage", localPlayer, pendingPlayers, visibleName, message)
		end
	end
)

addEvent("playRadioSound", true)
addEventHandler("playRadioSound", getRootElement(),
	function (pendingPlayers)
		for k, v in pairs(pendingPlayers) do
			if isElement(v) then
				local soundEffect = playSound3D("files/radionoise.wav", getElementPosition(v))

				if isElement(soundEffect) then
					setElementInterior(soundEffect, getElementInterior(v))
					setElementDimension(soundEffect, getElementDimension(v))
					setSoundMaxDistance(soundEffect, 12)
					setSoundVolume(soundEffect, 0.5)
					attachElements(soundEffect, v)
				end
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		setTimer(engineLoadIFP, 2000, 1, "files/megaphone.ifp", "megaphone_talk")
	end
)

addCommandHandler("m",
	function (command, ...)
		if getElementData(localPlayer, "loggedIn") and exports.sarp_groups:isPlayerHavePermission(localPlayer, "megaPhone") then
			if not (...) then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Üzenet]", 255, 255, 255, true)
			else
				local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
				local canUseMegaphone = true

				if occupiedVehicle and not getElementData(occupiedVehicle, "vehicle.sirenPanel") then
					canUseMegaphone = false
				end

				if not getElementData(localPlayer, "canUseMegaphone") then
					canUseMegaphone = false
				else
					canUseMegaphone = true
				end

				if not canUseMegaphone then
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A jármű amiben ülsz, nem rendelkezik megafonnal, vagy nincs a kezedben megafon!", 215, 89, 89, true)
					return
				end

				local message = string.gsub(table.concat({...}, " "), "#%x%x%x%x%x%x", "")

				if #message > 0 and utf8.len(message) > 0 then
					if utf8.len((utf8.gsub(message, " ", "") or 0)) > 0 then
						local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
						local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

						local pendingPlayers = {}
						local pendingCount = 0

						for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
							if v ~= localPlayer then
								local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(v))
								
								if distance <= 60 then
									table.insert(pendingPlayers, {v, 1 - distance / 60})
									pendingCount = pendingCount + 1
								end
							end
						end

						playSound("files/megaphone.wav")
						outputChatBox("((" .. visibleName .. ")) Megaphone <O: " .. firstToUpper(message), 255, 150, 0, true)
						
						if not isPedInVehicle(localPlayer) then
							triggerServerEvent("megaphoneAnim", localPlayer, getElementsByType("player", getRootElement(), true))
						end
						
						local spectatingPlayers = getElementData(localPlayer, "spectatingPlayers")
						if spectatingPlayers then
							for k, v in pairs(spectatingPlayers) do
								if isElement(k) then
									table.insert(pendingPlayers, {k, 1})
									pendingCount = pendingCount + 1
								end
							end
						end

						if pendingCount > 0 then
							triggerServerEvent("onMegaPhoneMessage", localPlayer, pendingPlayers, visibleName, firstToUpper(message))
						end
					end
				end
			end
		end
	end
)

addEvent("megaphoneAnim", true)
addEventHandler("megaphoneAnim", getRootElement(),
	function ()
		if isElement(source) then
			setPedAnimation(source, "megaphone_talk", "megaphone_talk", 750, false, false, false, false)
		end
	end
)

function formatNumber(amount, stepper)
	local left, center, right = string.match(math.floor(amount), "^([^%d]*%d)(%d*)(.-)$")
	return left .. string.reverse(string.gsub(string.reverse(center), "(%d%d%d)", "%1" .. (stepper or " "))) .. right
end

local gotSelling = false
local tradeContract = false

addCommandHandler("acceptsell",
	function()
		if tradeContract then
			-- jármű
			if isElement(tradeContract[2]) then
				triggerServerEvent("acceptVehicleBuy", localPlayer, tradeContract[1], tradeContract[2], tradeContract[3])
			-- ingatlan
			elseif tonumber(tradeContract[2]) then
				triggerServerEvent("acceptInteriorBuy", localPlayer, tradeContract[1], tradeContract[2], tradeContract[3])
			end

			tradeContract = false
		end
	end)

addEvent("sellInteriorNotification", true)
addEventHandler("sellInteriorNotification", getRootElement(),
	function(seller, inti, price, data)
		if not tradeContract then
			local sellerName = getElementData(seller, "visibleName"):gsub("_", " ")

			exports.sarp_hud:showInfobox("info", sellerName .. " el akar adni neked egy ingatlant " .. formatNumber(price) .. " $-ért!")

			outputChatBox(exports.sarp_core:getServerTag("info") .. "#32b3ef" .. sellerName .. " #ffffffel akar adni neked egy ingatlant #FF9600" .. formatNumber(price) .. " $#ffffff-ért!", 0, 0, 0, true)
			
			outputChatBox("    * #FF9600Ingatlan: #ffffff" .. data.name, 255, 255, 255, true)

			outputChatBox(exports.sarp_core:getServerTag("info") .. "#FF96005 #ffffffperced van elfogadni az ingatlant a #32b3ef/acceptsell #ffffffparanccsal.", 0, 0, 0, true)

			tradeContract = {seller, inti, price}
		end
	end)

addEvent("sellVehicleNotification", true)
addEventHandler("sellVehicleNotification", getRootElement(),
	function(seller, veh, price)
		if not tradeContract then
			local sellerName = getElementData(seller, "visibleName"):gsub("_", " ")

			exports.sarp_hud:showInfobox("info", sellerName .. " el akar adni neked egy járművet " .. formatNumber(price) .. " $-ért!")

			outputChatBox(exports.sarp_core:getServerTag("info") .. "#32b3ef" .. sellerName .. " #ffffffel akar adni neked egy járművet #FF9600" .. formatNumber(price) .. " $#ffffff-ért!", 0, 0, 0, true)
			
			outputChatBox("    * #FF9600Típus: #ffffff" .. exports.sarp_mods_veh:getVehicleName(veh), 255, 255, 255, true)

			outputChatBox(exports.sarp_core:getServerTag("info") .. "#FF96005 #ffffffperced van elfogadni a járművet a #32b3ef/acceptsell #ffffffparanccsal.", 0, 0, 0, true)

			tradeContract = {seller, veh, price}
		end
	end)

addEvent("failedToSell", true)
addEventHandler("failedToSell", getRootElement(),
	function(errno)
		if errno then
			exports.sarp_hud:showInfobox("error", errno)
		end

		gotSelling = false		
	end)

addCommandHandler("sell",
	function(cmd, targetPlayer, amount)
		amount = tonumber(amount)

		if not (targetPlayer and amount) then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Játékos név / ID] [Összeg]", 0, 0, 0, true)
		else
			targetPlayer = exports.sarp_core:findPlayer(localPlayer, targetPlayer)

			if targetPlayer then
				if targetPlayer ~= localPlayer then
					local px, py, pz = getElementPosition(localPlayer)
					local tx, ty, tz = getElementPosition(targetPlayer)

					local pi = getElementInterior(localPlayer)
					local ti = getElementInterior(targetPlayer)

					local pd = getElementDimension(localPlayer)
					local td = getElementDimension(targetPlayer)

					local dist = getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz)

					if dist <= 5 and pi == ti and pd == td then
						amount = math.ceil(amount)

						if amount >= 0 then
							local pedveh = getPedOccupiedVehicle(localPlayer)
							local inti = exports.sarp_interiors:getCurrentStandingMarker()

							if isElement(pedveh) then
								if not gotSelling then
									gotSelling = true

									triggerServerEvent("tryToSellVehicle", localPlayer, targetPlayer, pedveh, amount)
								else
									outputChatBox(exports.sarp_core:getServerTag("error") .. "Egy adásvételi szerződés már folyamatban van!", 0, 0, 0, true)
								end
							elseif inti then
								local intidata = exports.sarp_interiors:getInteriorData(inti)

								if intidata then
									if intidata.type == "house" or intidata.type == "garage" then
										if intidata.ownerId == getElementData(localPlayer, "char.ID") then
											if not gotSelling then
												gotSelling = true

												triggerServerEvent("tryToSellInterior", localPlayer, targetPlayer, inti, intidata, amount)
											else
												outputChatBox(exports.sarp_core:getServerTag("error") .. "Egy adásvételi szerződés már folyamatban van!", 0, 0, 0, true)
											end
										else
											outputChatBox(exports.sarp_core:getServerTag("error") .. "Ez az ingatlan nem a tiéd.", 0, 0, 0, true)
										end
									end
								end
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("error") .. "Maradjunk a nullánál nagyobb egész számoknál.", 0, 0, 0, true)
						end
					else
						outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled.", 0, 0, 0, true)
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "Magadnak nem adhatod el.", 0, 0, 0, true)
				end
			end
		end
	end)