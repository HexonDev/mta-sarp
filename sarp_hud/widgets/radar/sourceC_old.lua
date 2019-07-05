local screenSource = dxCreateScreenSource(screenX, screenY)

local gpsLineHeight = respc(50)
local gpsLineIconSize = respc(40)
local gpsLineIconHalfSize = gpsLineIconSize / 2

local minimapWidth = respc(330)
local minimapHeight = respc(190)
local minimapPosX = 0
local minimapPosY = 0
local minimapOldPosY = minimapPosY
local minimapCenterX = minimapPosX + minimapWidth / 2
local minimapCenterY = minimapPosY + minimapHeight / 2

local minimapInterpolation = false
local minimapTargetMove = false
local minimapRenderY = minimapPosY

function interpolateMinimapPosition(state)
	minimapInterpolation = getTickCount()
end

local minimapRenderSize = math.ceil((minimapWidth + minimapHeight) * 0.75)
local minimapRenderHalfSize = minimapRenderSize / 2
local minimapRender = dxCreateRenderTarget(minimapRenderSize, minimapRenderSize)
local minimapRenderSizeOffset = respc(minimapRenderSize * 0.75)

local localMinimapZoom = 0.75
local minimapZoom = localMinimapZoom

local mapTexture = dxCreateTexture("widgets/radar/files/map.png")
local mapTextureSize = 1600--3072
local mapRatio = 6000 / mapTextureSize
local mapUnit = mapTextureSize / 6000

local createdBlips = {}

local farshowBlips = {}
local farshowBlipsData = {}

local bigmapPosX = 0--30
local bigmapPosY = 0--30
local bigmapWidth = screenX-- - 60
local bigmapHeight = screenY-- - 60
local bigmapCenterX = bigmapPosX + bigmapWidth / 2
local bigmapCenterY = bigmapPosY + bigmapHeight / 2

local bigmapZoom = 0.5
local bigmapTargetZoom = bigmapZoom
local bigmapLastZoom = bigmapZoom
local bigmapZoomInterpolation = false

local minimapIsVisible = true
local bigmapIsVisible = false

local lastCursorPos = false
local cursorMoveDifference = false
local mapMoveDifference = false
local lastMapMovePos = false
local mapIsMoving = false
local lastMapPosX, lastMapPosY = 0, 0
local mapPlayerPosX, mapPlayerPosY = 0, 0
local cursorX, cursorY = -1, -1

local zoneLineHeight = respc(30)
local size32px = respc(32)
local size16px = respc(16)
local size8px = respc(8)
local size4px = respc(4)

local visibleBlipTooltip = false
local blipTextures = {}

for k,v in pairs(blipTooltips) do
	blipTextures[k] = dxCreateTexture("widgets/radar/files/blips/" .. k)
end

local canSeePlayers = false
local showPlayersButtonHover = false

carCanGPSVal = false

local gpsLines = {}
local gpsRouteImage = false
local gpsRouteImageData = {}
local gpsLineColor = tocolor(50, 179, 239)
local gpsNaviAlphaMul = 0

local disableMap = false

function showMap(state)
    disableMap = state
end

local unknownZones = {
	["San Fierro Bay"] = true,
	["Gant Bridge"] = true,
	["Las Venturas"] = true,
	["Bone County"] = true,
	["Tierra Robada"] = true,
}

local _getZoneName = getZoneName
function getZoneName(x, y, z, cities)
	local zoneName = _getZoneName(x, y, z, cities)
	local cityName = zoneName

	if not cities then
		cityName = _getZoneName(x, y, z, true)
	end

	if unknownZones[zoneName] or unknownZones[cityName] then
		return "Unknown"
	end

	return zoneName
end

local farBlips = {}
local farBlipsCount = 1
local manualBlipsCount = 1
local defaultBlipsCount = 1

local vin2 = dxCreateTexture("files/vin2.png")

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		table.insert(mainBlips, {0, 3000, 0, "north.png", true, 99999, 16})

		dxSetTextureEdge(mapTexture, "border", tocolor(0, 0, 0, 0))

		for k,v in ipairs(mainBlips) do
			createCustomBlip(unpack(v))
		end

		setPlayerHudComponentVisible("all", false)
		setPlayerHudComponentVisible("crosshair", true)
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if source == occupiedVehicle then
			if dataName == "gpsDestination" then
				local dataValue = getElementData(source, dataName) or false

				if dataValue then
					gpsThread = coroutine.create(makeRoute)
					coroutine.resume(gpsThread, unpack(dataValue))
					waypointInterpolation = false
				else
					endRoute()
				end
			end
		end
	end
)

addEventHandler("onClientKey", getRootElement(),
	function (key, pressDown)
		if key == "F11" then
			if pressDown and renderData.loggedIn and not renderData.editorActive then
				bigmapIsVisible = not bigmapIsVisible
				setElementData(localPlayer, "bigmapIsVisible", bigmapIsVisible)

				setPlayerHudComponentVisible("all", false)
				setPlayerHudComponentVisible("crosshair", true)

				showPlayersButtonHover = false

				if bigmapIsVisible then
					toggleHUD(false)
					showChat(false)
					addEventHandler("onClientRender", getRootElement(), renderTheBigmap)
				else
					removeEventHandler("onClientRender", getRootElement(), renderTheBigmap)
					toggleHUD(true)
					showChat(true)
				end
			end

			cancelEvent()
		elseif key == "mouse_wheel_up" then
			if pressDown then
				if bigmapIsVisible and bigmapTargetZoom + 0.1 <= 2.1 then
					bigmapZoomInterpolation = getTickCount()
					bigmapLastZoom = bigmapZoom
					bigmapTargetZoom = bigmapTargetZoom + 0.1
				end
			end
		elseif key == "mouse_wheel_down" then
			if pressDown then
				if bigmapIsVisible and bigmapTargetZoom - 0.1 >= 0.1 then
					bigmapZoomInterpolation = getTickCount()
					bigmapLastZoom = bigmapZoom
					bigmapTargetZoom = bigmapTargetZoom - 0.1
				end
			end
		end
	end
)

addEventHandler("onClientClick", getRootElement(),
	function (button, state, cursorX, cursorY)
		if not bigmapIsVisible then
			return
		end

		cancelEvent()

		if getElementData(localPlayer, "acc.adminLevel") >= 1 and button == "left" and state == "up" and showPlayersButtonHover then
			canSeePlayers = not canSeePlayers
			return
		end

		if state == "up" and mapIsMoving then
			mapIsMoving = false
			return
		end

		if button == "left" and state == "up" then
			if occupiedVehicle and carCanGPS() then
				if getElementData(occupiedVehicle, "gpsDestination") then
					setElementData(occupiedVehicle, "gpsDestination", false)
				else
					setElementData(occupiedVehicle, "gpsDestination", {
						reMap((cursorX - bigmapPosX) / bigmapZoom + (remapTheSecondWay(mapPlayerPosX) - bigmapWidth / bigmapZoom * 0.5), 0, mapTextureSize, -3000, 3000),
						reMap((cursorY - bigmapPosY) / bigmapZoom + (remapTheFirstWay(mapPlayerPosY) - bigmapHeight / bigmapZoom * 0.5), 0, mapTextureSize, 3000, -3000)
					})
				end
			end
		end
	end
)

addEventHandler("onClientRestore", getRootElement(),
	function ()
		if gpsRoute then
			processGPSLines()
		end
	end
)

local minimapOffY = 0

addEventHandler("onClientRender", getRootElement(),
	function ()
		if minimapInterpolation and getTickCount() >= minimapInterpolation then
			local progress = (getTickCount() - minimapInterpolation) / 500

			if gpsRoute then
				minimapOffY = interpolateBetween(0, 0, 0, gpsLineHeight, 0, 0, progress, "OutQuad")
			else
				minimapOffY = interpolateBetween(gpsLineHeight, 0, 0, 0, 0, 0, progress, "OutQuad")
			end

			if not waypointEndInterpolation and not reRouting then
				gpsNaviAlphaMul = interpolateBetween(0, 0, 0, 1, 0, 0, progress, "OutQuad")
			end

			if progress > 1 then
				minimapInterpolation = false
			end
		end
	end
)

render.minimap = function (x, y)
	local y2 = y - minimapOffY
	
	if not renderData.loggedIn then
		return
    end

    if disableMap then
		return
	end

	if bigmapIsVisible or not minimapIsVisible then
		return
	end

	y2 = y2 + size32px

	minimapWidth = widgets.minimap.sizeX
	minimapHeight = widgets.minimap.sizeY - size32px

	local rtSize = math.ceil((minimapWidth + minimapHeight) * 0.75)
	if math.abs(rtSize - minimapRenderSize) > 10 then
		minimapRenderSize = rtSize
		minimapRenderHalfSize = minimapRenderSize / 2
		minimapRenderSizeOffset = respc(minimapRenderSize * 0.75)
		destroyElement(minimapRender)
		minimapRender = dxCreateRenderTarget(minimapRenderSize, minimapRenderSize)
	end

	minimapPosX = x
	minimapPosY = y2

	minimapCenterX = minimapPosX + minimapWidth / 2
	minimapCenterY = minimapPosY + minimapHeight / 2

	dxUpdateScreenSource(screenSource, true)

	if getKeyState("num_add") and localMinimapZoom < 1.2 then
		localMinimapZoom = localMinimapZoom + 0.01
	elseif getKeyState("num_sub") and localMinimapZoom > 0.31 then
		localMinimapZoom = localMinimapZoom - 0.01
	end

	minimapZoom = localMinimapZoom

	if occupiedVehicle then
		local vehicleZoom = getVehicleSpeed(occupiedVehicle) / 1300

		if vehicleZoom >= 0.4 then
			vehicleZoom = 0.4
		end

		minimapZoom = minimapZoom - vehicleZoom
	end

	local localX, localY, localZ = getElementPosition(localPlayer)
	local localDimension = getElementDimension(localPlayer)

	local cameraX, cameraY, cameraZ, faceTowardX, faceTowardY = getCameraMatrix()
	local cameraRotation = math.deg(math.atan2(faceTowardY - cameraY, faceTowardX - cameraX)) + 360 + 90

	farshowBlips = {}
	farshowBlipsData = {}

	if localDimension == 0 and localZ <= 10000 then
		local remapLocalX, remapLocalY = remapTheFirstWay(localX), remapTheFirstWay(localY)

		local cameraRadiant = math.rad((cameraRotation - 270) + 90)
		local cameraCos = math.cos(cameraRadiant)
		local cameraSin = math.sin(cameraRadiant)

		farBlips = {}
		farBlipsCount = 1
		manualBlipsCount = 1
		defaultBlipsCount = 1

		local renderSizeScaled = minimapRenderSize / minimapZoom

		dxSetRenderTarget(minimapRender)
		dxDrawRectangle(0, 0, minimapRenderSize, minimapRenderSize, tocolor(22, 98, 173))
		dxDrawImageSection(0, 0, minimapRenderSize, minimapRenderSize, remapTheSecondWay(localX) - renderSizeScaled * 0.5, remapTheFirstWay(localY) - renderSizeScaled * 0.5, renderSizeScaled, renderSizeScaled, mapTexture)

		-- ** GPS Útvonal
		if gpsRouteImage then
			local scaledWidth = gpsRouteImageData[3] * minimapZoom
			local scaledHeight = gpsRouteImageData[4] * minimapZoom

			dxDrawImage(minimapRenderHalfSize + (remapTheFirstWay(localX) - (gpsRouteImageData[1] + gpsRouteImageData[3] * 0.5)) * minimapZoom - scaledWidth * 0.5, minimapRenderHalfSize - (remapTheFirstWay(localY) - (gpsRouteImageData[2] + gpsRouteImageData[4] * 0.5)) * minimapZoom + scaledHeight * 0.5, scaledWidth, -scaledHeight, gpsRouteImage, 180, 0, 0, gpsLineColor)
		end

		dxSetBlendMode("modulate_add")

		-- ** Resource álltal létrehozott blipek
		for i = 1, #createdBlips do
			local blip = createdBlips[i]

			if blip then
				if blip.farShow then
					farBlips[farBlipsCount + manualBlipsCount] = blip.icon
				end

				renderBlip(blip.icon, blip.posX, blip.posY, remapLocalX, remapLocalY, blip.iconSize, blip.iconSize, blip.color, cameraRotation, blip.farShow, i, cameraCos, cameraSin)
				
				manualBlipsCount = manualBlipsCount + 1
			end
		end

		-- ** Default blipek
		local defaultBlips = getElementsByType("blip")

		for i = 1, #defaultBlips do
			local blip = defaultBlips[i]

			if blip then
				local tableId = farBlipsCount + manualBlipsCount + defaultBlipsCount
				local blipPosX, blipPosY = getElementPosition(blip)

				local blipIcon = getElementData(blip, "blipIcon")
				if blipIcon then
					blipIcon = blipIcon .. ".png"
				else
					blipIcon = "target.png"
				end

				local blipSize = getElementData(blip, "blipSize") or 14.5
				local blipColor = getElementData(blip, "blipColor")

				if not blipColor then
					blipColor = tocolor(getBlipColor(blip))
				end

				farBlips[tableId] = blipIcon

				renderBlip(blipIcon, blipPosX, blipPosY, remapLocalX, remapLocalY, type(blipSize) == "table" and blipSize[1] or blipSize, type(blipSize) == "table" and blipSize[2] or blipSize, blipColor, cameraRotation, getElementData(blip, "exclusiveBlip"), tableId, cameraCos, cameraSin)

				defaultBlipsCount = defaultBlipsCount + 1
			end
		end

		dxSetBlendMode("blend")

		dxSetRenderTarget()
		dxDrawImage(minimapPosX - minimapRenderHalfSize + minimapWidth * 0.5, minimapPosY - minimapRenderHalfSize + minimapHeight * 0.5, minimapRenderSize, minimapRenderSize, minimapRender, cameraRotation - 180, 0, 0, tocolor(255, 255, 255, 245))
		dxDrawImage(minimapPosX, minimapPosY, minimapWidth, minimapHeight, vin2)

		for k in pairs(farshowBlips) do
			local blip = createdBlips[k]

			if blip then
				local farBlip = farshowBlipsData[k]

				if blipTextures[blip.icon] then
					dxDrawImage(farBlip.posX, farBlip.posY, blip.iconSize, blip.iconSize, blipTextures[blip.icon], 0, 0, 0, blip.color)
				else
					dxDrawImage(farBlip.posX, farBlip.posY, blip.iconSize, blip.iconSize, "widgets/radar/files/blips/" .. blip.icon, 0, 0, 0, blip.color)
				end
			else
				table.insert(farBlips, k)
			end
		end

		for i = 1, #farBlips do
			local blip = farBlips[i]
			local farBlip = farshowBlipsData[blip]

			if blip and farBlip then
				if blipTextures[farBlip.icon] then
					dxDrawImage(farBlip.posX, farBlip.posY, farBlip.iconWidth, farBlip.iconHeight, blipTextures[farBlip.icon], 0, 0, 0, farBlip.color)
				else
					dxDrawImage(farBlip.posX, farBlip.posY, farBlip.iconWidth, farBlip.iconHeight, "widgets/radar/files/blips/" .. farBlip.icon, 0, 0, 0, farBlip.color)
				end
			end
		end
	else
		renderLostConnection(minimapPosX, minimapPosY, minimapWidth, minimapHeight)
	end

	dxDrawImageSection(minimapPosX - minimapRenderSizeOffset, minimapPosY - minimapRenderSizeOffset, minimapWidth + minimapRenderSizeOffset * 2, minimapRenderSizeOffset, minimapPosX - minimapRenderSizeOffset, minimapPosY - minimapRenderSizeOffset, minimapWidth + minimapRenderSizeOffset * 2, minimapRenderSizeOffset, screenSource)
	dxDrawImageSection(minimapPosX - minimapRenderSizeOffset, minimapPosY + minimapHeight, minimapWidth + minimapRenderSizeOffset * 2, minimapRenderSizeOffset, minimapPosX - minimapRenderSizeOffset, minimapPosY + minimapHeight, minimapWidth + minimapRenderSizeOffset * 2, minimapRenderSizeOffset, screenSource)
	dxDrawImageSection(minimapPosX - minimapRenderSizeOffset, minimapPosY, minimapRenderSizeOffset, minimapHeight, minimapPosX - minimapRenderSizeOffset, minimapPosY, minimapRenderSizeOffset, minimapHeight, screenSource)
	dxDrawImageSection(minimapPosX + minimapWidth, minimapPosY, minimapRenderSizeOffset, minimapHeight, minimapPosX + minimapWidth, minimapPosY, minimapRenderSizeOffset, minimapHeight, screenSource)
	dxDrawOuterBorder(minimapPosX, minimapPosY, minimapWidth, minimapHeight, 2, tocolor(31, 31, 31, 240))

	if localDimension == 0 and localZ <= 10000 then
		local arrowSize = 60 / (4 - minimapZoom) + 3
		local localRx, localRy, localRz = getElementRotation(localPlayer)

		dxDrawImage(minimapCenterX - arrowSize * 0.5, minimapCenterY - arrowSize * 0.5, arrowSize, arrowSize, "widgets/radar/files/arrow.png", math.abs(360 - localRz) + (cameraRotation - 180))

		dxDrawRectangle(minimapPosX - 2, minimapPosY - size32px, minimapWidth + 4, size32px, tocolor(31, 31, 31, 240))

		dxDrawImage(minimapPosX + 3, minimapPosY - size32px + 3, size32px - 6, size32px - 6, ":sarp_assets/images/map/location.png", 0, 0, 0, tocolor(255, 255, 255, 230))
		dxDrawText(string.upper(getZoneName(localX, localY, localZ)), minimapPosX + 3 + size32px, minimapPosY - size32px, minimapPosX + minimapWidth, minimapPosY, tocolor(255, 255, 255, 230), 0.75, CenturyBold, "left", "center", true)

		renderGPSNavigator(minimapPosX, minimapPosY, minimapWidth, minimapHeight)
	end
end

function renderTheBigmap()
	if not bigmapIsVisible then
		return
    end

    if disableMap then
        return
    end

	if bigmapZoomInterpolation and getTickCount() >= bigmapZoomInterpolation then
		local progress = (getTickCount() - bigmapZoomInterpolation) / 150

		bigmapZoom = interpolateBetween(bigmapLastZoom, 0, 0, bigmapTargetZoom, 0, 0, progress, "Linear")

		if progress > 1 then
			bigmapZoomInterpolation = false
		end
	end

	if showPlayersButtonHover then
		showPlayersButtonHover = false
	end

	local localX, localY, localZ = getElementPosition(localPlayer)

	if getElementDimension(localPlayer) == 0 and localZ <= 10000 then
		cursorX, cursorY = getCursorPosition()

		if cursorX and cursorY then
			cursorX, cursorY = cursorX * screenX, cursorY * screenY

			if getKeyState("mouse1") then
				if not lastCursorPos then
					lastCursorPos = {cursorX, cursorY}
				end

				if not cursorMoveDifference then
					cursorMoveDifference = {0, 0}
				end

				cursorMoveDifference = {
					cursorMoveDifference[1] + cursorX - lastCursorPos[1],
					cursorMoveDifference[2] + cursorY - lastCursorPos[2]
				}

				if not lastMapMovePos then
					if not mapMoveDifference then
						lastMapMovePos = {0, 0}
					else
						lastMapMovePos = {mapMoveDifference[1], mapMoveDifference[2]}
					end
				end

				if not mapMoveDifference then
					if math.abs(cursorMoveDifference[1]) >= 3 or math.abs(cursorMoveDifference[2]) >= 3 then
						mapMoveDifference = {lastMapMovePos[1] - cursorMoveDifference[1] / bigmapZoom / mapUnit, lastMapMovePos[2] + cursorMoveDifference[2] / bigmapZoom / mapUnit}
						mapIsMoving = true
					end
				elseif cursorMoveDifference[1] ~= 0 or cursorMoveDifference[2] ~= 0 then
					mapMoveDifference = {lastMapMovePos[1] - cursorMoveDifference[1] / bigmapZoom / mapUnit, lastMapMovePos[2] + cursorMoveDifference[2] / bigmapZoom / mapUnit}
					mapIsMoving = true
				end

				lastCursorPos = {cursorX, cursorY}
			else
				if mapMoveDifference then
					lastMapMovePos = {mapMoveDifference[1], mapMoveDifference[2]}
				end

				lastCursorPos = false
				cursorMoveDifference = false
			end
		end

		mapPlayerPosX, mapPlayerPosY = lastMapPosX, lastMapPosY

		if mapMoveDifference then
			mapPlayerPosX = mapPlayerPosX + mapMoveDifference[1]
			mapPlayerPosY = mapPlayerPosY + mapMoveDifference[2]
		else
			mapPlayerPosX, mapPlayerPosY = localX, localY
			lastMapPosX, lastMapPosY = mapPlayerPosX, mapPlayerPosY
		end

		dxDrawRectangle(bigmapPosX, bigmapPosY, bigmapWidth, bigmapHeight, tocolor(22, 98, 173, 225))
		dxDrawImage(bigmapPosX, bigmapPosY, bigmapWidth, bigmapHeight, vin2)

		dxDrawImageSection(bigmapPosX, bigmapPosY, bigmapWidth, bigmapHeight, remapTheSecondWay(mapPlayerPosX) - bigmapWidth / bigmapZoom * 0.5, remapTheFirstWay(mapPlayerPosY) - bigmapHeight / bigmapZoom * 0.5, bigmapWidth / bigmapZoom, bigmapHeight / bigmapZoom, mapTexture, 0, 0, 0, tocolor(255, 255, 255, 235))

		-- ** GPS Útvonal
		if gpsRouteImage then
			dxUpdateScreenSource(screenSource, true)
			dxDrawImage(bigmapCenterX + (remapTheFirstWay(mapPlayerPosX) - (gpsRouteImageData[1] + gpsRouteImageData[3] * 0.5)) * bigmapZoom - gpsRouteImageData[3] * bigmapZoom * 0.5, bigmapCenterY - (remapTheFirstWay(mapPlayerPosY) - (gpsRouteImageData[2] + gpsRouteImageData[4] * 0.5)) * bigmapZoom + gpsRouteImageData[4] * bigmapZoom * 0.5, gpsRouteImageData[3] * bigmapZoom, -(gpsRouteImageData[4] * bigmapZoom), gpsRouteImage, 180, 0, 0, gpsLineColor)
			dxDrawImageSection(0, 0, bigmapPosX, screenY, 0, 0, bigmapPosX, screenY, screenSource)
			dxDrawImageSection(screenX - bigmapPosX, 0, bigmapPosX, screenY, screenX - bigmapPosX, 0, bigmapPosX, screenY, screenSource)
			dxDrawImageSection(bigmapPosX, 0, screenX - 2 * bigmapPosX, bigmapPosY, bigmapPosX, 0, screenX - 2 * bigmapPosX, bigmapPosY, screenSource)
			dxDrawImageSection(bigmapPosX, screenY - bigmapPosY, screenX - 2 * bigmapPosX, bigmapPosY, bigmapPosX, screenY - bigmapPosY, screenX - 2 * bigmapPosX, bigmapPosY, screenSource)
		end

		-- ** Resource álltal létrehozott blipek
		for i = 1, #createdBlips do
			local blip = createdBlips[i]

			if blip then
				renderBigBlip(blip.icon, blip.posX, blip.posY, mapPlayerPosX, mapPlayerPosY, blip.renderDistance, blip.iconSize, blip.iconSize, blip.color, false, i, blip.tooltipText)
			end
		end

		-- ** Default blipek
		local defaultBlips = getElementsByType("blip")

		for i = 1, #defaultBlips do
			local blip = defaultBlips[i]

			if blip and getElementAttachedTo(blip) ~= localPlayer then
				local blipPosX, blipPosY = getElementPosition(blip)

				local blipIcon = getElementData(blip, "blipIcon")
				if blipIcon then
					blipIcon = blipIcon .. ".png"
				else
					blipIcon = "target.png"
				end

				local blipSize = getElementData(blip, "blipSize") or 14.5
				local blipColor = getElementData(blip, "blipColor")

				if not blipColor then
					blipColor = tocolor(getBlipColor(blip))
				end

				renderBigBlip(blipIcon, blipPosX, blipPosY, mapPlayerPosX, mapPlayerPosY, getElementData(blip, "blipRenderDistance") or 9999, type(blipSize) == "table" and blipSize[1] or blipSize, type(blipSize) == "table" and blipSize[2] or blipSize, blipColor, blip, i, getElementData(blip, "blipTooltipText"))
			end
		end

		-- ** Admin -> játékosok
		if canSeePlayers then
			local players = getElementsByType("player")

			for i = 1, #players do
				local player = players[i]

				if player and isElement(player) and player ~= localPlayer then
					local playerX, playerY = getElementPosition(player)
					local blipColor = tocolor(255, 255, 0)

					if getElementData(player, "adminDuty") then
						blipColor = tocolor(50, 179, 239)
					end

					renderBigBlip("player.png", playerX, playerY, mapPlayerPosX, mapPlayerPosY, 9999, 22, 22, blipColor, player, i)
				end
			end
		end

		renderBigBlip("arrow.png", localX, localY, mapPlayerPosX, mapPlayerPosY, false, 20, 20)

		local currentStandingZone = "Unknown"

		if cursorX and cursorY then
			local zoneX = reMap((cursorX - bigmapPosX) / bigmapZoom + (remapTheSecondWay(mapPlayerPosX) - bigmapWidth / bigmapZoom * 0.5), 0, mapTextureSize, -3000, 3000)
			local zoneY = reMap((cursorY - bigmapPosY) / bigmapZoom + (remapTheFirstWay(mapPlayerPosY) - bigmapHeight / bigmapZoom * 0.5), 0, mapTextureSize, 3000, -3000)

			currentStandingZone = getZoneName(zoneX, zoneY, 0)

			if visibleBlipTooltip then
				local tooltipWidth = dxGetTextWidth(visibleBlipTooltip, 0.6, CenturyBold) + 10

				dxDrawRectangle(cursorX + 12.5, cursorY, tooltipWidth, 25, tocolor(0, 0, 0, 150))
				dxDrawText(visibleBlipTooltip, cursorX + 12.5, cursorY, cursorX + tooltipWidth + 12.5, cursorY + 25, tocolor(255, 255, 255), 0.6, CenturyBold, "center", "center")
			end
		else
			currentStandingZone = getZoneName(localX, localY, localZ)
		end

		local y_offset = zoneLineHeight * 2 - size16px
		if mapMoveDifference then
			y_offset = zoneLineHeight * 3 - size16px
		end

		local standingZoneWidth = dxGetTextWidth(utf8.upper(currentStandingZone), 0.75, CenturyBold) + 10 + 3.75 + zoneLineHeight - 6
		dxDrawRectangle(bigmapPosX + 10, bigmapPosY + bigmapHeight - y_offset, standingZoneWidth, zoneLineHeight, tocolor(0, 0, 0, 200))
		dxDrawImage(bigmapPosX + 10 + 3.75, bigmapPosY + bigmapHeight - y_offset + 3, zoneLineHeight - 6, zoneLineHeight - 6, ":sarp_assets/images/map/location.png", 0, 0, 0, tocolor(255, 255, 255, 230))
		dxDrawText(utf8.upper(currentStandingZone), bigmapPosX + 10 + 10.75, bigmapPosY + bigmapHeight - y_offset, bigmapPosX + 10 + 10.75 + standingZoneWidth, bigmapPosY + bigmapHeight - y_offset + zoneLineHeight, tocolor(255, 255, 255), 0.75, CenturyBold, "center", "center")

		if visibleBlipTooltip then
			visibleBlipTooltip = false
		end

		if mapMoveDifference then
			local resetTextWidth = dxGetTextWidth("A nézet visszaállításához nyomd meg a 'SPACE' gombot.", 0.75, CenturyBold) + 13.75
			
			dxDrawRectangle(bigmapPosX + 10, bigmapPosY + bigmapHeight - zoneLineHeight - 10, resetTextWidth, zoneLineHeight, tocolor(0, 0, 0, 200))
			dxDrawText("A nézet visszaállításához nyomd meg a 'SPACE' gombot.", bigmapPosX + 10, bigmapPosY + bigmapHeight - zoneLineHeight - 10, bigmapPosX + 10 + resetTextWidth, bigmapPosY + bigmapHeight - 10, tocolor(255, 255, 255), 0.75, CenturyBold, "center", "center")

			if getKeyState("space") then
				mapMoveDifference = false
				lastMapMovePos = false
			end
		end

		if (getElementData(localPlayer, "acc.adminLevel") or 0) >= 1 then
			local text = "Játékosok mutatása: " .. (canSeePlayers and "bekapcsolva" or "kikapcsolva")
			local textWidth = dxGetTextWidth(text, 0.75, CenturyBold) + 13.75
			
			y_offset = zoneLineHeight * 2 - size16px

			if isCursorWithinArea(cursorX, cursorY, bigmapPosX + bigmapWidth - textWidth - 10, bigmapPosY + bigmapHeight - y_offset, textWidth, zoneLineHeight) then
				showPlayersButtonHover = true
				dxDrawRectangle(bigmapPosX + bigmapWidth - textWidth - 10, bigmapPosY + bigmapHeight - y_offset, textWidth, zoneLineHeight, tocolor(50, 179, 239, 200))
			else
				dxDrawRectangle(bigmapPosX + bigmapWidth - textWidth - 10, bigmapPosY + bigmapHeight - y_offset, textWidth, zoneLineHeight, tocolor(0, 0, 0, 200))
			end

			dxDrawText(text, bigmapPosX + bigmapWidth - textWidth - 10, bigmapPosY + bigmapHeight - y_offset, bigmapPosX + bigmapWidth - 10, bigmapPosY + bigmapHeight - y_offset + zoneLineHeight, tocolor(255, 255, 255), 0.75, CenturyBold, "center", "center")
		end
	else
		renderLostConnection(bigmapPosX, bigmapPosY, bigmapWidth, bigmapHeight)
	end
end

function renderGPSNavigator(x, y, w, h)
	if gpsRoute or (not gpsRoute and waypointEndInterpolation) then
		local y2 = y + h

		local icon_middle_x = x
		local icon_middle_y = y + h + (gpsLineHeight - gpsLineIconSize) * 0.5

		if waypointEndInterpolation then
			local progress = (getTickCount() - waypointEndInterpolation) / 500
			local alpha_multipler = interpolateBetween(1, 0, 0, 0, 0, 0, progress, "OutQuad")

			dxDrawRectangle(x - 2, y2, w + 4, gpsLineHeight, tocolor(31, 31, 31, 240 * gpsNaviAlphaMul))

			local textWidth = dxGetTextWidth("0 m", 0.75, CenturyBold) + size8px
			icon_middle_x = x + (w - (gpsLineIconSize + textWidth)) * 0.5

			dxDrawImage(icon_middle_x, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/end.png", refreshAngle, 0, 0, tocolor(240, 200, 80, 255 * alpha_multipler))
			dxDrawText("0 m", icon_middle_x + gpsLineIconSize, icon_middle_y, icon_middle_x + gpsLineIconSize + textWidth, icon_middle_y + gpsLineIconSize, tocolor(240, 200, 80, 255 * alpha_multipler), 0.75, CenturyBold, "center", "center")

			if progress > 1 then
				waypointEndInterpolation = false
			end
		end

		if nextWp then
			local alpha255 = 255 * gpsNaviAlphaMul

			dxDrawRectangle(x - 2, y2, w + 4, gpsLineHeight, tocolor(31, 31, 31, 240 * gpsNaviAlphaMul))

			if currentWaypoint ~= nextWp and not tonumber(reRouting) then
				if nextWp > 1 then
					waypointInterpolation = {getTickCount(), currentWaypoint}
				end
				currentWaypoint = nextWp
			end

			if tonumber(reRouting) then
				currentWaypoint = nextWp

				local progress = (getTickCount() - reRouting) / 1250
				local refreshAngle, refreshDots = interpolateBetween(360, 0, 0, 0, 3, 0, progress, "Linear")

				local additionalDots = ""
				if refreshDots > 2 then
					additionalDots = additionalDots .. "..."
				elseif refreshDots > 1 then
					additionalDots = additionalDots .. ".."
				elseif refreshDots > 0 then
					additionalDots = additionalDots .. "."
				end

				local textWidth = dxGetTextWidth("Újratervezés", 0.75, CenturyBold) + size8px
				icon_middle_x = x + (w - (gpsLineIconSize + textWidth)) * 0.5

				dxDrawImage(icon_middle_x, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/refresh.png", refreshAngle, 0, 0, tocolor(240, 200, 80, alpha255))
				dxDrawText("Újratervezés" .. additionalDots, icon_middle_x + gpsLineIconSize + size8px, icon_middle_y, icon_middle_x + gpsLineIconSize + size8px + textWidth, icon_middle_y + gpsLineIconSize, tocolor(240, 200, 80, alpha255), 0.75, CenturyBold, "left", "center")

				if progress > 1 then
					reRouting = getTickCount()
				end
			elseif turnAround then
				currentWaypoint = nextWp

				local activeLabel = "Fordulj vissza!"
				local labelWidth = dxGetTextWidth(activeLabel, 0.75, CenturyBold) + size8px
				icon_middle_x = x + (w - (gpsLineIconSize + labelWidth)) * 0.5

				dxDrawImage(icon_middle_x, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/around.png", 0, 0, 0, tocolor(240, 200, 80, alpha255))
				dxDrawText(activeLabel, icon_middle_x + gpsLineIconSize, icon_middle_y, icon_middle_x + gpsLineIconSize + labelWidth, icon_middle_y + gpsLineIconSize, tocolor(240, 200, 80, alpha255), 0.75, CenturyBold, "center", "center")
			elseif not waypointInterpolation then
				local activeDistance = math.floor((gpsWaypoints[nextWp][3] or 0) / 10) * 10

				if activeDistance >= 1000 then
					activeDistance = activeDistance / 1000 .. " km"
				else
					activeDistance = activeDistance .. " m"
				end

				local activeDistanceWidth = dxGetTextWidth(activeDistance, 0.75, CenturyBold) + size8px
				icon_middle_x = x + (w - (gpsLineIconSize + activeDistanceWidth)) * 0.5

				dxDrawImage(icon_middle_x, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/" .. gpsWaypoints[nextWp][2] .. ".png", 0, 0, 0, tocolor(240, 200, 80, alpha255))
				dxDrawText(activeDistance, icon_middle_x + gpsLineIconSize, icon_middle_y, icon_middle_x + gpsLineIconSize + activeDistanceWidth, icon_middle_y + gpsLineIconSize, tocolor(240, 200, 80, alpha255), 0.75, CenturyBold, "center", "center")

				if gpsWaypoints[nextWp + 1] then
					dxDrawImage(x + size8px, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/" .. gpsWaypoints[nextWp + 1][2] .. ".png", 0, 0, 0, tocolor(93, 182, 229, alpha255))
				end
			else
				local activeDistance = math.floor((gpsWaypoints[waypointInterpolation[2]][3] or 0) / 10) * 10

				if activeDistance >= 1000 then
					activeDistance = activeDistance / 1000 .. " km"
				else
					activeDistance = activeDistance .. " m"
				end

				local nextDistance = math.floor((gpsWaypoints[waypointInterpolation[2] + 1][3] or 0) / 10) * 10

				if nextDistance >= 1000 then
					nextDistance = nextDistance / 1000 .. " km"
				else
					nextDistance = nextDistance .. " m"
				end

				local activeDistanceWidth = dxGetTextWidth(activeDistance, 0.75, CenturyBold) + size8px
				local nextDistanceWidth = dxGetTextWidth(nextDistance, 0.75, CenturyBold) + size8px

				icon_middle_x = x + (w - (gpsLineIconSize + activeDistanceWidth)) * 0.5

				local activeProgress, nextProgress = (getTickCount() - waypointInterpolation[1]) / 750, 0
				local activeItemAlpha, activeItemOffset, nextItemOffset = interpolateBetween(255, icon_middle_x, x + size8px, 0, x + w - (gpsLineIconSize + activeDistanceWidth), x + (w - (gpsLineIconSize + nextDistanceWidth)) * 0.5, activeProgress, "Linear")

				dxDrawImage(activeItemOffset, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/" .. gpsWaypoints[waypointInterpolation[2]][2] .. ".png", 0, 0, 0, tocolor(240, 200, 80, activeItemAlpha * gpsNaviAlphaMul))
				dxDrawText(activeDistance, activeItemOffset + gpsLineIconSize, icon_middle_y, activeItemOffset + gpsLineIconSize + activeDistanceWidth, icon_middle_y + gpsLineIconSize, tocolor(240, 200, 80, activeItemAlpha * gpsNaviAlphaMul), 0.75, CenturyBold, "center", "center")

				if gpsWaypoints[waypointInterpolation[2] + 1] then
					local r, g, b = interpolateBetween(93, 182, 229, 240, 200, 80, activeProgress, "Linear")
					local alpha = interpolateBetween(0, 0, 0, 255, 0, 0, activeProgress, "Linear") * gpsNaviAlphaMul

					dxDrawImage(nextItemOffset, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/" .. gpsWaypoints[waypointInterpolation[2] + 1][2] .. ".png", 0, 0, 0, tocolor(r, g, b, alpha255))
					dxDrawText(nextDistance, nextItemOffset + gpsLineIconSize, icon_middle_y, nextItemOffset + gpsLineIconSize + nextDistanceWidth, icon_middle_y + gpsLineIconSize, tocolor(r, g, b, alpha), 0.75, CenturyBold, "center", "center")
				end

				if activeProgress > 1 then
					nextProgress = (getTickCount() - waypointInterpolation[1] - 750) / 500
				end

				if gpsWaypoints[waypointInterpolation[2] + 2] then
					dxDrawImage(x + size8px, icon_middle_y, gpsLineIconSize, gpsLineIconSize, "widgets/radar/files/gps/" .. gpsWaypoints[waypointInterpolation[2] + 2][2] .. ".png", 0, 0, 0, tocolor(93, 182, 229, gpsNaviAlphaMul * interpolateBetween(0, 0, 0, 255, 0, 0, nextProgress, "Linear")))
				end

				if nextProgress > 1 then
					waypointInterpolation = false
				end
			end
		end
	end
end

function carCanGPS()
	if occupiedVehicle then
		local gpsVal = getElementData(occupiedVehicle, "vehicle.GPS") or 1

		if tonumber(gpsVal) then
			carCanGPSVal = tonumber(gpsVal)

			return true
		else
			return false
		end
	end

	return false
end

function addGPSLine(x, y)
	table.insert(gpsLines, {remapTheFirstWay(x), remapTheFirstWay(y)})
end

function processGPSLines()
	local routeStartPosX, routeStartPosY = 99999, 99999
	local routeEndPosX, routeEndPosY = -99999, -99999

	for i = 1, #gpsLines do
		local node = gpsLines[i]

		if node[1] < routeStartPosX then
			routeStartPosX = node[1]
		end

		if node[2] < routeStartPosY then
			routeStartPosY = node[2]
		end

		if node[1] > routeEndPosX then
			routeEndPosX = node[1]
		end

		if node[2] > routeEndPosY then
			routeEndPosY = node[2]
		end
	end

	local routeWidth = (routeEndPosX - routeStartPosX) + 16
	local routeHeight = (routeEndPosY - routeStartPosY) + 16

	if isElement(gpsRouteImage) then
		destroyElement(gpsRouteImage)
	end

	local routeRenderTarget = dxCreateRenderTarget(routeWidth, routeHeight, true)
	gpsRouteImageData = {routeStartPosX - 8, routeStartPosY - 8, routeWidth, routeHeight}

	dxSetRenderTarget(routeRenderTarget)
	dxSetBlendMode("modulate_add")

	dxDrawImage(gpsLines[1][1] - routeStartPosX + 4, gpsLines[1][2] - routeStartPosY + 4, 8, 8, "widgets/radar/files/gps/dot.png")
	dxDrawImage(gpsLines[#gpsLines][1] - routeStartPosX, gpsLines[#gpsLines][2] - routeStartPosY, 16, 16, "widgets/radar/files/gps/dot.png")

	for i = 2, #gpsLines do
		local j = i - 1

		if gpsLines[j] then
			local x0 = gpsLines[i][1] - routeStartPosX + 8
			local y0 = gpsLines[i][2] - routeStartPosY + 8
			local x1 = gpsLines[j][1] - routeStartPosX + 8
			local y1 = gpsLines[j][2] - routeStartPosY + 8

			dxDrawImage(x0 - 4, y0 - 4, 8, 8, "widgets/radar/files/gps/dot.png")
			dxDrawLine(x0, y0, x1, y1, tocolor(255, 255, 255), 9)
		end
	end

	dxSetBlendMode("blend")
	dxSetRenderTarget()

	if isElement(routeRenderTarget) then
		gpsRouteImage = dxCreateTexture(dxConvertPixels(dxGetTexturePixels(routeRenderTarget), "png"))

		destroyElement(routeRenderTarget)

		routeRenderTarget = nil
	end
end

function clearGPSRoute()
	gpsLines = {}

	if isElement(gpsRouteImage) then
		destroyElement(gpsRouteImage)
	end

	gpsRouteImage = nil
end

function renderBlip(icon, blipX, blipY, playerX, playerY, blipWidth, blipHeight, blipColor, cameraRotation, farShow, blipTableId, cosinus, sinus)
	local blipPosX = minimapRenderHalfSize + (playerX - remapTheFirstWay(blipX)) * minimapZoom
	local blipPosY = minimapRenderHalfSize - (playerY - remapTheFirstWay(blipY)) * minimapZoom

	if not farShow and (blipPosX > minimapRenderSize or 0 > blipPosX or blipPosY > minimapRenderSize or 0 > blipPosY) then
		return
	end

	local blipInnerBounds = true

	if farShow then
		if blipPosX > minimapRenderSize then
			blipPosX = minimapRenderSize
		end

		if blipPosX < 0 then
			blipPosX = 0
		end

		if blipPosY > minimapRenderSize then
			blipPosY = minimapRenderSize
		end

		if blipPosY < 0 then
			blipPosY = 0
		end

		local blipMapPosX = minimapPosX - minimapRenderHalfSize + minimapWidth * 0.5 + (minimapRenderHalfSize + cosinus * (blipPosX - minimapRenderHalfSize) - sinus * (blipPosY - minimapRenderHalfSize) - blipWidth * 0.5)
		local blipMapPosY = minimapPosY - minimapRenderHalfSize + minimapHeight * 0.5 + (minimapRenderHalfSize + sinus * (blipPosX - minimapRenderHalfSize) + cosinus * (blipPosY - minimapRenderHalfSize) - blipHeight * 0.5)

		farshowBlips[blipTableId] = nil

		if blipMapPosX < minimapPosX then
			blipInnerBounds = false
			blipMapPosX = minimapPosX
		end

		if blipMapPosX > minimapPosX + minimapWidth - blipWidth then
			blipInnerBounds = false
			blipMapPosX = minimapPosX + minimapWidth - blipWidth
		end

		if blipMapPosY < minimapPosY then
			blipInnerBounds = false
			blipMapPosY = minimapPosY
		end

		if blipMapPosY > minimapPosY + minimapHeight - blipHeight then
			blipInnerBounds = false
			blipMapPosY = minimapPosY + minimapHeight - blipHeight
		end

		if not blipInnerBounds then
			farshowBlips[blipTableId] = true
		end

		if farshowBlips[blipTableId] then
			farshowBlipsData[blipTableId] = {
				posX = blipMapPosX,
				posY = blipMapPosY,
				icon = icon,
				iconWidth = blipWidth,
				iconHeight = blipHeight,
				color = blipColor
			}
		end
	end

	if blipInnerBounds then
		if blipTextures[icon] then
			dxDrawImage(blipPosX - blipWidth * 0.5, blipPosY - blipHeight * 0.5, blipWidth, blipHeight, blipTextures[icon], 180 - cameraRotation, 0, 0, blipColor)
		else
			dxDrawImage(blipPosX - blipWidth * 0.5, blipPosY - blipHeight * 0.5, blipWidth, blipHeight, "widgets/radar/files/blips/" .. icon, 180 - cameraRotation, 0, 0, blipColor)
		end
	end
end

function renderBigBlip(icon, blipX, blipY, playerX, playerY, renderDistance, blipWidth, blipHeight, blipColor, blipElement, blipId, tooltipText)
	if renderDistance and getDistanceBetweenPoints2D(playerX, playerY, blipX, blipY) > renderDistance then
		return
	end

	blipWidth = (blipWidth / (4 - bigmapZoom) + 3) * 2.25
	blipHeight = (blipHeight / (4 - bigmapZoom) + 3) * 2.25

	local blipHalfWidth = blipWidth * 0.5
	local blipHalfHeight = blipHeight * 0.5

	blipX = bigmapCenterX + (remapTheFirstWay(playerX) - remapTheFirstWay(blipX)) * bigmapZoom
	blipY = bigmapCenterY - (remapTheFirstWay(playerY) - remapTheFirstWay(blipY)) * bigmapZoom

	local thisBlipOnBorder = false

	if blipX < bigmapPosX + blipHalfWidth then
		blipX = bigmapPosX + blipHalfWidth
		thisBlipOnBorder = true
	end

	if blipX > bigmapPosX + bigmapWidth - blipHalfWidth then
		blipX = bigmapPosX + bigmapWidth - blipHalfWidth
		thisBlipOnBorder = true
	end

	if blipY < bigmapPosY + blipHalfHeight then
		blipY = bigmapPosY + blipHalfHeight
		thisBlipOnBorder = true
	end

	if blipY > bigmapPosY + bigmapHeight - blipHalfHeight then
		blipY = bigmapPosY + bigmapHeight - blipHalfHeight
		thisBlipOnBorder = true
	end

	local thisBlipHovered = false

	if cursorX and cursorY and not visibleBlipTooltip then
		if isElement(blipElement) then
			if isCursorWithinArea(cursorX, cursorY, blipX - blipHalfWidth, blipY - blipHalfHeight, blipWidth, blipHeight) then
				if tooltipText then
					visibleBlipTooltip = tooltipText
					thisBlipHovered = true
				elseif blipTooltips[blipElement] then
					visibleBlipTooltip = blipTooltips[blipElement]
					thisBlipHovered = true
				elseif getElementType(blipElement) == "player" and canSeePlayers then
					if getElementData(blipElement, "loggedIn") then
						visibleBlipTooltip = utf8.gsub(utf8.gsub(getPlayerName(blipElement), "#%x%x%x%x%x%x", ""), "_", " ") .. " (" .. getElementData(blipElement, "playerID") .. ")"
						
						if getElementData(blipElement, "adminDuty") then
							visibleBlipTooltip = "[" .. exports.sarp_core:getPlayerAdminTitle(blipElement) .. "] " .. utf8.gsub(utf8.gsub(getElementData(blipElement, "acc.adminNick"), "#%x%x%x%x%x%x", ""), "_", " ") .. " (" .. getElementData(blipElement, "playerID") .. ")"
						end

						thisBlipHovered = true
					end
				end
			end
		elseif isCursorWithinArea(cursorX, cursorY, blipX - blipHalfWidth, blipY - blipHalfHeight, blipWidth, blipHeight) then
			if tooltipText then
				visibleBlipTooltip = tooltipText
				thisBlipHovered = true
			elseif blipTooltips[icon] then
				visibleBlipTooltip = blipTooltips[icon]
				thisBlipHovered = true
			end
		end
	end

	if thisBlipHovered and not thisBlipOnBorder then
		blipWidth, blipHeight = blipWidth * 1.25, blipHeight * 1.25
		blipHalfWidth, blipHalfHeight = blipWidth * 0.5, blipHeight * 0.5
	end

	if icon == "arrow.png" then
		local localRx, localRy, localRz = getElementRotation(localPlayer)

		dxDrawImage(blipX - blipHalfWidth, blipY - blipHalfHeight, blipWidth, blipHeight, "widgets/radar/files/" .. icon, math.abs(360 - localRz))
	elseif blipTextures[icon] then
		dxDrawImage(blipX - blipHalfWidth, blipY - blipHalfHeight, blipWidth, blipHeight, blipTextures[icon], 0, 0, 0, blipColor)
	else
		dxDrawImage(blipX - blipHalfWidth, blipY - blipHalfHeight, blipWidth, blipHeight, "widgets/radar/files/blips/" .. icon, 0, 0, 0, blipColor)
	end
end

function renderLostConnection(x, y, w, h)
	if not lostSignalStartTick then
		lostSignalStartTick = getTickCount()
	end

	local fadeAlpha = 1
	if not lostSignalFadeIn then
		fadeAlpha = 1
	else
		fadeAlpha = 0
	end

	local lostSignalTick = (getTickCount() - lostSignalStartTick) / 1500
	if lostSignalTick > 1 then
		lostSignalStartTick = getTickCount()
		lostSignalFadeIn = not lostSignalFadeIn
	end

	local alphaMul = interpolateBetween(fadeAlpha, 0, 0, 1 - fadeAlpha, 0, 0, lostSignalTick, "Linear")
	dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 200))
	dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 100 * alphaMul))
	dxDrawText("Nincs kapcsolat...", x, y, x + w, y + h, tocolor(255, 255, 255, 255 * alphaMul), 1, CenturyBold, "center", "center")
end

function createCustomBlip(x, y, z, icon, farShow, visibleDistance, size, color)
	local blipID = #createdBlips + 1

	createdBlips[blipID] = {
		posX = x,
		posY = y,
		posZ = z,
		icon = icon,
		farShow = farShow,
		renderDistance = visibleDistance or 99999,
		iconSize = size or 22,
		color = color or tocolor(255, 255, 255)
	}

	return blipID
end

function setCustomBlipTooltip(blipID, text)
	if createdBlips[blipID] then
		createdBlips[blipID].tooltipText = text
	end
end

function remapTheFirstWay(coord)
	return (-coord + 3000) / mapRatio
end

function remapTheSecondWay(coord)
	return (coord + 3000) / mapRatio
end

function getVehicleSpeed(vehicle)
	if isElement(vehicle) then
		local velocityX, velocityY, velocityZ = getElementVelocity(vehicle)
		return math.sqrt(velocityX * velocityX + velocityY * velocityY + velocityZ * velocityZ) * 187.5
	end
end

function dxDrawOuterBorder(x, y, w, h, borderSize, borderColor, postGUI)
	borderSize = borderSize or 2
	borderColor = borderColor or tocolor(0, 0, 0, 255)

	dxDrawRectangle(x - borderSize, y - borderSize, w + (borderSize * 2), borderSize, borderColor, postGUI)
	dxDrawRectangle(x, y + h, w, borderSize, borderColor, postGUI)
	dxDrawRectangle(x - borderSize, y, borderSize, h + borderSize, borderColor, postGUI)
	dxDrawRectangle(x + w, y, borderSize, h + borderSize, borderColor, postGUI)
end

function isCursorWithinArea(cx, cy, x, y, w, h)
	if isCursorShowing() then
		if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
			return true
		end
	end

	return false
end
