local screenX, screenY = guiGetScreenSize()

local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

function resp(value)
	return value * responsiveMultipler
end

function respc(value)
	return math.ceil(value * responsiveMultipler)
end

function loadFonts()
	local fonts = {
		Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
		Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
		Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", resp(16), false, "cleartype"),
		Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
		RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
		RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
		RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
		RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
		gtaFont2 = exports.sarp_assets:loadFont("gtaFont2.ttf", resp(40), false, "default"),
		Themify60 = exports.sarp_assets:loadFont("Themify.ttf", respc(60), false, "cleartype"),
		RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
		Themify18 = exports.sarp_assets:loadFont("Themify.ttf", respc(18), false, "cleartype"),
		RobotoL14 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(14), false, "cleartype"),
		RobotoB14 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(14), false, "cleartype"),

		metro18 = exports.sarp_assets:loadFont("metro.ttf", respc(18), false, "cleartype"),
		metro60 = exports.sarp_assets:loadFont("metro.ttf", respc(60), false, "cleartype"),
	}

	for k,v in pairs(fonts) do
		_G[k] = v
		_G[k .. "H"] = dxGetFontHeight(1, _G[k])
	end
end

local debugMode = true

local groupsIsLoading = false
local playerGroups = false
local loopPlayerGroups = false
local playerGroupsCount = 0

local groups = {}
local meInGroup = {}
local rankCount = {}
local groupMembers = {}
local selectedGroup = false

local groupVehicles = {}
local vehicleDatas = {}
local monitoredGroupVeh = {}
local monitoredDatasForVehicle = {
	["vehicle.dbID"] = true,
	["vehicle.owner"] = true,
	["vehicle.fuel"] = true,
	["vehicle.distance"] = true,
	["vehicle.engine"] = true,
	["vehicle.locked"] = true,
	["vehicle.handBrake"] = true,
	["lastOilChange"] = true
}

local monitoredLocalDatas = {}
local monitoredDatasForMe = {
	["char.ID"] = true,
	["acc.adminLevel"] = true,
	["player.groups"] = true
}

local selectedRank = 1

local renderData = {}
renderData.draggingGrips = {}
renderData.gripPoses = {}

local panelState = false
local haveActiveEvents = false

local buttons = {}
local activeButton = false
local cursorX, cursorY = -10, -10

local cursorState = false
local lastChangeCursorState = 0

local scrollbarActive = false

local openedTime = 0
local alphaAnim = false

local menuContainer = {
	[1] = {
		icon = "files/icons/home.png",
		name = "Áttekintés",
	},
	[2] = {
		icon = "files/icons/ranks.png",
		name = "Rangok",
	},
	[3] = {
		icon = "files/icons/members.png",
		name = "Tagok",
	},
	[4] = {
		icon = "files/icons/vehicles.png",
		name = "Járművek",
	},
	[5] = {
		icon = "files/icons/other.png",
		name = "Egyéb",
	},
	--[6] = {
	--	icon = "files/icons/settings.png",
	--	name = "Leader beállítások",
	--	needLeader = true
	--},
}

local selectedTab = 1
local tabAfterInterpolation = selectedTab

local fakeInputs = {}
local activeFakeInput = false

local errorToDisplay = false
local errorText = ""

local lastNewRankTime = 0

local lastScrollByArrowBtn = 0

local startHistogramInterpolation = false
local histogramProgress = 0

renderData.visibleGroups = 7
renderData.groupsOffset = 0

renderData.visibleRanks = 13
renderData.ranksOffset = 0

renderData.visibleMembers = 13
renderData.membersOffset = 0

renderData.visibleVehicles = 13
renderData.vehiclesOffset = 0

local selectedMember = 1
local selectedVehicle = 1

renderData.interpolationInverse = {}
renderData.interpolationStart = {}

local tabSwitchStartInterpolation = {}
local tabSwitchEndInterpolation = {}
local tabPanelAlphas = {1, 0, 0, 0, 0, 0}
local alphaMultipler = 0

local lastSetLeaderTick = 0
local lastModifyMemberRankTick = 0

renderData.permissionsOffset = 0
renderData.availableItemsOffset = 0
renderData.dutyItemsOffset = 0

local selectedAdminTab = 1
local adminTabAfterInterpolation = selectedAdminTab

renderData.dropDowns = {}
renderData.activeDropDown = false

function resetVars()
	fakeInputs = {}
	activeFakeInput = false

	errorToDisplay = false
	errorText = ""

	lastNewRankTime = 0
	lastScrollByArrowBtn = 0

	scrollbarActive = false

	buttons = {}
	activeButton = false

	selectedRank = 1

	renderData.groupsOffset = 0
	renderData.ranksOffset = 0
	renderData.membersOffset = 0
	renderData.vehiclesOffset = 0

	startHistogramInterpolation = false
	histogramProgress = 0

	tabSwitchStartInterpolation = {}
	tabSwitchEndInterpolation = {}
	tabPanelAlphas = {1, 0, 0, 0, 0, 0}
	alphaMultipler = 0

	selectedTab = 1
	tabAfterInterpolation = selectedTab

	selectedAdminTab = 1
	adminTabAfterInterpolation = selectedAdminTab
end

local dutyColShapes = {}
local dutyTexture = dxCreateTexture("files/duty.png")
local boundColor = tocolor(7, 112, 196, 75)
local boundRadius = 0.5
local standingColShape = false
local lastDutyTick = 0

function createDutyPositions()
	for k, v in pairs(dutyColShapes) do
		if isElement(v) then
			destroyElement(v)
		end

		dutyColShapes[k] = nil
	end

	dutyColShapes = {}

	local playerGroups = getPlayerGroups(localPlayer)

	for k, v in pairs(availableGroups) do
		if playerGroups[k] then
			for k2, v2 in ipairs(v.duty.positions) do
				local colShape = createColSphere(v2[1], v2[2], v2[3], 1)
				
				if isElement(colShape) then
					setElementInterior(colShape, v2[4])
					setElementDimension(colShape, v2[5])
					setElementData(colShape, "dutyColShape", k)

					table.insert(dutyColShapes, colShape)
				end
			end
		end
	end
end

addEventHandler("onClientColShapeHit", getResourceRootElement(),
	function (hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension and getElementData(source, "dutyColShape") then
			standingColShape = getElementData(source, "dutyColShape")

			if getElementData(hitElement, "groupDuty") then
				exports.sarp_hud:showInfobox("info", "Nyomj [E] gombot a szolgálat leadásához.")
			else
				exports.sarp_hud:showInfobox("info", "Nyomj [E] gombot a szolgálat felvételéhez.")
			end
		end
	end
)

addEventHandler("onClientColShapeLeave", getResourceRootElement(),
	function (hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension then
			standingColShape = false
		end
	end
)

bindKey("E", "down",
	function ()
		if standingColShape and isPlayerInGroup(localPlayer, standingColShape) then
			if getTickCount() >= lastDutyTick + 30000 then
				lastDutyTick = getTickCount()
				triggerServerEvent("requestDuty", localPlayer, standingColShape)
			else
				exports.sarp_hud:showInfobox("error", "Csak fél percenként dutyzhatsz.")
			end
		end
	end
)

addEventHandler("onInterfaceStarted", getRootElement(), 
	function ()
		UI = exports.sarp_ui
		responsiveMultipler = UI:getResponsiveMultiplier()
	end
)

addEventHandler("onAssetsLoaded", getRootElement(),
	function ()
		loadFonts()
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		loadFonts()

		if getElementData(localPlayer, "loggedIn") then
			groupsIsLoading = true
			setTimer(triggerServerEvent, 2000, 1, "requestGroups", localPlayer)
		end

		for k, v in pairs(monitoredDatasForMe) do
			monitoredLocalDatas[k] = getElementData(localPlayer, k)
		end
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		if panelState == "groupPanel" or panelState == "createGroup" then
			exports.sarp_hud:toggleHUD(true)
			showChat(renderData.lastChatState)
			resetVars()
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if source == localPlayer and monitoredDatasForMe[dataName] then
			monitoredLocalDatas[dataName] = getElementData(source, dataName)

			if dataName == "player.groups" then
				createDutyPositions()
			end
		end

		if getElementType(source) == "vehicle" and monitoredDatasForVehicle[data] and monitoredGroupVeh[source] then
			if not vehicleDatas[source] then
				vehicleDatas[source] = {}
				vehicleDatas[source].vehicleName = exports.sarp_mods_veh:getVehicleName(source)
			end

			vehicleDatas[source][data] = getElementData(source, data)
		end
	end
)

addEventHandler("onClientPlayerSpawn", getRootElement(),
	function ()
		createDutyPositions()
	end
)

function fetchGroups(notRequestData)
	playerGroups = getPlayerGroups(localPlayer)
	playerGroupsCount = 0
	loopPlayerGroups = {}

	if playerGroups then
		if not notRequestData then
			triggerServerEvent("requestGroupData", localPlayer, playerGroups)
		end

		for k, v in pairs(playerGroups) do
			playerGroupsCount = playerGroupsCount + 1
			loopPlayerGroups[playerGroupsCount] = k

			if not playerGroups[selectedGroup] then
				selectedGroup = k
			end

			groupVehicles[k] = {}
		end

		for k, v in ipairs(getElementsByType("vehicle")) do
			local groupID = getElementData(v, "vehicle.group")

			if groupVehicles[groupID] then
				table.insert(groupVehicles[groupID], v)
				table.insert(monitoredGroupVeh, v)

				vehicleDatas[v] = {}

				for k in pairs(monitoredDatasForVehicle) do
					vehicleDatas[v][k] = getElementData(v, k)
				end

				vehicleDatas[v].vehicleName = exports.sarp_mods_veh:getVehicleName(v)
			end
		end

		if panelState == "groupPanel" and selectedTab == 4 then
			if renderData.vehiclesOffset > #groupVehicles[selectedGroup] - renderData.visibleVehicles then
				renderData.vehiclesOffset = #groupVehicles[selectedGroup] - renderData.visibleVehicles
			end

			if #groupVehicles[selectedGroup] < renderData.visibleVehicles then
				renderData.vehiclesOffset = 0
			end

			if selectedMember > #groupVehicles[selectedGroup] then
				selectedMember = #groupVehicles[selectedGroup]
			end
		end
	end
end

addEvent("deleteGroup", true)
addEventHandler("deleteGroup", getRootElement(),
	function (groupID)
		availableGroups[groupID] = nil
		groupMembers[groupID] = nil
		rankCount[groupID] = nil
		meInGroup[groupID] = nil
		groupVehicles[groupID] = nil

		fetchGroups(true)

		availableGroupsCount = table.length(availableGroups)
		renderData.lastGroupsCountForAdmin = false

		createDutyPositions()
	end
)

addEvent("receiveGroups", true)
addEventHandler("receiveGroups", getRootElement(),
	function (groups)
		availableGroups = groups
		availableGroupsCount = table.length(availableGroups)
		renderData.lastGroupsCountForAdmin = false

		createDutyPositions()

		groupsIsLoading = false
	end
)

addEvent("receiveGroupMembers", true)
addEventHandler("receiveGroupMembers", getRootElement(),
	function (members, groupID, playerID)
		local onlinePlayers = {}

		for k, v in pairs(getElementsByType("player")) do
			local id = getElementData(v, "char.ID")

			if id then
				onlinePlayers[id] = v
			end
		end

		local myID = getElementData(localPlayer, "char.ID")

		for k, v in pairs(members) do
			rankCount[k] = {}

			for k2, v2 in pairs(v) do
				local charID = v2.charID

				if charID == myID then
					meInGroup[k] = v2
				end

				if onlinePlayers[charID] then
					members[k][k2].online = onlinePlayers[charID]
				else
					members[k][k2].online = false
				end

				rankCount[k][v2.rank] = (rankCount[k][v2.rank] or 0) + 1
			end
		end

		groupMembers = members

		for k, v in pairs(groupMembers) do
			table.sort(v, function (a, b)
				return a.rank < b.rank
			end)

			for k2, v2 in pairs(v) do
				if k == groupID and v2.charID == playerID then
					selectedMember = k2
				end
			end
		end

		if panelState == "groupPanel" then
			if selectedTab == 2 then
				if renderData.ranksOffset > #availableGroups[selectedGroup].ranks - renderData.visibleRanks then
					renderData.ranksOffset = #availableGroups[selectedGroup].ranks - renderData.visibleRanks
				end

				if #availableGroups[selectedGroup].ranks < renderData.visibleRanks then
					renderData.ranksOffset = 0
				end

				if selectedRank > #availableGroups[selectedGroup].ranks then
					selectedRank = #availableGroups[selectedGroup].ranks
				end
			elseif selectedTab == 3 then
				if renderData.membersOffset > #groupMembers[selectedGroup] - renderData.visibleMembers then
					renderData.membersOffset = #groupMembers[selectedGroup] - renderData.visibleMembers
				end

				if #groupMembers[selectedGroup] < renderData.visibleMembers then
					renderData.membersOffset = 0
				end

				if selectedMember > #groupMembers[selectedGroup] then
					selectedMember = #groupMembers[selectedGroup]
				end
			end
		end

		createDutyPositions()
	end
)

function groupsCommandHandler()
	if getElementData(localPlayer, "loggedIn") then
		if panelState or haveActiveEvents then
			togglePanel(false)
		elseif groupsIsLoading then
			exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Frakciók betöltése folyamatban van!", "Próbáld pár másodperc múlva.")
		elseif getTickCount() - openedTime >= 2000 then
			fetchGroups()

			if playerGroupsCount > 0 then
				if playerGroupsCount > 1 then
					togglePanel("selectGroup")
				else
					togglePanel("groupPanel")
				end
			else
				exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Nem tartozol egy frakció tagjai közé sem.")
			end

			openedTime = getTickCount()
		else
			exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Maximum 2 másodpercenként nyithatod meg a frakciópanelt!")
		end
	end
end
addCommandHandler("groups", groupsCommandHandler)
bindKey("F3", "down", groupsCommandHandler)

exports.sarp_admin:addAdminCommand("managegroups", 7, "Frakciók kezelése")
addCommandHandler("managegroups",
	function ()
		if monitoredLocalDatas["acc.adminLevel"] >= 7 then
			if panelState or haveActiveEvents then
				togglePanel(false)
			elseif groupsIsLoading then
				exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Frakciók betöltése folyamatban van!", "Próbáld pár másodperc múlva.")
			elseif getTickCount() - openedTime >= 2000 then
				if availableGroupsCount > 0 then
					selectedGroup = "new"
					togglePanel("selectGroup:admin")
				else
					togglePanel("createGroup")
				end

				openedTime = getTickCount()
			else
				exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Maximum 2 másodpercenként nyithatod meg a frakció kezelő panelt!")
			end
		end
	end
)

function togglePanel(state)
	if state then
		if not haveActiveEvents then
			alphaAnim = {getTickCount(), "Y", 0}
		elseif state ~= panelState then
			alphaAnim = {getTickCount(), "N", alphaAnim[3], state}
		end
	end

	if not state then
		if haveActiveEvents then
			alphaAnim = {getTickCount(), "N", alphaAnim[3], state}

			removeEventHandler("onClientClick", getRootElement(), onClientClick)
			removeEventHandler("onClientKey", getRootElement(), onClientKey)
			removeEventHandler("onClientCharacter", getRootElement(), onClientCharacter)

			showCursor(false)
		end
	end

	if state and not haveActiveEvents then
		panelState = state
		showCursor(true)

		addEventHandler("onClientRender", getRootElement(), onClientRender)
		addEventHandler("onClientClick", getRootElement(), onClientClick)
		addEventHandler("onClientKey", getRootElement(), onClientKey, true, "low-999")
		addEventHandler("onClientCharacter", getRootElement(), onClientCharacter)
		haveActiveEvents = true
	end

	if state == "groupPanel" or state == "createGroup" then
		exports.sarp_hud:toggleHUD(false)
		renderData.lastChatState = isChatVisible()
		showChat(false)
	end
end

function reMap(value, low1, high1, low2, high2)
	return (value - low1) * (high2 - low2) / (high1 - low1) + low2
end

function onClientRender()
	local x, y, sx, sy

	buttons = {}
	scrollbarActive = false

	renderData.cursorInAvailableItemsList = true
	renderData.cursorInDutyItemsList = true

	if alphaAnim and alphaAnim[1] then
		if getTickCount() >= alphaAnim[1] then
			local progress = (getTickCount() - alphaAnim[1]) / 250

			if alphaAnim[2] == "Y" then
				alphaAnim[3] = interpolateBetween(alphaAnim[3], 0, 0, 1, 0, 0, progress, "Linear")
			elseif alphaAnim[2] == "N" then
				alphaAnim[3] = interpolateBetween(alphaAnim[3], 0, 0, 0, 0, 0, progress, "Linear")
			end

			if progress >= 1 then
				if alphaAnim[2] == "N" then
					if alphaAnim[4] == false then
						if panelState == "groupPanel" or panelState == "createGroup" then
							exports.sarp_hud:toggleHUD(true)
							showChat(renderData.lastChatState)
						end

						haveActiveEvents = false
						panelState = false
						alphaAnim[1] = false
						resetVars()
						removeEventHandler("onClientRender", getRootElement(), onClientRender)
					elseif alphaAnim[4] then
						panelState = alphaAnim[4]
						alphaAnim[1] = getTickCount()
						alphaAnim[2] = "Y"
					end
				elseif alphaAnim[2] == "Y" then
					if panelState == "groupPanel" then
						if not startHistogramInterpolation then
							histogramProgress = 0
							startHistogramInterpolation = getTickCount()
						end
					end

					alphaAnim[1] = false
				end
			end
		end
	end

	if panelState == "selectGroup:admin" then
		drawGroupSelector(true)
	elseif panelState == "selectGroup" then
		drawGroupSelector()
	elseif panelState == "groupPanel" then
		drawGroupPanel()
	elseif panelState == "createGroup" then
		drawGroupCreator()
	end

	local cx, cy = getCursorPosition()

	if tonumber(cx) and tonumber(cy) then
		cx, cy = cx * screenX, cy * screenY
		cursorX, cursorY = cx, cy

		activeButton = false

		for k, v in pairs(buttons) do
			if cx >= v[1] and cy >= v[2] and cx <= v[1] + v[3] and cy <= v[2] + v[4] then
				local isScrollbarGrip = string.find(k, "scrollbar")

				if isScrollbarGrip then
					scrollbarActive = k
				end

				if (renderData.activeDropDown and string.find(k, renderData.activeDropDown)) or not renderData.activeDropDown then
					activeButton = k
				end
				--break
			end
		end

		if scrollbarActive then
			activeButton = scrollbarActive
		end
	else
		activeButton = false
		cursorX, cursorY = -10, -10
	end
end

local groupCreatorMenu = {
	[1] = {
		icon = "files/icons/settings.png",
		name = "Opciók 1"
	},
	[2] = {
		icon = "files/icons/settings.png",
		name = "Opciók 2"
	},
	[3] = {
		icon = "files/icons/settings.png",
		name = "Opciók 3"
	},
	[4] = {
		icon = false,
		name = "saveTab"
	}
}

function drawGroupCreator()
	sx = screenX - respc(60)
	sy = screenY - respc(60)

	x = (screenX - sx) / 2
	y = (screenY - sy) / 2

	local headerHeight = respc(70)
	local logoSize = respc(36)
	local marginOffset = (headerHeight - logoSize) / 2
	local menuWidth = respc(300)

	-- ** Háttér
	dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240 * alphaAnim[3]))
	
	-- ** Logó
	dxDrawRectangle(x, y, menuWidth, headerHeight, tocolor(28, 28, 28, 225 * alphaAnim[3]))
	dxDrawImage(math.ceil(x + marginOffset), math.ceil(y + marginOffset), logoSize, logoSize, "files/headerLogo.png", 0, 0, 0, tocolor(50, 179, 239, 255 * alphaAnim[3]))
	dxDrawText("San Andreas Roleplay", x + logoSize + marginOffset*2, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto14, "left", "center")

	-- ** Cím
	dxDrawRectangle(x + menuWidth, y, sx - menuWidth, headerHeight, tocolor(24, 24, 24, 225 * alphaAnim[3]))
	if renderData.editGroup then
		dxDrawText("Frakció szerkesztése", x + menuWidth + marginOffset, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL18, "left", "center")
	else
		dxDrawText("Frakció készítés", x + menuWidth + marginOffset, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL18, "left", "center")
	end

	-- ** Bezárás
	local closeSize = respc(24)
	local closeColor

	if activeButton == "closePanel" then
		closeColor = {processColorSwitchEffect("closePanel", {215, 89, 89, 255})}
	else
		closeColor = {processColorSwitchEffect("closePanel", {255, 255, 255, 255})}
	end
	dxDrawImage(x + sx - closeSize - marginOffset, y + (headerHeight - closeSize) / 2, closeSize, closeSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(closeColor[1], closeColor[2], closeColor[3], closeColor[4] * alphaAnim[3]))
	buttons["closePanel"] = {x + sx - closeSize - marginOffset, y + (headerHeight - closeSize) / 2, closeSize, closeSize}

	-- ** Frakció törlése gomb
	if renderData.editGroup then
		local buttonWidth = respc(200)
		local buttonHeight = respc(35)

		if errorToDisplay == "deleteGroup" and string.len(errorText) > 0 then
			buttonWidth = respc(500)
			local acceptWidth = respc(75)

			dxDrawText(errorText, x + sx - closeSize - marginOffset*2 - buttonWidth, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto14, "left", "center", false, false, false, true)
		
			drawButton("deleteGroup_promptOk", "Igen", x + sx - closeSize - marginOffset*2 - acceptWidth*2 - respc(5), y + (headerHeight - buttonHeight) / 2, acceptWidth, buttonHeight, {200, 50, 50})
			drawButton("errorOk", "Nem", x + sx - closeSize - marginOffset*2 - acceptWidth, y + (headerHeight - buttonHeight) / 2, acceptWidth, buttonHeight, {7, 112, 196})
		else
			drawButton("deleteGroup", "Frakció törlése", x + sx - closeSize - marginOffset*2 - buttonWidth, y + (headerHeight - buttonHeight) / 2, buttonWidth, buttonHeight, {200, 50, 50, 255}, "")
		end
	end

	-- ** Menü
	y = y + headerHeight

	dxDrawRectangle(x, y, menuWidth, sy - headerHeight, tocolor(24, 24, 24, 225 * alphaAnim[3]))

	local menuRowHeight = respc(48)
	local menuIconSize = respc(32)
	local iconMargin = (menuRowHeight - menuIconSize) / 2

	for i = 1, #groupCreatorMenu do
		local itemY = y + (menuRowHeight * (i - 1))
		local container = groupCreatorMenu[i]

		if container then
			local r, g, b = 60, 60, 60
			local containerName = container.name

			if container.name == "saveTab" then
				if renderData.editGroup then
					containerName = "VÁLTOZTATÁSOK MENTÉSE"
				else
					containerName = "FRAKCIÓ LÉTREHOZÁSA"
				end

				r, g, b = 50, 150, 50
				itemY = y + sy - menuRowHeight - headerHeight
			end

			local colorOfContainer

			if adminTabAfterInterpolation == i then
				colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {7, 112, 196, 255})}
			elseif activeButton == "selectTab:" .. i and not scrollbarActive and not getKeyState("mouse1") then
				colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {r, g, b, 255})}
			elseif i % 2 ~= 0 then
				colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {45, 45, 45, 100})}
			else
				colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {45, 45, 45, 50})}
			end

			dxDrawRectangle(x, itemY, menuWidth, menuRowHeight, tocolor(colorOfContainer[1], colorOfContainer[2], colorOfContainer[3], colorOfContainer[4] * alphaAnim[3]))
			
			if container.icon then
				dxDrawImage(math.floor(x + iconMargin*2), math.floor(itemY + iconMargin), menuIconSize, menuIconSize, container.icon, 0, 0, 0, tocolor(255, 255, 255, 255 * alphaAnim[3]))
			end

			if container.name == "saveTab" then
				dxDrawText(containerName, x, itemY, x + menuWidth, itemY + menuRowHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL14, "center", "center")
			else
				dxDrawText(containerName, x + menuIconSize + iconMargin*3, itemY, 0, itemY + menuRowHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto11, "left", "center")
			end
		
			buttons["selectTab:" .. i] = {x, itemY, menuWidth, menuRowHeight}
		end
	end

	-- ** Felületek
	local containerWidth = sx - menuWidth - marginOffset*2

	x = x + menuWidth + marginOffset
	y = y + marginOffset

	for i = 1, #menuContainer do
		if not tabPanelAlphas[i] then
			tabPanelAlphas[i] = 0
		end

		if tonumber(tabSwitchStartInterpolation[i]) then
			local progress = (getTickCount() - tabSwitchStartInterpolation[i]) / 250

			tabPanelAlphas[i] = interpolateBetween(tabPanelAlphas[i], 0, 0, 1, 0, 0, progress, "Linear")

			if progress >= 1 then
				tabSwitchStartInterpolation[i] = false
			end
		elseif tonumber(tabSwitchEndInterpolation[i]) then
			local progress = (getTickCount() - tabSwitchEndInterpolation[i]) / 250

			tabPanelAlphas[i] = interpolateBetween(tabPanelAlphas[i], 0, 0, 0, 0, 0, progress, "Linear")

			if progress >= 1 then
				tabSwitchEndInterpolation[i] = false

				if adminTabAfterInterpolation ~= selectedAdminTab then
					selectedAdminTab = adminTabAfterInterpolation

					tabSwitchStartInterpolation[selectedAdminTab] = getTickCount()
				end
			end
		end
	end

	alphaMultipler = alphaAnim[3] * tabPanelAlphas[selectedAdminTab]

	-- ** Opciók 1
	if selectedAdminTab == 1 then
		-- ** Alap adatok
		local dropdownY = y
		drawInput("groupName", "Csoport teljes neve", x + respc(455), y, sx - menuWidth - marginOffset*2 - respc(455), respc(35))
		
		y = y + respc(40)

		drawInput("groupMainLeader", "Csoport főleader karakter ID-je", x, y, respc(450), respc(35))
		drawInput("groupPrefix", "Csoport rövid neve (Prefix)", x + respc(455), y, containerWidth - respc(455), respc(35))

		y = y + respc(45)

		dxDrawLine(x, y, x + containerWidth, y, tocolor(255, 255, 255, 255 * alphaMultipler), 1)

		y = y + respc(10)

		-- ** Duty pozíciók
		if not renderData.dutyPoses then
			renderData.dutyPoses = {}
		end

		local totalListHeight = (sy - headerHeight - marginOffset*2 - respc(95 + 20 + 40 + 10) - RobotoL18H) / 2
		local listWidth = (containerWidth - marginOffset) / 2
		local oneItemHeight = totalListHeight / 8

		drawButton("addDutyPos", "Duty pozíció felvétele", x, y, listWidth, respc(35), {7, 112, 196, 255})

		y = y + respc(40)

		local removeIconSize = oneItemHeight * 0.6
		if removeIconSize > respc(24) then
			removeIconSize = respc(24)
		end

		for i = 1, 8 do
			local itemY = y + (oneItemHeight * (i - 1))
			local thisItem = renderData.dutyPoses[i]

			local colorOfRow
			if i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			else
				colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			end

			dxDrawRectangle(x, itemY, listWidth, oneItemHeight, colorOfRow)

			if thisItem then
				dxDrawText(getZoneName(thisItem[1], thisItem[2], thisItem[3]), x + 10, itemY, x + 10 + listWidth - 20 - removeIconSize - 10, itemY + oneItemHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto14, "left", "center", true)
				
				local removeIconColor
				if activeButton == "removeDutyPos:" .. i then
					removeIconColor = {processColorSwitchEffect("removeDutyPos:" .. i, {215, 89, 89, 255})}
				else
					removeIconColor = {processColorSwitchEffect("removeDutyPos:" .. i, {255, 255, 255, 255})}
				end
				dxDrawImage(x + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(removeIconColor[1], removeIconColor[2], removeIconColor[3], removeIconColor[4] * alphaMultipler))
				buttons["removeDutyPos:" .. i] = {x + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize}
			end
		end

		dxDrawInnerBorder(1, x, y, listWidth, oneItemHeight * 8, tocolor(118, 118, 118, 100 * alphaMultipler))

		-- ** Duty skinek
		if not renderData.dutySkins then
			renderData.dutySkins = {}
		end

		local x2 = x + listWidth + marginOffset
		local acceptWidth = respc(100)

		y = y - respc(40)

		drawInput("addDutySkin", "Duty skin ID", x2, y, listWidth - acceptWidth, respc(35))
		drawButton("addDutySkin", "Hozzáad", x2 + listWidth - acceptWidth, y, acceptWidth, respc(35), {7, 112, 196, 255})

		y = y + respc(40)

		for i = 1, 8 do
			local itemY = y + (oneItemHeight * (i - 1))
			local thisItem = renderData.dutySkins[i]

			local colorOfRow
			if i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			else
				colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			end

			dxDrawRectangle(x2, itemY, listWidth, oneItemHeight, colorOfRow)

			if thisItem then
				dxDrawText(thisItem, x2 + 10, itemY, x2 + 10 + listWidth - 20 - removeIconSize - 10, itemY + oneItemHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto14, "left", "center", true)
				
				local removeIconColor
				if activeButton == "removeDutySkin:" .. i then
					removeIconColor = {processColorSwitchEffect("removeDutySkin:" .. i, {215, 89, 89, 255})}
				else
					removeIconColor = {processColorSwitchEffect("removeDutySkin:" .. i, {255, 255, 255, 255})}
				end
				dxDrawImage(x2 + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(removeIconColor[1], removeIconColor[2], removeIconColor[3], removeIconColor[4] * alphaMultipler))
				buttons["removeDutySkin:" .. i] = {x2 + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize}
			end
		end

		dxDrawInnerBorder(1, x2, y, listWidth, oneItemHeight * 8, tocolor(118, 118, 118, 100 * alphaMultipler))

		-- ** Jogosultságok
		if not renderData.dutyPermissions then
			renderData.dutyPermissions = {}
		end

		y = y + oneItemHeight * 8 + respc(10)

		dxDrawLine(x, y, x + containerWidth, y, tocolor(255, 255, 255, 255 * alphaMultipler), 1)

		y = y + respc(10)

		dxDrawText("Jogosultságok", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

		y = y + RobotoL18H + respc(10)

		local listWidth = containerWidth

		if #availablePermissionsEx > 8 then
			listWidth = containerWidth - 12
		end

		for i = 1, 8 do
			local itemY = y + (oneItemHeight * (i - 1))
			local thisItem = availablePermissionsEx[i + renderData.permissionsOffset]

			local colorOfRow
			if i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			else
				colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			end

			local colorOfText = tocolor(255, 255, 255, 255 * alphaMultipler)

			if renderData.dutyPermissions[thisItem] then
				colorOfText = tocolor(50, 200, 50, 255 * alphaMultipler)
			end

			if activeButton == "togDutyPermission:" .. i + renderData.permissionsOffset then
				if renderData.dutyPermissions[thisItem] then
					colorOfText = tocolor(200, 50, 50, 255 * alphaMultipler)
				else
					colorOfText = tocolor(50, 179, 239, 255 * alphaMultipler)
				end
			end

			dxDrawRectangle(x, itemY, listWidth, oneItemHeight, colorOfRow)

			if thisItem then
				dxDrawText(availablePermissions[thisItem], x + 10, itemY, x + 10 + listWidth - 20 - removeIconSize - 10, itemY + oneItemHeight, colorOfText, 0.75, Roboto14, "left", "center", true)
				buttons["togDutyPermission:" .. i + renderData.permissionsOffset] = {x, itemY, listWidth, oneItemHeight}
			end
		end

		-- ** Scrollbar
		if #availablePermissionsEx > 8 then
			drawScrollbar("permissions", x + listWidth, y, 12, oneItemHeight * 8, 8, #availablePermissionsEx)
		end

		-- ** Dropdown
		drawDropDown("groupType", x, dropdownY, respc(450), respc(35), groupTypesEx)
	end

	-- ** Opciók 2
	if selectedAdminTab == 2 then
		drawInput("dutyArmor", "Duty armor (0-100)", x, y, containerWidth, respc(35))

		y = y + respc(40)

		dxDrawLine(x, y, x + containerWidth, y, tocolor(255, 255, 255, 255 * alphaMultipler), 1)

		y = y + respc(10)

		-- ** Elérhető itemek
		if not renderData.availableItems then
			renderData.availableItems = exports.sarp_inventory:getItemList()

			renderData.availableItemsEx = {}

			for i = 1, #renderData.availableItems do
				table.insert(renderData.availableItemsEx, i)
			end
		end

		local totalListHeight = (sy - headerHeight - marginOffset*2 - respc(50 + 45)) / 2
		local oneItemHeight = totalListHeight / 10
		local listWidth = containerWidth

		if #renderData.availableItemsEx > 10 then
			listWidth = listWidth - 12
		end

		for i = 1, 10 do
			local itemY = y + (oneItemHeight * (i - 1))
			local thisItem = renderData.availableItemsEx[i + renderData.availableItemsOffset]

			local colorOfRow
			if activeButton == "addItem:" .. i + renderData.availableItemsOffset then
				colorOfRow = tocolor(7, 112, 196, 255 * alphaMultipler)
			elseif i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			else
				colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			end

			dxDrawRectangle(x, itemY, listWidth, oneItemHeight, colorOfRow)

			if thisItem then
				local itemData = renderData.availableItems[thisItem]

				dxDrawText("#" .. thisItem .. "   " .. itemData[1], x + 10, itemY, x + 10 + listWidth - 20, itemY + oneItemHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto14, "left", "center", true)
				
				buttons["addItem:" .. i + renderData.availableItemsOffset] = {x, itemY, listWidth, oneItemHeight}
			end
		end

		-- ** Scrollbar
		if #renderData.availableItemsEx > 10 then
			if cursorX >= x and cursorY >= y and cursorX <= x + listWidth and cursorY <= y + oneItemHeight * 10 then
				renderData.cursorInAvailableItemsList = true
			end

			drawScrollbar("availableItems", x + listWidth, y, 12, oneItemHeight * 10, 10, #renderData.availableItemsEx)
		end

		-- ** Elérhető itemek kereső
		y = y + oneItemHeight * 10 + respc(5)

		drawInput("searchItem", "Item névrészlet/ID a kereséshez", x, y, containerWidth, respc(35))

		-- ** Duty itemek
		y = y + respc(35) + respc(5)

		if not renderData.dutyItems then
			renderData.dutyItems = {}
		end

		local totalListHeight = totalListHeight - respc(35)
		local oneItemHeight = totalListHeight / 10
		local listWidth = containerWidth

		if #renderData.dutyItems > 10 then
			listWidth = listWidth - 12
		end

		local removeIconSize = oneItemHeight * 0.6
		if removeIconSize > respc(24) then
			removeIconSize = respc(24)
		end

		for i = 1, 10 do
			local itemY = y + (oneItemHeight * (i - 1))
			local thisItem = renderData.dutyItems[i + renderData.dutyItemsOffset]

			local colorOfRow
			if renderData.selectedDutyItem == i + renderData.dutyItemsOffset then
				colorOfRow = tocolor(7, 112, 196, 255 * alphaMultipler)
			elseif activeButton == "selectDutyItem:" .. i + renderData.dutyItemsOffset then
				colorOfRow = tocolor(53, 53, 53, 255 * alphaMultipler)
			elseif i % 2 == 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			else
				colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			end

			dxDrawRectangle(x, itemY, listWidth, oneItemHeight, colorOfRow)

			if thisItem then
				dxDrawText("#" .. thisItem[1] .. "     " .. thisItem[2] .. "    |   Mennyiség: " .. thisItem[3] .. "   |   Data: " .. thisItem[4], x + 10, itemY, x + 10 + listWidth - 20, itemY + oneItemHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto14, "left", "center", true)
				
				local removeIconColor
				if activeButton == "removeDutyItem:" .. i + renderData.dutyItemsOffset then
					removeIconColor = tocolor(215, 89, 89, 255 * alphaMultipler)
				else
					removeIconColor = tocolor(255, 255, 255, 255 * alphaMultipler)
				end
				dxDrawImage(x + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, removeIconColor)
				
				buttons["removeDutyItem:" .. i + renderData.dutyItemsOffset] = {x + listWidth - removeIconSize - 10, itemY + (oneItemHeight - removeIconSize) / 2, removeIconSize, removeIconSize}
			
				if cursorX <= x + listWidth - removeIconSize - 15 then
					buttons["selectDutyItem:" .. i + renderData.dutyItemsOffset] = {x, itemY, listWidth, oneItemHeight}
				end
			end
		end

		-- ** Scrollbar
		if #renderData.dutyItems > 10 then
			if cursorX >= x and cursorY >= y and cursorX <= x + listWidth and cursorY <= y + oneItemHeight * 10 then
				renderData.cursorInAvailableItemsList = false
				renderData.cursorInDutyItemsList = true
			end

			drawScrollbar("dutyItems", x + listWidth, y, 12, oneItemHeight * 10, 10, #renderData.dutyItems)
		end

		-- ** Kijelölt duty item szerkesztése
		if renderData.selectedDutyItem then
			y = y + oneItemHeight * 10 + respc(5)

			local acceptWidth = respc(100)
			local inputWidth = (containerWidth - respc(5)*2 - acceptWidth) / 2

			if errorToDisplay == "acceptItemSettings" and string.len(errorText) > 0 then
				acceptWidth = respc(75)
				inputWidth = containerWidth - acceptWidth

				dxDrawText(errorText, x, y, x + inputWidth, y + respc(35), tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true, false, false, true)

				drawButton("errorOk", "OK", x + inputWidth, y, acceptWidth, respc(35), {7, 112, 196})
			else
				drawInput("setItemAmount", "Item mennyiség", x, y, inputWidth, respc(35))
				drawInput("setItemData1", "Item data 1 (opcionális)", x + inputWidth + respc(5), y, inputWidth, respc(35))
				drawButton("acceptItemSettings", "Mentés", x + inputWidth*2 + respc(5)*2, y, acceptWidth, respc(35), {7, 112, 196, 255})
			end
		end
	end

	-- ** Opciók 3
	if selectedAdminTab == 3 then
		local textWidth = dxGetTextWidth("Védett rádió frekvencia:", 1, Roboto14) + 12

		dxDrawText("Védett rádió frekvencia:", x, y, 0, y + respc(35), tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "center")

		drawInput("groupTuneRadio", "", x + textWidth, y, containerWidth - textWidth, respc(35))

		y = y + respc(40)
	end
end

local buttonCaptions = {"Rang nevének módosítása", "Fizetés módosítása", "RANG TÖRLÉSE"}
local buttonCaptionsEx = {"rankRename", "rankPayManaging", "rankRemove"}

function drawGroupPanel()
	local thisGroup = availableGroups[selectedGroup]
	local thisMembers = groupMembers[selectedGroup] or {}
	local thisVehicles = groupVehicles[selectedGroup] or {}
	local thisRanks = thisGroup.ranks or {}
	local thisRankCount = rankCount[selectedGroup] or {}

	if not thisGroup then
		panelState = "selectGroup"
	end

	sx = screenX - respc(60)
	sy = screenY - respc(60)

	x = (screenX - sx) / 2
	y = (screenY - sy) / 2

	local headerHeight = respc(70)
	local logoSize = respc(36)
	local marginOffset = (headerHeight - logoSize) / 2
	local menuWidth = respc(300)

	-- ** Háttér
	dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240 * alphaAnim[3]))
	
	-- ** Logó
	dxDrawRectangle(x, y, menuWidth, headerHeight, tocolor(28, 28, 28, 225 * alphaAnim[3]))
	dxDrawImage(math.ceil(x + marginOffset), math.ceil(y + marginOffset), logoSize, logoSize, "files/headerLogo.png", 0, 0, 0, tocolor(50, 179, 239, 255 * alphaAnim[3]))
	dxDrawText("San Andreas Roleplay", x + logoSize + marginOffset*2, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto14, "left", "center")

	-- ** Cím
	dxDrawRectangle(x + menuWidth, y, sx - menuWidth, headerHeight, tocolor(24, 24, 24, 225 * alphaAnim[3]))
	dxDrawText("#" .. thisGroup.groupID .. "    " .. thisGroup.name, x + menuWidth + marginOffset, y + respc(5), 0, 0, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL18, "left", "top")
	dxDrawText((groupTypes[thisGroup.type] or "Egyéb") .. " (" .. thisGroup.prefix .. ")", x + menuWidth + marginOffset, y, 0, y + headerHeight - respc(5), tocolor(100, 100, 100, 255 * alphaAnim[3]), 1, RobotoLI16, "left", "bottom")

	-- ** Bezárás
	local closeSize = respc(24)
	local closeColor

	if activeButton == "closePanel" then
		closeColor = {processColorSwitchEffect("closePanel", {215, 89, 89, 255})}
	else
		closeColor = {processColorSwitchEffect("closePanel", {255, 255, 255, 255})}
	end
	dxDrawImage(x + sx - closeSize - marginOffset, y + marginOffset, closeSize, closeSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(closeColor[1], closeColor[2], closeColor[3], closeColor[4] * alphaAnim[3]))
	buttons["closePanel"] = {x + sx - closeSize - marginOffset, y, closeSize, closeSize + marginOffset}

	-- ** Menü
	y = y + headerHeight

	dxDrawRectangle(x, y, menuWidth, sy - headerHeight, tocolor(24, 24, 24, 225 * alphaAnim[3]))

	local menuRowHeight = respc(48)
	local menuIconSize = respc(32)
	local iconMargin = (menuRowHeight - menuIconSize) / 2

	for i = 1, #menuContainer do
		local itemY = y + (menuRowHeight * (i - 1))
		local container = menuContainer[i]

		if container then
			if (container.needLeader and meInGroup[selectedGroup].isLeader == "Y") or not container.needLeader then
				local colorOfContainer

				if tabAfterInterpolation == i then
					colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {7, 112, 196, 255})}
				elseif activeButton == "selectTab:" .. i and not scrollbarActive and not getKeyState("mouse1") then
					colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {60, 60, 60, 255})}
				elseif i % 2 ~= 0 then
					colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {45, 45, 45, 100})}
				else
					colorOfContainer = {processColorSwitchEffect("menuTab:" .. i, {45, 45, 45, 50})}
				end

				dxDrawRectangle(x, itemY, menuWidth, menuRowHeight, tocolor(colorOfContainer[1], colorOfContainer[2], colorOfContainer[3], colorOfContainer[4] * alphaAnim[3]))
				dxDrawImage(math.floor(x + iconMargin*2), math.floor(itemY + iconMargin), menuIconSize, menuIconSize, container.icon, 0, 0, 0, tocolor(255, 255, 255, 255 * alphaAnim[3]))
				dxDrawText(container.name, x + menuIconSize + iconMargin*3, itemY, 0, itemY + menuRowHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto11, "left", "center")
			
				buttons["selectTab:" .. i] = {x, itemY, menuWidth, menuRowHeight}
			end
		end
	end

	-- ** Felületek
	x = x + menuWidth + marginOffset
	y = y + marginOffset

	for i = 1, #menuContainer do
		if not tabPanelAlphas[i] then
			tabPanelAlphas[i] = 0
		end

		if tonumber(tabSwitchStartInterpolation[i]) then
			local progress = (getTickCount() - tabSwitchStartInterpolation[i]) / 250

			tabPanelAlphas[i] = interpolateBetween(
				tabPanelAlphas[i], 0, 0,
				1, 0, 0,
				progress, "Linear")

			if progress >= 1 then
				tabSwitchStartInterpolation[i] = false
			end
		elseif tonumber(tabSwitchEndInterpolation[i]) then
			local progress = (getTickCount() - tabSwitchEndInterpolation[i]) / 250

			tabPanelAlphas[i] = interpolateBetween(
				tabPanelAlphas[i], 0, 0,
				0, 0, 0,
				progress, "Linear")

			if progress >= 1 then
				tabSwitchEndInterpolation[i] = false

				if tabAfterInterpolation ~= selectedTab then
					selectedTab = tabAfterInterpolation

					tabSwitchStartInterpolation[selectedTab] = getTickCount()

					if selectedTab == 1 then
						histogramProgress = 0
						startHistogramInterpolation = getTickCount()
					end
				end
			end
		end
	end

	alphaMultipler = alphaAnim[3] * tabPanelAlphas[selectedTab]

	--> Áttekintés
	if selectedTab == 1 then
		local cardCount = 3

		if thisGroup.tuneRadio and thisGroup.tuneRadio > 0 then
			cardCount = cardCount + 1
		end

		local cardMargin = respc(10)
		local cardWidth = (sx - menuWidth - marginOffset*2 - cardMargin*(cardCount-1)) / cardCount
		local cardHeight = respc(160)
		local cardX = x

		-- ** Rangok
		dxDrawRectangle(cardX, y, cardWidth, cardHeight, tocolor(7, 112, 196, 200 * alphaMultipler))
		dxDrawText("Rangok", cardX + respc(20), y + respc(10), 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
		dxDrawText("", cardX, y + respc(10), cardX + cardWidth, y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Themify60, "center", "center")
		dxDrawText(#thisRanks .. " db", cardX, y, cardX + cardWidth - respc(20), y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "right", "bottom")

		-- ** Tagok
		cardX = cardX + cardWidth + cardMargin

		dxDrawRectangle(cardX, y, cardWidth, cardHeight, tocolor(3, 153, 126, 200 * alphaMultipler))
		dxDrawText("Tagok", cardX + respc(20), y + respc(10), 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
		dxDrawText("", cardX, y + respc(10), cardX + cardWidth, y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, metro60, "center", "center")
		dxDrawText(#thisMembers .. " fő", cardX, y, cardX + cardWidth - respc(20), y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "right", "bottom")

		-- ** Járművek
		cardX = cardX + cardWidth + cardMargin

		dxDrawRectangle(cardX, y, cardWidth, cardHeight, tocolor(160, 124, 56, 200 * alphaMultipler))
		dxDrawText("Járművek", cardX + respc(20), y + respc(10), 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
		dxDrawText("", cardX, y + respc(10), cardX + cardWidth, y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, metro60, "center", "center")
		dxDrawText(#thisVehicles .. " db", cardX, y, cardX + cardWidth - respc(20), y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "right", "bottom")

		-- ** Frakció rádió frekvencia
		if thisGroup.tuneRadio and thisGroup.tuneRadio > 0 then
			cardX = cardX + cardWidth + cardMargin

			dxDrawRectangle(cardX, y, cardWidth, cardHeight, tocolor(200, 50, 50, 200 * alphaMultipler))
			dxDrawText("Rádió", cardX + respc(20), y + respc(10), 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
			dxDrawImage(math.floor(cardX + (cardWidth - respc(128)) / 2), math.floor(y + (cardHeight - respc(128)) / 2), respc(128), respc(128), "files/walkietalkie.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler))
			dxDrawText("CH-" .. thisGroup.tuneRadio, cardX, y, cardX + cardWidth - respc(20), y + cardHeight - respc(10), tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "right", "bottom")
		end

		-- ** Histogram
		local histogramWidth = sx - menuWidth - marginOffset*5
		local histogramHeight = (sy - headerHeight - marginOffset*7 - cardHeight)
		local tileWidth = (histogramWidth - respc(10)) / #thisRanks
		local tileHeight = histogramHeight / #thisMembers

		dxDrawText("Tagok (fő)", x, y + cardHeight + cardMargin * 2, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto11, "left", "top")

		y = y + cardHeight + cardMargin * 5

		dxDrawText("Rangok", x, y + histogramHeight + cardMargin, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto11, "left", "top")

		x = x + marginOffset * 3

		dxDrawRectangle(x, y, histogramWidth, histogramHeight, tocolor(50, 50, 50, 50 * alphaMultipler))

		if startHistogramInterpolation and getTickCount() >= startHistogramInterpolation then
			local progress = (getTickCount() - startHistogramInterpolation) / 500

			histogramProgress = interpolateBetween(
				0, 0, 0,
				1, 0, 0,
				progress, "OutQuad")

			if progress >= 1 then
				startHistogramInterpolation = false
			end
		end

		local activeTile = false

		for i = 1, #thisRanks do
			local x2 = x + (tileWidth * (i - 1))
			local y2 = y + histogramHeight
			local w = tileWidth

			if i % 2 ~= 0 then
				dxDrawRectangle(x2, y2, tileWidth, -histogramHeight, tocolor(25, 25, 25, 50 * alphaMultipler))
			else
				dxDrawRectangle(x2, y2, tileWidth, -histogramHeight, tocolor(25, 25, 25, 100 * alphaMultipler))
			end

			if thisRankCount[i] then
				local tileHeightProgress = (tileHeight * thisRankCount[i]) * histogramProgress
				local tileX = x2 + (tileWidth - w) / 2
				local tileY = y2 - tileHeightProgress

				dxDrawRectangle(tileX, tileY, w, tileHeightProgress, tocolor(7, 112, 196, 150 * alphaMultipler))

				if cursorX >= tileX and cursorY >= tileY and cursorX <= tileX + w and cursorY <= tileY + tileHeightProgress then
					activeTile = i
				end
			end

			dxDrawText(i, x2, y2, x2 + tileWidth, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto11, "center", "top")
		end

		x = x - marginOffset * 2

		if #thisMembers > 0 then
			for i = 0, #thisMembers do
				local y2 = y + histogramHeight - (tileHeight * i) - marginOffset / 2

				dxDrawText(i, x, y2, x + marginOffset, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto11, "center", "top")
			end
		end

		if activeTile then
			showTooltip(cursorX, cursorY, thisRanks[activeTile].name, "#8e8e8e" .. thisRankCount[activeTile] .. " tag")
		end
	end

	--> Rangok
	if selectedTab == 2 then
		-- ** Lista
		local listWidth = sx - menuWidth - marginOffset * 2
		local listWidthOrig = listWidth
		local listRowHeight = (sy - headerHeight - marginOffset * 2 - respc(235)) / renderData.visibleRanks

		if #thisRanks > renderData.visibleRanks then
			listWidth = listWidth - 12
		end

		for i = 1, renderData.visibleRanks do
			local rowY = y + (listRowHeight * (i - 1))
			local colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			local thisRank = thisRanks[i + renderData.ranksOffset]

			if thisRank and selectedRank == i + renderData.ranksOffset then
				colorOfRow = tocolor(7, 112, 196, 255 * alphaMultipler)
			elseif activeButton == "selectRank:" .. i + renderData.ranksOffset and not scrollbarActive and not getKeyState("mouse1") then
				colorOfRow = tocolor(53, 53, 53, 255 * alphaMultipler)
			elseif i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			end

			dxDrawRectangle(x, rowY, listWidth, listRowHeight, colorOfRow)

			if thisRank then
				dxDrawText("#" .. i + renderData.ranksOffset .. "   " .. thisRank.name, x + 10, rowY, x + 10 + listWidth - 20, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
				dxDrawText("$ " .. thousandsStepper(thisRank.pay, ","), x + listWidth, rowY, x + listWidth - 10, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "right", "center")

				buttons["selectRank:" .. i + renderData.ranksOffset] = {x, rowY, listWidth, listRowHeight}
			end
		end

		-- ** Scrollbar
		if #thisRanks > renderData.visibleRanks then
			drawScrollbar("ranks", x + listWidth, y, 12, listRowHeight * renderData.visibleRanks, renderData.visibleRanks, #thisRanks)
		end

		-- ** Új rang hozzáadása
		y = y + listRowHeight * renderData.visibleRanks

		if meInGroup[selectedGroup].isLeader == "Y" then
			if #thisRanks < maxGroupRank then
				drawButton("newRank", "+ Új rang hozzáadása", x, y, listWidthOrig, listRowHeight, {7, 112, 196})

				y = y + listRowHeight
			end
		end

		-- ** Kiválaszott rang
		if selectedRank and thisRanks[selectedRank] then
			local rank = thisRanks[selectedRank]
			local buttonY = y + marginOffset / 2

			y = y + marginOffset

			dxDrawText(rank.name .. " (" .. selectedRank .. ")", x, y, 0, 0, tocolor(7, 112, 196, 255 * alphaMultipler), 1, RobotoB18, "left", "top")

			y = y + RobotoB18H

			dxDrawText("Fizetés: ", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto16, "left", "top")
			dxDrawText("#32b3ef" .. (rank.pay or 0) .. " #eaeaea$", x + dxGetTextWidth("Fizetés: ", 1, Roboto16) + resp(5), y - resp(5), 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 0.5, gtaFont2, "left", "top", false, false, false, true)

			y = y + Roboto16H

			dxDrawText("Tagok száma ezen a rangon: #32b3ef" .. (thisRankCount[selectedRank] or 0) .. " #eaeaeafő", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto16, "left", "top", false, false, false, true)
		
			if meInGroup[selectedGroup].isLeader == "Y" then
				local acceptWidth = respc(75)
				local buttonWidth = listWidthOrig / 3
				local buttonX = x + listWidthOrig - buttonWidth - acceptWidth

				for i = 0, #thisRanks > 1 and 2 or 1 do
					local buttonY = buttonY + ((listRowHeight + marginOffset / 2) * i)

					if i == errorToDisplay and string.len(errorText) > 0 then
						if errorToDisplay < 2 then
							dxDrawText(errorText, buttonX, buttonY, buttonX + buttonWidth, buttonY + listRowHeight, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true, false, false, true)

							drawButton("errorOk", "OK", buttonX + buttonWidth, buttonY, acceptWidth, listRowHeight, {7, 112, 196})
						else
							dxDrawText(errorText, buttonX, buttonY, buttonX + buttonWidth, buttonY + listRowHeight, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true, false, false, true)

							drawButton("promptDecline", "Nem", buttonX + buttonWidth, buttonY, acceptWidth, listRowHeight, {7, 112, 196})

							drawButton("rankRemove_promptAccept", "Igen", buttonX + buttonWidth - acceptWidth - marginOffset / 2, buttonY, acceptWidth, listRowHeight, {200, 50, 50})
						end
					else
						local caption = buttonCaptionsEx[i+1]

						if i < 2 then
							if not fakeInputs[caption] then
								fakeInputs[caption] = ""
							end

							dxDrawRectangle(buttonX, buttonY, buttonWidth, listRowHeight, tocolor(50, 50, 50, 100 * alphaMultipler))
							buttons[caption .. ":input"] = {buttonX, buttonY, buttonWidth, listRowHeight}

							if utf8.len(fakeInputs[caption]) > 0 then
								dxDrawText(fakeInputs[caption], buttonX + 10, buttonY, buttonX + 10 + buttonWidth - 20, buttonY + listRowHeight, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true)
							else
								dxDrawText(buttonCaptions[i+1], buttonX + 10, buttonY, buttonX + 10 + buttonWidth - 20, buttonY + listRowHeight, tocolor(100, 100, 100, 200 * alphaMultipler), 1, Roboto14, "left", "center", true)
							end

							if activeFakeInput == caption then
								if cursorState then
									local w = dxGetTextWidth(fakeInputs[caption], 1, Roboto14)
									dxDrawLine(buttonX + 10 + w, buttonY + respc(5), buttonX + 10 + w, buttonY + listRowHeight - respc(5), tocolor(230, 230, 230, 255 * alphaMultipler))
								end

								if getTickCount() - lastChangeCursorState >= 500 then
									cursorState = not cursorState
									lastChangeCursorState = getTickCount()
								end
							end

							drawButton(caption, "OK", buttonX + buttonWidth, buttonY, acceptWidth, listRowHeight, {7, 112, 196})
						else
							drawButton(caption, buttonCaptions[i+1], buttonX, buttonY, buttonWidth + acceptWidth, listRowHeight, {200, 50, 50}, "")
						end
					end
				end
			end
		end
	end

	--> Tagok
	if selectedTab == 3 then
		y = y - marginOffset/2

		-- ** Lista
		local listWidth = sx - menuWidth - marginOffset * 2
		local listWidthOrig = listWidth
		local listRowHeight = (sy - headerHeight - marginOffset * 2 - respc(305) - RobotoL18H - respc(5)) / renderData.visibleMembers

		local listY = y + RobotoL18H + respc(5)

		if #thisMembers > renderData.visibleMembers then
			listWidth = listWidth - 12
		end

		local onlineMembersCount = 0

		for i = 1, renderData.visibleMembers do
			local rowY = listY + (listRowHeight * (i - 1))
			local colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			local thisMember = thisMembers[i + renderData.membersOffset]
			local isHovered = false

			if thisMember and selectedMember == i + renderData.membersOffset then
				colorOfRow = tocolor(7, 112, 196, 255 * alphaMultipler)
				isHovered = true
			elseif activeButton == "selectMember:" .. i + renderData.membersOffset and not scrollbarActive and not getKeyState("mouse1") then
				colorOfRow = tocolor(53, 53, 53, 255 * alphaMultipler)
			elseif i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			end

			dxDrawRectangle(x, rowY, listWidth, listRowHeight, colorOfRow)

			if thisMember then
				if thisMember.online then
					dxDrawRectangle(x, rowY, respc(5), listRowHeight, tocolor(50, 200, 50, 255 * alphaMultipler))
					onlineMembersCount = onlineMembersCount + 1
				else
					dxDrawRectangle(x, rowY, respc(5), listRowHeight, tocolor(200, 50, 50, 255 * alphaMultipler))
				end

				local thisIsMe = thisMember.charID == monitoredLocalDatas["char.ID"]

				if thisGroup.mainLeader == thisMember.charID then
					if isHovered then
						dxDrawText("", x + 15, rowY, 0, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.5, Themify18, "left", "center")
					else
						dxDrawText("", x + 15, rowY, 0, rowY + listRowHeight, tocolor(223, 181, 81, 255 * alphaMultipler), 0.5, Themify18, "left", "center")
					end

					dxDrawText(thisMember.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or "") .. " (Főleader)", x + 35, rowY, x + 35 + listWidth - 20, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
				elseif thisMember.isLeader == "Y" then
					if isHovered then
						dxDrawText("", x + 15, rowY, 0, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.5, metro18, "left", "center")
					else
						dxDrawText("", x + 15, rowY, 0, rowY + listRowHeight, tocolor(50, 179, 239, 255 * alphaMultipler), 0.5, metro18, "left", "center")
					end

					dxDrawText(thisMember.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or ""), x + 35, rowY, x + 35 + listWidth - 20, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
				else
					dxDrawText(thisMember.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or ""), x + 15, rowY, x + 15 + listWidth - 20, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
				end

				dxDrawText(thisRanks[thisMember.rank].name .. " (" .. thisMember.rank .. ")", x + listWidth, rowY, x + listWidth - 10, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "right", "center")

				buttons["selectMember:" .. i + renderData.membersOffset] = {x, rowY, listWidth, listRowHeight}
			end
		end

		-- ** Scrollbar
		if #thisMembers > renderData.visibleMembers then
			drawScrollbar("members", x + listWidth, listY, 12, listRowHeight * renderData.visibleMembers, renderData.visibleMembers, #thisMembers)
		end

		-- ** Kis infó
		dxDrawText("Tagok: " .. #thisMembers .. ", ebből online: " .. onlineMembersCount, x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

		-- ** Új tag hozzáadása
		y = listY + listRowHeight * renderData.visibleMembers + respc(5)

		if meInGroup[selectedGroup].isLeader == "Y" then
			drawInputWithErrorDisplay("addNewMember", "Hozzáadandó játékos névrészlet/ID-je", x, y, listWidthOrig, respc(40), {7, 112, 196}, "", "Hozzáad", false, metro18, 0.75, 0.5)

			y = y + respc(45)
		else
			y = y + respc(5)
		end

		-- ** Kijelölt tag
		if selectedMember and thisMembers[selectedMember] then
			local member = thisMembers[selectedMember]
			local thisIsMe = member.charID == monitoredLocalDatas["char.ID"]
			
			if thisGroup.mainLeader == member.charID then
				dxDrawText("", x, y, 0, y + RobotoL18H, tocolor(223, 181, 81, 255 * alphaMultipler), 0.75, Themify18, "left", "center")
				dxDrawText(member.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or "") .. " (Főleader)", x + dxGetTextWidth("", 0.75, Themify18) + respc(5), y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
			elseif member.isLeader == "Y" then
				dxDrawText("", x, y, 0, y + RobotoL18H, tocolor(50, 179, 239, 255 * alphaMultipler), 0.75, metro18, "left", "center")
				dxDrawText(member.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or ""), x + dxGetTextWidth("", 0.75, metro18) + respc(5), y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
			else
				dxDrawText("", x, y, 0, y + RobotoL18H, tocolor(200, 200, 200, 255 * alphaMultipler), 0.75, Themify18, "left", "center")
				dxDrawText(member.characterName:gsub("_", " ") .. (thisIsMe and " (Te)" or ""), x + dxGetTextWidth("", 0.75, Themify18) + respc(5), y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
			end
			dxDrawRectangle(x, y + RobotoL18H + respc(5), listWidthOrig, 1, tocolor(255, 255, 255, 255 * alphaMultipler))

			y = y + RobotoL18H + respc(10)

			-- ** Gombok
			local buttonWidth = 0

			if meInGroup[selectedGroup].isLeader == "Y" then
				buttonWidth = listWidthOrig / 2

				local buttonX = x + listWidthOrig - buttonWidth
				local buttonY = y + respc(15)
				local buttonHeight = respc(40)

				if not thisIsMe and member.charID ~= thisGroup.mainLeader then
					if member.isLeader == "Y" then
						drawButtonWithPrompt("removeLeaderFromMember", "Leader elvétele", buttonX, buttonY, buttonWidth, buttonHeight, {7, 112, 196}, "")
					else
						drawButtonWithPrompt("addLeaderToMember", "Hozzáadás a Leaderekhez", buttonX, buttonY, buttonWidth, buttonHeight, {7, 112, 196}, "", false, metro18)
					end

					buttonY = buttonY + buttonHeight + respc(5)
				end

				if (not thisIsMe and member.charID ~= thisGroup.mainLeader) or thisIsMe then
					drawButton("increaseMemberRank", "Előléptetés", buttonX, buttonY, buttonWidth, buttonHeight, {3, 153, 126}, "")
					buttonY = buttonY + buttonHeight + respc(5)

					drawButton("decreaseMemberRank", "Lefokozás", buttonX, buttonY, buttonWidth, buttonHeight, {200, 100, 50}, "")
					buttonY = buttonY + buttonHeight + respc(5)
				end

				if not thisIsMe and member.charID ~= thisGroup.mainLeader then
					drawButtonWithPrompt("removeMemberFromGroup", "Kirúgás a csoportból", buttonX, buttonY, buttonWidth, buttonHeight, {200, 50, 50}, "", false, metro18, false, 0.75)
				end
			end

			-- ** Adatok
			local dataRowHeight = respc(35)
			local x2 = x + respc(5)
			local y2 = y

			if member.lastOnline == 0 then
				onlineStatus = "#8e8e8eNem volt még online"
			else
				local time = getRealTime(member.lastOnline)
				local formattedTime = string.format("%.4i/%.2i/%.2i %.2i:%.2i:%.2i", time.year + 1900, time.month + 1, time.monthday, time.hour, time.minute, time.second)

				if getRealTime().timestamp > member.lastOnline + 604800 then
					formattedTime = formattedTime .. " #8e8e8e(Inaktív)"
				end

				onlineStatus = "#dddddd" .. formattedTime
			end

			buttonWidth = buttonWidth + respc(10)

			y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Leader: ", member.isLeader == "Y" and "#03997eIgen" or "#c83232Nem", RobotoL14, 1, x, x + listWidthOrig - buttonWidth)
			y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Online: ", member.online and "#03997eIgen" or "#c83232Nem", RobotoL14, 1, x, x + listWidthOrig - buttonWidth)
			
			if not member.online then
				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Utoljára online: ", onlineStatus, RobotoL14, 1, x, x + listWidthOrig - buttonWidth)
			end

			y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Rang: ", "#32b3ef" .. thisRanks[member.rank].name .. " (" .. member.rank .. ")", RobotoL14, 1, x, x + listWidthOrig - buttonWidth)
			y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Fizetés: ", "#32b3ef" .. thisRanks[member.rank].pay .. " #eaeaea$", gtaFont2, 0.5, x, x + listWidthOrig - buttonWidth)
			y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Szolgálati öltözék: ", member.dutySkin ~= 0 and "#ffa600" .. member.dutySkin or "#c83232Nincs beállítva", RobotoL14, 1)
		end
	end

	--> Járművek
	if selectedTab == 4 then
		y = y - marginOffset/2

		-- ** Lista
		local listWidth = sx - menuWidth - marginOffset * 2
		local listWidthOrig = listWidth
		local listRowHeight = (sy - headerHeight - marginOffset * 2 - respc(305) - RobotoL18H - respc(5)) / renderData.visibleVehicles

		local listY = y + RobotoL18H + respc(5)

		if #thisVehicles > renderData.visibleVehicles then
			listWidth = listWidth - respc(20)
		end

		local healthyVehiclesCount = 0

		local healthBarWidth = listWidth * 0.375
		local healthBarHeight = listRowHeight * 0.6

		for i = 1, renderData.visibleVehicles do
			local rowY = listY + (listRowHeight * (i - 1))
			local colorOfRow = tocolor(53, 53, 53, 50 * alphaMultipler)
			local thisVehicle = thisVehicles[i + renderData.vehiclesOffset]
			local thisSelected = false

			if thisVehicle and selectedVehicle == i + renderData.vehiclesOffset then
				colorOfRow = tocolor(7, 112, 196, 255 * alphaMultipler)
				thisSelected = true
			elseif activeButton == "selectVehicle:" .. i + renderData.vehiclesOffset and not scrollbarActive and not getKeyState("mouse1") then
				colorOfRow = tocolor(53, 53, 53, 255 * alphaMultipler)
			elseif i % 2 ~= 0 then
				colorOfRow = tocolor(53, 53, 53, 100 * alphaMultipler)
			end

			dxDrawRectangle(x, rowY, listWidth, listRowHeight, colorOfRow)

			if isElement(thisVehicle) then
				local datas = vehicleDatas[thisVehicle]

				if datas then
					local vehicleType = getVehicleType(thisVehicle)
					if vehicleType == "Train" or vehicleType == "Trailer" or vehicleType == "Monster Truck" then
						vehicleType = "Automobile"
					end

					local imageSize = listRowHeight - 2
					local offsetX = 0

					dxDrawText("#" .. datas["vehicle.dbID"], x + 10, rowY, 0, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
					offsetX = offsetX + 10 + dxGetTextWidth("#" .. datas["vehicle.dbID"], 0.75, Roboto16)

					dxDrawImage(x + offsetX + 10, rowY + (listRowHeight - imageSize) / 2, imageSize, imageSize, "files/vehicleTypes/" .. vehicleType .. ".png", 0, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler))
					offsetX = offsetX + imageSize + 20

					dxDrawText(datas.vehicleName, x + offsetX, rowY, 0, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")

					local vehicleHealth = math.floor(getElementHealth(thisVehicle) / 10)

					if vehicleHealth > 32 then
						healthyVehiclesCount = healthyVehiclesCount + 1
					elseif vehicleHealth < 32 then
						vehicleHealth = 32
					end

					vehicleHealth = math.floor(reMap(vehicleHealth, 32, 100, 0, 100))

					dxDrawText("Állapot: " .. vehicleHealth .. "%   Benzin: " .. math.floor(datas["vehicle.fuel"] or 100) .. "%", 0, rowY, x + listWidth - 10, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "right", "center")

					buttons["selectVehicle:" .. i + renderData.vehiclesOffset] = {x, rowY, listWidth, listRowHeight}
				end
			elseif thisVehicle then
				dxDrawText("Hiányzó jármű.", x + 10, rowY, x + 10 + listWidth - 20, rowY + listRowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 0.75, Roboto16, "left", "center")
				
				buttons["selectVehicle:" .. i + renderData.vehiclesOffset] = {x, rowY, listWidth, listRowHeight}
			end
		end

		-- ** Scrollbar
		if #thisVehicles > renderData.visibleVehicles then
			drawScrollbar("vehicles", x + listWidth, y, 12, listRowHeight * renderData.visibleVehicles, renderData.visibleVehicles, #thisVehicles)
		end

		-- ** Kis infó
		dxDrawText("Járművek: " .. #thisVehicles .. ", ebből használható: " .. healthyVehiclesCount, x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

		-- ** Kijelölt jármű
		y = listY + listRowHeight * renderData.visibleVehicles + respc(5)

		if selectedVehicle and thisVehicles[selectedVehicle] then
			local vehicle = thisVehicles[selectedVehicle]
			local datas = vehicleDatas[vehicle]

			if datas then
				local numberPlate = getVehiclePlateText(vehicle)
				local segments = {}
				numberPlate = split(numberPlate, "-")

				for i = 1, #numberPlate do
					if utf8.len(numberPlate[i]) > 0 then
						table.insert(segments, numberPlate[i])
					end
				end

				dxDrawText("#" .. datas["vehicle.dbID"] .. " " .. datas.vehicleName, x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")
				dxDrawText(table.concat(segments, "-"), 0, y, x + listWidthOrig, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "right", "top")
			
				dxDrawRectangle(x, y + RobotoL18H + respc(5), listWidthOrig, 1, tocolor(255, 255, 255, 255 * alphaMultipler))

				y = y + RobotoL18H + respc(10)

				-- ** Adatok
				local dataRowHeight = respc(35)
				local x2 = x + respc(5)
				local y2 = y

				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Motor: ", datas["vehicle.engine"] and "#03997eelindítva" or "#c83232leállítva", RobotoL14, 1, x, x + listWidthOrig - respc(10))
				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Lámpa: ", getVehicleOverrideLights(vehicle) == 2 and "#03997efelkapcsolva" or "#c83232lekapcsolva", RobotoL14, 1, x, x + listWidthOrig - respc(10))
				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Kézifék: ", datas["vehicle.handBrake"] and "#03997ebehúzva" or "#c83232kiengedve", RobotoL14, 1, x, x + listWidthOrig - respc(10))
				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Ajtók: ", datas["vehicle.locked"] and "#c83232zárva" or "#03997enyitva", RobotoL14, 1, x, x + listWidthOrig - respc(10))
				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Megtett mérföld: ", "#ffa600" .. math.floor(datas["vehicle.distance"] / 10) * 10 .. " mérföld", RobotoL14, 1)
				
				local kilometersToChangeOil = 500 - math.floor(math.floor(datas["lastOilChange"] or 0) / 1000)
				if kilometersToChangeOil <= 0 then
					kilometersToChangeOil = "Olajcsere szükséges"
				else
					kilometersToChangeOil = thousandsStepper(kilometersToChangeOil, " ") .. " mérföld múlva"
				end

				y2 = drawDataRow(x2, y2, dataRowHeight, 1, "Következő olajcsere: ", "#ffa600" .. kilometersToChangeOil, RobotoL14, 1)
			end
		end
	end

	--> Egyéb
	if selectedTab == 5 then
		local listWidth = sx - menuWidth - marginOffset * 2

		y = y - marginOffset/2

		dxDrawText("Megjegyzés:", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

		y = y + RobotoL18H + respc(5)

		dxDrawRectangle(x, y, listWidth, 1, tocolor(255, 255, 255, 255 * alphaMultipler))

		y = y + respc(5)

		-- ** Megjegyzés
		local descHeight = respc(100)

		if meInGroup[selectedGroup].isLeader == "Y" then
			if not fakeInputs["groupDesc"] then
				fakeInputs["groupDesc"] = thisGroup.description
			end

			dxDrawRectangle(x, y, listWidth, descHeight, tocolor(50, 50, 50, 100 * alphaMultipler))
			buttons["groupDesc" .. ":input"] = {x, y, listWidth, descHeight}

			if activeFakeInput == "groupDesc" then
				if cursorState then
					dxDrawText(fakeInputs["groupDesc"] .. "|", x + 10, y + 10, x + 10 + listWidth - 20, 0, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "top", false, true)
				else
					dxDrawText(fakeInputs["groupDesc"], x + 10, y + 10, x + 10 + listWidth - 20, 0, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "top", false, true)
				end

				if getTickCount() - lastChangeCursorState >= 500 then
					cursorState = not cursorState
					lastChangeCursorState = getTickCount()
				end
			else
				dxDrawText(fakeInputs["groupDesc"], x + 10, y + 10, x + 10 + listWidth - 20, 0, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "top", false, true)
			end

			drawButtonWithPrompt("groupDesc", "Mentés", x, y + descHeight, listWidth, respc(35), {7, 112, 196})

			y = y + descHeight + respc(35) + respc(20)
		else
			dxDrawText(thisGroup.description, x, y, x + listWidth, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "top", false, true)
			
			y = y + descHeight + respc(20)
		end

		local rowHeight = respc(35)

		-- ** Egyenleg @ kezelés
		if meInGroup[selectedGroup].isLeader == "Y" then
			dxDrawText("Egyenleg kezelés", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

			y = y + RobotoL18H + respc(5)

			dxDrawRectangle(x, y, listWidth, 1, tocolor(255, 255, 255, 255 * alphaMultipler))

			y = y + respc(5)
			drawDataRow(x, y, rowHeight, 1, "Egyenleg: ", "#32b3ef" .. thousandsStepper(thisGroup.balance, ",") .. " #eaeaea$", gtaFont2, 0.5)

			local acceptWidth = respc(125)
			local inputWidth = respc(450)
			local inputX = x + listWidth - acceptWidth*2 - inputWidth - respc(5)
			local getOutX = inputX + inputWidth
			local putBackX = getOutX + acceptWidth + respc(5)

			if renderData.payManagingInProcess then
				dxDrawText("Feldolgozás...", inputX, y, putBackX + acceptWidth, y + rowHeight, tocolor(215, 89, 89, 255 * alphaMultipler), 1, Roboto14, "center", "center")
			elseif errorToDisplay == "groupBalance" and string.len(errorText) > 0 then
				dxDrawText(errorText, inputX + 10, y, inputX + 10 + inputWidth - 20, y + rowHeight, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", false, false, false, true)

				drawButton("errorOk", "OK", getOutX, y, acceptWidth*2 + respc(5), rowHeight, {7, 112, 196})
			else
				if not fakeInputs["groupBalance"] then
					fakeInputs["groupBalance"] = ""
				end

				dxDrawRectangle(inputX, y, inputWidth, rowHeight, tocolor(50, 50, 50, 100 * alphaMultipler))
				buttons["groupBalance" .. ":input"] = {inputX, y, inputWidth, rowHeight}

				if utf8.len(fakeInputs["groupBalance"]) > 0 then
					dxDrawText(fakeInputs["groupBalance"], inputX + 10, y, inputX + 10 + inputWidth - 20, y + rowHeight, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true)
				else
					dxDrawText("Összeg", inputX + 10, y, inputX + 10 + inputWidth - 20, y + rowHeight, tocolor(100, 100, 100, 200 * alphaMultipler), 1, Roboto14, "left", "center", true)
				end

				if activeFakeInput == "groupBalance" then
					if cursorState then
						local w = dxGetTextWidth(fakeInputs["groupBalance"], 1, Roboto14)
						dxDrawLine(inputX + 10 + w, y + respc(5), inputX + 10 + w, y + rowHeight - respc(5), tocolor(230, 230, 230, 255 * alphaMultipler))
					end

					if getTickCount() - lastChangeCursorState >= 500 then
						cursorState = not cursorState
						lastChangeCursorState = getTickCount()
					end
				end

				drawButton("groupBalance:putBack", "+ Berakás", putBackX, y, acceptWidth, rowHeight, {7, 112, 196})
				drawButton("groupBalance:getOut", "- Kivétel", getOutX, y, acceptWidth, rowHeight, {7, 112, 196})
			end

			y = y + rowHeight + respc(5)
		end

		-- ** Leader beállítások
		dxDrawText("Beállítások", x, y, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler), 1, RobotoL18, "left", "top")

		y = y + RobotoL18H + respc(5)

		dxDrawRectangle(x, y, listWidth, 1, tocolor(255, 255, 255, 255 * alphaMultipler))

		local rowHeight = respc(35)

		y = y + respc(5)

		if standingColShape then
			dxDrawText("> Szolgálati öltözék", x, y, 0, y + rowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "center")
			drawButton("setDutySkin", "Módosítás", x + listWidth - respc(150), y, respc(150), rowHeight, {7, 112, 196})

			y = y + rowHeight + respc(5)
		end

		if meInGroup[selectedGroup].isLeader == "Y" then
			--dxDrawText("> Különleges egység szolgálat", x, y, 0, y + rowHeight, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "center")
			--drawButtonSlider("swatDutyMode", thisGroup.swatDutyMode, x + listWidth - 64, y, rowHeight, {50, 50, 50, 255}, {7, 112, 196, 255})
		end
	end

	--> Leader beállítások (Egyelőre nincs értelme)
	--if selectedTab == 6 then
	--
	--end
end

function drawGroupSelector(isAdminMode)
	local headerHeight = respc(35)

	sx = respc(600)
	sy = headerHeight * (renderData.visibleGroups + 3)

	x = (screenX - sx) / 2
	y = (screenY - sy) / 2

	dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240 * alphaAnim[3]))

	local logoSize = headerHeight * 0.85
	local closeSize = respc(24)
	local marginOffset = (headerHeight - logoSize) / 2

	dxDrawImage(math.ceil(x + marginOffset), math.ceil(y + marginOffset), logoSize, logoSize, "files/headerLogo.png", 0, 0, 0, tocolor(50, 179, 239, 255 * alphaAnim[3]))

	if isAdminMode then
		dxDrawText("Frakciók kezelése", x + headerHeight + marginOffset, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL18, "left", "center")
	else
		dxDrawText("Frakciók", x + headerHeight + marginOffset, y, 0, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL18, "left", "center")
	end

	local closeColor
	if activeButton == "closePanel" then
		closeColor = {processColorSwitchEffect("closePanel", {215, 89, 89, 255})}
	else
		closeColor = {processColorSwitchEffect("closePanel", {255, 255, 255, 255})}
	end
	marginOffset = (headerHeight - closeSize) / 2
	dxDrawImage(x + sx - closeSize - marginOffset, y + marginOffset, closeSize, closeSize, ":sarp_assets/images/cross_x.png", 0, 0, 0, tocolor(closeColor[1], closeColor[2], closeColor[3], closeColor[4] * alphaAnim[3]))
	buttons["closePanel"] = {x + sx - closeSize - marginOffset, y, closeSize, closeSize}

	-- ** Lista
	local columnWidth = sx / 2

	if isAdminMode then
		if availableGroupsCount+1 > renderData.visibleGroups then
			columnWidth = (sx - 12) / 2
		end
	elseif playerGroupsCount > renderData.visibleGroups then
		columnWidth = (sx - 12) / 2
	end

	y = y + headerHeight

	dxDrawText("Név", x + 5, y, x + 5 + columnWidth - 10, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto16, "left", "center", true)
	dxDrawText("Típus", x + columnWidth, y, x + columnWidth * 2 - 5, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, Roboto16, "right", "center", true)

	y = y + headerHeight

	if isAdminMode then
		if not renderData.lastGroupsCountForAdmin or renderData.lastGroupsCountForAdmin ~= availableGroupsCount then
			renderData.lastGroupsCountForAdmin = availableGroupsCount
			renderData.adminGroupList = {}

			table.insert(renderData.adminGroupList, {name = "+ Új frakció létrehozása", groupID = "new"})

			for k,v in pairs(availableGroups) do
				table.insert(renderData.adminGroupList, v)
			end
		end
	end

	for i = 1, renderData.visibleGroups do
		local thisGroup

		if isAdminMode then
			thisGroup = renderData.adminGroupList[i + renderData.groupsOffset]
		else
			thisGroup = loopPlayerGroups[i + renderData.groupsOffset]

			if thisGroup and availableGroups[thisGroup] then
				thisGroup = availableGroups[thisGroup]
			else
				thisGroup = false
			end
		end

		local itemY = y + (headerHeight * (i - 1))
		local colorOfRow = tocolor(53, 53, 53, 50 * alphaAnim[3])

		if thisGroup and selectedGroup == thisGroup.groupID then
			colorOfRow = tocolor(7, 112, 196, 255 * alphaAnim[3])
		elseif thisGroup and activeButton == "selectGroup:" .. thisGroup.groupID and not scrollbarActive and not getKeyState("mouse1") then
			colorOfRow = tocolor(53, 53, 53, 255 * alphaAnim[3])
		elseif i % 2 ~= 0 then
			colorOfRow = tocolor(53, 53, 53, 100 * alphaAnim[3])
		end

		dxDrawRectangle(x, itemY, columnWidth * 2, headerHeight, colorOfRow)

		if thisGroup then
			if thisGroup.mainLeader == 0 then
				dxDrawText("#" .. thisGroup.groupID .. "   " .. thisGroup.name .. " (Nincs főleader)", x + 10, itemY, x + 10 + columnWidth - 20, itemY + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 0.75, Roboto16, "left", "center", true)
			else
				if thisGroup.groupID ~= "new" then
					dxDrawText("#" .. thisGroup.groupID .. "   " .. thisGroup.name, x + 10, itemY, x + 10 + columnWidth - 20, itemY + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 0.75, Roboto16, "left", "center", true)
				else
					dxDrawText(thisGroup.name, x + 10, itemY, x + 10 + columnWidth - 20, itemY + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 0.75, Roboto16, "left", "center", true)
				end
			end

			if thisGroup.type then
				dxDrawText(groupTypes[thisGroup.type] or "Egyéb", x + columnWidth, itemY, x + columnWidth * 2 - 10, itemY + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 0.75, Roboto16, "right", "center", true)
			end

			buttons["selectGroup:" .. thisGroup.groupID] = {x, itemY, columnWidth * 2, headerHeight}
		end
	end

	-- ** Scrollbar
	if isAdminMode then
		if availableGroupsCount > renderData.visibleGroups then
			drawScrollbar("groups", x + sx - 12, y, 12, headerHeight * renderData.visibleGroups, renderData.visibleGroups, availableGroups)
		end
	elseif playerGroupsCount > renderData.visibleGroups then
		drawScrollbar("groups", x + sx - 12, y, 12, headerHeight * renderData.visibleGroups, renderData.visibleGroups, playerGroupsCount)
	end

	-- ** Tovább gomb
	y = y + headerHeight * renderData.visibleGroups

	local buttonColor
	if activeButton == "selectGroup:next" then
		buttonColor = {processColorSwitchEffect("selectGroup:next", {7, 112, 196, 175})}
	else
		buttonColor = {processColorSwitchEffect("selectGroup:next", {7, 112, 196, 125})}
	end
	dxDrawRectangle(x, y, sx, headerHeight, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], buttonColor[4] * alphaAnim[3]))
	dxDrawText("Tovább", x, y, x + sx, y + headerHeight, tocolor(255, 255, 255, 255 * alphaAnim[3]), 1, RobotoL16, "center", "center")
	buttons["selectGroup:next"] = {x, y, sx, headerHeight}
end

function onClientClick(button, state)
	if button == "left" and state == "down" then
		local lastActiveFakeInput = activeFakeInput
		activeFakeInput = false

		if activeButton then
			local selected = split(activeButton, ":")

			if selected[1] == "selectDropdownItem" then
				renderData.dropDowns[selected[2]] = tonumber(selected[3])
				renderData.activeDropDown = false
				playSound(":sarp_assets/audio/interface/10.ogg")
			else
				renderData.activeDropDown = false
			end

			if selected[1] == "setDutySkin" then
				toggleDutySkinSelect(true, selectedGroup)
				togglePanel(false)
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "deleteGroup_promptOk" then
				triggerServerEvent("deleteGroup", localPlayer, selectedGroup)
				togglePanel(false)
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "deleteGroup" then
				showError("deleteGroup", "#d75959Biztos, hogy törlöd ezt a frakciót?", ":sarp_assets/audio/admin/error.ogg")
			elseif selected[1] == "selectDutyItem" then
				renderData.selectedDutyItem = tonumber(selected[2])

				fakeInputs["setItemAmount"] = tostring(renderData.dutyItems[renderData.selectedDutyItem][3])
				fakeInputs["setItemData1"] = tostring(renderData.dutyItems[renderData.selectedDutyItem][4])

				playSound(":sarp_assets/audio/interface/10.ogg")
			elseif selected[1] == "acceptItemSettings" and renderData.selectedDutyItem then
				local selectedDutyItem = renderData.selectedDutyItem

				if tonumber(fakeInputs["setItemAmount"]) then
					renderData.dutyItems[selectedDutyItem][3] = tonumber(fakeInputs["setItemAmount"])
				end

				renderData.dutyItems[selectedDutyItem][4] = fakeInputs["setItemData1"]

				showError("acceptItemSettings", "#7cc576Item adatok sikeresen megváltoztatva.", ":sarp_assets/audio/admin/notify.ogg")

				fakeInputs["setItemAmount"] = ""
				fakeInputs["setItemData1"] = ""
			elseif selected[1] == "removeDutyItem" then
				table.remove(renderData.dutyItems, tonumber(selected[2]))

				if #renderData.dutyItems == 0 then
					renderData.selectedDutyItem = false
				else
					renderData.selectedDutyItem = #renderData.dutyItems
				end

				if renderData.selectedDutyItem > 10 then
					renderData.ranksOffset = #renderData.dutyItems - 10
				else
					renderData.ranksOffset = 0
				end

				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "addItem" then
				local itemRowID = tonumber(selected[2])
				local itemID = renderData.availableItemsEx[itemRowID]

				table.insert(renderData.dutyItems, {
					itemID,
					exports.sarp_inventory:getItemName(itemID),
					1,
					""
				})

				renderData.selectedDutyItem = #renderData.dutyItems

				if renderData.selectedDutyItem > 10 then
					renderData.ranksOffset = #renderData.dutyItems - 10
				else
					renderData.ranksOffset = 0
				end

				fakeInputs["setItemAmount"] = tostring(renderData.dutyItems[renderData.selectedDutyItem][3])
				fakeInputs["setItemData1"] = tostring(renderData.dutyItems[renderData.selectedDutyItem][4])
			elseif selected[1] == "togDutyPermission" then
				local permissionID = tonumber(selected[2])
				local thisPermission = availablePermissionsEx[permissionID]

				if renderData.dutyPermissions[thisPermission] then
					renderData.dutyPermissions[thisPermission] = nil
				else
					renderData.dutyPermissions[thisPermission] = true
				end
			elseif selected[1] == "removeDutyPos" then
				table.remove(renderData.dutyPoses, tonumber(selected[2]))
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "removeDutySkin" then
				table.remove(renderData.dutySkins, tonumber(selected[2]))
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "addDutyPos" then
				if #renderData.dutyPoses < 8 then
					local localX, localY, localZ = getElementPosition(localPlayer)

					table.insert(renderData.dutyPoses, {localX, localY, localZ, getElementInterior(localPlayer), getElementDimension(localPlayer)})

					playSound(":sarp_assets/audio/admin/notify.ogg")
				else
					exports.sarp_hud:showInfobox("error", "Elérted a maximális duty pozíció számát!")
				end
			elseif selected[1] == "addDutySkin" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				else
					local skinID = tonumber(fakeInputs["addDutySkin"]) or -1

					if skinID < 0 or skinID > 312 then
						exports.sarp_hud:showInfobox("error", "Érvénytelen skin ID! Minimum 0 és maximum 312 lehet.")
					else
						fakeInputs["addDutySkin"] = ""
						table.insert(renderData.dutySkins, skinID)
						playSound(":sarp_assets/audio/admin/notify.ogg")
					end
				end
			elseif selected[1] == "groupName" or selected[1] == "groupMainLeader" or selected[1] == "groupPrefix" or selected[1] == "dutyArmor" or selected[1] == "searchItem" or selected[1] == "setItemAmount" or selected[1] == "setItemData1" or selected[1] == "groupTuneRadio" then
				activeFakeInput = selected[1]
			elseif selected[1] == "dropdownToggle" then
				renderData.activeDropDown = selected[2]
				playSound(":sarp_assets/audio/interface/10.ogg")
			elseif selected[1] == "selectTab" then
				local tabID = tonumber(selected[2])

				if panelState == "createGroup" or panelState == "editGroup" then
					if selectedAdminTab ~= tabID and adminTabAfterInterpolation ~= tabID then
						hideError()

						if tabID == #groupCreatorMenu then
							if renderData.editGroup then
								processGroupCreation("edit")
							else
								processGroupCreation()
							end
						else
							adminTabAfterInterpolation = tabID
							tabSwitchEndInterpolation[selectedAdminTab] = getTickCount()

							playSound(":sarp_assets/audio/interface/10.ogg")
						end
					end
				else
					if selectedTab ~= tabID and tabAfterInterpolation ~= tabID then
						hideError()

						tabAfterInterpolation = tabID
						tabSwitchEndInterpolation[selectedTab] = getTickCount()

						playSound(":sarp_assets/audio/interface/10.ogg")
					end
				end
			elseif selected[1] == "scrollbarGrip" then
				local key = selected[2]

				renderData.draggingGrips[key] = cursorY - renderData.gripPoses[key]
			elseif selected[1] == "selectGroup" then
				if selected[2] == "next" and selectedGroup then
					if panelState == "selectGroup:admin" then
						if selectedGroup == "new" then
							setGroupCreationValues(nil)
							renderData.editGroup = false
							togglePanel("createGroup")
						else
							setGroupCreationValues(availableGroups[selectedGroup])
							togglePanel("createGroup")
							renderData.editGroup = true
						end
					else
						togglePanel("groupPanel")
					end
				else
					local groupID = tonumber(selected[2]) or "new"

					if groupID ~= selectedGroup then
						selectedGroup = groupID
						playSound(":sarp_assets/audio/interface/10.ogg")
					end
				end
			elseif selected[1] == "selectRank" then
				local rankID = tonumber(selected[2])

				if availableGroups[selectedGroup].ranks[rankID] and rankID ~= selectedRank then
					hideError()
					selectedRank = rankID
					playSound(":sarp_assets/audio/interface/10.ogg")
				end
			elseif selected[1] == "addNewMember" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				else
					errorToDisplay = selected[1]

					local inputText = fakeInputs["addNewMember"]

					if string.len(inputText) < 1 then
						errorText = "#d75959Nem hagyhatod üresen a mezőt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					else
						local found = false
						local multipleFounds = false
						local inputText = string.lower(string.gsub(inputText, " ", "_"))

						local players = getElementsByType("player")
						for i = 1, #players do
							local player = players[i]

							if isElement(player) and getElementData(player, "loggedIn") then
								local id = getElementData(player, "playerID")
								local name = string.lower(getElementData(player, "visibleName"):gsub(" ", "_"))

								if id == tonumber(inputText) or string.find(name, inputText) then
									if found then
										found = false
										multipleFounds = true
										break
									else
										found = player
									end
								end
							end
						end

						if multipleFounds then
							errorText = "#d75959Több találat!"
							playSound(":sarp_assets/audio/admin/error.ogg")
						elseif isElement(found) then
							local name = getElementData(found, "visibleName")
							local charID = getElementData(found, "char.ID")
							local memberFound = false

							for i = 1, #groupMembers[selectedGroup] do
								if groupMembers[selectedGroup][i].charID == charID then
									memberFound = true
									break
								end
							end

							if memberFound then
								errorText = "#d75959" .. name:gsub("_", " ") .. " már a csoport tagja!"
								playSound(":sarp_assets/audio/admin/error.ogg")
							else
								errorText = "#7cc576" .. name:gsub("_", " ") .. " sikeresen felvéve!"
								triggerServerEvent("invitePlayerToGroup", localPlayer, selectedGroup, playerGroups, getElementData(found, "char.ID"), found)
								playSound(":sarp_assets/audio/admin/notify.ogg")
							end
						else
							errorText = "#d75959Nincs találat!"
							playSound(":sarp_assets/audio/admin/error.ogg")
						end
					end

					fakeInputs["addNewMember"] = ""
				end
			elseif selected[1] == "selectMember" then
				local memberID = tonumber(selected[2])

				if memberID ~= selectedMember then
					hideError()
					selectedMember = memberID
					playSound(":sarp_assets/audio/interface/10.ogg")
				end
			elseif selected[1] == "selectVehicle" then
				local vehicleID = tonumber(selected[2])

				if vehicleID ~= selectedVehicle then
					hideError()
					selectedVehicle = vehicleID
					playSound(":sarp_assets/audio/interface/10.ogg")
				end
			elseif selected[1] == "rankRename" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				else
					errorToDisplay = 0

					if utf8.len(fakeInputs["rankRename"]) < 1 then
						errorText = "#d75959Nem hagyhatod üresen a mezőt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif fakeInputs["rankRename"] == availableGroups[selectedGroup].ranks[rankID] then
						errorText = "#d75959Nem lehet ugyan az a név mint volt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					else
						errorText = "#7cc576Rang sikeresen átnevezve!"
						triggerServerEvent("renameGroupRank", localPlayer, selectedGroup, selectedRank, fakeInputs["rankRename"])
						playSound(":sarp_assets/audio/admin/notify.ogg")
					end

					fakeInputs["rankRename"] = ""
				end
			elseif selected[1] == "rankPayManaging" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				else
					errorToDisplay = 1

					local inputValue = fakeInputs["rankPayManaging"]

					if utf8.len(inputValue) < 1 then
						errorText = "#d75959Nem hagyhatod üresen a mezőt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif not tonumber(inputValue) or (tonumber(inputValue) and string.find(inputValue, "e")) then
						errorText = "#d75959Ez nem szám!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif tonumber(inputValue) < 0 then
						errorText = "#d75959Csak pozítiv egész számokat adhatsz meg!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif tonumber(inputValue) > 10000000 then
						errorText = "#d75959Maximum " .. thousandsStepper(10000000, ",") .. "!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif inputValue == availableGroups[selectedGroup].ranks[rankID] then
						errorText = "#d75959Nem lehet ugyan az a fizetés mint volt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					else
						errorText = "#7cc576Rang fizetése sikeresen módosítva!"
						triggerServerEvent("setGroupRankPayment", localPlayer, selectedGroup, selectedRank, math.floor(tonumber(inputValue)))
						playSound(":sarp_assets/audio/admin/notify.ogg")
					end

					fakeInputs["rankPayManaging"] = ""
				end
			elseif selected[1] == "rankRemove" and not errorToDisplay then
				showError(2, "Biztos, hogy törlöd a rangot?", ":sarp_assets/audio/admin/error.ogg")
			elseif selected[1] == "errorOk" then
				hideError()
			elseif selected[1] == "rankRemove_promptAccept" then
				triggerServerEvent("removeGroupRank", localPlayer, selectedGroup, selectedRank, playerGroups)
				hideError()
				playSound(":sarp_assets/audio/admin/inmsg.ogg")
			elseif selected[1] == "promptDecline" then
				hideError()
				playSound(":sarp_assets/audio/admin/outmsg.ogg")
			elseif selected[1] == "newRank" and selectedGroup and #availableGroups[selectedGroup].ranks <= maxGroupRank then
				if getTickCount() - lastNewRankTime >= 1000 then
					triggerServerEvent("addNewGroupRank", localPlayer, selectedGroup)

					playSound(":sarp_assets/audio/admin/notify.ogg")
					lastNewRankTime = getTickCount()
				else
					exports.sarp_hud:showInfobox("error", "Ne ilyen gyorsan!")
				end
			elseif selected[1] == "addLeaderToMember" and not errorToDisplay then
				showError(selected[1], "Biztos, hogy hozzáadod a Leaderekhez?", ":sarp_assets/audio/admin/error.ogg")
			elseif selected[1] == "removeLeaderFromMember" and not errorToDisplay then
				showError(selected[1], "Biztos, hogy eltávolítod a Leaderek közül?", ":sarp_assets/audio/admin/error.ogg")
			elseif selected[1] == "addLeaderToMember_promptAccept" and selectedMember and groupMembers[selectedGroup][selectedMember] then
				if getTickCount() - lastSetLeaderTick >= 2000 then
					local thisMember = groupMembers[selectedGroup][selectedMember]

					triggerServerEvent("setGroupMemberLeader", localPlayer, selectedGroup, playerGroups, "Y", thisMember.charID, thisMember.online)

					playSound(":sarp_assets/audio/admin/notify.ogg")
					lastSetLeaderTick = getTickCount()
				else
					exports.sarp_hud:showInfobox("error", "Maximum 2 másodpercenként módosíthatod!")
				end

				hideError()
			elseif selected[1] == "removeLeaderFromMember_promptAccept" and selectedMember and groupMembers[selectedGroup][selectedMember] then
				if getTickCount() - lastSetLeaderTick >= 2000 then
					local thisMember = groupMembers[selectedGroup][selectedMember]

					triggerServerEvent("setGroupMemberLeader", localPlayer, selectedGroup, playerGroups, "N", thisMember.charID, thisMember.online)

					playSound(":sarp_assets/audio/admin/notify.ogg")
					lastSetLeaderTick = getTickCount()
				else
					exports.sarp_hud:showInfobox("error", "Maximum 2 másodpercenként módosíthatod!")
				end

				hideError()
			elseif selected[1] == "increaseMemberRank" and selectedMember and groupMembers[selectedGroup][selectedMember] then
				if getTickCount() - lastModifyMemberRankTick >= 1000 then
					local thisMember = groupMembers[selectedGroup][selectedMember]

					triggerServerEvent("modifyGroupMemberRank", localPlayer, selectedGroup, playerGroups, "up", thisMember.charID, thisMember.online, thisMember.rank)

					playSound(":sarp_assets/audio/admin/notify.ogg")
					lastModifyMemberRankTick = getTickCount()
				else
					exports.sarp_hud:showInfobox("error", "Ne ilyen gyorsan!")
				end
			elseif selected[1] == "decreaseMemberRank" and selectedMember and groupMembers[selectedGroup][selectedMember] then
				if getTickCount() - lastModifyMemberRankTick >= 1000 then
					local thisMember = groupMembers[selectedGroup][selectedMember]

					triggerServerEvent("modifyGroupMemberRank", localPlayer, selectedGroup, playerGroups, "down", thisMember.charID, thisMember.online, thisMember.rank)

					playSound(":sarp_assets/audio/admin/notify.ogg")
					lastModifyMemberRankTick = getTickCount()
				else
					exports.sarp_hud:showInfobox("error", "Ne ilyen gyorsan!")
				end
			elseif selected[1] == "removeMemberFromGroup" and not errorToDisplay then
				showError(selected[1], "Biztos, hogy eltávolítod a csoportból?", ":sarp_assets/audio/admin/error.ogg")
			elseif selected[1] == "removeMemberFromGroup_promptAccept" and selectedMember and groupMembers[selectedGroup][selectedMember] then
				local thisMember = groupMembers[selectedGroup][selectedMember]

				triggerServerEvent("removePlayerFromGroup", localPlayer, selectedGroup, playerGroups, thisMember.charID, thisMember.online)

				hideError()
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "groupDesc" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				else
					showError(selected[1], "Biztos, hogy felülírod a jelenlegi megjegyzést?", ":sarp_assets/audio/admin/error.ogg")
				end
			elseif selected[1] == "groupDesc_promptAccept" then
				availableGroups[selectedGroup].description = fakeInputs["groupDesc"]

				if availableGroups[selectedGroup].description ~= fakeInputs["groupDesc"] then
					triggerServerEvent("rewriteGroupDescription", localPlayer, selectedGroup, fakeInputs["groupDesc"])
				end

				hideError()
				playSound(":sarp_assets/audio/admin/notify.ogg")
			elseif selected[1] == "groupBalance" then
				if selected[2] == "input" then
					activeFakeInput = selected[1]
				elseif selected[2] == "putBack" or selected[2] == "getOut" then
					local inputValue = fakeInputs["groupBalance"]

					errorToDisplay = selected[1]
					renderData.payManagingInProcess = false

					if utf8.len(inputValue) < 1 then
						errorText = "#d75959Nem hagyhatod üresen a mezőt!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif not tonumber(inputValue) or (tonumber(inputValue) and string.find(inputValue, "e")) then
						errorText = "#d75959Ez nem szám!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					elseif tonumber(inputValue) < 1000 then
						errorText = "#d75959Minimum " .. thousandsStepper(1000, ",") .. "$-t kezelhetsz!"
						playSound(":sarp_assets/audio/admin/error.ogg")
					else
						inputValue = math.floor(tonumber(inputValue))

						if selected[2] == "getOut" then
							inputValue = -inputValue
						end

						renderData.payManagingInProcess = true
						errorText = "#7cc576Feldolgozás..."
						
						triggerServerEvent("setGroupBalance", localPlayer, selectedGroup, inputValue)

						playSound(":sarp_assets/audio/admin/notify.ogg")
					end
				end
			elseif selected[1] == "swatDutyMode" then
				availableGroups[selectedGroup].swatDutyMode = not availableGroups[selectedGroup].swatDutyMode
			elseif activeButton == "closePanel" then
				togglePanel(false)
			end
		else
			renderData.activeDropDown = false
		end
	elseif button == "left" and state == "up" then
		renderData.draggingGrips = {}
	end
end

local repeatTimer
local repeatStartTimer

function onClientKey(key, press)
	if press then
		cancelEvent()

		if panelState == "selectGroup" then
			if key == "mouse_wheel_down" and renderData.groupsOffset < playerGroupsCount - renderData.visibleGroups then
				renderData.groupsOffset = renderData.groupsOffset + 1
			elseif key == "mouse_wheel_up" and renderData.groupsOffset > 0 then
				renderData.groupsOffset = renderData.groupsOffset - 1
			end
		elseif panelState == "groupPanel" then
			if selectedTab == 2 then
				if key == "mouse_wheel_down" and renderData.ranksOffset < #availableGroups[selectedGroup].ranks - renderData.visibleRanks then
					renderData.ranksOffset = renderData.ranksOffset + 1
				elseif key == "mouse_wheel_up" and renderData.ranksOffset > 0 then
					renderData.ranksOffset = renderData.ranksOffset - 1
				end
			elseif selectedTab == 3 then
				if key == "mouse_wheel_down" and renderData.membersOffset < #groupMembers[selectedGroup] - renderData.visibleMembers then
					renderData.membersOffset = renderData.membersOffset + 1
				elseif key == "mouse_wheel_up" and renderData.membersOffset > 0 then
					renderData.membersOffset = renderData.membersOffset - 1
				end
			elseif selectedTab == 4 then
				if key == "mouse_wheel_down" and renderData.vehiclesOffset < #groupVehicles[selectedGroup] - renderData.visibleVehicles then
					renderData.vehiclesOffset = renderData.vehiclesOffset + 1
				elseif key == "mouse_wheel_up" and renderData.vehiclesOffset > 0 then
					renderData.vehiclesOffset = renderData.vehiclesOffset - 1
				end
			end
		elseif panelState == "createGroup" or panelState == "editGroup" then
			if selectedAdminTab == 1 then
				if key == "mouse_wheel_down" and renderData.permissionsOffset < #availablePermissionsEx - 8 then
					renderData.permissionsOffset = renderData.permissionsOffset + 1
				elseif key == "mouse_wheel_up" and renderData.permissionsOffset > 0 then
					renderData.permissionsOffset = renderData.permissionsOffset - 1
				end
			elseif selectedAdminTab == 2 then
				if renderData.cursorInAvailableItemsList then
					if key == "mouse_wheel_down" and renderData.availableItemsOffset < #renderData.availableItemsEx - 10 then
						renderData.availableItemsOffset = renderData.availableItemsOffset + 1
					elseif key == "mouse_wheel_up" and renderData.availableItemsOffset > 0 then
						renderData.availableItemsOffset = renderData.availableItemsOffset - 1
					end
				elseif renderData.cursorInDutyItemsList then
					if key == "mouse_wheel_down" and renderData.dutyItemsOffset < #renderData.dutyItems - 10 then
						renderData.dutyItemsOffset = renderData.dutyItemsOffset + 1
					elseif key == "mouse_wheel_up" and renderData.dutyItemsOffset > 0 then
						renderData.dutyItemsOffset = renderData.dutyItemsOffset - 1
					end
				end
			end
		end

		if key == "backspace" and activeFakeInput then
			removeCharacterFromFakeInput(activeFakeInput)

			if getKeyState(key) then
				repeatStartTimer = setTimer(removeCharacterFromFakeInput, 500, 1, activeFakeInput, true)
			end
		end
	else
		if isTimer(repeatStartTimer) then
			killTimer(repeatStartTimer)
		end

		if isTimer(repeatTimer) then
			killTimer(repeatTimer)
		end
	end
end

function removeCharacterFromFakeInput(input, repeatTheTimer)
	if utf8.len(fakeInputs[input]) >= 1 then
		fakeInputs[input] = utf8.sub(fakeInputs[input], 1, -2)

		if input == "searchItem" then
			searchItems()
		end
	end

	if repeatTheTimer then
		repeatTimer = setTimer(removeCharacterFromFakeInput, 50, 1, activeFakeInput, repeatTheTimer)
	end
end

function onClientCharacter(character)
	if activeFakeInput then
		local maxCharacter = 25
		local onlyNumbers = false

		if activeFakeInput == "rankRename" or activeFakeInput == "groupName" then
			maxCharacter = maxCharacter * 2
		elseif activeFakeInput == "rankPayManaging" or activeFakeInput == "groupBalance" or activeFakeInput == "groupMainLeader" or activeFakeInput == "addDutySkin" or activeFakeInput == "dutyArmor" or activeFakeInput == "setItemAmount" or activeFakeInput == "groupTuneRadio" then
			onlyNumbers = true
		elseif activeFakeInput == "groupDesc" then
			maxCharacter = 255

			if not (string.find(character, "[a-zA-Z0-9öüóőúéáűíöÖÜÓŐÚÁŰÉ.,-?!]") or character == " ") then
				return
			end
		end

		if utf8.len(fakeInputs[activeFakeInput]) <= maxCharacter and ((onlyNumbers and tonumber(character)) or not onlyNumbers) then
			fakeInputs[activeFakeInput] = fakeInputs[activeFakeInput] .. character

			if activeFakeInput == "searchItem" then
				searchItems()
			end
		end
	end
end

function searchItems()
	renderData.availableItemsEx = {}

	local searchValue = fakeInputs["searchItem"]
	
	if utf8.len(searchValue) < 1 then
		for i = 1, #renderData.availableItems do
			table.insert(renderData.availableItemsEx, i)
		end
	elseif tonumber(searchValue) then
		searchValue = tonumber(searchValue)

		if renderData.availableItems[searchValue] then
			table.insert(renderData.availableItemsEx, searchValue)
		end
	else
		for i = 1, #renderData.availableItems do
			if utf8.find(utf8.lower(renderData.availableItems[i][1]), utf8.lower(searchValue)) then
				table.insert(renderData.availableItemsEx, i)
			end
		end
	end
	
	renderData.availableItemsOffset = 0
end

function showTooltip(x, y, text, text2)
	text = tostring(text)

	if text2 then
		text2 = tostring(text2)
	end

	if text == text2 then
		text2 = nil
	end

	local w = dxGetTextWidth(text, 1, Roboto11, true) + 10
	local h = 3

	if text2 then
		w = math.max(w, dxGetTextWidth(text2, 1, Roboto11, true) + 10)
		_, h = utf8.gsub(text2, "\n", "")
		h = h + 5
		text = text .. "\n#ffffff" .. text2
	end

	h = 10 * h

	dxDrawRectangle(x - 1, y - 1, w + 2, h + 2, tocolor(50, 50, 50, 240 * alphaMultipler))
	dxDrawRectangle(x, y, w, h, tocolor(28, 28, 28, 240 * alphaMultipler))
	dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto11, "center", "center", false, false, false, true)
end

addEvent("modifyGroupData", true)
addEventHandler("modifyGroupData", getRootElement(),
	function (groupId, dataType, rankId, data, managedBy)
		if availableGroups[groupId] then
			if dataType == "rankName" then
				if availableGroups[groupId].ranks[rankId] then
					availableGroups[groupId].ranks[rankId].name = data
				end
			elseif dataType == "rankPayment" then
				if availableGroups[groupId].ranks[rankId] then
					availableGroups[groupId].ranks[rankId].pay = tonumber(data)
				end
			elseif dataType == "rank" then
				availableGroups[groupId].ranks[rankId] = data

				if managedBy == localPlayer then
					selectedRank = rankId

					if selectedRank > renderData.visibleRanks then
						renderData.ranksOffset = #availableGroups[groupId].ranks - renderData.visibleRanks
					else
						renderData.ranksOffset = 0
					end
				end
			elseif dataType == "description" then
				availableGroups[groupId].description = data

				if selectedGroup == groupId then
					fakeInputs["groupDesc"] = data
				end
			elseif dataType == "balance" then
				availableGroups[groupId].balance = data

				if selectedGroup == groupId then
					fakeInputs["groupBalance"] = ""
				end
			end
		end
	end
)

addEvent("removeGroupRank", true)
addEventHandler("removeGroupRank", getRootElement(),
	function (groupId, ranks, members)
		if availableGroups[groupId] then
			availableGroups[groupId].ranks = ranks

			if meInGroup[groupId] then
				triggerEvent("receiveGroupMembers", localPlayer, members)
			end
		end
	end
)

addEvent("setErrorDisplay", true)
addEventHandler("setErrorDisplay", getRootElement(),
	function (soundType, display, text)
		showError(display, text, ":sarp_assets/audio/admin/" .. soundType .. ".ogg")

		if display == "groupBalance" then
			renderData.payManagingInProcess = false
		end
	end
)

function showError(display, text, sound)
	errorToDisplay = display
	errorText = text
	playSound(sound)
end

function hideError()
	errorToDisplay = false
	errorText = ""
end

function drawDataRow(x, y, h, scale, caption, data, dataFont, dataFontScale, startX, endX)
	scale = scale or 1

	local w1 = dxGetTextWidth(caption, scale, RobotoB14) + respc(5)
	local w2 = dxGetTextWidth(string.gsub(data, "#......", ""), dataFontScale, dataFont)

	dxDrawText(caption, x, y, x + w1, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), scale, RobotoB14, "center", "center")
	dxDrawText(data, x + w1, y, x + w1 + w2, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), dataFontScale, dataFont, "center", "center", false, false, false, true)

	if startX and endX then
		dxDrawLine(startX, y + h, endX, y + h, tocolor(50, 50, 50, 200 * alphaMultipler), 1)
	end

	return y + h, w1 + w2, h
end

function drawButtonWithPrompt(key, label, x, y, w, h, activeColor, icon, labelFont, iconFont, labelScale, iconScale)
	if errorToDisplay == key and string.len(errorText) > 0 then
		local acceptWidth = respc(75)
		local x2 = x + w - acceptWidth

		dxDrawText(errorText, x, y, x + w, y + h, tocolor(255, 255, 255, 230 * alphaMultipler), 0.9, Roboto14, "left", "center", true, false, false, true)

		drawButton("promptDecline", "Nem", x2, y, acceptWidth, h, {7, 112, 196})

		x2 = x2 - acceptWidth - respc(5)

		drawButton(key .. "_promptAccept", "Igen", x2, y, acceptWidth, h, {215, 89, 89})
	else
		drawButton(key, label, x, y, w, h, activeColor, icon, labelFont, iconFont, labelScale, iconScale)
	end
end

function drawInputWithErrorDisplay(key, label, x, y, w, h, activeColor, icon, acceptLabel, labelFont, iconFont, labelScale, iconScale)
	if errorToDisplay == key and string.len(errorText) > 0 then
		local acceptWidth = respc(75)
		local inputWidth = w - acceptWidth

		dxDrawText(errorText, x, y, x + inputWidth, y + h, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true, false, false, true)

		drawButton("errorOk", "OK", x + inputWidth, y, acceptWidth, h, {7, 112, 196}, icon)
	else
		local acceptWidth = dxGetTextWidth(acceptLabel or "OK", 1, RobotoL16) + respc(20)
		local inputWidth = w - acceptWidth

		if not fakeInputs[key] then
			fakeInputs[key] = ""
		end

		dxDrawRectangle(x, y, inputWidth, h, tocolor(50, 50, 50, 100 * alphaMultipler))
		buttons[key .. ":input"] = {x, y, inputWidth, h}

		if utf8.len(fakeInputs[key]) > 0 then
			dxDrawText(fakeInputs[key], x + 10, y, x + 10 + inputWidth - 20, y + h, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true)
		else
			dxDrawText(label, x + 10, y, x + 10 + inputWidth - 20, y + h, tocolor(100, 100, 100, 200 * alphaMultipler), 1, Roboto14, "left", "center", true)
		end

		if activeFakeInput == key then
			if cursorState then
				local w = dxGetTextWidth(fakeInputs[key], 1, Roboto14)
				dxDrawLine(x + 10 + w, y + respc(5), x + 10 + w, y + h - respc(5), tocolor(230, 230, 230, 255 * alphaMultipler))
			end

			if getTickCount() - lastChangeCursorState >= 500 then
				cursorState = not cursorState
				lastChangeCursorState = getTickCount()
			end
		end

		drawButton(key, acceptLabel or "OK", x + inputWidth, y, acceptWidth, h, activeColor, icon, labelFont, iconFont, labelScale, iconScale)
	end
end

renderData.colorSwitches = {}
renderData.lastColorSwitches = {}
renderData.startColorSwitch = {}
renderData.lastColorConcat = {}

function processColorSwitchEffect(key, color, duration, type)
	if not renderData.colorSwitches[key] then
		if not color[4] then
			color[4] = 255
		end

		renderData.colorSwitches[key] = color
		renderData.lastColorSwitches[key] = color

		renderData.lastColorConcat[key] = table.concat(color)
	end

	duration = duration or 500
	type = type or "Linear"

	if renderData.lastColorConcat[key] ~= table.concat(color) then
		renderData.lastColorConcat[key] = table.concat(color)
		renderData.lastColorSwitches[key] = color
		renderData.startColorSwitch[key] = getTickCount()
	end

	if renderData.startColorSwitch[key] then
		local progress = (getTickCount() - renderData.startColorSwitch[key]) / duration

		local r, g, b = interpolateBetween(
			renderData.colorSwitches[key][1], renderData.colorSwitches[key][2], renderData.colorSwitches[key][3],
			color[1], color[2], color[3],
			progress, type
		)

		local a = interpolateBetween(renderData.colorSwitches[key][4], 0, 0, color[4], 0, 0, progress, type)

		renderData.colorSwitches[key][1] = r
		renderData.colorSwitches[key][2] = g
		renderData.colorSwitches[key][3] = b
		renderData.colorSwitches[key][4] = a

		if progress >= 1 then
			renderData.startColorSwitch[key] = false
		end
	end

	return renderData.colorSwitches[key][1], renderData.colorSwitches[key][2], renderData.colorSwitches[key][3], renderData.colorSwitches[key][4]
end

renderData.buttonSliderOffsets = {}
renderData.buttonStartSlider = {}
renderData.buttonSliderStates = {}

function drawButtonSlider(key, state, x, y, h, offColor, onColor)
	if not renderData.buttonSliderOffsets[key] then
		renderData.buttonSliderOffsets[key] = 0
		renderData.buttonSliderStates[key] = state
	end

	local buttonColor
	if state then
		buttonColor = {processColorSwitchEffect(key, {onColor[1], onColor[2], onColor[3], 0})}
	else
		buttonColor = {processColorSwitchEffect(key, {offColor[1], offColor[2], offColor[3], 255})}
	end

	if renderData.buttonSliderStates[key] ~= state then
		renderData.buttonSliderStates[key] = state
		renderData.buttonStartSlider[key] = {getTickCount(), state}
	end

	if renderData.buttonStartSlider[key] then
		local progress = (getTickCount() - renderData.buttonStartSlider[key][1]) / 500

		if  renderData.buttonStartSlider[key][2] then
			renderData.buttonSliderOffsets[key] = interpolateBetween(renderData.buttonSliderOffsets[key], 0, 0, 32, 0, 0, progress, "Linear")
		else
			renderData.buttonSliderOffsets[key] = interpolateBetween(renderData.buttonSliderOffsets[key], 0, 0, 0, 0, 0, progress, "Linear")
		end

		if progress >= 1 then
			renderData.buttonStartSlider[key] = false
		end
	end

	local alphaDifference = 255 - buttonColor[4]

	buttons[key] = {x, y, 64, 32}

	y = y + (h - 32) / 2

	dxDrawImage(x, y, 64, 32, "files/toggleSwitch/off.png", 0, 0, 0, tocolor(255, 255, 255, (255 - alphaDifference) * alphaMultipler))
	dxDrawImage(x, y, 64, 32, "files/toggleSwitch/on.png", 0, 0, 0, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], (0 + alphaDifference) * alphaMultipler))
	dxDrawImage(x + renderData.buttonSliderOffsets[key], y, 64, 32, "files/toggleSwitch/circle.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler))
end

function drawButton(key, label, x, y, w, h, activeColor, icon, labelFont, iconFont, labelScale, iconScale)
	local buttonColor
	if activeButton == key then
		buttonColor = {processColorSwitchEffect(key, {activeColor[1], activeColor[2], activeColor[3], 175})}
	else
		buttonColor = {processColorSwitchEffect(key, {activeColor[1], activeColor[2], activeColor[3], 125})}
	end

	local alphaDifference = 175 - buttonColor[4]

	dxDrawRectangle(x, y, w, h, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], (175 - alphaDifference) * alphaMultipler))
	dxDrawInnerBorder(2, x, y, w, h, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], (125 + alphaDifference) * alphaMultipler))

	labelFont = labelFont or RobotoL14
	labelScale = labelScale or 1

	if icon then
		iconFont = iconFont or Themify18
		iconScale = iconScale or 0.75

		local iconWidth = dxGetTextWidth(icon, iconScale, iconFont) + respc(5)
		local textWidth = dxGetTextWidth(label, labelScale, labelFont)
		local totalWidth = iconWidth + textWidth

		local x2 = x + (w - totalWidth) / 2

		dxDrawText(icon, x2, y, 0, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), iconScale, iconFont, "left", "center")
		dxDrawText(label, x2 + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), labelScale, labelFont, "left", "center")
	else
		dxDrawText(label, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), labelScale, labelFont, "center", "center")
	end
	
	buttons[key] = {x, y, w, h}
end

function dxDrawInnerBorder(thickness, x, y, w, h, color, postGUI)
	thickness = thickness or 2

	dxDrawLine(x, y, x + w, y, color, thickness, postGUI)
	dxDrawLine(x, y + h, x + w, y + h, color, thickness, postGUI)
	dxDrawLine(x, y, x, y + h, color, thickness, postGUI)
	dxDrawLine(x + w, y, x + w, y + h, color, thickness, postGUI)
end

function drawScrollbar(key, x, y, w, h, visibleItems, currentItems)
	local trackY = y + w
	local trackHeight = h - (w * 2)

	local gripHeight = (trackHeight / currentItems) * visibleItems
	local gripColor

	if not renderData[key .. "Offset"] then
		renderData[key .. "Offset"] = 0
	end

	if renderData.draggingGrips[key] then
		gripColor = {processColorSwitchEffect("scrollbarGrip:" .. key, {174, 174, 174, 255})}

		renderData.gripPoses[key] = cursorY - renderData.draggingGrips[key]

		if renderData.gripPoses[key] < trackY then
			renderData.gripPoses[key] = trackY
		elseif renderData.gripPoses[key] > trackY + trackHeight - gripHeight then
			renderData.gripPoses[key] = trackY + trackHeight - gripHeight
		end

		renderData[key .. "Offset"] = math.floor(reMap(renderData.gripPoses[key], trackY, trackY + trackHeight - gripHeight, 0, 1) * (currentItems - visibleItems))
	elseif activeButton == "scrollbarGrip:" .. key then
		if getKeyState("mouse1") then
			gripColor = {processColorSwitchEffect("scrollbarGrip:" .. key, {174, 174, 174, 255})}
		else
			gripColor = {processColorSwitchEffect("scrollbarGrip:" .. key, {134, 134, 134, 255})}
		end
	else
		gripColor = {processColorSwitchEffect("scrollbarGrip:" .. key, {93, 93, 93, 255})}
	end

	local gripY = trackY + (trackHeight / currentItems) * math.min(renderData[key .. "Offset"], currentItems - visibleItems)

	if gripY < trackY then
		gripY = trackY
	elseif gripY > trackY + trackHeight - gripHeight then
		gripY = trackY + trackHeight - gripHeight
	end

	renderData.gripPoses[key] = gripY

	dxDrawRectangle(x, trackY, w, trackHeight, tocolor(53, 53, 53, 255 * alphaMultipler))
	dxDrawRectangle(x, gripY, w, gripHeight, tocolor(gripColor[1], gripColor[2], gripColor[3], gripColor[4] * alphaMultipler))
	buttons["scrollbarGrip:" .. key] = {x, gripY, w, gripHeight}

	-- ** Kis gomb (fel)
	local colorOfUp = tocolor(50, 50, 48, 255 * alphaMultipler)
	local colorOfArrow = tocolor(210, 210, 210, 255 * alphaMultipler)

	if activeButton == "scrollUp:" .. key then
		if getKeyState("mouse1") then
			colorOfUp = tocolor(173, 173, 173, 255 * alphaMultipler)
			colorOfArrow = tocolor(83, 83, 83, 255 * alphaMultipler)

			if lastScrollByArrowBtn == 0 then
				renderData[key .. "Offset"] = renderData[key .. "Offset"] - 1
				lastScrollByArrowBtn = getTickCount()
			end

			if getTickCount() - lastScrollByArrowBtn >= 125 then
				renderData[key .. "Offset"] = renderData[key .. "Offset"] - 1
				lastScrollByArrowBtn = getTickCount()
			end

			if renderData[key .. "Offset"] < 0 then
				renderData[key .. "Offset"] = 0
			end
		else
			lastScrollByArrowBtn = 0
			colorOfUp = tocolor(73, 73, 72)
		end
	end

	dxDrawRectangle(x, trackY - w, w, w, colorOfUp)
	dxDrawImage(x, trackY - w, w, w, "files/icons/arrow.png", 0, 0, 0, colorOfArrow)
	buttons["scrollUp:" .. key] = {x, trackY - w, w, w}

	-- ** Kis gomb (le)
	local colorOfDown = tocolor(50, 50, 48, 255 * alphaMultipler)
	local colorOfArrow = tocolor(210, 210, 210, 255 * alphaMultipler)

	if activeButton == "scrollDown:" .. key then
		if getKeyState("mouse1") then
			colorOfDown = tocolor(173, 173, 173, 255 * alphaMultipler)
			colorOfArrow = tocolor(83, 83, 83, 255 * alphaMultipler)

			if lastScrollByArrowBtn == 0 then
				renderData[key .. "Offset"] = renderData[key .. "Offset"] + 1
				lastScrollByArrowBtn = getTickCount()
			end

			if getTickCount() - lastScrollByArrowBtn >= 125 then
				renderData[key .. "Offset"] = renderData[key .. "Offset"] + 1
				lastScrollByArrowBtn = getTickCount()
			end

			if renderData[key .. "Offset"] > currentItems - visibleItems then
				renderData[key .. "Offset"] = currentItems - visibleItems
			end
		else
			lastScrollByArrowBtn = 0
			colorOfDown = tocolor(73, 73, 72)
		end
	end

	dxDrawRectangle(x, trackY + trackHeight, w, w, colorOfDown)
	dxDrawImage(x, trackY + trackHeight, w, w, "files/icons/arrow.png", 180, 0, 0, colorOfArrow)
	buttons["scrollDown:" .. key] = {x, trackY + trackHeight, w, w}
end

function drawInput(key, label, x, y, w, h)
	if not fakeInputs[key] then
		fakeInputs[key] = ""
	end

	dxDrawRectangle(x, y, w, h, tocolor(50, 50, 50, 100 * alphaMultipler))
	buttons[key .. ":input"] = {x, y, w, h}

	if utf8.len(fakeInputs[key]) > 0 then
		dxDrawText(fakeInputs[key], x + 10, y, x + 10 + w - 20, y + h, tocolor(255, 255, 255, 230 * alphaMultipler), 1, Roboto14, "left", "center", true)
	else
		dxDrawText(label, x + 10, y, x + 10 + w - 20, y + h, tocolor(100, 100, 100, 200 * alphaMultipler), 1, Roboto14, "left", "center", true)
	end

	if activeFakeInput == key then
		if cursorState then
			local w = dxGetTextWidth(fakeInputs[key], 1, Roboto14)
			dxDrawLine(x + 10 + w, y + respc(5), x + 10 + w, y + h - respc(5), tocolor(230, 230, 230, 255 * alphaMultipler))
		end

		if getTickCount() - lastChangeCursorState >= 500 then
			cursorState = not cursorState
			lastChangeCursorState = getTickCount()
		end
	end
end

function drawDropDown(key, x, y, w, h, items)
	if not renderData.dropDowns[key] then
		renderData.dropDowns[key] = 1
	end

	if renderData.activeDropDown ~= key then
		local arrowImgSize = h * 0.75

		dxDrawRectangle(x, y, w, h, tocolor(50, 50, 50, 100 * alphaMultipler))
		dxDrawText(items[renderData.dropDowns[key]], x + 10, y, x + 10 + w - 20 - arrowImgSize - 10, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "center")
		dxDrawImage(x + w - arrowImgSize - 10, y + (h - arrowImgSize) / 2, arrowImgSize, arrowImgSize, "files/icons/arrow.png", 180, 0, 0, tocolor(255, 255, 255, 255 * alphaMultipler))
		
		buttons["dropdownToggle:" .. key] = {x, y, w, h}
	else
		dxDrawRectangle(x, y - 5, w, h * #items + 10, tocolor(43, 43, 43, 255 * alphaMultipler))

		for i = 1, #items do
			local y2 = y + (h * (i - 1))
			local colorOfContainer

			if renderData.dropDowns[key] == i then
				colorOfContainer = {processColorSwitchEffect("dropdownItem:" .. key .. ":" .. i, {17, 48, 95, 255})}
			elseif activeButton == "selectDropdownItem:" .. key .. ":" .. i and not scrollbarActive and not getKeyState("mouse1") then
				colorOfContainer = {processColorSwitchEffect("dropdownItem:" .. key .. ":" .. i, {64, 64, 64, 255})}
			else
				colorOfContainer = {processColorSwitchEffect("dropdownItem:" .. key .. ":" .. i, {43, 43, 43, 255})}
			end

			if colorOfContainer then
				dxDrawRectangle(x + 1, y2, w - 2, h, tocolor(colorOfContainer[1], colorOfContainer[2], colorOfContainer[3], colorOfContainer[4] * alphaMultipler))
			end

			dxDrawText(items[i], x + 10, y2, x + 10 + w - 20, y2 + h, tocolor(255, 255, 255, 255 * alphaMultipler), 1, Roboto14, "left", "center", true)

			buttons["selectDropdownItem:" .. key .. ":" .. i] = {x, y2, w, h}
		end

		dxDrawInnerBorder(1, x, y - 5, w, h * #items + 10, tocolor(118, 118, 118, 255 * alphaMultipler))
	end
end

function processGroupCreation(state)
	local groupName = fakeInputs["groupName"]
	local groupPrefix = fakeInputs["groupPrefix"]
	local groupMainLeader = tonumber(fakeInputs["groupMainLeader"]) or 0
	local groupType = groupTypesEx[renderData.dropDowns["groupType"]]
	local groupArmor = tonumber(fakeInputs["dutyArmor"]) or 0
	local groupRadio = tonumber(fakeInputs["groupTuneRadio"]) or 0

	if utf8.len(groupName) < 1 then
		exports.sarp_hud:showInfobox("error", "A csoport nevének legalább 1 karakterből kell állnia!")
		return
	end

	if utf8.len(groupPrefix) > 10 then
		exports.sarp_hud:showInfobox("error", "A csoport prefix nem lehet hosszabb 10 karaktertől!")
		return
	end

	if groupArmor > 100 then
		exports.sarp_hud:showInfobox("error", "A duty armor nem lehet nagyobb 100-nál!")
		return
	end

	if not groupRadio or groupRadio <= 0 then
		exports.sarp_hud:showInfobox("error", "A védett rádió frekvenciának nagyobbnak kell lennie nullánál!")
		return
	else
		local tuneRadioExists = false

		for k, v in pairs(availableGroups) do
			if v.tuneRadio and v.tuneRadio == groupRadio and k ~= selectedGroup then
				tuneRadioExists = v
				break
			end
		end

		if tuneRadioExists then
			exports.sarp_hud:showInfobox("error", "A kiválasztott rádió frekvenciát már használja egy másik frakció. (" .. tuneRadioExists.name .. ")")
			return
		end
	end

	for k, v in pairs(groupTypes) do
		if v == groupType then
			groupType = k
			break
		end
	end

	local dutyItems = renderData.dutyItems
	local dutyItemsEx = {}

	if dutyItems then
		for i = 1, #dutyItems do
			if utf8.len(dutyItems[i][4]) < 1 then
				table.insert(dutyItemsEx, {dutyItems[i][1], dutyItems[i][3]})
			else
				table.insert(dutyItemsEx, {dutyItems[i][1], dutyItems[i][3], dutyItems[i][4]})
			end
		end
	end

	local mainLeaderFound = false
	for k, v in ipairs(getElementsByType("player")) do
		if getElementData(v, "loggedIn") and getElementData(v, "char.ID") == groupMainLeader then
			mainLeaderFound = v
			groupMainLeader = getElementData(v, "char.ID")
			break
		end
	end

	local oldLeaderFound = false
	if availableGroups[selectedGroup] and groupMainLeader ~= availableGroups[selectedGroup].mainLeader then
		for k, v in ipairs(getElementsByType("player")) do
			if getElementData(v, "loggedIn") and getElementData(v, "char.ID") == availableGroups[selectedGroup].mainLeader then
				oldLeaderFound = v
				break
			end
		end
	end

	local preGroupTable = {
		mainLeader = groupMainLeader,
		name = groupName,
		prefix = groupPrefix,
		type = groupType,
		description = "nincs leírás",
		balance = 0,
		permissions = renderData.dutyPermissions,
		duty = {
			positions = renderData.dutyPoses,
			skins = renderData.dutySkins,
			items = dutyItemsEx,
			armor = groupArmor
		},
		tuneRadio = groupRadio
	}

	if not availableGroups[selectedGroup] then
		triggerServerEvent("createGroup", localPlayer, preGroupTable, mainLeaderFound)
	else
		triggerServerEvent("modifyGroup", localPlayer, selectedGroup, preGroupTable, mainLeaderFound, oldLeaderFound)
	end

	togglePanel(false)
	setGroupCreationValues(nil)
end

function setGroupCreationValues(data)
	if not data then
		fakeInputs["groupName"] = nil
		fakeInputs["groupPrefix"] = nil
		fakeInputs["groupMainLeader"] = nil
		fakeInputs["dutyArmor"] = nil
		fakeInputs["groupTuneRadio"] = nil

		renderData.dropDowns["groupType"] = nil

		renderData.dutyPermissions = nil
		renderData.dutyItems = nil
		renderData.dutyPoses = nil
		renderData.dutySkins = nil
	else
		fakeInputs["groupName"] = data.name
		fakeInputs["groupPrefix"] = data.prefix
		fakeInputs["groupMainLeader"] = tostring(data.mainLeader)
		fakeInputs["dutyArmor"] = tostring(data.duty.armor)
		fakeInputs["groupTuneRadio"] = tostring(data.tuneRadio)

		for k, v in pairs(groupTypesEx) do
			if v == groupTypes[data.type] then
				renderData.dropDowns["groupType"] = k
				break
			end
		end

		renderData.dutyItems = {}

		for i = 1, #data.duty.items do
			table.insert(renderData.dutyItems, {
				data.duty.items[i][1],
				exports.sarp_inventory:getItemName(data.duty.items[i][1]),
				data.duty.items[i][2],
				data.duty.items[i][3] or ""
			})
		end

		renderData.dutyPermissions = data.permissions
		renderData.dutyPoses = data.duty.positions
		renderData.dutySkins = data.duty.skins
	end
end

local dutySkinSelectState = false
local originalSkin = 0
local currentSkinOffset = 0
local skinForGroup = false

function toggleDutySkinSelect(state, groupID)
	if dutySkinSelectState ~= state then
		if state then
			dutySkinSelectState = true
			exports.sarp_controls:toggleControl("all", false)

			originalSkin = getElementModel(localPlayer)
			skinForGroup = groupID
			currentSkinOffset = 0

			bindKey("arrow_r", "up", nextSkin)
			bindKey("arrow_l", "up", previousSkin)
			bindKey("enter", "up", processDutySkinSelection)
		else
			unbindKey("arrow_r", "up", nextSkin)
			unbindKey("arrow_l", "up", previousSkin)
			unbindKey("enter", "up", processDutySkinSelection)

			skinForGroup = false
			exports.sarp_controls:toggleControl("all", true)
			dutySkinSelectState = false
		end
	end
end

function nextSkin()
	if skinForGroup and availableGroups[skinForGroup] and availableGroups[skinForGroup].duty.skins[currentSkinOffset + 1] then
		currentSkinOffset = currentSkinOffset + 1
		setElementModel(localPlayer, availableGroups[skinForGroup].duty.skins[currentSkinOffset])
	end
end

function previousSkin()
	if skinForGroup and availableGroups[skinForGroup] and availableGroups[skinForGroup].duty.skins[currentSkinOffset - 1] then
		currentSkinOffset = currentSkinOffset - 1
		setElementModel(localPlayer, availableGroups[skinForGroup].duty.skins[currentSkinOffset])
	end
end

function processDutySkinSelection()
	local selectedSkin = getElementModel(localPlayer)
	
	if selectedSkin ~= originalSkin then
		setElementModel(localPlayer, originalSkin)

		triggerServerEvent("updateDutySkin", localPlayer, skinForGroup, selectedSkin, originalSkin)
	end

	toggleDutySkinSelect(false)
	exports.sarp_hud:showInfobox("success", "Sikeresen megváltoztattad a csoporthoz tartozó szolgálati öltözékedet.")
end

addEventHandler("onClientRender", getRootElement(),
	function ()
		local localX, localY, localZ = getElementPosition(localPlayer)

		for i = 1, #dutyColShapes do
			local colShape = dutyColShapes[i]

			if isElement(colShape) then
				local colShapeX, colShapeY, colShapeZ = getElementPosition(colShape)
				local screenX, screenY = getScreenFromWorldPosition(colShapeX, colShapeY, colShapeZ, 10)

				if screenX and screenY then
					if 100 >= getDistanceBetweenPoints3D(colShapeX, colShapeY, colShapeZ, localX, localY, localZ) then
						dxDrawMaterialLine3D(colShapeX, colShapeY, colShapeZ + 0.5, colShapeX, colShapeY, colShapeZ - 0.5, dutyTexture, 1, tocolor(50, 179, 239, 255))

						for j = -0.5, 0.5, 0.5 do
							local colShapeZ = colShapeZ + j

							dxDrawLine3D(colShapeX - boundRadius, colShapeY - boundRadius, colShapeZ, colShapeX + boundRadius, colShapeY - boundRadius, colShapeZ, boundColor, 2)
							dxDrawLine3D(colShapeX - boundRadius, colShapeY + boundRadius, colShapeZ, colShapeX + boundRadius, colShapeY + boundRadius, colShapeZ, boundColor, 2)
							dxDrawLine3D(colShapeX - boundRadius, colShapeY - boundRadius, colShapeZ, colShapeX - boundRadius, colShapeY + boundRadius, colShapeZ, boundColor, 2)
							dxDrawLine3D(colShapeX + boundRadius, colShapeY - boundRadius, colShapeZ, colShapeX + boundRadius, colShapeY + boundRadius, colShapeZ, boundColor, 2)
						end
					end
				end
			end
		end

		if dutySkinSelectState then
			dxDrawText("Lapozás: [<-] és [->] Kiválasztás: [ENTER]", 0 + 1, 0 + 1, screenX + 1, screenY - 200 + 1, tocolor(0, 0, 0), 1, RobotoL18, "center", "bottom")
			dxDrawText("Lapozás: #32b3ef[<-] és [->] #ffffffKiválasztás: #32b3ef[ENTER]", 0, 0, screenX, screenY - 200, tocolor(255, 255, 255), 1, RobotoL18, "center", "bottom", false, false, false, true)
		end
	end
)