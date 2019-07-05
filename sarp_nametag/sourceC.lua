local screenX, screenY = guiGetScreenSize()

local fontSizeMultipler = (1920 + screenX) / 3840

local RobotoFont = false
local FontAwesome = false

local streamedPlayers = {}
local streamedPeds = {}

local hitPlayers = {}
local hitTimers = {}

local playerCanSeeYourself = false

local canSeeNametags = true
local adminNames = false
local maxDistance = 35

local consoleState = false
local chatboxState = false
local afkTickCount = 0

local blackColor = tocolor(0, 0, 0)
local whiteColor = tocolor(255, 255, 255)

local serverTick = 0

local messageBubbles = {}
local maxBubbles = 5

addEvent("getTickSync", true)
addEventHandler("getTickSync", getRootElement(),
	function (tick)
		serverTick = tick - getRealTime().timestamp
	end
)

function createFonts()
	RobotoFont = exports.sarp_assets:loadFont("Roboto-Regular.ttf", 18, false, "antialiased")
	FontAwesome = exports.sarp_assets:loadFont("FontAwesome.ttf", 18, false, "antialiased")
end
addEventHandler("onAssetsLoaded", getRootElement(), createFonts)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		createFonts()

		setTimer(triggerServerEvent, 2000, 1, "getTickSync", localPlayer)

		if getElementData(localPlayer, "loggedIn") then
			for k,v in ipairs(getElementsByType("player", getRootElement(), true)) do
				if (v ~= localPlayer or playerCanSeeYourself) and not streamedPlayers[v] then
					processPlayerNametag(v)
				end
			end
			
			for k,v in ipairs(getElementsByType("ped", getRootElement(), true)) do
				if not streamedPeds[v] then
					processPedNametag(v)
				end
			end
		end
		
		if isConsoleActive() then
			setElementData(localPlayer, "consoling", true)
			consoleState = true
		else
			setElementData(localPlayer, "consoling", false)
			consoleState = false
		end
	
		if isChatBoxInputActive() then
			setElementData(localPlayer, "typing", true)
			chatboxState = true
		else
			setElementData(localPlayer, "typing", false)
			chatboxState = false
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "player" then
			if (source ~= localPlayer or playerCanSeeYourself) and not streamedPlayers[source] then
				processPlayerNametag(source)
			end
		elseif getElementType(source) == "ped" and not streamedPeds[source] then
			processPedNametag(source)
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if getElementType(source) == "player" then
			if (source ~= localPlayer or playerCanSeeYourself) and streamedPlayers[source] then
				processPlayerNametag(source, dataName, getElementData(source, dataName))
			end
		elseif getElementType(source) == "ped" and streamedPeds[source] then
			processPedNametag(source, dataName, getElementData(source, dataName))
		end
	end
)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if getElementType(source) == "player" then
			if (source ~= localPlayer or playerCanSeeYourself) and streamedPlayers[source] then
				streamedPlayers[source] = nil
			end
		elseif getElementType(source) == "ped" and streamedPeds[source] then
			streamedPeds[source] = nil
		end
	end
)

addEventHandler("onClientPlayerQuit", getRootElement(),
	function ()
		streamedPlayers[source] = nil
	end
)

addEventHandler("onClientPlayerChangeNick", getRootElement(),
	function (oldNick, newNick)
		if streamedPlayers[source] then
			streamedPlayers[source].playerName = utf8.gsub(newNick, "_", " ")
		end
	end
)

function processPlayerNametag(player, dataName, dataValue)
	if not dataName and not dataValue then
		streamedPlayers[player] = {
			playerId = getElementData(player, "playerID") or 0,
			playerName = utf8.gsub((getElementData(player, "visibleName") or getPlayerName(player)), "_", " "),
			adminLevel = getElementData(player, "acc.adminLevel") or 0,
			adminNick = getElementData(player, "acc.adminNick") or "Admin",
			adminDuty = getElementData(player, "adminDuty"),
			isTyping = getElementData(player, "typing"),
			isConsoling = getElementData(player, "consoling"),
			isAfk = getElementData(player, "afk"),
			startAfk = getElementData(player, "startAfk"),
			cuffed = getElementData(player, "player.Cuffed"),
			tazed = getElementData(player, "player.Tazed"),
			bloodLevel = getElementData(player, "bloodLevel") or 100,
			deathReason = getElementData(player, "deathReason"),
			badgeData = getElementData(player, "badgeData"),
			inAnimTime = getElementData(player, "inAnimTime"),
		}

		if streamedPlayers[player].adminDuty then
			streamedPlayers[player].adminBadgeColor = exports.sarp_core:getAdminLevelColor(streamedPlayers[player].adminLevel)
			streamedPlayers[player].adminRankName = exports.sarp_core:getPlayerAdminTitleByLevel(streamedPlayers[player].adminLevel)
		end
	else
		if dataName == "playerID" then
			streamedPlayers[player].playerId = dataValue
		elseif dataName == "visibleName" then
			streamedPlayers[player].playerName = dataValue and utf8.gsub(dataValue, "_", " ") or getPlayerName(player)
		elseif dataName == "acc.adminLevel" then
			streamedPlayers[player].adminLevel = dataValue
			streamedPlayers[player].adminBadgeColor = exports.sarp_core:getAdminLevelColor(streamedPlayers[player].adminLevel)
			streamedPlayers[player].adminRankName = exports.sarp_core:getPlayerAdminTitleByLevel(streamedPlayers[player].adminLevel)
		elseif dataName == "acc.adminNick" then
			streamedPlayers[player].adminNick = dataValue or "Admin"
		elseif dataName == "adminDuty" then
			streamedPlayers[player].adminDuty = dataValue
			streamedPlayers[player].adminBadgeColor = exports.sarp_core:getAdminLevelColor(streamedPlayers[player].adminLevel)
			streamedPlayers[player].adminRankName = exports.sarp_core:getPlayerAdminTitleByLevel(streamedPlayers[player].adminLevel)
		elseif dataName == "typing" then
			streamedPlayers[player].isTyping = dataValue
		elseif dataName == "consoling" then
			streamedPlayers[player].isConsoling = dataValue
		elseif dataName == "afk" then
			streamedPlayers[player].isAfk = dataValue
		elseif dataName == "startAfk" then
			streamedPlayers[player].startAfk = dataValue
		elseif dataName == "player.Cuffed" then
			streamedPlayers[player].cuffed = dataValue
		elseif dataName == "player.Tazed" then
			streamedPlayers[player].tazed = dataValue
		elseif dataName == "bloodLevel" then
			streamedPlayers[player].bloodLevel = dataValue or 100
		elseif dataName == "deathReason" then
			streamedPlayers[player].deathReason = dataValue
		elseif dataName == "badgeData" then
			streamedPlayers[player].badgeData = dataValue
		elseif dataName == "inAnimTime" then
			streamedPlayers[player].inAnimTime = dataValue
		end
	end
end

function processPedNametag(ped, dataName, dataValue)
	if not dataName and not dataValue then
		streamedPeds[ped] = {
			visibleName = getElementData(ped, "dog.id") and utf8.gsub(getElementData(ped, "dog.name") or "", "_", " ") or utf8.gsub(getElementData(ped, "ped.name") or "", "_", " "),
			animalId = getElementData(ped, "dog.id"),
			pedNameType = getElementData(ped, "pedNameType")
		}

		if not streamedPeds[ped].visibleName or streamedPeds[ped].visibleName and utf8.len(streamedPeds[ped].visibleName) <= 0 then
			streamedPeds[ped].visibleName = utf8.gsub(getElementData(ped, "visibleName") or "", "_", " ")
		end
	else
		if dataName == "visibleName" then
			streamedPeds[ped].visibleName = utf8.gsub(dataValue or "", "_", " ")
		elseif dataName == "ped.name" then
			streamedPeds[ped].visibleName = utf8.gsub(dataValue or "", "_", " ")
		elseif dataName == "dog.name" then
			streamedPeds[ped].visibleName = utf8.gsub(dataValue or "", "_", " ")
		elseif dataName == "dog.id" then
			streamedPeds[ped].animalId = dataValue
		end
	end
end

addEventHandler("onClientRestore", getRootElement(),
	function ()
		afkTickCount = getTickCount()
		setElementData(localPlayer, "afk", false)
	end
)

addEventHandler("onClientMinimize", getRootElement(),
	function ()
		setElementData(localPlayer, "afk", true)
	end
)

addEventHandler("onClientCursorMove", getRootElement(),
	function ()
		afkTickCount = getTickCount()
		if getElementData(localPlayer, "afk") then
			setElementData(localPlayer, "afk", false)
		end
	end
)

addEventHandler("onClientKey", getRootElement(),
	function ()
		afkTickCount = getTickCount()
		if getElementData(localPlayer, "afk") then
			setElementData(localPlayer, "afk", false)
		end
	end
)

addEventHandler("onClientPlayerDamage", getRootElement(),
	function ()
		hitPlayers[source] = true
		
		if hitTimers[source] and isTimer(hitTimers[source]) then
			killTimer(hitTimers[source])
		end
		
		hitTimers[source] = setTimer(
			function (element)
				hitPlayers[element] = false
			end,
		3000, 1, source)
	end
)

addCommandHandler("tognames",
	function ()
		canSeeNametags = not canSeeNametags
	end
)

exports.sarp_admin:addAdminCommand("anames", 1, "Adminisztrátori nevek be/ki kapcsolása")
addCommandHandler("anames",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if not adminNames then
				adminNames = "normal"
				setElementData(localPlayer, "adminNames", tostring(adminNames), false)
				
				if getElementData(localPlayer, "acc.adminLevel") >= 7 then
					adminNames = "super"
					setElementData(localPlayer, "adminNames", tostring(adminNames), false)
				end
				
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen #ffff99bekapcsoltad #ffffffaz adminisztrátori neveket.", 255, 255, 255, true)
			else
				adminNames = false
				setElementData(localPlayer, "adminNames", tostring(adminNames), false)
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen #ff4646kikapcsoltad #ffffffaz adminisztrátori neveket.", 255, 255, 255, true)
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local currentTick = getTickCount()

		if currentTick - afkTickCount >= 25000 and not getElementData(localPlayer, "afk") and getElementHealth(localPlayer) > 1 then
			setElementData(localPlayer, "afk", true)
		end

		if not consoleState then
			if isConsoleActive() then
				setElementData(localPlayer, "consoling", true)
				consoleState = true
			end
		elseif consoleState and not isConsoleActive() then
			setElementData(localPlayer, "consoling", false)
			consoleState = false
		end
		
		if not chatboxState then
			if isChatBoxInputActive() then
				setElementData(localPlayer, "typing", true)
				chatboxState = true
			end
		elseif chatboxState and not isChatBoxInputActive() then
			setElementData(localPlayer, "typing", false)
			chatboxState = false
		end
		
		if not canSeeNametags then
			return
		end

		local progress = getTickCount() % 1000
		local r, g, b = interpolateBetween(255, 255, 255, 215, 89, 89, progress / 500, "Linear")

		if progress > 500 then
			r, g, b = interpolateBetween(215, 89, 89, 255, 255, 255, (progress - 500) / 500, "Linear")
		end

		local cameraX, cameraY, cameraZ = getCameraMatrix()
		local currentTimestamp = getRealTime().timestamp

		for k, v in pairs(streamedPlayers) do
			local playerX, playerY, playerZ = getElementPosition(k)
			
			if isElement(k) then
				if (getElementAlpha(k) > 0 or adminNames == "super") and (isLineOfSightClear(cameraX, cameraY, cameraZ, playerX, playerY, playerZ, true, false, false, true, false, true, false) or adminNames == "super") then
					local bonePosX, bonePosY, bonePosZ = getPedBonePosition(k, 5)
					local headPosX, headPosY = getScreenFromWorldPosition(bonePosX, bonePosY, bonePosZ + 0.38, 0, false)
					
					if headPosX and headPosY then
						local distance = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, playerX, playerY, playerZ)
						local visibleDistance = maxDistance

						if adminNames then
							visibleDistance = 150
						end
						
						if distance <= visibleDistance then
							local progress = distance / visibleDistance
							
							if progress < 1 then
								local alpha = interpolateBetween(255, 0, 0, 0, 0, 0, progress, "Linear")
								local scale = interpolateBetween(1.15, 0, 0, 0.175, 0, 0, progress, "OutQuad") * fontSizeMultipler
								local imgscale = interpolateBetween(1, 0, 0, 0.15, 0, 0, progress, "OutQuad") * fontSizeMultipler

								if adminNames then
									imgscale = imgscale * fontSizeMultipler
								end
								
								local playerHealth = getElementHealth(k)
								local nameColor = "#FFFFFF"
								local adminNameColor = "#FFFFFF"
								
								if adminNames then
									adminNameColor = "#af3f3f"
									nameColor = "#54ad6a"
								end
								
								if hitPlayers[k] then
									nameColor = "#af3f3f"
								elseif playerHealth <= 0 then
									nameColor = "#101010"
								end

								if v.bloodLevel < 100 then
									if not isPedInVehicle(k) and math.random(100) <= 10 then
										fxAddBlood(playerX, playerY, playerZ - 2, 0, 0, 3, math.random(5))
									end

									nameColor = string.format("#%.2X%.2X%.2X", r, g, b)
								end
								
								local text = adminNameColor .. nameColor .. v.playerName
								
								if v.adminDuty then
									local adminBadge = ""

									if v.adminLevel >= 10 then
										adminBadge = v.adminBadgeColor .. "<" .. v.adminRankName .. "/>"
									else
										adminBadge = v.adminBadgeColor .. "(" .. v.adminRankName .. ")"
									end
									
									text = adminBadge .. " " .. text
								end

								text = text .. adminNameColor .. " (" .. v.playerId .. ")"

								local fontScale = scale * fontSizeMultipler
								local textWidth = dxGetTextWidth(text, fontScale, RobotoFont, true)
								local fontHeight = dxGetFontHeight(fontScale, RobotoFont)

								if textWidth then
									local textPosX = headPosX - textWidth * 0.5

									dxDrawText(utf8.gsub(text, "#%x%x%x%x%x%x", ""), textPosX + 1, headPosY + 1, 100, 100, blackColor, fontScale, RobotoFont, "left", "top", false, false, false, false, true)
									dxDrawText(text, textPosX, headPosY, 100, 100, whiteColor, fontScale, RobotoFont, "left", "top", false, false, false, true, true)
								
									if playerHealth == 0 and v.deathReason then
										textWidth = dxGetTextWidth("* A halál oka: " .. v.deathReason .. " *", fontScale, RobotoFont)
										textPosX = headPosX - textWidth * 0.5

										dxDrawText("* A halál oka: " .. v.deathReason .. " *", textPosX + 1, headPosY + 1 + fontHeight, 100, 100, blackColor, fontScale, RobotoFont, "left", "top", false, false, false, false, true)
										dxDrawText("#d75959* #ffffffA halál oka: #d75959" .. v.deathReason .. " *", textPosX, headPosY + fontHeight, 100, 100, whiteColor, fontScale, RobotoFont, "left", "top", false, false, false, true, true)
									elseif playerHealth <= 20 and playerHealth > 0 then
										local timeLeft = (600000 - (v.inAnimTime[1] or 0)) / 1000
										local text = "* Eszméletlen (" .. string.format("%.2d:%.2d", timeLeft / 60, timeLeft % 60) .. ") *"

										textWidth = dxGetTextWidth(text, fontScale, RobotoFont)
										textPosX = headPosX - textWidth * 0.5

										dxDrawText(text, textPosX + 1, headPosY + 1 + fontHeight, 100, 100, blackColor, fontScale, RobotoFont, "left", "top", false, false, false, false, true)
										dxDrawText(text, textPosX, headPosY + fontHeight, 100, 100, tocolor(215, 89, 89), fontScale, RobotoFont, "left", "top", false, false, false, true, true)
									elseif v.badgeData then
										local text = "# " .. v.badgeData .. " #"

										textWidth = dxGetTextWidth(text, fontScale, RobotoFont)
										textPosX = headPosX - textWidth * 0.5

										dxDrawText(text, textPosX + 1, headPosY + 1 + fontHeight, 100, 100, blackColor, fontScale, RobotoFont, "left", "top", false, false, false, false, true)
										dxDrawText(text, textPosX, headPosY + fontHeight, 100, 100, tocolor(220, 163, 0), fontScale, RobotoFont, "left", "top", false, false, false, true, true)
									end
								end

								--** Ikonok
								local iconSize = 32 * imgscale
								local sizeForIcons = 0

								if v.isAfk and v.startAfk and v.startAfk > 0 then
									local afkTime = currentTimestamp - v.startAfk - serverTick

									if afkTime < 0 then
										afkTime = 0
									end
									
									local text = "[AFK - " .. string.format("%.2d:%.2d:%.2d", afkTime / 3600, afkTime / 60 % 60, afkTime % 60) .. "]"
									local textWidth = dxGetTextWidth(text, fontScale, FontAwesome, true)

									dxDrawText(text, headPosX - textWidth * 0.5 + 1, headPosY - fontHeight + 1, 100, 100, blackColor, fontScale, FontAwesome, "left", "top", false, false, false, false, true)
									dxDrawText(text, headPosX - textWidth * 0.5, headPosY - fontHeight, 100, 100, tocolor(175, 175, 175), fontScale, FontAwesome, "left", "top", false, false, false, false, true)
								end

								if v.isTyping then
									sizeForIcons = sizeForIcons + iconSize
								elseif v.isConsoling then
									sizeForIcons = sizeForIcons + iconSize
								end

								if v.cuffed then
									sizeForIcons = sizeForIcons + iconSize
								end

								if v.tazed then
									sizeForIcons = sizeForIcons + iconSize
								end

								if v.bloodLevel < 100 and playerHealth > 0 then
									sizeForIcons = sizeForIcons + iconSize
								end

								local iconPosX = headPosX - sizeForIcons * 0.5
								local iconPosY = headPosY - fontHeight - iconSize * 0.4

								if v.isAfk then
									iconPosY = headPosY - fontHeight - iconSize
								end

								if v.isTyping then
									dxDrawImage(iconPosX, iconPosY, iconSize, iconSize, "files/typing.png")
									iconPosX = iconPosX + iconSize
								elseif v.isConsoling then
									dxDrawImage(iconPosX, iconPosY, iconSize, iconSize, "files/consoling.png")
									iconPosX = iconPosX + iconSize
								end

								if v.cuffed then
									dxDrawImage(iconPosX, iconPosY, iconSize, iconSize, "files/cuffed.png")
									iconPosX = iconPosX + iconSize
								end

								if v.tazed then
									dxDrawImage(iconPosX, iconPosY, iconSize, iconSize, "files/tazed.png")
									iconPosX = iconPosX + iconSize
								end

								if v.bloodLevel < 100 and playerHealth > 0 then
									local progress = v.bloodLevel / 100

									dxDrawImage(iconPosX, iconPosY, iconSize, iconSize, "files/drop.png", 0, 0, 0, tocolor(0, 0, 0, 180))
									dxDrawImageSection(iconPosX, iconPosY + iconSize, iconSize, -iconSize * progress, 0, 0, iconSize / imgscale, -iconSize / imgscale * progress, "files/drop.png", 0, 0, 0, tocolor(215, 89, 89))

									iconPosX = iconPosX + iconSize
								end

								if distance <= 30 then
									local pictureSizeX = 128 * imgscale
									local pictureSizeY = 128 * imgscale
									local picturePosX = headPosX - pictureSizeX * 0.5
									local picturePosY = headPosY - pictureSizeY * 0.8 - fontHeight

									if v.isAfk then
										picturePosY = picturePosY - iconSize * 0.5
									end

									if sizeForIcons > 0 then
										picturePosY = picturePosY - iconSize * 1.35
									end

									if v.adminLevel > 0 and v.adminDuty then
										if v.adminLevel == 10 then
											dxDrawImage(picturePosX, picturePosY, pictureSizeX, pictureSizeY, "files/devlogo.png", 0, 0, 0, tocolor(255, 255, 255, alpha))
										elseif v.adminLevel == 9 then
											dxDrawImage(picturePosX, picturePosY, pictureSizeX, pictureSizeY, "files/owner.png", 0, 0, 0, tocolor(255, 255, 255, alpha))
										elseif v.adminLevel == 7 then
											dxDrawImage(picturePosX, picturePosY, pictureSizeX, pictureSizeY, "files/superadmin.png", 0, 0, 0, tocolor(255, 255, 255, alpha))
										end
									end
								end

								-- ** Admin nevek
								if adminNames then
									local sx = 200 * imgscale
									local sy = 8 * imgscale
									local x = headPosX - sx * 0.5
									local y = headPosY + 20 + fontHeight - sy - 10
									
									dxDrawRectangle(x - 2, y - 2, sx + 4, sy + 4, tocolor(0, 0, 0, 175), false, true)

									if playerHealth > 0 then
										dxDrawRectangle(x, y, sx * (playerHealth / 100), sy, tocolor(215, 89, 89, 200), false, true)
									end
									
									local playerArmor = getPedArmor(k)

									if playerArmor > 0 then
										y = y + sy + 4

										dxDrawRectangle(x - 2, y - 2, sx + 4, sy + 4, tocolor(0, 0, 0, 175), false, true)
										dxDrawRectangle(x, y, sx * (playerArmor / 100), sy, tocolor(255, 255, 255, 200), false, true)
									end
								end

								-- ** Üzenet buborékok
								if messageBubbles[k] and distance <= 10 then
									local i = 1

									if sizeForIcons > 0 or v.isAfk then
										i = 2
									end

									for k2, v2 in pairs(messageBubbles[k]) do
										local prefix = ""
										local r, g, b = 255, 255, 255

										if v2[2] == "me" then
											r, g, b = 194, 162, 218
											prefix = "*** "
										elseif v2[2] == "do" then
											r, g, b = 255, 40, 40
											prefix = "* "
										elseif v2[2] == "ame" then
											r, g, b = 162, 183, 218
											prefix = "> "
										end

										local elapsedTime = currentTick - v2[3]
										local interpolate = interpolateBetween(
											0, 0, 0,
											1, 0, 0,
											elapsedTime / 750, "InOutQuad")

										if elapsedTime > v2[4] then
											local progress = (elapsedTime - v2[4]) / 750

											interpolate = interpolateBetween(
												1, 0, 0,
												0, 0, 0,
												progress, "InOutQuad")

											if progress > 1 then
												table.remove(messageBubbles[k], k2)
											end
										end

										local textWidth = dxGetTextWidth(prefix .. v2[1], fontScale, RobotoFont)
										local textPosX = headPosX - textWidth / 2
										local textPosY = headPosY - 35 * i * interpolate

										dxDrawRectangle(textPosX - 5, textPosY - 5, textWidth + 10, fontHeight + 10, tocolor(0, 0, 0, 150 * interpolate), false, true)
										dxDrawRectangle(textPosX - 5, textPosY + fontHeight + 4, textWidth + 10, 1, tocolor(50, 179, 239, 150 * interpolate), false, true)
										dxDrawText(prefix .. v2[1], textPosX, textPosY, textPosX + textWidth, textPosY + fontHeight, tocolor(r, g, b, 255 * interpolate), fontScale, RobotoFont, "center", "center", false, false, false, false, true)

										i = i + 1
									end
								end
							end
						end
					end
				end
			end
		end

		for k, v in pairs(streamedPeds) do
			if isElement(k) then
				local pedX, pedY, pedZ = getElementPosition(k)
				
				if isLineOfSightClear(cameraX, cameraY, cameraZ, pedX, pedY, pedZ, true, false, false, true, false, true, false) then
					if v.visibleName and utfLen(v.visibleName) > 0 then
						local bonePosX, bonePosY, bonePosZ = getPedBonePosition(k, 5)
						local boneDeltaZ = 0.38
						
						if v.animalId then
							boneDeltaZ = 0.25
						end
						
						local headPosX, headPosY = getScreenFromWorldPosition(bonePosX, bonePosY, bonePosZ + boneDeltaZ, 0, false)
						
						if headPosX and headPosY then
							local distance = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, pedX, pedY, pedZ)
							
							if distance <= maxDistance then
								local progress = distance / maxDistance
								
								if progress < 1 then
									local scale = interpolateBetween(1, 0, 0, 0.17, 0, 0, progress, "OutQuad") * fontSizeMultipler
									local text = ""
									
									if v.animalId then
										text = "#00aaff[PET] #ffffff" .. v.visibleName
									else
										text = "#00aaff[NPC] #ffffff" .. v.visibleName .. (v.pedNameType and " #00aaff(" .. v.pedNameType .. ")" or "")
									end

									local fontScale = fontSizeMultipler * scale
									local textWidth = dxGetTextWidth(text, fontScale, RobotoFont, true)
									local fontHeight = dxGetFontHeight(fontScale, RobotoFont)

									if textWidth then
										local textPosX = headPosX - textWidth * 0.5
										
										dxDrawText(utf8.gsub(text, "#%x%x%x%x%x%x", ""), textPosX + 1, headPosY + 1, 100, 100, blackColor, fontScale, RobotoFont, "left", "top", false, false, false, true, true)
										dxDrawText(text, textPosX, headPosY, 100, 100, whiteColor, fontScale, RobotoFont, "left", "top", false, false, false, true, true)
									end
								end
							end
						end
					end
				end
			end
		end
	end, true, "high+999"
)

addEventHandler("onClientChatMessage", getRootElement(),
	function (message, r, g, b)
		local playerName = false
		local statement = false

		if utf8.sub(message, 1, 1) == "#" then
			if r == 16 and g == 16 and b == 16 then
				local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

				message = utf8.sub(message, 8, utf8.len(message))

				local data = splitLocalMessage(message, "mondja:")

				if data[1] ~= visibleName or playerCanSeeYourself then
					message = data[2]
					playerName = data[1]
					statement = "local"
				end
			elseif r == 32 and g == 32 and b == 32 then
				local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

				message = utf8.sub(message, 12, utf8.len(message))

				local data = splitLocalAction(message, "#C2A2DA")

				if data[1] ~= visibleName or playerCanSeeYourself then
					message = data[2]
					playerName = data[1]
					statement = "me"
				end
			elseif r == 64 and g == 64 and b == 64 then
				local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

				message = utf8.sub(message, 10, utf8.len(message))

				local data = splitLocalDoAction(message, "((#FF2850")

				data[2] = utf8.sub(data[2], 10, utf8.len(data[2]) - 2)

				if data[2] ~= visibleName or playerCanSeeYourself then
					message = data[1]
					playerName = data[2]
					statement = "do"
				end
			elseif r == 164 and g == 164 and b == 164 then
				local visibleName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

				message = utf8.sub(message, 10, utf8.len(message))

				local data = splitLocalAmeAction(message, "#a2b7da")

				if data[1] ~= visibleName or playerCanSeeYourself then
					message = data[2]
					playerName = data[1]
					statement = "ame"
				end
			end
		end

		if playerName and statement then
			for k, v in pairs(streamedPlayers) do
				if isElement(k) and v.playerName == playerName then
					if not v.adminDuty then
						if not messageBubbles[k] then
							messageBubbles[k] = {}
						end

						if #messageBubbles[k] >= maxBubbles then
							table.remove(messageBubbles[k], 1)
						end

						table.insert(messageBubbles[k], {message:gsub("#......", ""), statement, getTickCount(), 2500 + utf8.len(message) * 125})
					end

					break
				end
			end
		end
	end
)

function splitLocalMessage(inputstr, seperator)
	local words = split(inputstr, " ")
	local i = 1
	local t = {}

	for k = 1, #words do
		local v = words[k]

		if v then
			if v == seperator then
				i = i + 1
			else
				if not t[i] then
					t[i] = {}
				end

				table.insert(t[i], v)
			end
		end
	end

	t[1] = table.concat(t[1], " ")
	t[2] = t[2] and table.concat(t[2], " ") or ""
	
	return t
end

function splitLocalAction(inputstr, seperator)
	local words = split(inputstr, " ")
	local i = 1
	local t = {}

	for k = 1, #words do
		local v = words[k]

		if v then
			if utf8.sub(v, 1, 7) == seperator then
				i = i + 1
			end

			if v == seperator .. "***" then
				i = 2
			end
			
			if not t[i] then
				t[i] = {}
			end

			table.insert(t[i], v)
		end
	end

	t[1] = table.concat(t[1], " ")
	t[2] = t[2] and table.concat(t[2], " ") or ""
	
	return t
end

function splitLocalDoAction(inputstr, seperator)
	local words = split(inputstr, " ")
	local i = 1
	local t = {}

	for k = 1, #words do
		local v = words[k]

		if v then
			if utf8.sub(v, 1, 9) == seperator then
				i = i + 1
			end

			if v == seperator .. "*" then
				i = 2
			end
			
			if not t[i] then
				t[i] = {}
			end

			table.insert(t[i], v)
		end
	end

	t[1] = table.concat(t[1], " ")
	t[2] = t[2] and table.concat(t[2], " ") or ""
	
	return t
end

function splitLocalAmeAction(inputstr, seperator)
	local words = split(inputstr, " ")
	local i = 1
	local t = {}

	for k = 1, #words do
		local v = words[k]

		if v then
			if utf8.sub(v, 1, 7) == seperator then
				i = i + 1
			end

			if v == seperator .. ">" then
				i = 2
			end
			
			if not t[i] then
				t[i] = {}
			end

			table.insert(t[i], v)
		end
	end

	t[1] = table.concat(t[1], " ")
	t[2] = t[2] and table.concat(t[2], " ") or ""
	
	return t
end