pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

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
		return "Ismeretlen"
	end

	if zoneName == "Unknown" or cityName == "Unknown" then
		return "Ismeretlen"
	end

	return zoneName
end

local screenSource = dxCreateScreenSource(screenX, screenY)

local mapPicture = dxCreateTexture("widgets/radar/files/map.png")
dxSetTextureEdge(mapPicture, "border", tocolor(0, 0, 0, 0))

local pictureSize = 1600
local mapScaleFactor = 6000 / pictureSize
local mapUnit = pictureSize / 6000

local panelWidth = respc(330)
local panelHeight = respc(190)
local panelPosX = 0
local panelPosY = 0

local renderTargetSize = math.ceil((panelWidth + panelHeight) * 0.85)
local renderTarget = dxCreateRenderTarget(renderTargetSize, renderTargetSize)

local zoomValue = 0.7
local zoom = zoomValue

local blipPictures = {}

createdBlips = {}

function delCustomBlip(blipId)
	table.remove(createdBlips, blipId)
end

function addCustomBlip(data)
	table.insert(createdBlips, {
		blipPosX = data[1],
		blipPosY = data[2],
		blipPosZ = data[3],
		blipId = data[4],
		farShow = data[6],
		renderDistance = 9999,
		iconSize = data[5] or 14.5,
		blipColor = data[7] or tocolor(255, 255, 255)
	})

	return #createdBlips
end

local blipData = {}

carCanGPSVal = false

local gpsLines = {}
local gpsRoutePicture = false
local gpsRoutePos = {}
local gpsLineColor = tocolor(50, 179, 239)

function carCanGPS()
	carCanGPSVal = false

	if occupiedVehicle then
		local gpsVal = getElementData(occupiedVehicle, "vehicle.GPS") or 1

		if tonumber(gpsVal) then
			carCanGPSVal = tonumber(gpsVal)

			if gpsVal == 2 then
				carCanGPSVal = "off"
			end
		else
			carCanGPSVal = false

			if getElementData(occupiedVehicle, "gpsDestination") then
				setElementData(occupiedVehicle, "gpsDestination", false)
			end
		end
	end

	return carCanGPSVal
end

function addGPSLine(x, y)
	table.insert(gpsLines, {remapTheFirstWay(x), remapTheFirstWay(y)})
end

function clearGPSRoute()
	gpsLines = {}

	if isElement(gpsRoutePicture) then
		destroyElement(gpsRoutePicture)
	end

	gpsRoutePicture = nil
end

function processGPSLines()
	local minX, minY = 99999, 99999
	local maxX, maxY = -99999, -99999

	for k = 1, #gpsLines do
		local v = gpsLines[k]

		if v[1] < minX then
			minX = v[1]
		end

		if v[1] > maxX then
			maxX = v[1]
		end

		if v[2] < minY then
			minY = v[2]
		end

		if v[2] > maxY then
			maxY = v[2]
		end
	end

	local sx = maxX - minX + 16
	local sy = maxY - minY + 16

	gpsRoutePos = {minX - 8, minY - 8, sx, sy}

	if isElement(gpsRoutePicture) then
		destroyElement(gpsRoutePicture)
	end

	gpsRoutePicture = dxCreateRenderTarget(sx, sy, true)

	dxSetRenderTarget(gpsRoutePicture)
	dxSetBlendMode("modulate_add")

	dxDrawImage(gpsLines[1][1] - minX + 4, gpsLines[1][2] - minY + 4, 8, 8, "widgets/radar/files/gps/dot.png")
	dxDrawImage(gpsLines[#gpsLines][1] - minX, gpsLines[#gpsLines][2] - minY, 16, 16, "widgets/radar/files/gps/dot.png")

	for k = 2, #gpsLines do
		local k2 = k - 1

		if gpsLines[k2] then
			dxDrawImage(gpsLines[k][1] - minX + 4, gpsLines[k][2] - minY + 4, 8, 8, "widgets/radar/files/gps/dot.png")

			dxDrawLine(gpsLines[k][1] - minX + 8, gpsLines[k][2] - minY + 8, gpsLines[k2][1] - minX + 8, gpsLines[k2][2] - minY + 8, tocolor(255, 255, 255), 9)
		end
	end

	dxSetBlendMode("blend")
	dxSetRenderTarget()
end

addEventHandler("onClientRestore", getRootElement(),
	function ()
		if gpsRoute then
			processGPSLines()
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for k, v in ipairs(getElementsByType("blip")) do
			blipData[v] = {}
			blipData[v].icon = getElementData(v, "blipIcon") or "target"
			blipData[v].size = getElementData(v, "blipSize") or 14.5
			blipData[v].color = getElementData(v, "blipColor")
			blipData[v].tooltip = getElementData(v, "blipTooltipText")
			blipData[v].farShow = getElementData(v, "blipFarShow") or true
		end

		for k, v in ipairs(defaultBlips) do
			if not blipPictures[v[4]] then
				blipPictures[v[4]] = dxCreateTexture("widgets/radar/files/blips/" .. v[4])
			end

			v[5] = v[5] or 22
			v[6] = v[6] or false
			v[7] = v[7] or 9999
			v[8] = v[8] or tocolor(255, 255, 255)

			table.insert(createdBlips, {
				blipPosX = v[1],
				blipPosY = v[2],
				blipPosZ = v[3],
				blipId = v[4],
				iconSize = v[5],
				farShow = v[6],
				renderDistance = v[7],
				blipColor = v[8]
			})
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if getElementType(source) == "blip" then
			if not blipData[source] then
				blipData[source] = {}
			end

			if dataName == "blipIcon" then
				blipData[source].icon = getElementData(source, "blipIcon") or "target"
			elseif dataName == "blipSize" then
				blipData[source].size = getElementData(source, "blipSize") or 14.5
			elseif dataName == "blipColor" then
				blipData[source].color = getElementData(source, "blipColor")
			elseif dataName == "blipTooltipText" then
				blipData[source].tooltip = getElementData(source, "blipTooltipText")
			elseif dataName == "blipFarShow" then
				blipData[source].farShow = getElementData(source, "blipFarShow") or true
			end
		elseif source == occupiedVehicle then
			if dataName == "gpsDestination" then
				local value = getElementData(source, "gpsDestination")

				if value then
					gpsThread = coroutine.create(makeRoute)

					coroutine.resume(gpsThread, unpack(value))

					waypointInterpolation = false
				else
					endRoute()
				end
			end
		end
	end
)

addEventHandler("onClientElementDestroy", getRootElement(),
	function ()
		if getElementType(source) == "blip" then
			blipData[source] = nil
		end
	end
)

function remapTheFirstWay(x)
	return (-x + 3000) / mapScaleFactor
end

function remapTheSecondWay(x)
	return (x + 3000) / mapScaleFactor
end

function rotateAround(angle, x, y, x2, y2)
	local centerX, centerY = x, y
	local targetX, targetY = x2 or 0, y2 or 0

	local rotatedX = centerX + (targetX - centerX) * math.cos(angle) - (targetY - centerY) * math.sin(angle)
	local rotatedY = centerY + (targetX - centerX) * math.sin(angle) + (targetY - centerY) * math.cos(angle)

	return rotatedX, rotatedY
end

local farBlips = {}

function renderBlip(icon, blipX, blipY, middleX, middleY, width, height, color, farShow, cameraRotZ, k)
	local x = 0 + renderTargetSize / 2 + (remapTheFirstWay(middleX) - remapTheFirstWay(blipX)) * zoom
	local y = 0 + renderTargetSize / 2 - (remapTheFirstWay(middleY) - remapTheFirstWay(blipY)) * zoom

	if not farShow and (x > renderTargetSize or x < 0 or y > renderTargetSize or y < 0) then
		return
	end

	local render = true

	if farShow then
		if icon == 0 then
			width = width / 1.5
			height = height / 1.5
		end

		if x > renderTargetSize then
			x = renderTargetSize
		elseif x < 0 then
			x = 0
		end

		if y > renderTargetSize then
			y = renderTargetSize
		elseif y < 0 then
			y = 0
		end

		local x2, y2 = rotateAround(math.rad(cameraRotZ), renderTargetSize / 2, renderTargetSize / 2, x, y)

		x2 = x2 + panelPosX - renderTargetSize / 2 + (panelWidth - width) / 2
		y2 = y2 + panelPosY - renderTargetSize / 2 + (panelHeight - height) / 2

		farBlips[k] = nil

		if x2 < panelPosX then
			render = false
			x2 = panelPosX
		elseif x2 > panelPosX + panelWidth - width then
			render = false
			x2 = panelPosX + panelWidth - width
		end

		if y2 < panelPosY then
			render = false
			y2 = panelPosY
		elseif y2 > panelPosY + panelHeight - height then
			render = false
			y2 = panelPosY + panelHeight - height
		end

		if not render then
			farBlips[k] = {x2, y2, width, height, icon, color}
		end
	end

	if render then
		if blipPictures[icon] then
			dxDrawImage(x - width / 2, y - height / 2, width, height, blipPictures[icon], 360 - cameraRotZ, 0, 0, color)
		else
			dxDrawImage(x - width / 2, y - height / 2, width, height, "widgets/radar/files/blips/" .. icon, 360 - cameraRotZ, 0, 0, color)
		end
	end
end

render.minimap = function (x, y)
	-- ** Pozíciók és méretek frissítése
	panelWidth, panelHeight = widgets.minimap.sizeX, widgets.minimap.sizeY - resp(30)

	local size = math.ceil((panelWidth + panelHeight) * 0.85)

	if math.abs(size - renderTargetSize) > 10 then
		renderTargetSize = size

		if isElement(renderTarget) then
			destroyElement(renderTarget)
		end

		renderTarget = dxCreateRenderTarget(renderTargetSize, renderTargetSize)
	end

	panelPosX, panelPosY = x, y

	-- ** Térkép zoomolása
	if getKeyState("num_add") and zoomValue < 1.2 then
		zoomValue = zoomValue + 0.01
	elseif getKeyState("num_sub") and zoomValue > 0.3 then
		zoomValue = zoomValue - 0.01
	end

	zoom = zoomValue

	-- ** Gyorsulás hatása a térképre
	if isElement(occupiedVehicle) then
		local velocityX, velocityY, velocityZ = getElementVelocity(occupiedVehicle)
		local factor = getDistanceBetweenPoints3D(0, 0, 0, velocityX, velocityY, velocityZ) * 180 / 1300

		if factor >= 0.4 then
			factor = 0.4
		end

		zoom = zoom - factor
	end

	-- ** Térkép
	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
	local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
	local playerDimension = getElementDimension(localPlayer)

	if playerDimension == 0 and playerPosZ <= 10000 then
		local cameraRotX, cameraRotY, cameraRotZ = getElementRotation(getCamera())

		farBlips = {}

		dxUpdateScreenSource(screenSource, true)

		dxSetRenderTarget(renderTarget)
		dxSetBlendMode("modulate_add")

		dxDrawRectangle(0, 0, renderTargetSize, renderTargetSize, tocolor(22, 98, 173))
		dxDrawImageSection(0, 0, renderTargetSize, renderTargetSize, remapTheSecondWay(playerPosX) - renderTargetSize / zoom / 2, remapTheFirstWay(playerPosY) - renderTargetSize / zoom / 2, renderTargetSize / zoom, renderTargetSize / zoom, mapPicture)

		if gpsRoutePicture then
			dxDrawImage(
				renderTargetSize / 2 + (remapTheFirstWay(playerPosX) - (gpsRoutePos[1] + gpsRoutePos[3] / 2)) * zoom - gpsRoutePos[3] * zoom / 2,
				renderTargetSize / 2 - (remapTheFirstWay(playerPosY) - (gpsRoutePos[2] + gpsRoutePos[4] / 2)) * zoom + gpsRoutePos[4] * zoom / 2,
				gpsRoutePos[3] * zoom,
				-(gpsRoutePos[4] * zoom),
				gpsRoutePicture,
				180, 0, 0,
				gpsLineColor
			)
		end

		local blipCount = 0

		for k = 1, #createdBlips do
			local v = createdBlips[k]

			if v then
				blipCount = blipCount + 1

				renderBlip(v.blipId, v.blipPosX, v.blipPosY, playerPosX, playerPosY, v.iconSize, v.iconSize, v.blipColor, v.farShow, cameraRotZ, blipCount)
			end
		end

		local blips = getElementsByType("blip")
		for k = 1, #blips do
			local v = blips[k]

			if v then
				local v2 = blipData[v]

				if v2 then
					local x, y = getElementPosition(v)
					
					if not v2.color then
						v2.color = tocolor(getBlipColor(v))
					end

					if not v2.size then
						v2.size = 14.5
					end

					blipCount = blipCount + 1

					renderBlip(v2.icon .. ".png", x, y, playerPosX, playerPosY, v2.size, v2.size, v2.color, v2.farShow, cameraRotZ, blipCount)
				end
			end
		end

		dxSetBlendMode("blend")
		dxSetRenderTarget()

		dxDrawImage(panelPosX - renderTargetSize / 2 + panelWidth / 2, panelPosY - renderTargetSize / 2 + panelHeight / 2, renderTargetSize, renderTargetSize, renderTarget, cameraRotZ)
		dxDrawImage(panelPosX, panelPosY, panelWidth, panelHeight, "files/vin2.png")
		
		-- ** Kereten lévő blipek
		for k, v in pairs(farBlips) do
			if blipPictures[v[5]] then
				dxDrawImage(v[1], v[2], v[3], v[4], blipPictures[v[5]], 0, 0, 0, v[6])
			else
				dxDrawImage(v[1], v[2], v[3], v[4], "widgets/radar/files/blips/" .. v[5], 0, 0, 0, v[6])
			end
		end

		-- ** Kliens pozíciója
		local size = 60 / (4 - zoom) + 3

		dxDrawImage(panelPosX + (panelWidth - size) / 2, panelPosY + (panelHeight - size) / 2, size, size, "widgets/radar/files/arrow.png", cameraRotZ + math.abs(360 - playerRotZ))

		-- ** Képernyőforrás
		splitImageAroundRectangle(screenSource, panelPosX, panelPosY, panelWidth, panelHeight, respc(renderTargetSize * 0.75))

		-- ** Keret
		dxDrawRectangle(panelPosX - 2, panelPosY - 2, panelWidth + 4, 2, tocolor(0, 0, 0, 200)) -- felső
		dxDrawRectangle(panelPosX - 2, panelPosY + panelHeight, panelWidth + 4, resp(30), tocolor(0, 0, 0, 200)) -- alsó
		dxDrawRectangle(panelPosX - 2, panelPosY, 2, panelHeight, tocolor(0, 0, 0, 200)) -- bal
		dxDrawRectangle(panelPosX + panelWidth, panelPosY, 2, panelHeight, tocolor(0, 0, 0, 200)) -- jobb

		-- ** GPS Lokátor
		dxDrawImage(panelPosX + 3, panelPosY + panelHeight + 3, resp(30) - 6, resp(30) - 6, ":sarp_assets/images/map/location.png")

		dxDrawText(getZoneName(playerPosX, playerPosY, playerPosZ), panelPosX + 3 + resp(30), panelPosY + panelHeight, panelPosX + panelWidth, panelPosY + panelHeight + resp(30), tocolor(255, 255, 255), 0.75, RobotoL18, "left", "center", true)
	
		drawNavi(panelPosX, panelPosY, panelWidth, panelHeight)
	else
		dxDrawRectangle(panelPosX - 2, panelPosY - 2, panelWidth + 4, 2, tocolor(0, 0, 0, 200)) -- felső
		dxDrawRectangle(panelPosX - 2, panelPosY + panelHeight, panelWidth + 4, resp(30), tocolor(0, 0, 0, 200)) -- alsó
		dxDrawRectangle(panelPosX - 2, panelPosY, 2, panelHeight, tocolor(0, 0, 0, 200)) -- bal
		dxDrawRectangle(panelPosX + panelWidth, panelPosY, 2, panelHeight, tocolor(0, 0, 0, 200)) -- jobb

		drawLostSignal(panelPosX, panelPosY, panelWidth, panelHeight)
	end
end

local signalInterpolation = false
local signalState = false

function drawLostSignal(x, y, sx, sy)
	if not signalInterpolation then
		signalInterpolation = getTickCount()
	end

	local sum = 1

	if not signalState then
		sum = 1
	else
		sum = 0
	end

	local elapsedTime = getTickCount() - signalInterpolation
	local progress = elapsedTime / 1500

	if progress > 1 then
		signalInterpolation = getTickCount()
		signalState = not signalState
	end

	local alpha = interpolateBetween(
		sum, 0, 0,
		1 - sum, 0, 0,
		progress, "Linear"
	)

	dxDrawRectangle(x, y, sx, sy, tocolor(0, 0, 0, 225))

	dxDrawImage(math.floor(x + (sx - respc(128)) / 2), math.floor(y + (sy - respc(128)) / 2), respc(128), respc(128), "widgets/radar/files/loader.png", getTickCount() / 5 % 360, 0, 0, tocolor(255, 255, 255, 40))

	dxDrawText("NINCS JEL", x, y, x + sx, y + sy, tocolor(255, 255, 255, 255 * alpha), 1, RobotoL18, "center", "center")

	dxDrawImage(x, y, sx, sy, "files/lights.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
end

function splitImageAroundRectangle(image, x, y, sx, sy, margin)
	dxDrawImageSection(x - margin, y - margin, sx + margin * 2, margin, x - margin, y - margin, sx + margin * 2, margin, image) -- felsó
	dxDrawImageSection(x - margin, y + sy, sx + margin * 2, margin, x - margin, y + sy, sx + margin * 2, margin, image) -- alsó
	dxDrawImageSection(x - margin, y, margin, sy, x - margin, y, margin, sy, image) -- bal
	dxDrawImageSection(x + sx, y, margin, sy, x + sx, y, margin, sy, image) -- jobb
end

function drawNavi(x, y, sx, sy)
	if gpsRoute or (not gpsRoute and waypointEndInterpolation) then
		local iconSize = resp(40)

		y = y - 2 - resp(50)

		if waypointEndInterpolation then
			local elapsedTime = getTickCount() - waypointEndInterpolation
			local progress = elapsedTime / 500

			local alpha = interpolateBetween(
				1, 0, 0,
				0, 0, 0,
				progress, "Linear"
			)

			dxDrawRectangle(x - 2, y, sx + 4, resp(50), tocolor(0, 0, 0, 200 * alpha))

			local textWidth = dxGetTextWidth("0 m", 0.75, Roboto18)
			local x2 = x + (sx - (iconSize + textWidth)) / 2

			dxDrawImage(x2, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/end.png", angle, 0, 0, tocolor(50, 179, 239, 255 * alpha))
			dxDrawText("0 m", x2 + resp(8) + iconSize, y, 0, y + resp(50), tocolor(50, 179, 239, 255 * alpha), 0.75, Roboto18, "left", "center")

			if progress > 1 then
				waypointEndInterpolation = false
			end
		elseif nextWp then
			dxDrawRectangle(x - 2, y, sx + 4, resp(50), tocolor(0, 0, 0, 200))

			if currentWaypoint ~= nextWp and not tonumber(reRouting) then
				if nextWp > 1 then
					waypointInterpolation = {getTickCount(), currentWaypoint}
				end

				currentWaypoint = nextWp
			end

			if tonumber(reRouting) then
				currentWaypoint = nextWp

				local elapsedTime = getTickCount() - reRouting
				local progress = elapsedTime / 1250

				local angle, section = interpolateBetween(
					360, 0, 0,
					0, 3, 0,
					progress, "Linear"
				)

				local dots = ""

				if section > 2 then
					dots =  "..."
				elseif section > 1 then
					dots =  ".."
				elseif section > 0 then
					dots = "."
				end

				local textWidth = dxGetTextWidth("Újratervezés...", 0.75, Roboto18)
				local x2 = x + (sx - (iconSize + textWidth)) / 2

				dxDrawImage(x2, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/refresh.png", angle, 0, 0, tocolor(50, 179, 239, 255))
				dxDrawText("Újratervezés" .. dots, x2 + resp(8) + iconSize, y, 0, y + resp(50), tocolor(50, 179, 239, 255), 0.75, Roboto18, "left", "center")

				if progress > 1 then
					reRouting = getTickCount()
				end
			elseif turnAround then
				currentWaypoint = nextWp

				local textWidth = dxGetTextWidth("Fordulj vissza!", 0.75, Roboto18)
				local x2 = x + (sx - (iconSize + textWidth)) / 2

				dxDrawImage(x2, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/around.png", 0, 0, 0, tocolor(50, 179, 239, 255))
				dxDrawText("Fordulj vissza!", x2 + resp(8) + iconSize, y, 0, y + resp(50), tocolor(50, 179, 239, 255), 0.75, Roboto18, "left", "center")
			elseif not waypointInterpolation then
				local dist = math.floor((gpsWaypoints[nextWp][3] or 0) / 10) * 10

				if dist >= 1000 then
					dist = dist / 1000 .. " km"
				else
					dist = dist .. " m"
				end

				local textWidth = dxGetTextWidth(dist, 0.75, Roboto18)
				local x2 = x + (sx - (iconSize + textWidth)) / 2

				dxDrawImage(x2, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/" .. gpsWaypoints[nextWp][2] .. ".png", 0, 0, 0, tocolor(50, 179, 239, 255))
				dxDrawText(dist, x2 + resp(8) + iconSize, y, 0, y + resp(50), tocolor(50, 179, 239, 255), 0.75, Roboto18, "left", "center")

				if gpsWaypoints[nextWp + 1] then
					dxDrawImage(x + resp(8), y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/" .. gpsWaypoints[nextWp+1][2] .. ".png", 0, 0, 0, tocolor(100, 100, 100, 255))
				end
			else
				local wp = waypointInterpolation[2]

				local currentDist = math.floor((gpsWaypoints[wp][3] or 0) / 10) * 10
				local nextDist = math.floor((gpsWaypoints[wp + 1][3] or 0) / 10) * 10

				if currentDist >= 1000 then
					currentDist = currentDist / 1000 .. " km"
				else
					currentDist = currentDist .. " m"
				end

				if nextDist >= 1000 then
					nextDist = nextDist / 1000 .. " km"
				else
					nextDist = nextDist .. " m"
				end

				local currentDistWidth = sx - iconSize - dxGetTextWidth(currentDist, 0.75, Roboto18)
				local nextDistWidth = sx - iconSize - dxGetTextWidth(nextDist, 0.75, Roboto18)

				local elapsedTime = getTickCount() - waypointInterpolation[1]
				local progress = elapsedTime / 1500

				if progress > 1 then
					progress = 1
				end

				local alpha, currentX, nextX = interpolateBetween(
					255, currentDistWidth / 2, resp(8),
					0, currentDistWidth, nextDistWidth / 2,
					progress, "InOutQuad"
				)

				dxDrawImage(x + currentX, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/" .. gpsWaypoints[wp][2] .. ".png", 0, 0, 0, tocolor(50, 179, 239, alpha))
				dxDrawText(currentDist, x + currentX + resp(8) + iconSize, y, 0, y + resp(50), tocolor(50, 179, 239, alpha), 0.75, Roboto18, "left", "center")

				if gpsWaypoints[wp + 1] then
					local r, g, b = interpolateBetween(
						100, 100, 100,
						50, 179, 239,
						progress, "InOutQuad"
					)

					dxDrawImage(x + nextX, y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/" .. gpsWaypoints[wp + 1][2] .. ".png", 0, 0, 0, tocolor(r, g, b, 255))
					dxDrawText(nextDist, x + nextX + resp(8) + iconSize, y, 0, y + resp(50), tocolor(r, g, b, 255 - alpha), 0.75, Roboto18, "left", "center")
				end

				if progress >= 1 then
					local elapsedTime = getTickCount() - waypointInterpolation[1] - 1500
					local progress = elapsedTime / 500

					if gpsWaypoints[wp + 2] then
						if progress > 1 then
							progress = 1
						end

						dxDrawImage(x + resp(8), y + (resp(50) - iconSize) / 2, iconSize, iconSize, "widgets/radar/files/gps/" .. gpsWaypoints[wp + 2][2] .. ".png", 0, 0, 0, tocolor(100, 100, 100, 255 * progress))
					end

					if progress >= 1 then
						waypointInterpolation = false
					end
				end
			end
		end
	end
end

local bigRadarState = false

local panelWidth = screenX
local panelHeight = screenY
local panelPosX = 0
local panelPosY = 0

local zoom = 0.5
local targetZoom = zoom

local cursorX, cursorY = -1, -1
local lastCursorPos = false
local cursorMoveDiff = false

local mapMoveDiff = false
local lastMapMovePos = false
local mapIsMoving = false

local lastMapPosX, lastMapPosY = 0, 0
local mapPlayerPosX, mapPlayerPosY = 0, 0

local activeBlip = false
local blurShader = false
local showPlayers = false

local mapBlipOffset = 0
local mapBlipNum = 10

function onBigmapClick(button, state)
	if button == "left" and state == "up" then
		if activeButton == "btn:showPlayers" then
			if renderData.adminLevel >= 3 then
				showPlayers = not showPlayers
				return
			end
		end
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
				local x = reMap((cursorX - panelPosX) / zoom + (remapTheSecondWay(mapPlayerPosX) - panelWidth / zoom / 2), 0, pictureSize, -3000, 3000)
				local y = reMap((cursorY - panelPosY) / zoom + (remapTheFirstWay(mapPlayerPosY) - panelHeight / zoom / 2), 0, pictureSize, 3000, -3000)

				setElementData(occupiedVehicle, "gpsDestination", {x, y})
			end
		end
	end
end

function renderBigBlip(icon, blipX, blipY, middleX, middleY, width, height, color, renderDistance, tooltip, k, v)
	if renderDistance and getDistanceBetweenPoints2D(middleX, middleY, blipX, blipY) > renderDistance then
		return
	end

	local x = panelPosX + panelWidth / 2 + (remapTheFirstWay(middleX) - remapTheFirstWay(blipX)) * zoom
	local y = panelPosY + panelHeight / 2 - (remapTheFirstWay(middleY) - remapTheFirstWay(blipY)) * zoom

	width = width / (2 - zoom) + 3
	height = height / (2 - zoom) + 3

	if cursorX and cursorY and cursorY >= respc(70) and cursorY <= screenY - respc(70) then
		if not activeBlip then
			if cursorX >= x - width / 2 and cursorY >= y - height / 2 and cursorX <= x + width / 2 and cursorY <= y + height / 2 then
				if isElement(v) and getElementType(v) == "player" then
					activeBlip = v
				elseif tooltip then
					activeBlip = tooltip
				elseif defaultTooltips[icon] then
					activeBlip = defaultTooltips[icon]
				end

				if activeBlip then
					width = width * 1.25
					height = height * 1.25
				end
			end
		end
	end

	if icon == "arrow.png" then
		local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)

		dxDrawImage(x - width / 2, y - height / 2, width, height, "widgets/radar/files/" .. icon, math.abs(360 - playerRotZ))
	elseif blipPictures[icon] then
		dxDrawImage(x - width / 2, y - height / 2, width, height, blipPictures[icon], 0, 0, 0, color)
	else
		dxDrawImage(x - width / 2, y - height / 2, width, height, "widgets/radar/files/blips/" .. icon, 0, 0, 0, color)
	end
end

function renderTheBigmap()
	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
	local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
	local playerDimension = getElementDimension(localPlayer)

	if playerDimension == 0 and playerPosZ <= 10000 then
		-- ** Térkép mozgatása az egérrel
		cursorX, cursorY = getCursorPosition()

		if cursorX and cursorY then
			cursorX, cursorY = cursorX * screenX, cursorY * screenY

			if getKeyState("mouse1") then
				if not lastCursorPos then
					lastCursorPos = {cursorX, cursorY}
				end

				if not cursorMoveDiff then
					cursorMoveDiff = {0, 0}
				end

				cursorMoveDiff = {cursorMoveDiff[1] + cursorX - lastCursorPos[1], cursorMoveDiff[2] + cursorY - lastCursorPos[2]}

				if not lastMapMovePos then
					if not mapMoveDiff then
						lastMapMovePos = {0, 0}
					else
						lastMapMovePos = {mapMoveDiff[1], mapMoveDiff[2]}
					end
				end

				if not mapMoveDiff then
					if math.abs(cursorMoveDiff[1]) >= 3 or math.abs(cursorMoveDiff[2]) >= 3 then
						mapMoveDiff = {lastMapMovePos[1] - cursorMoveDiff[1] / zoom / mapUnit, lastMapMovePos[2] + cursorMoveDiff[2] / zoom / mapUnit}
						mapIsMoving = true
					end
				elseif cursorMoveDiff[1] ~= 0 or cursorMoveDiff[2] ~= 0 then
					mapMoveDiff = {lastMapMovePos[1] - cursorMoveDiff[1] / zoom / mapUnit, lastMapMovePos[2] + cursorMoveDiff[2] / zoom / mapUnit}
					mapIsMoving = true
				end

				lastCursorPos = {cursorX, cursorY}
			else
				if mapMoveDiff then
					lastMapMovePos = {mapMoveDiff[1], mapMoveDiff[2]}
				end

				lastCursorPos = false
				cursorMoveDiff = false
			end
		end

		mapPlayerPosX, mapPlayerPosY = lastMapPosX, lastMapPosY

		if mapMoveDiff then
			mapPlayerPosX = mapPlayerPosX + mapMoveDiff[1]
			mapPlayerPosY = mapPlayerPosY + mapMoveDiff[2]
		else
			mapPlayerPosX, mapPlayerPosY = playerPosX, playerPosY
			lastMapPosX, lastMapPosY = mapPlayerPosX, mapPlayerPosY
		end

		-- ** Térkép @ háttér
		dxDrawRectangle(panelPosX, panelPosY, panelWidth, panelHeight, tocolor(22, 98, 173, 225))
		dxDrawImage(panelPosX, panelPosY, panelWidth, panelHeight, "files/vin2.png")
		dxDrawImageSection(panelPosX, panelPosY, panelWidth, panelHeight, remapTheSecondWay(mapPlayerPosX) - panelWidth / zoom / 2, remapTheFirstWay(mapPlayerPosY) - panelHeight / zoom / 2, panelWidth / zoom, panelHeight / zoom, mapPicture, 0, 0, 0, tocolor(255, 255, 255, 235))

		if gpsRoutePicture then
			dxDrawImage(
				panelPosX + panelWidth / 2 + (remapTheFirstWay(mapPlayerPosX) - (gpsRoutePos[1] + gpsRoutePos[3] / 2)) * zoom - gpsRoutePos[3] * zoom / 2,
				panelPosY + panelHeight / 2 - (remapTheFirstWay(mapPlayerPosY) - (gpsRoutePos[2] + gpsRoutePos[4] / 2)) * zoom + gpsRoutePos[4] * zoom / 2,
				gpsRoutePos[3] * zoom,
				-(gpsRoutePos[4] * zoom),
				gpsRoutePicture,
				180, 0, 0,
				gpsLineColor
			)
		end

		local blipCount = 0

		for k = 1, #createdBlips do
			local v = createdBlips[k]

			if v then
				blipCount = blipCount + 1

				renderBigBlip(v.blipId, v.blipPosX, v.blipPosY, mapPlayerPosX, mapPlayerPosY, v.iconSize, v.iconSize, v.blipColor, v.renderDistance or 9999, v.tooltip, blipCount)
			end
		end

		local blips = getElementsByType("blip")
		for k = 1, #blips do
			local v = blips[k]

			if v then
				local v2 = blipData[v]

				if v2 then
					local x, y = getElementPosition(v)
					
					if not v2.color then
						v2.color = tocolor(getBlipColor(v))
					end

					if not v2.size then
						v2.size = 14.5
					end

					blipCount = blipCount + 1

					renderBigBlip(v2.icon .. ".png", x, y, mapPlayerPosX, mapPlayerPosY, v2.size, v2.size, v2.color, v2.renderDistance or 9999, v2.tooltip, blipCount, v)
				end
			end
		end

		if showPlayers and renderData.adminLevel >= 3 then
			local players = getElementsByType("player")
			for k = 1, #players do
				local v = players[k]

				if v and v ~= localPlayer then
					if getElementData(v, "loggedIn") then
						local x, y = getElementPosition(v)
						local color = 0

						if getElementData(v, "adminDuty") then
							color = tocolor(50, 179, 239)
						else
							color = tocolor(255, 255, 0)
						end

						blipCount = blipCount + 1

						renderBigBlip("player.png", x, y, mapPlayerPosX, mapPlayerPosY, 20, 20, color, 9999, false, blipCount, v)
					end
				end
			end
		end

		-- ** Kliens pozíciója
		renderBigBlip("arrow.png", playerPosX, playerPosY, mapPlayerPosX, mapPlayerPosY, 20, 20)

		-- ** Blur alul & felül
		--[[
		if cursorX and cursorY then
			dxDrawImage(0, cursorY, cursorX, 2, "widgets/radar/files/white.png")
			dxDrawImage(cursorX, cursorY, screenX - cursorX, 2, "widgets/radar/files/white.png", 180)

			dxDrawImage(cursorX, 0, 2, cursorY, "widgets/radar/files/white2.png", 180)
			dxDrawImage(cursorX, cursorY, 2, screenY - cursorY,  "widgets/radar/files/white2.png")
		end
		]]

		--if mapMoveDiff then
			--renderBigBlip("cross.png", mapPlayerPosX, mapPlayerPosY, mapPlayerPosX, mapPlayerPosY, 256, 256)
			dxDrawImage(screenX / 2 - respc(128), screenY / 2 - respc(128), respc(256), respc(256), "widgets/radar/files/blips/cross.png")
		--end

		if isElement(blurShader.screenSource) then
			dxUpdateScreenSource(blurShader.screenSource, true)
			dxSetShaderValue(blurShader.shader, "screenSource", blurShader.screenSource)

			dxDrawImageSection(0, 0, screenX, respc(70), 0, 0, screenX, respc(70), blurShader.shader)
			dxDrawImageSection(0, screenY - respc(70), screenX, respc(70), 0, screenY - respc(70), screenX, respc(70), blurShader.shader)
		else
			dxDrawRectangle(0, 0, screenX, respc(70), tocolor(255, 255, 255, 40))
			dxDrawRectangle(0, screenY - respc(70), screenX, respc(70), tocolor(255, 255, 255, 40))
		end

		-- ** GPS Lokátor
		dxDrawImage(panelPosX + 12, panelPosY + 12, respc(70) - 24, respc(70) - 24, ":sarp_assets/images/map/location.png")

		dxDrawText(getZoneName(playerPosX, playerPosY, playerPosZ), panelPosX + 12 + respc(70 - 12), panelPosY, panelPosX + panelWidth, panelPosY + respc(70), tocolor(255, 255, 255), 1, Roboto18, "left", "center")

		if cursorX and cursorY then
			local x = reMap((cursorX - panelPosX) / zoom + (remapTheSecondWay(mapPlayerPosX) - panelWidth / zoom / 2), 0, pictureSize, -3000, 3000)
			local y = reMap((cursorY - panelPosY) / zoom + (remapTheFirstWay(mapPlayerPosY) - panelHeight / zoom / 2), 0, pictureSize, 3000, -3000)

			dxDrawText("#eaeaeaKijelölt hely: #ffffff" .. getZoneName(x, y, 0), panelPosX, panelPosY, panelPosX + panelWidth - respc(12), panelPosY + respc(70), tocolor(255, 255, 255), 1, RobotoL18, "right", "center", false, false, false, true)
		end

		-- ** Térkép mozgatás visszaállítása
		if mapMoveDiff then
			if getKeyState("space") then
				mapMoveDiff = false
				lastMapMovePos = false
			end

			dxDrawText("A nézet visszaállításához nyomd meg a 'SPACE' gombot.", panelPosX + respc(12), panelPosY + panelHeight - respc(70), 0, panelPosY + panelHeight, tocolor(255, 255, 255), 1, RobotoL18, "left", "center")
		end

		-- ** Blip tooltipek
		if activeBlip then
			if cursorX and cursorY then
				local text = false

				if isElement(activeBlip) then
					if getElementType(activeBlip) == "player" then
						if getElementData(activeBlip, "adminDuty") then
							text = "[" .. exports.sarp_core:getPlayerAdminTitle(activeBlip) .. "] " .. getElementData(activeBlip, "visibleName"):gsub("_", " ") .. " (" .. getElementData(activeBlip, "playerID") .. ")"
						else
							text = getElementData(activeBlip, "visibleName"):gsub("_", " ") .. " (" .. getElementData(activeBlip, "playerID") .. ")"
						end
					end
				else
					text = activeBlip
				end

				if text then
					local textWidth = dxGetTextWidth(text, 0.7, Roboto18) + resp(12)

					dxDrawRectangle(cursorX + 12.5, cursorY, textWidth, resp(30), tocolor(0, 0, 0, 150))

					dxDrawText(text, cursorX + 12.5, cursorY, cursorX + 12.5 + textWidth, cursorY + resp(30), tocolor(255, 255, 255), 0.7, Roboto18, "center", "center")
				end
			end

			activeBlip = false
		end

		-- ** Játékosok mutatás
		if renderData.adminLevel >= 3 then
			buttons = {}

			if showPlayers then
				drawButton("showPlayers", "Játékosok mutatásának kikapcsolása", panelPosX + panelWidth - respc(12) - respc(320), panelPosY + panelHeight - respc(70 - 17.5), respc(320), respc(35), 200, 50, 50, 1, Roboto18, 0.75)
			else
				drawButton("showPlayers", "Játékosok mutatása", panelPosX + panelWidth - respc(12) - respc(200), panelPosY + panelHeight - respc(70 - 17.5), respc(200), respc(35), 50, 179, 239, 1, Roboto18, 0.75)
			end

			activeButton = false

			if cursorX and cursorY then
				for k, v in pairs(buttons) do
					if cursorX >= v[1] and cursorY >= v[2] and cursorX <= v[1] + v[3] and cursorY <= v[2] + v[4] then
						activeButton = k
						break
					end
				end
			end
		end
	else
		drawLostSignal(panelPosX, panelPosY, panelWidth, panelHeight)
	end
end

function bigmapZoomHandler(timeSlice)
	zoom = zoom + (targetZoom - zoom) * timeSlice * 0.005
end

addEventHandler("onClientKey", getRootElement(),
	function (key, state)
		if key == "F11" then
			if state and renderData.loggedIn and not renderData.editorActive then
				bigRadarState = not bigRadarState

				if bigRadarState then
					toggleHUD(false)
					showChat(false)

					blurShader = {
						screenSource = dxCreateScreenSource(panelWidth, panelHeight),
						shader = dxCreateShader("widgets/radar/files/blur.fx")
					}

					if isElement(blurShader.shader) then
						dxSetShaderValue(blurShader.shader, "screenSize", {screenX, screenY})
						dxSetShaderValue(blurShader.shader, "blurStrength", 5)
					end

					addEventHandler("onClientPreRender", getRootElement(), bigmapZoomHandler)
					addEventHandler("onClientRender", getRootElement(), renderTheBigmap)
					addEventHandler("onClientClick", getRootElement(), onBigmapClick)
				else
					removeEventHandler("onClientPreRender", getRootElement(), bigmapZoomHandler)
					removeEventHandler("onClientRender", getRootElement(), renderTheBigmap)
					removeEventHandler("onClientClick", getRootElement(), onBigmapClick)

					if isElement(blurShader.shader) then
						destroyElement(blurShader.shader)
					end

					if isElement(blurShader.screenSource) then
						destroyElement(blurShader.screenSource)
					end

					blurShader = nil

					toggleHUD(true)
					showChat(true)
				end

				setElementData(localPlayer, "bigmapIsVisible", bigRadarState, false)
			end

			cancelEvent()
		elseif key == "mouse_wheel_up" and bigRadarState then
			if targetZoom + 0.1 <= 1 then
				targetZoom = targetZoom + 0.1
			end
		elseif key == "mouse_wheel_down" and bigRadarState then
			if targetZoom - 0.1 >= 0.2 then
				targetZoom = targetZoom - 0.1
			end
		end
	end
)