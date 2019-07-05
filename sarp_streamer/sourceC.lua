local streamerThreads = {}

local streamedOutElements = {}
local streamOutDimension = 54321

local streamElementTypes = {
	vehicle = 150,
	object = 150
}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		engineSetAsynchronousLoading(true, true)

		for elementType in pairs(streamElementTypes) do
			streamedOutElements[elementType] = {}
			streamerThreads[elementType] = coroutine.create(processStream)
			
			if streamerThreads[elementType] then
				coroutine.resume(streamerThreads[elementType], elementType)
			end
		end
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		for elementType in pairs(streamElementTypes) do
			for element, dimension in pairs(streamedOutElements[elementType]) do
				if isElement(element) then
					setElementDimension(element, dimension)
				end
			end
		end
	end
)

function processStream(elementType)
	while true do
		if elementType then
			local cameraX, cameraY, cameraZ = getCameraMatrix()
			local playerX, playerY, playerZ = getElementPosition(localPlayer)
		
			if elementType == "vehicle" then
				local streamedVehicles = {}
				
				for k,v in ipairs(getElementsByType(elementType, getRootElement(), true)) do
					if not streamedOutElements[elementType][v] and not getVehicleOccupant(v) and getElementModel(v) ~= 577 then
						local elementX, elementY, elementZ = getElementPosition(v)
						local _, _, elementRotation = getElementRotation(v)
						
						if getDistanceBetweenPoints3D(playerX, playerY, playerZ, elementX, elementY, elementZ) > streamElementTypes[elementType] then
							streamedOutElements[elementType][v] = getElementDimension(v)
							setElementDimension(v, streamOutDimension)
							streamedVehicles[v] = true
						elseif not isElementVisible(cameraX, cameraY, cameraZ, elementX, elementY, elementZ, elementRotation, getElementRadius(v) * 2) then
							streamedOutElements[elementType][v] = getElementDimension(v)
							setElementDimension(v, streamOutDimension)
							streamedVehicles[v] = true
						end
					end
				end
				
				for k,v in pairs(streamedOutElements[elementType]) do
					if isElement(k) then
						if not getVehicleOccupant(k) then
							local elementX, elementY, elementZ = getElementPosition(k)
							local _, _, elementRotation = getElementRotation(k)
							
							if not streamedVehicles[k] and getDistanceBetweenPoints3D(playerX, playerY, playerZ, elementX, elementY, elementZ) <= streamElementTypes[elementType] and isElementVisible(cameraX, cameraY, cameraZ, elementX, elementY, elementZ, elementRotation, getElementRadius(k) * 2) then
								setElementDimension(k, v)
								streamedOutElements[elementType][k] = nil
							end
						else
							setElementDimension(k, v)
							streamedOutElements[elementType][k] = nil
						end
					else
						streamedOutElements[elementType][k] = nil
					end
				end
			elseif elementType == "object" then
				local streamedObjects = {}
				
				for k,v in ipairs(getElementsByType(elementType, getRootElement(), true)) do
					if not streamedOutElements[elementType][v] then
						local objectX, objectY, objectZ = getElementPosition(v)
						
						if getDistanceBetweenPoints3D(playerX, playerY, playerZ, objectX, objectY, objectZ) > streamElementTypes[elementType] then
							streamedOutElements[elementType][v] = getElementDimension(v)
							setElementDimension(v, streamOutDimension)
							streamedObjects[v] = true
						end
					end
				end
				
				for k,v in pairs(streamedOutElements[elementType]) do
					if isElement(k) then
						local objectX, objectY, objectZ = getElementPosition(k)
						
						if not streamedObjects[k] and getDistanceBetweenPoints3D(playerX, playerY, playerZ, objectX, objectY, objectZ) <= streamElementTypes[elementType] then
							setElementDimension(k, v)
							streamedOutElements[elementType][k] = nil
						end
					else
						streamedOutElements[elementType][k] = nil
					end
				end
			end
			
			setTimer(
				function(eType)
					coroutine.resume(streamerThreads[eType], eType)
				end,
			500, 1, elementType)

			coroutine.yield()
		end
	end
end

function isElementVisible(x0, y0, z0, x1, y1, z1, rotation, radius)
	rotation = math.rad(90 + rotation)
	
	local x2, y2 = rotatePosition(x1, y1, radius, 0, rotation)
	local x3, y3 = rotatePosition(x1, y1, -radius, 0, rotation)
	
	return isLineOfSightClear(x0, y0, z0, x2, y2, z1, true, false, false, false, false, true) or isLineOfSightClear(x0, y0, z0, x3, y3, z1, true, false, false, false, false, true)
end

function rotatePosition(x, y, cx, cy, angle)
	local cosinus, sinus = math.cos(angle), math.sin(angle)
	return x + (cx * cosinus - cy * sinus), y + (cx * sinus + cy * cosinus)
end