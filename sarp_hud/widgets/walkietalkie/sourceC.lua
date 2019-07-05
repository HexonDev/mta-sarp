local imageSizeX = 512
local imageSizeY = 512

local panelSizeX = 195
local panelSizeY = 495

local isVisible = false
local forceVisibleState = true

local tempChannel = 0
local channelSwitchTimer = false

local protectedChannels = {}

local activeRadioItemID = false
local lastChannel = 0
local radioChannelsMuted = false

local antiFloodTick = 0

local panelPosX = screenX - resp(12) - 195
local panelPosY = screenY / 2 - 495 / 2

local draggingPanel = false

local buttons = {}
local activeButton = false

function setRadioStartPos(x, y)
	panelPosX, panelPosY = x, y
end

function getRadioStartPos()
	return panelPosX, panelPosY
end

addCommandHandler("togradio",
	function()
		forceVisibleState = not forceVisibleState
	end)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue, newValue)
		if source == localPlayer and dataName == "player.groups" or dataName == "loggedIn" then
			checkForGroups()
		end
	end
)

function checkForGroups()
	local loggedIn = getElementData(localPlayer, "loggedIn")

	if loggedIn then
		local localPlayerGroups = getElementData(localPlayer, "player.groups") or {}
		local groups = exports.sarp_groups:getGroups()

		protectedChannels = {}

		for k, v in pairs(groups) do
			if v.tuneRadio and v.tuneRadio > 0 then
				if not localPlayerGroups[k] or not loggedIn then
					protectedChannels[v.tuneRadio] = true
				end
			end
		end

		local currentRadioTune = getElementData(localPlayer, "currentRadioTune")
		if currentRadioTune then
			setElementData(localPlayer, "currentRadioTune", {tempChannel, radioChannelsMuted, protectedChannels[tempChannel]})
		end
	end
end
addEventHandler("receiveGroups", getRootElement(), checkForGroups)
addEventHandler("onClientResourceStart", getResourceRootElement(), checkForGroups)

function showWalkieTalkie(show, data)
	isVisible = show

	if isVisible then
		local channel = data.data1

		checkForGroups()

		activeRadioItemID = data.dbID

		tempChannel = data.data1 and tonumber(data.data1) or 0

		lastChannel = tempChannel

		radioChannelsMuted = data.data2

		setElementData(localPlayer, "currentRadioTune", {tempChannel, radioChannelsMuted, protectedChannels[tempChannel]})

		if not forceVisibleState then
			outputChatBox("#32b3ef>> Információ: #ffffffA rádió el van rejtve! Előhozni a #6fcc9f/togradio #ffffffparanccsal tudod.", 0, 0, 0, true)
		end
	else
		setElementData(localPlayer, "currentRadioTune", false)
	end
end

function switchChannel(value, step, havePressing)
	tempChannel = value

	if tempChannel > 99999 then
		tempChannel = 99999
	elseif tempChannel < 0 then
		tempChannel = 0
	end

	if isTimer(channelSwitchTimer) then
		killTimer(channelSwitchTimer)
	end

	if step and havePressing then
		channelSwitchTimer = setTimer(switchChannel, 125, 0, tempChannel + step, step, havePressing)
	end
end

addEventHandler("onClientClick", getRootElement(),
	function (button, state, cx, cy)
		if button == "left" and state == "down" and isVisible and forceVisibleState and not renderData.editorActive and activeButton then
			if activeButton == "nextchannel" then
				if tempChannel < 99999 then
					switchChannel(tempChannel + 1, 1)
					channelSwitchTimer = setTimer(switchChannel, 500, 1, tempChannel + 1, 1, true)
				end

				playSound("widgets/walkietalkie/files/stationswitch.mp3")
			elseif activeButton == "prevchannel" then
				if tempChannel > 0 then
					switchChannel(tempChannel - 1, -1)
					channelSwitchTimer = setTimer(switchChannel, 500, 1, tempChannel - 1, -1, true)
				end

				playSound("widgets/walkietalkie/files/stationswitch.mp3")
			elseif activeButton == "mutechannel" then
				if getTickCount() >= antiFloodTick then
					playSound("widgets/walkietalkie/files/stationswitch.mp3")

					if radioChannelsMuted == "Y" then
						radioChannelsMuted = "N"
					else
						radioChannelsMuted = "Y"
					end

					if activeRadioItemID then
						if protectedChannels[lastChannel] then
							exports.sarp_hud:showInfobox("error", "A kiválasztott frekvencia védett!")
						else
							setElementData(localPlayer, "currentRadioTune", {lastChannel, radioChannelsMuted, protectedChannels[lastChannel]})

							triggerEvent("updateItemData1", localPlayer, "player", activeRadioItemID, lastChannel, true)
							triggerEvent("updateItemData2", localPlayer, "player", activeRadioItemID, radioChannelsMuted, true)

							checkRadioChannels()
						end
					end

					if radioChannelsMuted == "Y" then
						playSound("widgets/walkietalkie/files/mute.wav")
					else
						playSound("widgets/walkietalkie/files/unmute.wav")
					end

					antiFloodTick = getTickCount() + 1000
				end
			elseif activeButton == "setchannel" then
				if activeRadioItemID then
					playSound("widgets/walkietalkie/files/stationswitch.mp3")

					if lastChannel ~= tempChannel then
						if protectedChannels[tempChannel] then
							exports.sarp_hud:showInfobox("error", "A kiválasztott frekvencia védett!")
						else
							lastChannel = tempChannel

							setElementData(localPlayer, "currentRadioTune", {lastChannel, radioChannelsMuted, protectedChannels[lastChannel]})

							triggerEvent("updateItemData1", localPlayer, "player", activeRadioItemID, lastChannel, true)
							triggerEvent("updateItemData2", localPlayer, "player", activeRadioItemID, radioChannelsMuted, true)

							checkRadioChannels()
							
							playSound("widgets/walkietalkie/files/alert.wav")
						end
					end
				end
			end
		elseif button == "left" and state == "up" and isTimer(channelSwitchTimer) then
			killTimer(channelSwitchTimer)
			channelSwitchTimer = nil
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function()
		if isVisible and forceVisibleState then
			local absX, absY = getCursorPosition()

			buttons = {}

			if isCursorShowing() then
				absX = absX * screenX
				absY = absY * screenY

				if getKeyState("mouse1") then
					if absX >= panelPosX and absX <= panelPosX + panelSizeX and absY >= panelPosY and absY <= panelPosY + panelSizeY and not activeButton and not draggingPanel then
						draggingPanel = {absX, absY, panelPosX, panelPosY}
					end

					if draggingPanel then
						panelPosX = absX - draggingPanel[1] + draggingPanel[3]
						panelPosY = absY - draggingPanel[2] + draggingPanel[4]
					end
				elseif draggingPanel then
					draggingPanel = false
				end
			else
				absX, absY = -1, -1

				if draggingPanel then
					draggingPanel = false
				end
			end

			dxDrawImageSection(panelPosX, panelPosY, imageSizeX, imageSizeY, (imageSizeX - panelSizeX) / 2, (imageSizeY - panelSizeY) / 2, imageSizeX, imageSizeY - 1, "widgets/walkietalkie/files/walkietalkie.png")

			if tempChannel > 0 then
				if protectedChannels[tempChannel] then
					dxDrawText("PRT-" .. tempChannel, panelPosX + 50, panelPosY + 234, panelPosX + 138, panelPosY + 284, tocolor(0, 0, 0, 200), 1, LEDCalculator, "center", "center")
				else
					dxDrawText("CH-" .. tempChannel, panelPosX + 50, panelPosY + 234, panelPosX + 138, panelPosY + 284, tocolor(0, 0, 0, 200), 1, LEDCalculator, "center", "center")
				end

				if radioChannelsMuted == "N" then
					dxDrawImage(panelPosX + 50, panelPosY + 234, 12, 12, "files/icons/soundoff.png", 0, 0, 0, tocolor(0, 0, 0, 200))
				else
					dxDrawImage(panelPosX + 50, panelPosY + 234, 12, 12, "files/icons/soundon.png", 0, 0, 0, tocolor(0, 0, 0, 200))
				end
			else
				dxDrawText("No channel\nselected", panelPosX + 50, panelPosY + 234, panelPosX + 138, panelPosY + 284, tocolor(0, 0, 0, 200), 1, LEDCalculator, "center", "center")
			end

			buttons["nextchannel"] = {panelPosX + 38, panelPosY + 319, panelPosX + 70, panelPosY + 345}
			buttons["prevchannel"] = {panelPosX + 118, panelPosY + 319, panelPosX + 150, panelPosY + 345}
			buttons["mutechannel"] = {panelPosX + 41, panelPosY + 350, panelPosX + 143, panelPosY + 366}
			buttons["setchannel"] = {panelPosX + 73, panelPosY + 321, panelPosX + 115, panelPosY + 347}

			activeButton = false

			if isCursorShowing() and not renderData.editorActive then
				for k, v in pairs(buttons) do
					if absX >= v[1] and absX <= v[3] and absY >= v[2] and absY <= v[4] then
						activeButton = k
						break
					end
				end
			end
		end
	end)