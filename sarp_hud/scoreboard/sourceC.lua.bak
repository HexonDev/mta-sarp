local maxPlayers = 0
local playersCount = 0

local headerHeight = respc(60)
local footerHeight = respc(40)

local visibleRows = 15
local rowHeight = respc(40)

local panelWidth = respc(680)
local panelHeight = headerHeight + footerHeight + rowHeight * visibleRows

local panelX = (screenX - panelWidth) / 2
local panelY = (screenY - panelHeight) / 2

local logoSize = respc(48)
local logoOffset = (headerHeight - logoSize) / 2

local panelState = false

local scoreboardTeams = {
	{"Szolgálatban lévő Adminisztrátorok", 50, 179, 239},
	{"Játékosok", 255, 255, 255},
	{"Nincs bejelentkezve", 175, 175, 175}
}

local scoreboardColumns = {}
local scoreboardPlayers = {}
local scoreboardTeamPlayers = {}

local scoreboardOffsets = {}

local fadeAmount = 0
local fadeStart = false
local fadeEnd = false

addEventHandler("onClientResourceStart", getRootElement(),
	function (startedRes)
		if getResourceName(startedRes) == "sarp_core" or startedRes == getThisResource() then
			maxPlayers = getElementData(getResourceRootElement(getResourceFromName("sarp_core")), "server.maxPlayers") or 0
		end
	end
)

function initScoreboard()
	local localAdminLevel = getElementData(localPlayer, "acc.adminLevel") or 0
	local localAdminDuty = getElementData(localPlayer, "adminDuty")

	if localAdminLevel >= 1 and localAdminDuty then
		scoreboardColumns = {
			{"ID", 0.05},
			{"Név", 0.3},
			{"Account ID", 0.15, "center"},
			{"Karakter ID", 0.1, "center"},
			{"Szint", 0.07, "center"},
			{"Ping", 0.05, "right"}
		}
	else
		scoreboardColumns = {
			{"ID", 0.05},
			{"Név", 0.3},
			{"Szint", 0.07, "center"},
			{"Ping", 0.05, "right"}
		}
	end

	local sizeForColumns = 0

	for k, v in ipairs(scoreboardColumns) do
		sizeForColumns = sizeForColumns + v[2]
	end

	local columnX = respc(15)

	for k, v in ipairs(scoreboardColumns) do
		local columnSize = v[2] / sizeForColumns * (panelWidth - respc(30))

		v[4] = columnX
		v[5] = columnSize

		columnX = columnX + columnSize
	end

	for k, v in ipairs(scoreboardTeams) do
		scoreboardTeamPlayers[k] = {}

		if not scoreboardOffsets[k] then
			scoreboardOffsets[k] = 0
		end
	end

	for k, v in ipairs(getElementsByType("player")) do
		if getElementData(v, "loggedIn") then
			local playerID = getElementData(v, "playerID")
			local adminLevel = getElementData(v, "acc.adminLevel") or 0
			local adminDuty = getElementData(v, "adminDuty")

			if adminLevel >= 1 and adminDuty then
				scoreboardTeamPlayers[1][playerID] = v
			else
				scoreboardTeamPlayers[2][playerID] = v
			end

			local str = ""

			if adminDuty then
				local adminTitle = exports.sarp_core:getPlayerAdminTitleByLevel(adminLevel)
				local adminTitleColor = exports.sarp_core:getAdminLevelColor(adminLevel) or "#FFFFFF"

				str = adminTitleColor .. "(" .. adminTitle .. ") "
			end
			
			str = str .. (getElementData(v, "visibleName") or getPlayerName(v)):gsub("_", " ")

			scoreboardPlayers[v] = {
				playerID = playerID,
				playerName = str,
				adminLevel = adminLevel,
				adminDuty = adminDuty,
				charID = getElementData(v, "char.ID") or 0,
				accID = getElementData(v, "acc.ID") or 0,
				level = exports.sarp_core:getLevel(v)
			}
		else
			local playerID = getElementData(v, "playerID") or math.random(4000, 6000)

			scoreboardTeamPlayers[3][playerID] = v

			scoreboardPlayers[v] = {
				playerID = playerID,
				playerName = ((getElementData(v, "visibleName") or getPlayerName(v)):gsub("_", " ")):gsub("#......", ""),
				loggedOut = true
			}
		end
	end

	playersCount = #getElementsByType("player")
end

function renderTheScoreboard()
	if not panelState then
		return false
	end

	local currentTick = getTickCount()

	if fadeStart and currentTick >= fadeStart then
		local progress = (currentTick - fadeStart) / 250

		fadeAmount = interpolateBetween(0, 0, 0, 1, 0, 0, progress, "OutQuad")

		if progress > 1 then
			fadeAmount = 1
			fadeStart = false
		end
	elseif fadeEnd and currentTick >= fadeEnd then
		local progress = (currentTick - fadeEnd) / 250

		fadeAmount = interpolateBetween(1, 0, 0, 0, 0, 0, progress, "InQuad")
		
		if progress > 1 then
			fadeAmount = 0
			fadeEnd = false
			fadeStart = false
			panelState = false
		end
	end

	local alpha255 = 255 * fadeAmount
	local whiteColor = tocolor(255, 255, 255, alpha255)

	dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, tocolor(20, 20, 20, 230 * fadeAmount))

	-- ** Header
	dxDrawRectangle(panelX, panelY, panelWidth, headerHeight, tocolor(30, 30, 30, 230 * fadeAmount))
	dxDrawImage(panelX + logoOffset, panelY + logoOffset, logoSize, logoSize, ":sarp_accounts/files/logo.png", 0, 0, 0, tocolor(50, 179, 239, alpha255))
	dxDrawText("Játékos lista", panelX + logoOffset*2 + logoSize, panelY, 0, panelY + headerHeight, whiteColor, 1, RobotoL18, "left", "center")
	dxDrawText("#eaeaeaOnline: #32b3ef" .. playersCount .. "#eaeaea / #32b3ef" .. maxPlayers, panelX, panelY, panelX + panelWidth - respc(10), panelY + headerHeight, tocolor(200, 200, 200, alpha255), 0.75, chaletcomprime, "right", "center", false, false, false, true)

	-- ** Content
	local scoreboardContent = {}

	local playerCount = 0
	local dataRowCount = 0
	local groupRowCount = 0

	local teamMembersCount = {}

	for k, v in ipairs(scoreboardTeams) do
		teamMembersCount[k] = 0

		for k2, v2 in pairs(scoreboardTeamPlayers[k]) do
			teamMembersCount[k] = teamMembersCount[k] + 1
		end
	end

	for k, v in ipairs(scoreboardTeams) do
		--if teamMembersCount[k] > 0 then
			scoreboardContent[k] = {}

			if scoreboardTeamPlayers[k] then
				for k2, v2 in pairs(scoreboardTeamPlayers[k]) do
					if isElement(v2) and scoreboardPlayers[v2] then
						table.insert(scoreboardContent[k], {playerID = k2, playerElement = v2})
					else
						scoreboardTeamPlayers[k][k2] = nil
					end

					table.sort(scoreboardContent[k],
						function (a, b)
							return a.playerID < b.playerID
						end
					)
				end
			end
		--end
	end

	local localAdminLevel = scoreboardPlayers[localPlayer].adminLevel or 0
	local panelBottomY = panelY + panelHeight - footerHeight

	for k, v in pairs(scoreboardContent) do
		local x = panelX + respc(15)
		local y = panelY + headerHeight + groupRowCount * rowHeight + dataRowCount * rowHeight + playerCount * rowHeight

		if y + rowHeight <= panelBottomY then
			local groupData = scoreboardTeams[k]

			dxDrawRectangle(panelX, y, panelWidth, rowHeight, tocolor(0, 0, 0, 75 * fadeAmount))
			dxDrawText(groupData[1], x, y, x + panelWidth - respc(30), y + rowHeight, tocolor(groupData[2], groupData[3], groupData[4], alpha255), 1, OpenSansLight16, "left", "center")
			dxDrawText(teamMembersCount[k] .. " játékos", x, y, x + panelWidth - respc(30), y + rowHeight, tocolor(175, 175, 175, alpha255), 0.85, OpenSansRegular16, "right", "center")
		
			local columnY = y + rowHeight
			local drawing = false
			local count = 0
			local rowCount = 0

			groupRowCount = groupRowCount + 1

			for k2, v2 in pairs(v) do
				if rowCount >= scoreboardOffsets[k] then
					if not drawing then
						if columnY + rowHeight <= panelBottomY then
							for k3, v3 in ipairs(scoreboardColumns) do
								if (k == #scoreboardTeams and k3 <= 2) or k ~= #scoreboardTeams then
									dxDrawText(v3[1], panelX + v3[4], columnY, panelX + v3[4] + v3[5], columnY + rowHeight, whiteColor, 0.75, OpenSansRegular16, v3[3] and v3[3] or "left", "center")
								end
							end

							dxDrawLine(panelX + respc(15), columnY + rowHeight, panelX + panelWidth - respc(15), columnY + rowHeight, tocolor(100, 100, 100, 100 * fadeAmount), 1)
						end

						dataRowCount = dataRowCount + 1
						drawing = true
					end

					count = count + 1

					for k3, v3 in ipairs(scoreboardColumns) do
						local rowY = columnY + count * rowHeight

						if rowY + rowHeight <= panelBottomY then
							local playerElement = v2.playerElement
							local data = scoreboardPlayers[playerElement]

							if data then
								local column = v3[1]

								if data.loggedOut then
									if column == "ID" then
										dxDrawText("#" .. data.playerID, panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, whiteColor, 0.8, Roboto, "left", "center")
									elseif column == "Név" then
										dxDrawText(data.playerName, panelX + v3[4], rowY, 0, rowY + rowHeight, whiteColor, 1, Roboto, "left", "center", false, false, false, true)
									end
								else
									if column == "ID" then
										dxDrawText("#" .. data.playerID, panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, whiteColor, 0.8, Roboto, "left", "center")
									elseif column == "Név" then
										dxDrawText(data.playerName, panelX + v3[4], rowY, 0, rowY + rowHeight, whiteColor, 1, Roboto, "left", "center", false, false, false, true)
									elseif column == "Karakter ID" and localAdminLevel >= 1 then
										dxDrawText(data.charID, panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, whiteColor, 1, Roboto, "center", "center")
									elseif column == "Account ID" and localAdminLevel >= 1 then
										dxDrawText(data.accID, panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, whiteColor, 1, Roboto, "center", "center")
									elseif column == "Szint" then
										dxDrawText(data.level, panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, whiteColor, 1, Roboto, "center", "center")
									elseif column == "Ping" then
										local playerPing = getPlayerPing(playerElement)
										
										if playerPing > 100 and playerPing <= 150 then
											dxDrawText(playerPing .. " ms", panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, tocolor(200, 200, 75, alpha255), 1, Roboto, "right", "center")
										elseif playerPing <= 100 then
											dxDrawText(playerPing .. " ms", panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, tocolor(50, 200, 50, alpha255), 1, Roboto, "right", "center")
										else
											dxDrawText(playerPing .. " ms", panelX + v3[4], rowY, panelX + v3[4] + v3[5], rowY + rowHeight, tocolor(200, 50, 50, alpha255), 1, Roboto, "right", "center")
										end
									end
								end
							end
						end
					end

					playerCount = playerCount + 1
				end

				rowCount = rowCount + 1
			end
		end
	end

	-- ** Footer
	dxDrawRectangle(panelX, panelY + panelHeight - footerHeight, panelWidth, footerHeight, tocolor(30, 30, 30, 230 * fadeAmount))
	dxDrawText("www.sa-rp.eu", panelX, panelY + panelHeight - footerHeight, panelX + panelWidth, panelY + panelHeight, whiteColor, 1, RobotoL18, "center", "center")
end

bindKey("tab", "both",
	function (button, state)
		if state == "down" then
			if getElementData(localPlayer, "loggedIn") then
				initScoreboard()

				fadeStart = getTickCount()
				fadeEnd = false

				panelState = true

				playSound(":sarp_assets/audio/scoreboard/popup.wav")
			end
		elseif state == "up" and getElementData(localPlayer, "loggedIn") then
			fadeStart = false
			fadeEnd = getTickCount()
		end
	end
)

bindKey("mouse_wheel_down", "both",
	function (button, state)
		if panelState and not fadeEnd then
			local found = false
			
			for k,v in ipairs(scoreboardTeams) do
				local playersInGroup = 0

				for k2, v2 in pairs(scoreboardTeamPlayers[k]) do
					playersInGroup = playersInGroup + 1
				end

				if playersInGroup > 0 and scoreboardOffsets[k] ~= playersInGroup then
					found = k
					break
				end
			end

			if found then
				scoreboardOffsets[found] = scoreboardOffsets[found] + 1
			end
		end
	end
)

bindKey("mouse_wheel_up", "both",
	function (button, state)
		if panelState and not fadeEnd then
			local found = false
			
			for k,v in ipairs(scoreboardTeams) do
				local playersInGroup = 0

				for k2, v2 in pairs(scoreboardTeamPlayers[k]) do
					playersInGroup = playersInGroup + 1
				end

				if playersInGroup > 0 and (scoreboardOffsets[k] ~= 0) then
					found = k
				end
			end

			if found then
				scoreboardOffsets[found] = scoreboardOffsets[found] - 1
			end
		end
	end
)