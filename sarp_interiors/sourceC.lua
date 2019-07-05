pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

local screenX, screenY = guiGetScreenSize()

local responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

function respc(x)
	return math.ceil(x * responsiveMultipler)
end

function resp(x)
	return x * responsiveMultipler
end

local interiorIcons = {
	building = {
		icon = "files/icons/building.png",
		color = tocolor(225, 225, 225)
	},
	house = {
		icon = "files/icons/house.png",
		color = tocolor(50, 179, 239)
	},
	houseforsale = {
		icon = "files/icons/houseforsale.png",
		color = tocolor(20, 250, 140)
	},
	garage = {
		icon = "files/icons/garage.png",
		color = tocolor(50, 179, 239)
	},
	garageforsale = {
		icon = "files/icons/garageforsale.png",
		color = tocolor(20, 250, 140)
	},
	rentable = {
		icon = "files/icons/rentable.png",
		color = tocolor(50, 179, 239)
	},
	rentabletolet = {
		icon = "files/icons/rentable.png",
		color = tocolor(146, 104, 212)
	},
	door = {
		icon = "files/icons/door.png",
		color = tocolor(200, 50, 50)
	}
}

local interiorMarkers = {}
local interiorMarkerIds = {}
local interiorMarkerDetails = {}
local interiorTypes = {}
local streamedMarkers = {}
local interiorColShapes = {}

local activeInteriorMarker = false
local interiorInfo = false

local Roboto = dxCreateFont("files/fonts/Roboto.ttf", respc(17.5), false, "antialiased")
local RobotoL = dxCreateFont("files/fonts/RobotoL.ttf", respc(12), false, "cleartype")

local lastEnterTick = 0
local lastBuyTick = 0
local lastLockTick = 0
local lastUnRentTick = 0
local lastKnockTick = 0
local lastBellTick = 0

local itemListState = false
local itemListWidth = screenX / 2
local itemListHeight = 30 + 432 + 30 + 5
local itemListPosX = screenX / 2 - itemListWidth / 2
local itemListPosY = screenY / 2 - itemListHeight / 2
local itemListOffset = 0
local itemListItems = false

local currentInteriorId = false
local currentInteriorData = {}
local interiorObjects = {}

function destroyCustomInterior()
	for k, v in pairs(interiorObjects) do
		if isElement(v) then
			destroyElement(v)
		end
	end

	interiorObjects = {}
end

addEvent("loadCustomInterior", true)
addEventHandler("loadCustomInterior", getRootElement(),
	function (interiorId, sourceVehicle)
		if availableInteriors[interiorId] then
			local data = availableInteriors[interiorId]

			currentInteriorId = interiorId
			currentInteriorData = data

			local customInterior = gameInteriors[data.gameInterior].customInterior

			for k, v in pairs(customInteriorObjects[customInterior]) do
				local obj = createObject(v[1], v[2], v[3], v[4], v[5], v[6], v[7])

				if isElement(obj) then
					setElementInterior(obj, data.exit.interior)
					setElementDimension(obj, data.exit.dimension)
					setObjectBreakable(obj, false)
					setElementDoubleSided(obj, true)

					table.insert(interiorObjects, obj)
				end
			end
		end
	end
)

addEvent("playKnocking", true)
addEventHandler("playKnocking", getRootElement(),
	function (interiorId)
		if interiorId and availableInteriors[interiorId] then
			local data = availableInteriors[interiorId]

			local entranceSound = playSound3D("files/sounds/knock.mp3", data.entrance.position[1], data.entrance.position[2], data.entrance.position[3])
			if isElement(entranceSound) then
				setElementInterior(entranceSound, data.entrance.interior)
				setElementDimension(entranceSound, data.entrance.dimension)
				setSoundMaxDistance(entranceSound, 60)
				setSoundVolume(entranceSound, 1)
			end

			local exitSound = playSound3D("files/sounds/knock.mp3", data.exit.position[1], data.exit.position[2], data.exit.position[3])
			if isElement(exitSound) then
				setElementInterior(exitSound, data.exit.interior)
				setElementDimension(exitSound, data.exit.dimension)
				setSoundMaxDistance(exitSound, 60)
				setSoundVolume(exitSound, 1)
			end
		end
	end
)

addEvent("playBell", true)
addEventHandler("playBell", getRootElement(),
	function (interiorId)
		if interiorId and availableInteriors[interiorId] then
			local data = availableInteriors[interiorId]

			local entranceSound = playSound3D("files/sounds/bell.mp3", data.entrance.position[1], data.entrance.position[2], data.entrance.position[3])
			if isElement(entranceSound) then
				setElementInterior(entranceSound, data.entrance.interior)
				setElementDimension(entranceSound, data.entrance.dimension)
				setSoundMaxDistance(entranceSound, 160)
				setSoundVolume(entranceSound, 1)
			end

			local exitSound = playSound3D("files/sounds/bell.mp3", data.exit.position[1], data.exit.position[2], data.exit.position[3])
			if isElement(exitSound) then
				setElementInterior(exitSound, data.exit.interior)
				setElementDimension(exitSound, data.exit.dimension)
				setSoundMaxDistance(exitSound, 160)
				setSoundVolume(exitSound, 1)
			end
		end
	end
)

function knockOnDoorCommand()
	if activeInteriorMarker then
		local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

		if interiorDatas then
			if interiorDatas.type == "house" or interiorDatas.type == "garage" or string.find(interiorDatas.type, "rentable") then
				if lastKnockTick + 5000 <= getTickCount() then
					triggerServerEvent("useDoorKnocking", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)

					exports.sarp_chat:sendLocalMeAction(localPlayer, "kopogtat egy ajtón.")

					lastKnockTick = getTickCount()
				else
					exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
				end
			else
				exports.sarp_hud:showAlert("error", "Csak házba vagy garázsba kopogtathatsz.")
			end
		end
	end
end
addCommandHandler("kopogtat", knockOnDoorCommand)
addCommandHandler("kopog", knockOnDoorCommand)
addCommandHandler("kopogas", knockOnDoorCommand)
addCommandHandler("kopogás", knockOnDoorCommand)

function bellOnDoorCommand()
	if activeInteriorMarker then
		local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

		if interiorDatas then
			if interiorDatas.type == "house" or interiorDatas.type == "garage" or string.find(interiorDatas.type, "rentable") then
				if getElementDimension(localPlayer) ~= 0 then
					exports.sarp_hud:showAlert("error", "Csak kintről csengethetsz be.")
				else
					if lastBellTick + 5000 <= getTickCount() then
						triggerServerEvent("useDoorBell", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)

						exports.sarp_chat:sendLocalMeAction(localPlayer, "megnyomja a csengőt.")

						lastBellTick = getTickCount()
					else
						exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
					end
				end
			else
				exports.sarp_hud:showAlert("error", "Csak házba vagy garázsba csengethetsz.")
			end
		end
	end
end
addCommandHandler("csenget", bellOnDoorCommand)
addCommandHandler("csengetes", bellOnDoorCommand)
addCommandHandler("csengetés", bellOnDoorCommand)

function getInteriorType(interiorId)
	if availableInteriors[interiorId] then
		local intiType = "Ház"

		if availableInteriors[interiorId].type == "building" then
			intiType = "Középület"
		elseif availableInteriors[interiorId].type == "garage" then
			intiType = "Garázs"
		elseif availableInteriors[interiorId].type == "rentabletolet" then
			intiType = "Kibérelt lakás"
		elseif availableInteriors[interiorId].type == "rentable" then
			intiType = "Bérelhető lakás"
		elseif availableInteriors[interiorId].type == "door" then
			intiType = "Ajtó"
		end

		return intiType
	end

	return "Ismeretlen"
end

function requestInteriors(player)
	if isElement(player) then
		local characterId = getElementData(player, "char.ID")

		if characterId then
			local interiors = {}
			
			for k,v in pairs(availableInteriors) do
				if v.ownerId == characterId then
					table.insert(interiors, {interiorId = k, data = v})
				end
			end
			
			return interiors
		end
	end
	
	return false
end

function getInteriorPosition(interiorId)
	if availableInteriors[interiorId] then
		return availableInteriors[interiorId].entrance.position
	end

	return false
end

function getInteriorName(interiorId)
	if availableInteriors[interiorId] then
		return availableInteriors[interiorId].name
	end

	return false
end

function getInteriorOwner(interiorId)
	if availableInteriors[interiorId] then
		return availableInteriors[interiorId].ownerId
	end

	return false
end

function isAvailableInterior(interiorId)
	if availableInteriors[interiorId] then
		return true
	end

	return false
end

function getInteriorEntrancePosition(interior)
	if interior then
		if availableInteriors[interior] then
			return availableInteriors[interior].entrance.position[1], availableInteriors[interior].entrance.position[2], availableInteriors[interior].entrance.position[3]
		end
	end
	
	return false
end

function getInteriorExitPosition(interior)
	if interior then
		if availableInteriors[interior] then
			return availableInteriors[interior].exit.position[1], availableInteriors[interior].exit.position[2], availableInteriors[interior].exit.position[3]
		end
	end
	
	return false
end

addEvent("lockInterior", true)
addEventHandler("lockInterior", getRootElement(),
	function (interiorId, state)
		if interiorId and availableInteriors[interiorId] then
			availableInteriors[interiorId].locked = state

			if activeInteriorMarker then
				local markerDetails = interiorMarkerDetails[activeInteriorMarker]

				if markerDetails.interiorId == interiorId then
					showInteriorInfo(activeInteriorMarker)
				end
			end
		end
	end
)

addCommandHandler("lock/unlock-property",
	function ()
		if activeInteriorMarker then
			local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

			if interiorDatas then
				if getElementData(localPlayer, "char.ID") then
					if lastLockTick + 5000 <= getTickCount() then
						triggerServerEvent("lockInterior", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)
						lastLockTick = getTickCount()
					else
						exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként nyithatod / zárhatod az ajtót.")
					end
				end
			end
		end
	end
)
bindKey("K", "down", "lock/unlock-property")

addEvent("changeInteriorOwner", true)
addEventHandler("changeInteriorOwner", getRootElement(),
	function (interiorId, ownerId)
		if interiorId and ownerId and availableInteriors[interiorId] then
			availableInteriors[interiorId].ownerId = ownerId

			if activeInteriorMarker then
				local markerDetails = interiorMarkerDetails[activeInteriorMarker]

				if markerDetails.interiorId == interiorId then
					showInteriorInfo(activeInteriorMarker)
				end
			end
		end
	end
)

addEvent("buyInterior", true)
addEventHandler("buyInterior", getRootElement(),
	function (interiorId, ownerId)
		availableInteriors[interiorId].ownerId = ownerId

		if availableInteriors[interiorId] and availableInteriors[interiorId].type ~= "building" then
			if isElement(availableInteriors[interiorId].enterMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].type, availableInteriors[interiorId].ownerId > 0 and "sold" or "unSold")
			end

			if isElement(availableInteriors[interiorId].exitMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].type, availableInteriors[interiorId].ownerId > 0 and "sold" or "unSold")
			end
		end


		if activeInteriorMarker then
			local markerDetails = interiorMarkerDetails[activeInteriorMarker]

			if markerDetails.interiorId == interiorId then
				showInteriorInfo(activeInteriorMarker)
			end
		end
	end
)

function getCurrentStandingMarker()
	if activeInteriorMarker then
		return interiorMarkerDetails[activeInteriorMarker].interiorId
	end

	return false
end

function getInteriorData(interiorId)
	if interiorId and availableInteriors[interiorId] then
		return availableInteriors[interiorId]
	end

	return false
end

addCommandHandler("unrent",
	function ()
		if activeInteriorMarker then
			local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

			if interiorDatas then
				if interiorDatas.type == "rentable" then
					if interiorDatas.ownerId == getElementData(localPlayer, "char.ID") then
						if lastUnRentTick + 5000 <= getTickCount() then
							triggerServerEvent("unRentInterior", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)

							lastUnRentTick = getTickCount()
						else
							exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
						end
					else
						exports.sarp_hud:showAlert("error", "Ezt az ingatlant nem te bérled.")
					end
				end
			end
		end
	end
)

addCommandHandler("rent",
	function ()
		if activeInteriorMarker then
			local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

			if interiorDatas then
				if interiorDatas.type == "rentable" then
					if interiorDatas.ownerId == 0 then
						if exports.sarp_core:getMoney(localPlayer) >= interiorDatas.price * 5 then
							if lastBuyTick + 5000 <= getTickCount() then
								triggerServerEvent("rentInterior", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)

								lastBuyTick = getTickCount()
							else
								exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
							end
						else
							exports.sarp_hud:showAlert("error", "Nincs elég pénzed, hogy kifizesd a bérleti díjat és kauciót. (" .. formatNumber(interiorDatas.price * 5) .. "$)")
						end
					elseif interiorDatas.ownerId == getElementData(localPlayer, "char.ID") then
						if exports.sarp_core:getMoney(localPlayer) >= interiorDatas.price then
							if lastBuyTick + 5000 <= getTickCount() then
								triggerServerEvent("tryToRenewalRent", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)

								lastBuyTick = getTickCount()
							else
								exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
							end
						else
							exports.sarp_hud:showAlert("error", "Nincs elég pénzed, hogy kifizesd a bérleti díjat. (" .. formatNumber(interiorDatas.price) .. "$)")
						end
					else
						exports.sarp_hud:showAlert("error", "Ez az ingatlan nem kiadó.")
					end
				else
					exports.sarp_hud:showAlert("error", "Ezt az ingatlant nem lehet kibérelni.")
				end
			end
		end
	end
)

addCommandHandler("buy",
	function ()
		if activeInteriorMarker then
			local interiorDatas = availableInteriors[interiorMarkerDetails[activeInteriorMarker].interiorId]

			if interiorDatas then
				if interiorDatas.type == "rentable" then
					exports.sarp_hud:showAlert("error", "Bérlakást nem vásárolhatsz meg! A bérléshez használd a /rent parancsot.")
					return
				end

				if interiorDatas.type ~= "building" or interiorDatas.type ~= "door" then
					if interiorDatas.ownerId == 0 then
						if exports.sarp_core:getMoney(localPlayer) >= interiorDatas.price then
							if lastBuyTick + 5000 <= getTickCount() then
								triggerServerEvent("buyInterior", localPlayer, interiorMarkerDetails[activeInteriorMarker].interiorId)
								lastBuyTick = getTickCount()
							else
								exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként használhatod ezt a parancsot.")
							end
						else
							exports.sarp_hud:showAlert("error", "Nincs elég pénzed az ingatlan megvásárlásához. (" .. formatNumber(interiorDatas.price) .. "$)")
						end
					else
						exports.sarp_hud:showAlert("error", "Ez az ingatlan nem eladó.")
					end
				else
					exports.sarp_hud:showAlert("error", "Középületet nem vásárolhatsz meg.")
				end
			end
		end
	end
)

addEvent("playInteriorSound", true)
addEventHandler("playInteriorSound", getRootElement(),
	function (soundType)
		if soundType then
			playSound("files/sounds/" .. soundType, false)
		end
	end
)

addCommandHandler("enter",
	function ()
		if activeInteriorMarker then
			local markerDetails = interiorMarkerDetails[activeInteriorMarker]

			if markerDetails then
				local interiorId = markerDetails.interiorId
				local colShapeType = markerDetails.colShapeType

				if not availableInteriors[interiorId].dummy or availableInteriors[interiorId].dummy == "N" then
					if not getElementData(localPlayer, "player.Cuffed") and not getElementData(localPlayer, "player.Grabbed") then
						if lastEnterTick + 3000 <= getTickCount() then
							local task = getPedSimplestTask(localPlayer)

							if task == "TASK_SIMPLE_GO_TO_POINT" or (task ~= "TASK_SIMPLE_CAR_DRIVE" and string.sub(task, 0, 15) == "TASK_SIMPLE_CAR") then
								return
							end
							
							local playerVehicle = getPedOccupiedVehicle(localPlayer)

							if playerVehicle and isElement(playerVehicle) then
								if getVehicleOccupant(playerVehicle) == localPlayer then
									if availableInteriors[interiorId].type ~= "garage" then
										if not availableInteriors[interiorId].allowedVehicles then
											return
										elseif type(availableInteriors[interiorId].allowedVehicles) == "table" then
											local canEnter = false
											
											for _, v in ipairs(availableInteriors[interiorId].allowedVehicles) do
												if getElementModel(playerVehicle) == v then
													canEnter = true
													break
												end
											end
											
											if not canEnter then
												return
											end
										end
									end
								else
									return
								end
							end
							
							lastEnterTick = getTickCount()

							local dataType = false

							if colShapeType == "entrance" then -- ha a bejáratnál van
								dataType = "exit" -- kijárathoz rakja
							elseif colShapeType == "exit" then -- ha a kijáratnál van
								dataType = "entrance" -- bejárathoz rakja
							end

							setPedCanBeKnockedOffBike(localPlayer, false)
							setTimer(setPedCanBeKnockedOffBike, 3000, 1, localPlayer, true)

							local gameInterior = availableInteriors[interiorId].gameInterior

							triggerServerEvent("warpPlayer", localPlayer, interiorId, (colShapeType == "entrance" and "enter" or "exit"), {
								posX = availableInteriors[interiorId][dataType].position[1],
								posY = availableInteriors[interiorId][dataType].position[2],
								posZ = availableInteriors[interiorId][dataType].position[3],
								rotX = availableInteriors[interiorId][dataType].rotation[1],
								rotY = availableInteriors[interiorId][dataType].rotation[2],
								rotZ = availableInteriors[interiorId][dataType].rotation[3],
								interior = availableInteriors[interiorId][dataType].interior,
								dimension = availableInteriors[interiorId][dataType].dimension,
								customInterior = gameInterior > 136
							})
						else
							exports.sarp_hud:showAlert("error", "Várj egy kicsit, mielőtt újra használod az ajtót.")
						end
					end
				else
					exports.sarp_hud:showAlert("error", "Ez az interior nem rendelkezik tényleges belső térrel.")
				end
			end
		end
	end
)
bindKey("E", "down", "enter")

addEventHandler("onClientColShapeHit", getResourceRootElement(),
	function (hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension and interiorColShapes[source] then
			activeInteriorMarker = interiorColShapes[source]

			showInteriorInfo(interiorColShapes[source])

			local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
			local sourceInterior = getElementInterior(source)
			local sourceDimension = getElementDimension(source)
			local soundElement = playSound3D("files/sounds/markerhit.wav", sourcePosX, sourcePosY, sourcePosZ)

			setElementInterior(soundElement, sourceInterior)
			setElementDimension(soundElement, sourceDimension)
			setSoundVolume(soundElement, 0.5)
		end
	end
)

addEventHandler("onClientColShapeLeave", getResourceRootElement(),
	function (hitElement)
		if hitElement == localPlayer and activeInteriorMarker then
			activeInteriorMarker = false

			showInteriorInfo(false)

			local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
			local sourceInterior = getElementInterior(source)
			local sourceDimension = getElementDimension(source)
			local soundElement = playSound3D("files/sounds/markerleave.wav", sourcePosX, sourcePosY, sourcePosZ)

			setElementInterior(soundElement, sourceInterior)
			setElementDimension(soundElement, sourceDimension)
			setSoundVolume(soundElement, 0.5)
		end
	end
)

local flyMode = false

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if source == localPlayer then
			if dataName == "flyMode" then
				flyMode = getElementData(localPlayer, "flyMode")
			elseif dataName == "loggedIn" then
				local interiorId = tonumber(getElementData(localPlayer, "currentCustomInterior") or 0)

				if interiorId and interiorId > 0 then
					triggerEvent("loadCustomInterior", localPlayer, interiorId)
				end
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for k, v in pairs(interiorIcons) do
			v.icon = dxCreateTexture(v.icon)
		end

		setTimer(triggerServerEvent, 2000, 1, "requestInteriors", localPlayer)

		flyMode = getElementData(localPlayer, "flyMode")

		local interiorId = tonumber(getElementData(localPlayer, "currentCustomInterior") or 0)

		if interiorId and interiorId > 0 then
			currentInteriorId = interiorId
		end
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		local interiorId = tonumber(getElementData(localPlayer, "currentCustomInterior") or 0)

		if interiorId and interiorId > 0 then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)

			if playerVehicle then
				setElementFrozen(playerVehicle, true)
			end

			setElementFrozen(localPlayer, true)

			for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
				setElementFrozen(v, true)
			end

			currentInteriorId = interiorId
		end
	end
)

addEvent("requestInteriors", true)
addEventHandler("requestInteriors", getRootElement(),
	function (interiors)
		for interiorId, data in pairs(interiors) do
			if not availableInteriors[interiorId] then
				availableInteriors[interiorId] = {}
			end
			
			for k, v in pairs(data) do
				parseInteriorData(interiorId, k, v)
			end
		end
		
		for interiorId in pairs(availableInteriors) do
			createInterior(interiorId)
		end

		local interiorId = tonumber(getElementData(localPlayer, "currentCustomInterior") or 0)

		if interiorId and interiorId > 0 then
			triggerEvent("loadCustomInterior", localPlayer, interiorId)
		end
	end
)

function showInteriorInfo(sourceElement)
	if isElement(sourceElement) then
		local markerDetails = interiorMarkerDetails[sourceElement]

		if markerDetails then
			local interiorData = availableInteriors[markerDetails.interiorId]
			local interpolate = interiorInfo and interiorInfo.interiorId

			interiorInfo = {}

			interiorInfo.interiorId = markerDetails.interiorId
			interiorInfo.colShapeType = markerDetails.colShapeType

			if not interpolate then
				interiorInfo.startInterpolate = getTickCount()
				interiorInfo.stopInterpolate = false
			else
				interiorInfo.startInterpolate = 0
				interiorInfo.stopInterpolate = false
			end

			if interiorData.ownerId > 0 or interiorData.type == "building" then
				if interiorData.locked == "Y" then
					interiorInfo.infoText = "Az ingatlan ajtaja be van zárva."
				else
					interiorInfo.infoText = "Nyomj [E] gombot a belépéshez."
				end
			elseif interiorData.type == "door" then
				if interiorData.locked == "Y" then
					interiorInfo.infoText = "Az ajtó zárva van."
				else
					interiorInfo.infoText = "Nyomj [E] gombot a belépéshez."
				end
			elseif interiorData.ownerId == 0 and interiorData.type == "rentable" then
				interiorInfo.infoText = "KIADÓ - Bérleti díj: " .. formatNumber(interiorData.price) .. " $/hét. Kaució: " .. formatNumber(interiorData.price * 4) .. " $"
				exports.sarp_hud:showAlert("info", "Ez az albérlet kiadó. A kibérléshez használd a /rent parancsot.")
			else
				interiorInfo.infoText = "ELADÓ - Ár: " .. formatNumber(interiorData.price) .. " $"
				exports.sarp_hud:showAlert("info", "Ez az ingatlan eladó. A megvételhez használd a /buy parancsot.")
			end

			interiorInfo.panelSizeX = math.max(dxGetTextWidth(interiorData.name, 0.85, Roboto, true), dxGetTextWidth(interiorInfo.infoText, 0.8, RobotoL, true))
			interiorInfo.panelSizeX = interiorInfo.panelSizeX + respc(20) + 2 * respc(64)
		end
	elseif interiorInfo then
		interiorInfo.startInterpolate = false
		interiorInfo.stopInterpolate = getTickCount()
	end
end

local markerRot = 0

addEventHandler("onClientPreRender", getRootElement(),
	function (timeSlice)
		timeSlice = timeSlice / 1000

		local cameraPosX, cameraPosY, cameraPosZ = getElementPosition(getCamera())
		local cameraInterior = getCameraInterior()
		local playerInterior = getElementInterior(localPlayer)

		if cameraInterior ~= playerInterior then
			setCameraInterior(playerInterior)
		end

		markerRot = markerRot + 75 * timeSlice

		for k = 1, #streamedMarkers do
			local v = streamedMarkers[k]

			if isElement(v[3]) then
				if getElementInterior(v[3]) == cameraInterior then
					local markerPosX, markerPosY, markerPosZ = getElementPosition(v[3])
					local color = interiorIcons[v[2]].color

					if getDistanceBetweenPoints3D(markerPosX, markerPosY, markerPosZ, cameraPosX, cameraPosY, cameraPosZ) <= 50 then
						local rr, gg, bb = getColorFromDecimal(color)

						for i = 0, 360, 45 do
							local r = math.rad(i + markerRot)
							local c = math.cos(r) * 0.5
							local s = math.sin(r) * 0.5

							dxDrawLine3D(markerPosX - c, markerPosY - s, markerPosZ + 1, markerPosX - c, markerPosY - s, markerPosZ, tocolor(rr, gg, bb, 100), 1)
						end
					end

					markerPosZ = markerPosZ + 1

					dxDrawMaterialLine3D(markerPosX, markerPosY, markerPosZ + 0.32, markerPosX, markerPosY, markerPosZ - 0.32, interiorIcons[v[2]].icon, 0.64, color)
				end
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local now = getTickCount()

		if currentInteriorId then
			if currentInteriorId ~= getElementDimension(localPlayer) then
				currentInteriorId = false
				destroyCustomInterior()
			elseif not flyMode then
				local playerVehicle = getPedOccupiedVehicle(localPlayer)

				if playerVehicle then
					local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(playerVehicle)
					local distanceFromMass = getElementDistanceFromCentreOfMassToBaseOfModel(playerVehicle)

					if isLineOfSightClear(vehiclePosX, vehiclePosY, vehiclePosZ, vehiclePosX, vehiclePosY, vehiclePosZ - distanceFromMass - 10, true, false, false, true, false, false, false) then
						setElementFrozen(playerVehicle, true)
					else
						setElementFrozen(playerVehicle, false)
					end
				else
					local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
					local distanceFromMass = getElementDistanceFromCentreOfMassToBaseOfModel(localPlayer)

					if isLineOfSightClear(playerPosX, playerPosY, playerPosZ, playerPosX, playerPosY, playerPosZ - distanceFromMass - 10, true, false, false, true, false, false, false) then
						setElementFrozen(localPlayer, true)
					else
						setElementFrozen(localPlayer, false)
					end
				end

				for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
					local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(v)
					local distanceFromMass = getElementDistanceFromCentreOfMassToBaseOfModel(v)

					if isLineOfSightClear(vehiclePosX, vehiclePosY, vehiclePosZ, vehiclePosX, vehiclePosY, vehiclePosZ - distanceFromMass - 10, true, false, false, true, false, false, false) then
						setElementFrozen(v, true)
					else
						setElementFrozen(v, false)
					end
				end
			end
		end

		-- ** Aktív marker
		buttons = {}

		if interiorInfo then
			local progress = 0

			if interiorInfo.startInterpolate and now >= interiorInfo.startInterpolate then
				local elapsedTime = now - interiorInfo.startInterpolate
				local duration = 375

				progress = interpolateBetween(
					0, 0, 0,
					1, 0, 0,
					elapsedTime / duration, "OutQuad")

				if progress > 1 then
					progress = 1
				end
			elseif interiorInfo.stopInterpolate and now >= interiorInfo.stopInterpolate then
				local elapsedTime = now - interiorInfo.stopInterpolate
				local duration = 375

				progress = interpolateBetween(
					1, 0, 0,
					0, 0, 0,
					elapsedTime / duration, "InQuad")

				if progress <= 0 then
					progress = 0
					interiorInfo = false
					return
				end
			end

			local interiorData = availableInteriors[interiorInfo.interiorId]

			if interiorData then
				local interiorIcon = interiorIcons[interiorData.type]
				local fontHeight = dxGetFontHeight(0.75, Roboto)

				local sx = interiorInfo.panelSizeX
				local sy = respc(130)
				local x = (screenX - sx) / 2
				local y = screenY - 56 - sy * progress

				dxDrawRectangle(x, y, sx, sy, tocolor(24, 24, 24, 225 * progress))
				dxDrawRectangle(x, y + sy - 2, sx, 2, tocolor(50, 179, 239, 255 * progress))

				dxDrawImage(math.floor(x + respc(10)), math.floor(y + (sy - respc(64) - fontHeight) / 2), respc(64), respc(64), interiorIcon.icon, 0, 0, 0, tocolor(50, 179, 239, 225 * progress))
				dxDrawText("[" .. interiorInfo.interiorId .. "]", x + respc(10), math.floor(y + (sy - respc(64) - fontHeight) / 2) + respc(64), x + respc(74), 0, tocolor(50, 179, 239, 255 * progress), 0.75, Roboto, "center", "top")
				
				dxDrawText(interiorData.name, x + respc(58), y, x + interiorInfo.panelSizeX, y + sy - fontHeight, tocolor(255, 255, 255, 255 * progress), 0.85, Roboto, "center", "center", true)
				dxDrawText(interiorInfo.infoText, x + respc(58), y + fontHeight, x + interiorInfo.panelSizeX, y + sy, tocolor(255, 255, 255, 255 * progress), 0.8, RobotoL, "center", "center", true)
			
				if interiorData.type == "house" or interiorData.type == "garage" or string.find(interiorData.type, "rentable") then
					local x2, y2 = x + sx - respc(28), y + sy - respc(28) - 2
					local r, g, b = 50, 179, 239
					local r2, g2, b2 = 255, 255, 255

					if activeButton == "knock" then
						r, g, b = 255, 255, 153
						r2, g2, b2 = 0, 0, 0
					end

					dxDrawRectangle(x2, y2, respc(28), respc(28), tocolor(r, g, b, 180 * progress))
					dxDrawImage(math.floor(x2 + respc(2)), math.floor(y2 + respc(2)), respc(24), respc(24), "files/icons/knock.png", 0, 0, 0, tocolor(r2, g2, b2, 255 * progress))
					buttons.knock = {x2, y2, respc(28), respc(28)}

					if getElementDimension(localPlayer) == 0 then
						x2 = x2 - respc(30)
						r, g, b = 50, 179, 239
						r2, g2, b2 = 255, 255, 255

						if activeButton == "bell" then
							r, g, b = 255, 255, 153
							r2, g2, b2 = 0, 0, 0
						end

						dxDrawRectangle(x2, y2, respc(28), respc(28), tocolor(r, g, b, 180 * progress))
						dxDrawImage(math.floor(x2 + respc(2)), math.floor(y2 + respc(2)), respc(24), respc(24), "files/icons/bell.png", 0, 0, 0, tocolor(r2, g2, b2, 255 * progress))
						buttons.bell = {x2, y2, respc(28), respc(28)}
					end
				end
			end
		end

		if itemListState then
			-- ** Háttér
			dxDrawRectangle(itemListPosX, itemListPosY, itemListWidth, itemListHeight, tocolor(31, 31, 31, 240))

			-- ** Cím
			dxDrawRectangle(itemListPosX, itemListPosY, itemListWidth, 30, tocolor(31, 31, 31, 240))
			dxDrawImage(math.floor(itemListPosX + 3), math.floor(itemListPosY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
			dxDrawText("Belső azonosítók", itemListPosX + 30, itemListPosY, 0, itemListPosY + 30, tocolor(255, 255, 255), 1, RobotoL, "left", "center")

			-- ** Kilépés
			local closeTextWidth = dxGetTextWidth("X", 1, RobotoL)
			local closeTextPosX = itemListPosX + itemListWidth - closeTextWidth - 5
			local closeColor = tocolor(255, 255, 255)

			if activeButton == "close" then
				closeColor = tocolor(215, 89, 89)

				if getKeyState("mouse1") then
					itemListState = false
					return
				end
			end

			dxDrawText("X", closeTextPosX, itemListPosY, 0, itemListPosY + 30, closeColor, 1, RobotoL, "left", "center")
			buttons.close = {closeTextPosX, itemListPosY, closeTextWidth, 30}

			-- ** Content
			local x = itemListPosX + 5
			local y = itemListPosY + 30

			for i = 1, 12 do
				local colorOfRow = tocolor(10, 10, 10, 125)

				if i % 2 == 0 then
					colorOfRow = tocolor(10, 10, 10, 75)
				end

				dxDrawRectangle(x, y, itemListWidth - 10, 36, colorOfRow)

				local interiorId = itemListItems[i + itemListOffset]

				if interiorId then
					dxDrawText("#32b3ef[" .. interiorId .. "] #ffffff" .. gameInteriors[interiorId].name, x + 5, y, 0, y + 36, tocolor(255, 255, 255), 0.75, Roboto, "left", "center", false, false, false, true)
				end

				y = y + 36
			end

			-- ** Scrollbar
			if #itemListItems > 12 then
				local listSize = 36 * 12

				dxDrawRectangle(itemListPosX + itemListWidth - 10, itemListPosY + 30, 5, listSize, tocolor(0, 0, 0, 100))
				dxDrawRectangle(itemListPosX + itemListWidth - 10, itemListPosY + 30 + (listSize / #itemListItems) * math.min(itemListOffset, #itemListItems - 12), 5, (listSize / #itemListItems) * 12, tocolor(50, 179, 239))
			end

			-- ** Kereső mező
			drawInput("searchitem|50", "Keresés...", itemListPosX + 5, itemListPosY + itemListHeight - 30, itemListWidth - 10, 25, RobotoL, 1)
		end

		local relX, relY = getCursorPosition()

		activeButton = false

		if relX and relY then
			relX = relX * screenX
			relY = relY * screenY

			for k, v in pairs(buttons) do
				if relX >= v[1] and relX <= v[1] + v[3] and relY >= v[2] and relY <= v[2] + v[4] then
					activeButton = k
					break
				end
			end
		end
	end
)

function searchItems()
	itemListItems = {}
	
	local searchText = fakeInputs["searchitem|50"] or ""

	if utf8.len(searchText) < 1 then
		for i = 1, #gameInteriors do
			table.insert(itemListItems, i)
		end
	elseif tonumber(searchText) then
		searchText = tonumber(searchText)

		if gameInteriors[searchText] then
			table.insert(itemListItems, searchText)
		end
	else
		for i = 1, #gameInteriors do
			if utf8.find(utf8.lower(gameInteriors[i].name), utf8.lower(searchText)) then
				table.insert(itemListItems, i)
			end
		end
	end
	
	itemListOffset = 0
end

exports.sarp_admin:addAdminCommand("gameintlist", 6, "Elérhető interior belsők")
addCommandHandler("gameintlist",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			itemListState = not itemListState
			
			if itemListState then
				if not itemListItems then
					itemListItems = {}
					
					for i = 1, #gameInteriors do
						table.insert(itemListItems, i)
					end
				end
			end
		end
	end
)

addEventHandler("onClientCharacter", getRootElement(),
	function (character)
		if selectedInput and character ~= "\\" then
			local selected = split(selectedInput, "|")

			if utf8.len(fakeInputs[selectedInput]) < tonumber(selected[2]) then
				fakeInputs[selectedInput] = fakeInputs[selectedInput] .. character

				if selected[1] == "searchitem" then
					searchItems()
				end
			end
		end
	end
)

addEventHandler("onClientKey", getRootElement(),
	function (key, state)
		if itemListState then
			if #itemListItems > 12 then
				if key == "mouse_wheel_down" and itemListOffset < #itemListItems - 12 then
					itemListOffset = itemListOffset + 12
				elseif key == "mouse_wheel_up" and itemListOffset > 0 then
					itemListOffset = itemListOffset - 12
				end
			end
		end

		if itemListState and selectedInput and state then
			cancelEvent()

			if key == "backspace" then
				removeCharacterFromInput(selectedInput)

				if getKeyState(key) then
					repeatStartTimer = setTimer(removeCharacterFromInput, 500, 1, selectedInput, true)
				end
			end
		else
			if isTimer(repeatStartTimer) then
				killTimer(repeatStartTimer)
			end

			if isTimer(repeatTimer) then
				killTimer(repeatTimer)
			end

			repeatStartTimer = nil
			repeatTimer = nil
		end
	end
)

function removeCharacterFromInput(input, repeatTheTimer)
	if utf8.len(fakeInputs[input]) >= 1 then
		fakeInputs[input] = utf8.sub(fakeInputs[input], 1, -2)

		if string.find(input, "searchitem") then
			searchItems()
		end
	end

	if repeatTheTimer then
		repeatTimer = setTimer(removeCharacterFromInput, 50, 1, selectedInput, repeatTheTimer)
	end
end

addEventHandler("onClientClick", getRootElement(),
	function (button, state)
		selectedInput = false

		if activeButton then
			if button == "left" and state == "up" then
				if activeButton == "knock" then
					knockOnDoorCommand()
				elseif activeButton == "bell" then
					bellOnDoorCommand()
				elseif string.find(activeButton, "input") then
					selectedInput = string.gsub(activeButton, "input:", "")
				end
			end
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if interiorMarkerIds[source] then
			local markerPosX, markerPosY, markerPosZ = getElementPosition(source)
			local markerInterior = getElementInterior(source)
			local markerDimension = getElementDimension(source)

			local colShape = createColTube(markerPosX, markerPosY, markerPosZ, 0.5, 1.5)
			setElementInterior(colShape, markerInterior)
			setElementDimension(colShape, markerDimension)

			table.insert(streamedMarkers, {
				interiorMarkerIds[source],
				interiorTypes[interiorMarkerIds[source]],
				source,
				colShape
			})

			interiorColShapes[colShape] = source
		end
	end
)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if interiorMarkerIds[source] then
			for i = 1, #streamedMarkers do
				if streamedMarkers[i] and (source == streamedMarkers[i][3] or streamedMarkers[i] == interiorMarkerIds[source]) then
					if isElement(streamedMarkers[i][4]) then
						destroyElement(streamedMarkers[i][4])
					end

					interiorColShapes[streamedMarkers[i][4]] = nil

					table.remove(streamedMarkers, i)

					break
				end
			end
		end
	end
)

addEventHandler("onClientElementDestroy", getRootElement(),
	function ()
		if interiorMarkerIds[source] then
			interiorMarkers[interiorMarkerIds[source]] = nil

			for i = 1, #streamedMarkers do
				if streamedMarkers[i] and (source == streamedMarkers[i][3] or streamedMarkers[i] == interiorMarkerIds[source]) then
					if isElement(streamedMarkers[i][4]) then
						destroyElement(streamedMarkers[i][4])
					end

					interiorColShapes[streamedMarkers[i][4]] = nil

					table.remove(streamedMarkers, i)

					interiorMarkerIds[source] = nil

					if activeInteriorMarker and source == activeInteriorMarker then
						activeInteriorMarker = false
						showInteriorInfo(false)
					end

					break
				end
			end
		end
	end
)

function getColorFromDecimal(decimal)
	local red = bitExtract(decimal, 16, 8)
	local green = bitExtract(decimal, 8, 8)
	local blue = bitExtract(decimal, 0, 8)
	local alpha = bitExtract(decimal, 24, 8)
	
	return red, green, blue, alpha
end

function destroyInterior(interiorId)
	if availableInteriors[interiorId] then
		for _, v in pairs(availableInteriors[interiorId]) do
			if isElement(v) then
				destroyElement(v)
			end
		end
		
		availableInteriors[interiorId] = nil
	end
end

function setInteriorMarkerType(marker, type, state)
	if type == "house" and state == "unSold" then
		type = "houseforsale"
	elseif type == "garage" and state == "unSold" then
		type = "garageforsale"
	elseif type == "rentable" and state == "unSold" then
		type = "rentabletolet"
	end

	local r, g, b = getColorFromDecimal(interiorIcons[type].color)

	setMarkerColor(marker, r, g, b, 75)
	interiorTypes[interiorMarkerIds[marker]] = type

	for i = 1, #streamedMarkers do
		if streamedMarkers[i] and (marker == streamedMarkers[i][3] or streamedMarkers[i] == interiorMarkerIds[marker]) then
			streamedMarkers[i][2] = type
			break
		end
	end
end

function createInteriorMarker(x, y, z, type, state)
	if type == "house" and state == "unSold" then
		type = "houseforsale"
	elseif type == "garage" and state == "unSold" then
		type = "garageforsale"
	elseif type == "rentable" and state == "unSold" then
		type = "rentabletolet"
	end

	local r, g, b = getColorFromDecimal(interiorIcons[type].color)
	local markerElement = createMarker(x, y, z - 1, "corona", 1, r, g, b, 75)

	table.insert(interiorMarkers, markerElement)
	interiorMarkerIds[markerElement] = #interiorMarkers
	interiorTypes[interiorMarkerIds[markerElement]] = type

	return markerElement
end

function createInterior(interiorId)
	if availableInteriors[interiorId] then
		local interiorState = "unSold"

		if availableInteriors[interiorId].ownerId > 0 then
			interiorState = "sold"
		end

		local entrancePos = availableInteriors[interiorId].entrance
		local exitPos = availableInteriors[interiorId].exit

		availableInteriors[interiorId].enterMarker = createInteriorMarker(entrancePos.position[1], entrancePos.position[2], entrancePos.position[3], availableInteriors[interiorId].type, interiorState)

		if isElement(availableInteriors[interiorId].enterMarker) then
			setElementInterior(availableInteriors[interiorId].enterMarker, entrancePos.interior)
			setElementDimension(availableInteriors[interiorId].enterMarker, entrancePos.dimension)

			interiorMarkerDetails[availableInteriors[interiorId].enterMarker] = {
				interiorId = interiorId,
				colShapeType = "entrance"
			}
		end

		availableInteriors[interiorId].exitMarker = createInteriorMarker(exitPos.position[1], exitPos.position[2], exitPos.position[3], availableInteriors[interiorId].type, interiorState)

		if isElement(availableInteriors[interiorId].exitMarker) then
			setElementInterior(availableInteriors[interiorId].exitMarker, exitPos.interior)
			setElementDimension(availableInteriors[interiorId].exitMarker, exitPos.dimension)

			interiorMarkerDetails[availableInteriors[interiorId].exitMarker] = {
				interiorId = interiorId,
				colShapeType = "exit"
			}
		end
	end
end

exports.sarp_admin:addAdminCommand("setinteriorowner", 6, "Interior tulajdonosának beállítása")
addCommandHandler("setinteriorowner",
	function (command, interiorId, targetPlayer)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			interiorId = tonumber(interiorId)

			if not (interiorId and targetPlayer) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID] [Játékos név / ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					targetPlayer = exports.sarp_core:findPlayer(localPlayer, targetPlayer)

					if targetPlayer then
						triggerServerEvent("changeInteriorOwner", localPlayer, interiorId, getElementData(targetPlayer, "char.ID"))
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriorid", 6, "Interior belsőjének megváltoztatása")
addCommandHandler("setinteriorid",
	function (command, interiorId, interior)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not (tonumber(interiorId) and tonumber(interior)) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID] [Belső Azonosító]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
				interior = tonumber(interior)

				if availableInteriors[interiorId] then
					if gameInteriors[interior] then
						triggerServerEvent("setInteriorId", localPlayer, interiorId, {
							exit_position = gameInteriors[interior].position[1] .. "," .. gameInteriors[interior].position[2] .. "," .. gameInteriors[interior].position[3],
							exit_rotation = gameInteriors[interior].rotation[1] .. "," .. gameInteriors[interior].rotation[2] .. "," .. gameInteriors[interior].rotation[3],
							exit_interior = gameInteriors[interior].interior,
							exit_dimension = interiorId,
							gameInterior = interior
						})
					else
						outputChatBox("#ff4646>> Interior: #ffff99Érvénytelen interior azonosító.", 0, 0, 0, true)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("gotointerior", 1, "Interiorhoz teleportálás")
addCommandHandler("gotointerior",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
			
				if availableInteriors[interiorId] then
					triggerServerEvent("warpPlayer", localPlayer, interiorId, "exit", {
						posX = availableInteriors[interiorId].entrance.position[1],
						posY = availableInteriors[interiorId].entrance.position[2],
						posZ = availableInteriors[interiorId].entrance.position[3],
						rotX = availableInteriors[interiorId].entrance.rotation[1],
						rotY = availableInteriors[interiorId].entrance.rotation[2],
						rotZ = availableInteriors[interiorId].entrance.rotation[3],
						interior = availableInteriors[interiorId].entrance.interior,
						dimension = availableInteriors[interiorId].entrance.dimension
					}, true)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("nearbyinteriors", 1, "Közelben lévő interiorok listázása")
addCommandHandler("nearbyinteriors",
	function (command, yard)
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local playerInterior = getElementInterior(localPlayer)
			local playerDimension = getElementDimension(localPlayer)
			local nearbyInteriors = {}

			if not tonumber(yard) then
				yard = 15
			else
				yard = tonumber(yard)
			end
			
			for k, v in pairs(availableInteriors) do
				local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, v.entrance.position[1], v.entrance.position[2], v.entrance.position[3])

				if distance <= yard and playerInterior == v.entrance.interior and playerDimension == v.entrance.dimension then
					table.insert(nearbyInteriors, {k, v.name})
				end

				distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, v.exit.position[1], v.exit.position[2], v.exit.position[3])

				if distance <= yard and playerInterior == v.exit.interior and playerDimension == v.exit.dimension then
					table.insert(nearbyInteriors, {k, v.name})
				end
			end
			
			if #nearbyInteriors > 0 then
				outputChatBox("#cdcdcd>> Interior: #ff4646Közeledben lévő interiorok (#ffff99" .. yard .. " yard#ff4646):", 0, 0, 0, true)

				for k, v in ipairs(nearbyInteriors) do
					outputChatBox("  #ffff99>> Azonosító: #ffa600" .. v[1] .. " | #ffff99Név: #ffa600" .. utf8.gsub(v[2], "_", " "), 0, 0, 0, true)
				end
			else
				outputChatBox("#ff4646>> Interior: #ffff99Nincs interior #ffa600" .. yard .. " yard #ffff99távolságon belül.", 0, 0, 0, true)
			end
		end
	end
)

addEvent("resetInterior", true)
addEventHandler("resetInterior", getRootElement(),
	function (interiorId)
		availableInteriors[interiorId].ownerId = 0

		if availableInteriors[interiorId] and availableInteriors[interiorId].type ~= "building" then
			if isElement(availableInteriors[interiorId].enterMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].type, availableInteriors[interiorId].ownerId > 0 and "sold" or "unSold")
			end

			if isElement(availableInteriors[interiorId].exitMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].type, availableInteriors[interiorId].ownerId > 0 and "sold" or "unSold")
			end
		end


		if activeInteriorMarker then
			local markerDetails = interiorMarkerDetails[activeInteriorMarker]

			if markerDetails.interiorId == interiorId then
				showInteriorInfo(activeInteriorMarker)
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("resetinterior", 6, "Interior visszaállítása")
addCommandHandler("resetinterior",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
			
				if availableInteriors[interiorId] then
					triggerServerEvent("resetInterior", localPlayer, interiorId)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("setInteriorName", true)
addEventHandler("setInteriorName", getRootElement(),
	function (interiorId, name)
		if interiorId and name and availableInteriors[interiorId] then
			availableInteriors[interiorId].name = name
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriorname", 6, "Interior nevének módosítása")
addCommandHandler("setinteriorname",
	function (command, interiorId, ...)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not (tonumber(interiorId) and {...}) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID] [Név]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					local name = table.concat({...}, " ")

					if utfLen(name) > 0 then
						triggerServerEvent("setInteriorName", localPlayer, interiorId, name)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("getinteriorname", 6, "Interior nevének lekérdezése")
addCommandHandler("getinteriorname",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					outputChatBox("#cdcdcd>> Interior: #ffff99A kiválasztott interior neve #ffa600" .. availableInteriors[interiorId].name .. ".", 0, 0, 0, true)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("setInteriorPrice", true)
addEventHandler("setInteriorPrice", getRootElement(),
	function (interiorId, price)
		if interiorId and price and availableInteriors[interiorId] then
			availableInteriors[interiorId].price = price
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriorprice", 6, "Interior árának módosítása")
addCommandHandler("setinteriorprice",
	function (command, interiorId, price)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not (tonumber(interiorId) and tonumber(price)) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID] [Ár]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
				price = math.floor(tonumber(price))

				if availableInteriors[interiorId] then
					if price >= 0 and price <= 10000000000 then
						triggerServerEvent("setInteriorPrice", localPlayer, interiorId, price)
					else
						outputChatBox("#ff4646>> Interior: #ffff99Az ár nem lehet kisebb mint #ff46460 #ffff99és nem lehet nagyobb mint #ff464610 000 000 000#ffff99.", 0, 0, 0, true)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("getinteriorprice", 6, "Interior árának lekérdezése")
addCommandHandler("getinteriorprice",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					outputChatBox("#cdcdcd>> Interior: #ffff99A kiválasztott interior ára #ffa600" .. formatNumber(availableInteriors[interiorId].price) .. "$.", 0, 0, 0, true)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("setInteriorType", true)
addEventHandler("setInteriorType", getRootElement(),
	function (interiorId, intiType)
		if interiorId and intiType and availableInteriors[interiorId] then
			availableInteriors[interiorId].type = intiType

			if isElement(availableInteriors[interiorId].enterMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].type, 0 < (availableInteriors[interiorId].ownerId or 0) and "sold" or "unSold")
			end

			if isElement(availableInteriors[interiorId].exitMarker) then
				setInteriorMarkerType(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].type, 0 < (availableInteriors[interiorId].ownerId or 0) and "sold" or "unSold")
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriortype", 6, "Interior típusának módosítása")
addCommandHandler("setinteriortype",
	function (command, interiorId, typeId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not (tonumber(interiorId) and tonumber(typeId)) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID] [Típus]", 0, 0, 0, true)
				outputChatBox("#32b3ef>> Típusok: #ffffffKözépület (1), Ház (2), Garázs (3), Bérlakás (4), Ajtó (5)", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
				typeId = tonumber(typeId)

				if availableInteriors[interiorId] then
					if typeId >= 1 and typeId <= 3 then
						if typeId == 1 then
							typeId = "building"
						elseif typeId == 2 then
							typeId = "house"
						elseif typeId == 3 then
							typeId = "garage"
						elseif typeId == 4 then
							typeId = "rentable"
						elseif typeId == 5 then
							typeId = "door"
						end

						triggerServerEvent("setInteriorType", localPlayer, interiorId, typeId)
					else
						outputChatBox("#ff4646>> Interior: #ffff99Érvénytelen interior típus.", 0, 0, 0, true)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("getinteriortype", 6, "Interior típusának lekérdezése")
addCommandHandler("getinteriortype",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					outputChatBox("#cdcdcd>> Interior: #ffff99A kiválasztott interior típusa #ffa600" .. getInteriorType(interiorId) .. ".", 0, 0, 0, true)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("setInteriorEntrance", true)
addEventHandler("setInteriorEntrance", getRootElement(),
	function (interiorId, datas)
		if interiorId and datas and availableInteriors[interiorId] then
			for k, v in pairs(datas) do
				parseInteriorData(interiorId, k, v)
			end

			if isElement(availableInteriors[interiorId].enterMarker) then
				setElementPosition(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].entrance.position[1], availableInteriors[interiorId].entrance.position[2], availableInteriors[interiorId].entrance.position[3] - 1)
				setElementInterior(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].entrance.interior)
				setElementDimension(availableInteriors[interiorId].enterMarker, availableInteriors[interiorId].entrance.dimension)

				local sourceMarker = availableInteriors[interiorId].enterMarker

				if interiorMarkerIds[sourceMarker] then
					for k = 1, #streamedMarkers do
						local v = streamedMarkers[k]

						if v and (sourceMarker == v[3] or v == interiorMarkerIds[sourceMarker]) then
							if isElement(v[4]) then
								setElementPosition(v[4], availableInteriors[interiorId].entrance.position[1], availableInteriors[interiorId].entrance.position[2], availableInteriors[interiorId].entrance.position[3] - 1)
								setElementInterior(v[4], availableInteriors[interiorId].entrance.interior)
								setElementDimension(v[4], availableInteriors[interiorId].entrance.dimension)
							end

							break
						end
					end
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriorentrance", 6, "Interior bejáratának módosítása")
addCommandHandler("setinteriorentrance",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
					local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
					local playerInterior = getElementInterior(localPlayer)
					local playerDimension = getElementDimension(localPlayer)

					triggerServerEvent("setInteriorEntrance", localPlayer, interiorId, {
						entrance_position = playerPosX .. "," .. playerPosY .. "," .. playerPosZ,
						entrance_rotation = playerRotX .. "," .. playerRotY .. "," .. playerRotZ,
						entrance_interior = playerInterior,
						entrance_dimension = playerDimension
					})
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("setInteriorExit", true)
addEventHandler("setInteriorExit", getRootElement(),
	function (interiorId, datas)
		if interiorId and datas and availableInteriors[interiorId] then
			for k, v in pairs(datas) do
				parseInteriorData(interiorId, k, v)
			end

			if isElement(availableInteriors[interiorId].exitMarker) then
				setElementPosition(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].exit.position[1], availableInteriors[interiorId].exit.position[2], availableInteriors[interiorId].exit.position[3] - 1)
				setElementInterior(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].exit.interior)
				setElementDimension(availableInteriors[interiorId].exitMarker, availableInteriors[interiorId].exit.dimension)

				local sourceMarker = availableInteriors[interiorId].exitMarker

				if interiorMarkerIds[sourceMarker] then
					for k = 1, #streamedMarkers do
						local v = streamedMarkers[k]

						if v and (sourceMarker == v[3] or v == interiorMarkerIds[sourceMarker]) then
							if isElement(v[4]) then
								setElementPosition(v[4], availableInteriors[interiorId].exit.position[1], availableInteriors[interiorId].exit.position[2], availableInteriors[interiorId].exit.position[3] - 1)
								setElementInterior(v[4], availableInteriors[interiorId].exit.interior)
								setElementDimension(v[4], availableInteriors[interiorId].exit.dimension)
							end

							break
						end
					end
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setinteriorexit", 6, "Interior kijáratának módosítása")
addCommandHandler("setinteriorexit",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)

				if availableInteriors[interiorId] then
					local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
					local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
					local playerInterior = getElementInterior(localPlayer)
					local playerDimension = getElementDimension(localPlayer)

					triggerServerEvent("setInteriorExit", localPlayer, interiorId, {
						exit_position = playerPosX .. "," .. playerPosY .. "," .. playerPosZ,
						exit_rotation = playerRotX .. "," .. playerRotY .. "," .. playerRotZ,
						exit_interior = playerInterior,
						exit_dimension = playerDimension
					})
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("deleteInterior", true)
addEventHandler("deleteInterior", getRootElement(),
	function (interiorId)
		destroyInterior(interiorId)
	end
)

exports.sarp_admin:addAdminCommand("deleteinterior", 6, "Interior törlése")
addCommandHandler("deleteinterior",
	function (command, interiorId)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not tonumber(interiorId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Interior ID]", 0, 0, 0, true)
			else
				interiorId = tonumber(interiorId)
			
				if availableInteriors[interiorId] then
					triggerServerEvent("deleteInterior", localPlayer, interiorId)
				else
					outputChatBox("#ff4646>> Interior: #ffff99A kiválasztott interior nem létezik.", 0, 0, 0, true)
				end
			end
		end
	end
)

addEvent("createInterior", true)
addEventHandler("createInterior", getRootElement(),
	function (interiorId, data)
		if interiorId and data then
			if not availableInteriors[interiorId] then
				availableInteriors[interiorId] = {}
			end

			for k, v in pairs(data) do
				parseInteriorData(interiorId, k, v)
			end
		
			createInterior(interiorId)
		end
	end
)

exports.sarp_admin:addAdminCommand("createinterior", 6, "Interior létrehozása")
addCommandHandler("createinterior",
	function (command, interior, typeId, price, ...)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			if not (tonumber(interior) and tonumber(typeId)) then
				outputChatBox("#32b3ef>> Használat: #FFFFFF/" .. command .. " [Belső Azonosító (/gameintlist) (0: Átjáróhoz)] [Típus] [Ár] [Név]", 0, 0, 0, true)
				outputChatBox("#32b3ef>> Típusok: #ffffffKözépület (1), Ház (2), Garázs (3), Bérlakás (4), Ajtó (5)", 0, 0, 0, true)
			else
				interior = tonumber(interior)
				typeId = tonumber(typeId)
				price = math.floor(tonumber(price) or 0)
				
				if gameInteriors[interior] or interior == 0 then
					if typeId >= 1 and typeId <= 5 then
						if typeId == 2 then
							typeId = "house"
						elseif typeId == 3 then
							typeId = "garage"
						elseif typeId == 4 then
							typeId = "rentable"
						elseif typeId == 5 then
							typeId = "door"
						else
							typeId = "building"
						end
						
						if price >= 0 and price <= 10000000000 then
							local name = table.concat({...}, " ")
							
							if utfLen(name) == 0 then
								if gameInteriors[interior] then
									name = gameInteriors[interior].name
								else
									name = "Ajtó"
								end
							end

							local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
							local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
							local playerInterior = getElementInterior(localPlayer)
							local playerDimension = getElementDimension(localPlayer)
							local data = {
								name = name,
								allowedVehicles = false,
								type = typeId,
								dummy = "Y",
								price = price,
								ownerId = 0,
								gameInterior = interior,
								entrance_position = playerPosX .. "," .. playerPosY .. "," .. playerPosZ,
								entrance_rotation = playerRotX .. "," .. playerRotY .. "," .. playerRotZ,
								entrance_interior = playerInterior,
								entrance_dimension = playerDimension,
								exit_position = "0,0,0",
								exit_rotation = "0,0,0",
								exit_interior = 0,
								exit_dimension = 65535
							}
							
							if gameInteriors[interior] then
								data.dummy = "N"
								data.exit_position = gameInteriors[interior].position[1] .. "," .. gameInteriors[interior].position[2] .. "," .. gameInteriors[interior].position[3]
								data.exit_rotation = gameInteriors[interior].rotation[1] .. "," .. gameInteriors[interior].rotation[2] .. "," .. gameInteriors[interior].rotation[3]
								data.exit_interior = gameInteriors[interior].interior
							end
							
							triggerServerEvent("createInterior", localPlayer, data)
						else
							outputChatBox("#ff4646>> Interior: #ffff99Az ár nem lehet kisebb mint #ff46460 #ffff99és nem lehet nagyobb mint #ff464610 000 000 000#ffff99.", 0, 0, 0, true)
						end
					else
						outputChatBox("#ff4646>> Interior: #ffff99Érvénytelen interior típus.", 0, 0, 0, true)
					end
				else
					outputChatBox("#ff4646>> Interior: #ffff99Érvénytelen interior azonosító.", 0, 0, 0, true)
				end
			end
		end
	end
)