local sirenSounds = {}
local airhornSounds = {}

addCommandHandler("siren",
	function (command, id)
		id = tonumber(id)

		if not id or id < 0 or id > 3 then
			outputChatBox("Használat: #ffffff/" .. command .. " [0-3 (0 == kikapcsolás)]", 50, 179, 239, true)
			return
		end

		if (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) and allowedVehicles[getElementModel(getPedOccupiedVehicle(localPlayer))] then
			if id == 0 then
				triggerSirenFunctions("sound", false)
			else
				triggerSirenFunctions("sound", id)
			end
		end
	end
)

addCommandHandler("lights",
	function (command, id)
		id = tonumber(id)

		if not id or id < 0 or id > 3 then
			outputChatBox("Használat: #ffffff/" .. command .. " [0-3 (0 == kikapcsolás)]", 50, 179, 239, true)
			return
		end

		if (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) and allowedVehicles[getElementModel(getPedOccupiedVehicle(localPlayer))] then
			if id == 0 then
				triggerSirenFunctions("lights", false)
			else
				triggerSirenFunctions("lights", id)
			end
		end
	end
)

function triggerSirenFunctions(type, id)
	local vehicleElement = getPedOccupiedVehicle(localPlayer)

	if type == "sound" then
		local sirenData = getElementData(vehicleElement, "vehicle.siren") or {sound = false, light = false, strobe = false}

		if sirenData.sound ~= id then
			sirenData.sound = id
			triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, id)
		elseif not id or sirenData.sound == id then
			sirenData.sound = false
			triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, false)
		end

		setElementData(vehicleElement, "vehicle.siren", sirenData)
	elseif type == "lights" then
		local sirenData = getElementData(vehicleElement, "vehicle.siren") or {sound = false, light = false, strobe = false}

		if sirenData.light ~= id then
			sirenData.light = id
			triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, id)
		elseif not id or sirenData.light == id then
			sirenData.light = false
			triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, false)
		end

		setElementData(vehicleElement, "vehicle.siren", sirenData)
   end
end

addEvent("sarp_sirenC:toggleSirenSound", true)
addEventHandler("sarp_sirenC:toggleSirenSound", root, function(soundID)
	if source == localPlayer and not isPedInVehicle(source) then
		return
	end

	local vehicle = getPedOccupiedVehicle(source)
	local modelID = getElementModel(vehicle) 
	if soundID and tonumber(soundID) then
		if allowedVehicles[modelID] and vehiclesSiren[modelID] then

			if isElement(sirenSounds[vehicle]) then
				destroyElement(sirenSounds[vehicle])
			end

			local x, y, z = getElementPosition(vehicle)
			if vehiclesSiren[modelID][soundID] then
				sirenSounds[vehicle] = playSound3D("siren/sounds/" .. vehiclesSiren[modelID][soundID], x, y, z, true)
				setSoundMaxDistance(sirenSounds[vehicle], 200)
				attachElements(sirenSounds[vehicle], vehicle)
				setSoundVolume(sirenSounds[vehicle], 0.5)
			else
				exports.sarp_alert:showAlert("error", "Nincs beállítva megkülönböztető hangjelzés erre a gombra")
			end
		end
	else
		if isElement(sirenSounds[vehicle]) then
			destroyElement(sirenSounds[vehicle])
		end
	end
end)

addEvent("sarp_sirenC:useAirhorn", true)
addEventHandler("sarp_sirenC:useAirhorn", root, function(state)
	if source == localPlayer and not isPedInVehicle(source) then
		return
	end

	local vehicle = getPedOccupiedVehicle(source)
	local modelID = getElementModel(vehicle) 
	if state then
		if allowedVehicles[modelID] and vehiclesSiren[modelID] then
			if isElement(airhornSounds[vehicle]) then
				destroyElement(airhornSounds[vehicle])
			end

			local x, y, z = getElementPosition(vehicle)
			if vehiclesSiren[modelID]["horn"] then
				airhornSounds[vehicle] = playSound3D("siren/sounds/" .. vehiclesSiren[modelID]["horn"], x, y, z, true)
				setSoundMaxDistance(airhornSounds[vehicle], 200)
				attachElements(airhornSounds[vehicle], vehicle)
			else
				exports.sarp_alert:showAlert("error", "Nincs beállítva légkürt ezen a járművön")
			end
		end
	else
		if isElement(airhornSounds[vehicle]) then
			destroyElement(airhornSounds[vehicle])
		end
	end
end)

addEventHandler("onClientRender", root, function()
	--if getElementData(localPlayer, "groupDuty") then
		local pX, pY, pZ = getElementPosition(localPlayer)
		for k, v in pairs(getElementsByType("vehicle")) do
			if v ~= getPedOccupiedVehicle(localPlayer) then
				if getElementData(v, "siren.unit") then
					if isElement(v) then
						local vX, vY, vZ = getElementPosition(v)
						if getDistanceBetweenPoints3D(vX, vY, vZ, pX, pY, pZ) <= 10 then
							local cX, cY, cZ = getVehicleComponentPosition(v, "wheel_lb_dummy", "world")
							local worldX, worldY = getScreenFromWorldPosition(cX, cY, cZ, 10)
							if worldX then
								local cameraX, cameraY, cameraZ = getCameraMatrix()
								if isLineOfSightClear(cameraX, cameraY, cameraZ, cX, cY, cZ, true, false, false, true, false, true, false) then
									exports.sarp_UI:dxDrawBorderedText(getElementData(v, "siren.unit"), worldX, worldY, worldX, worldY, tocolor(255, 255, 255), 1, fonts.Roboto11)
								end
							end
						end
					end
				end
			end
		end
	--end
end)

local vehicleLightData = {}
local strobeLightTimer = {}

function processStrobe(vehicle, state)
	if isElement(vehicle) then
		if state then
			setVehicleLightState(vehicle, 0, 1)
			setVehicleLightState(vehicle, 3, 1)
			setVehicleLightState(vehicle, 1, 0)
			setVehicleLightState(vehicle, 2, 0)
			setVehicleHeadLightColor(vehicle, 255, 255, 255) -- 0, 0, 255
		else
			setVehicleLightState(vehicle, 0, 0)
			setVehicleLightState(vehicle, 3, 0)
			setVehicleLightState(vehicle, 1, 1)
			setVehicleLightState(vehicle, 2, 1)
			setVehicleHeadLightColor(vehicle, 255, 255, 255) -- 255, 0, 0
		end

		strobeLightTimer[vehicle] = setTimer(processStrobe, 150, 1, vehicle, not state)
	else
		strobeLightTimer[vehicle] = nil
	end
end

addEventHandler("onClientElementDataChange", root, function(dataName, oldValue, newValue)
	if getElementType(source) == "vehicle" then
		if dataName == "siren.status" then
			createBackupBlip(source)
		elseif dataName == "vehicle.siren" then
			local data = getElementData(source, "vehicle.siren") or {sound = false, light = false, strobe = false}

			if data.strobe then
				if not vehicleLightData[source] then
					vehicleLightData[source] = {}

					for i = 0, 3 do
						vehicleLightData[source][i] = getVehicleLightState(source, i)
					end

					vehicleLightData[source].color = {getVehicleHeadLightColor(source)}
					vehicleLightData[source].override = getVehicleOverrideLights(source)

					setVehicleOverrideLights(source, 2)

					strobeLightTimer[source] = setTimer(processStrobe, 150, 1, source, true)
				end
			else
				if isTimer(strobeLightTimer[source]) then
					killTimer(strobeLightTimer[source])
				end

				if vehicleLightData[source] then
					for i = 0, 3 do
						setVehicleLightState(source, i, vehicleLightData[source][i])
					end

					setVehicleHeadLightColor(source, unpack(vehicleLightData[source].color))
					setVehicleOverrideLights(source, vehicleLightData[source].override)

					vehicleLightData[source] = nil
				end
			end
		end
	end

	if getElementType(source) == "player" and dataName == "player.groups" then
		local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)

		if oldValue then
			if table.length(playerGroups) < table.length(oldValue) then
				for k, v in pairs(gpsBlips) do
					if not playerGroups[getElementData(k, "vehicle.group")] then
						destroyElement(gpsBlips[k])    
					end
				end
			elseif table.length(playerGroups) > table.length(oldValue) then
				for k, v in ipairs(getElementsByType("vehicle")) do
					createBackupBlip(v)
				end
			end
		end
	end

	if getElementType(source) == "player" and dataName == "loggedIn" then
		if newValue == true then
			setTimer(function()
				for k, v in ipairs(getElementsByType("vehicle")) do
					createBackupBlip(v)
				end
			end, 5000, 1)
		end
	end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
	for k, vehicle in pairs(getElementsByType("vehicle")) do
		createBackupBlip(vehicle)
	end
end)

table.length = function (tbl)
	local count = 0

	for _ in pairs(tbl) do
		count = count + 1
	end

	return count
end

local statusColors = {
	[1] = tocolor(255, 182, 0),
	[2] = tocolor(50, 179, 239),
	[3] = tocolor(255, 66, 66),
}

local statusCodes = {
	[1] = "Inaktív",
	[2] = "Elérhető",
	[3] = "Erősítés"
}

local backupSound = false

function createBackupBlip(vehicle, player, status)
	if isElement(vehicle) then
		if getElementData(vehicle, "vehicle.group") > 0 then
			local currentStatus = getElementData(vehicle, "siren.status")
			local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)

			local v = vehicle
			if playerGroups[getElementData(v, "vehicle.group")] then
				if gpsBlips[v] and isElement(gpsBlips[v]) then
					destroyElement(gpsBlips[v])
				end

				local unitNum = getElementData(v, "siren.unit") or "Ismeretlen"

				gpsBlips[v] = createBlip(0, 0, 0)
				setElementData(gpsBlips[v], "blipIcon", "cp")
				--setElementData(gpsBlips[v], "blipSize", 30)
				setElementData(gpsBlips[v], "blipTooltipText", "[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "] " .. unitNum .. " (" .. statusCodes[currentStatus] .. ")")
				attachElements(gpsBlips[v], v)
				setElementData(gpsBlips[v], "blipColor", statusColors[currentStatus])
				setElementData(gpsBlips[v], "blipFarShow", true)

				if currentStatus == 3 then
					if isElement(backupSound) then
						destroyElement(backupSound)
					end

					backupSound = playSound("siren/sounds/backup.mp3")

					outputChatBox("#32b3ef[" .. exports.sarp_groups:getGroupPrefix(getElementData(v, "vehicle.group")) .. "]#ffffff " .. unitNum .. " #ff4646erősítést #ffffffkért.", 0, 0, 0, true)
				end
			end
		end
	end
end

addEventHandler("onClientElementDestroy", getRootElement(), function()
	if getElementType(source) == "vehicle" then
		if gpsBlips[source] then
			destroyElement(gpsBlips[source])
		end
	end
end)