local ferPos = {
	{389.875, -2028.52, 8.78125},
	{389.875, -2021.63, 10.9844},
	{389.875, -2017.43, 16.8516},
	{389.875, -2017.45, 24.0312},
	{389.875, -2021.64, 29.9297},
	{389.875, -2028.50, 32.2266},
	{389.875, -2035.38, 29.9531},
	{389.875, -2039.66, 24.1094},
	{389.875, -2039.64, 16.8438},
	{389.875, -2035.40, 10.9453},
}

local mov_ferPos = {
	{389.875, -2028.52, 8.78125},
	{389.875, -2024.9080810547, 9.3344249725342},
	{389.875, -2021.63, 10.9844},
	{389.875, -2019.0773925781, 13.53436088562},
	{389.875, -2017.43, 16.8516},
	{389.875, -2016.7751464844, 20.459255218506},
	{389.875, -2017.45, 24.0312},
	{389.875, -2018.9772949219, 27.334150314331},
	{389.875, -2021.64, 29.9297},
	{389.875, -2024.8330078125, 31.609085083008},
	{389.875, -2028.5, 32.2266},
	{389.875, -2032.0650634766, 31.609085083008},
	{389.875, -2035.38, 29.9531},
	{389.875, -2037.9958496094, 27.359149932861},
	{389.875, -2039.66, 24.1094},
	{389.875, -2040.2230224609, 20.484254837036},
	{389.875, -2039.64, 16.8438},
	{389.875, -2037.9958496094, 13.584360122681},
	{389.875, -2035.4, 10.9453},
	{389.875, -2032.1401367188, 9.2844257354736},
}

local cabinMoveInterval = 7000
local cabinData = {
	obj = {},
	step = {}
}

function moveCabins()
	for k = 1, #cabinData.obj do
		cabinData.step[k] = cabinData.step[k] + 1

		if cabinData.step[k] > #mov_ferPos then
			cabinData.step[k] = 1
		end

		local pos = mov_ferPos[cabinData.step[k]]

		moveObject(cabinData.obj[k], cabinMoveInterval, pos[1], pos[2], pos[3])
	end
end

local streamedHelicopters = {}

local towedVehicle = {}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function()
		removeWorldModel(3752, 500, 390.34, -2028.42, 22.47)
		removeWorldModel(3751, 500, 390.34, -2028.42, 22.47)

		for k, v in ipairs(ferPos) do
			local coronaEffect = createMarker(0, 0, 0, "corona", 3, math.random(255), math.random(255), math.random(255), 80)

			cabinData.obj[k] = createObject(3752, v[1], v[2], v[3], 0, 0, 0, false)

			attachElements(coronaEffect, cabinData.obj[k], 0, 0, 1.65)
		end

		local i = 1
		for k, v in ipairs(mov_ferPos) do
			if k % 2 ~= 0 then
				cabinData.step[i] = k
				i = i + 1
			end
		end

		moveCabins()
		setTimer(moveCabins, cabinMoveInterval, 0)

		for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
			if getVehicleType(v) == "Helicopter" then
				streamedHelicopters[v] = getElementData(v, "vehicle.engine")
			end

			if getElementData(v, "towCar") then
				towedVehicle[v] = getElementData(v, "towCar")
				outputDebugString("Data change of " .. tostring(source) .. " - on")
			end
		end

		setWorldSoundEnabled(5, 70, false)
	end)

addEventHandler("onClientTrailerAttach", getRootElement(),
	function(towedBy)
		if towedBy == getPedOccupiedVehicle(localPlayer) and getPedOccupiedVehicleSeat(localPlayer) == 0 and getElementModel(towedBy) == 403 then
			setElementData(towedBy, "towCar", source)
			outputDebugString("attach")
		end
	end)

addEventHandler("onClientTrailerDetach", getRootElement(),
	function(towedBy)
		if towedBy == getPedOccupiedVehicle(localPlayer) and getPedOccupiedVehicleSeat(localPlayer) == 0 and getElementModel(towedBy) == 403 then
			setElementData(towedBy, "towCar", false)
			outputDebugString("detach")
		end
	end)

addCommandHandler("deatchmy",
	function ()
		local pedveh = getPedOccupiedVehicle(localPlayer)

		if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
			pedveh = false
		end

		if pedveh and getElementData(pedveh, "towCar") then
			detachTrailerFromVehicle(pedveh, getElementData(pedveh, "towCar"))
		end
	end)

addCommandHandler("fixcam",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			setCameraTarget(localPlayer)
		end
	end)

addEventHandler("onClientVehicleDamage", getRootElement(),
	function (theAttacker, _, _, _, _, _, tireID)
		if source == getPedOccupiedVehicle(localPlayer) and getPedOccupiedVehicleSeat(localPlayer) == 0 and tireID then
			if theAttacker and getElementDaata(theAttacker, "tazerState") then
				return
			end
			
			triggerServerEvent("onTireFlatten", source, tireID)
		end
	end)

addEventHandler("onClientVehicleEnter", getRootElement(),
	function ()
		if getVehicleType(source) ~= "BMX" then
			setVehicleEngineState(source, true)

			if not getElementData(source, "vehicle.engine") then
				setVehicleEngineState(source, false)
			end
		end
	end)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (data, oldValue, newValue)
		if data == "vehicle.engine" and getVehicleType(source) == "Helicopter" and isElementStreamedIn(source) then
			streamedHelicopters[source] = getElementData(source, "vehicle.engine")
		end

		if data == "towCar" then
			if getElementData(source, data) then
				if isElementStreamedIn(source) then
					towedVehicle[source] = getElementData(source, data)
					outputDebugString("Data change of " .. tostring(source) .. " - on")
				end
			else
				towedVehicle[source] = nil
				outputDebugString("Data change of " .. tostring(source) .. " - off")
			end
		end
	end)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" and getVehicleType(source) == "Helicopter" then
			streamedHelicopters[source] = getElementData(source, "vehicle.engine")
		end

		if getElementData(source, "towCar") then
			towedVehicle[source] = getElementData(source, "towCar")
			outputDebugString("Data change of " .. tostring(source) .. " - on")
		end
	end)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" and getVehicleType(source) == "Helicopter" then
			streamedHelicopters[source] = nil
		end

		if towedVehicle[source] then
			towedVehicle[source] = nil
			outputDebugString("Data change of " .. tostring(source) .. " - off")
		end
	end)

addEventHandler("onClientPreRender", getRootElement(),
	function (timeSlice)
		timeSlice = timeSlice / 1000

		for k, v in pairs(streamedHelicopters) do
			if isElement(k) then
				if not v then
					local speed = getHelicopterRotorSpeed(k)

					if speed > 0 then
						local new_speed = speed - 0.075 * timeSlice

						if new_speed < 0 then
							new_speed = 0
						end

						setHelicopterRotorSpeed(k, new_speed)
					else
						setHelicopterRotorSpeed(k, 0)
					end
				elseif not getVehicleController(k) then
					setHelicopterRotorSpeed(k, 0.1)
				end
			else
				streamedHelicopters[k] = nil
			end
		end
	end)

function getElementMatrix(element)
	local rx, ry, rz = getElementRotation(element, "ZXY")
	rx, ry, rz = math.rad(rx), math.rad(ry), math.rad(rz)

	local matrix = {}
	matrix[1] = {}
	matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][3] = -math.cos(rx)*math.sin(ry)
	matrix[1][4] = 1

	matrix[2] = {}
	matrix[2][1] = -math.cos(rx)*math.sin(rz)
	matrix[2][2] = math.cos(rz)*math.cos(rx)
	matrix[2][3] = math.sin(rx)
	matrix[2][4] = 1

	matrix[3] = {}
	matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
	matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
	matrix[3][3] = math.cos(rx)*math.cos(ry)
	matrix[3][4] = 1

	matrix[4] = {}
	matrix[4][1], matrix[4][2], matrix[4][3] = getElementPosition(element)
	matrix[4][4] = 1

	return matrix
end

function getPositionFromElementOffset(element,offX,offY,offZ)
	local m = getElementMatrix(element)
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z
end

local isjayceon = false

addEventHandler("onClientRender", getRootElement(),
	function()
		local pedveh = getPedOccupiedVehicle(localPlayer)

		if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
			pedveh = false
		end

		for k, v in pairs(towedVehicle) do
			if k ~= pedveh then
				if not isElement(k) then
					towedVehicle[k] = nil
				end	
				if not isElement(v) then
					towedVehicle[k] = nil
				end

				local x, y, z = getPositionFromElementOffset(k, 0, -3, -0.1)
				local x2, y2, z2 = getPositionFromElementOffset(v, 0, 6, 0)

				local dist = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)

				if isjayceon then
					local sx, sy = getScreenFromWorldPosition(x, y, z)

					if sx and sy then
						dxDrawRectangle(sx-10, sy-10, 20, 20, tocolor(255, 0, 0, 100))
					end

					local sx, sy = getScreenFromWorldPosition(x2, y2, z2)

					if sx and sy then
						dxDrawRectangle(sx-10, sy-10, 20, 20, tocolor(0, 255, 0, 100))
					end

					dxDrawText(dist, 500, 500)
				end

				if dist >= 0.25 then
					detachTrailerFromVehicle(k, v)
					attachTrailerToVehicle(k, v)

					--outputChatBox(getTickCount() .. " retach")
				end
			end
		end
	end)