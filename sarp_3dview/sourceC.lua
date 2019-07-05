local screenWidth, screenHeight = guiGetScreenSize()

local screenRenderTarget = false

local skinData = false
local vehicleData = false

local getLastTick = getTickCount()
local lastCamVelocity = {0, 0, 0}
local currentCamPos = {0, 0, 0}
local lastCamPos = {0, 0, 0}

function setVehicleProjection(x, y, w, h, vehicleAlpha)
	if not vehicleData or not vehicleData.projection then
		return
	end
	
	vehicleData.projection = {x / screenWidth, y / screenHeight, w / screenWidth, h / screenHeight}
	vehicleData.onScreenPosition = {x, y, w, h}
	
	if vehicleAlpha and vehicleAlpha >= 0 and vehicleAlpha <= 255 then
		setElementAlpha(vehicleData.vehicleElement, math.min(vehicleAlpha, 254))
		vehicleData.alpha = vehicleAlpha
	end
	
	return renderTheActiveVehicleImage()
end

function setPreviewVehicleModel(vehicleModel)
	if not vehicleData or not vehicleModel then
		return
	end
	
	setElementModel(vehicleData.vehicleElement, vehicleModel)
	setElementCollidableWith(vehicleData.vehicleElement, getCamera(), false)
end

function setVehicleAlpha(alpha)
	if not vehicleData or not alpha or alpha < 0 or alpha > 255 then
		return
	end
	
	setElementAlpha(vehicleData.vehicleElement, math.min(alpha, 254))
	vehicleData.alpha = alpha
end

function rotateVehicle(cursorRelativeX)
	if not vehicleData then
		return
	end
	
	vehicleData.elementRotation[3] = (vehicleData.elementRotation[3] - (0.5 - cursorRelativeX) * 50) % 360
end

function toggleVehicleDamages(state)
	if not vehicleData or not isElement(vehicleData.vehicleElement) then
		return
	end
	
	if state ~= vehicleData.damageView then
		if state then
			for i = 0, 6 do
				if i <= 5 then
					setVehicleDoorState(vehicleData.vehicleElement, i, getVehicleDoorState(vehicleData.mainVehicle, i))
				end
			
				setVehiclePanelState(vehicleData.vehicleElement, i, getVehiclePanelState(vehicleData.mainVehicle, i))
			end
			
			setVehicleWheelStates(vehicleData.vehicleElement, getVehicleWheelStates(vehicleData.mainVehicle))
		else
			fixVehicle(vehicleData.vehicleElement)
		end
		
		vehicleData.damageView = state
	end
end

function processVehiclePreview(vehicle, x, y, w, h, damageView)
	if not vehicle or not isElement(vehicle) then
		if vehicleData then
			removeEventHandler("onClientPreRender", getRootElement(), onClientVehicleRender)
			
			if isElement(vehicleData.shaderElement) then
				engineRemoveShaderFromWorldTexture(vehicleData.shader, "*", vehicleData.vehicleElement)
				destroyElement(vehicleData.shader)
			end
			
			if isElement(vehicleData.vehicleElement) then
				destroyElement(vehicleData.vehicleElement)
			end

			if isElement(vehicleData.shader) then
				destroyElement(vehicleData.shader)
			end

			if not skinData then
				destroyElement(screenRenderTarget)
			end
			
			vehicleData = nil
		end
		
		return
	end
	
	if vehicleData then
		return
	end
	
	local cameraPosX, cameraPosY, cameraPosZ = getCameraMatrix()
	
	vehicleData = {
		mainVehicle = vehicle,
		vehicleElement = createVehicle(getElementModel(vehicle) or 0, cameraPosX, cameraPosY, cameraPosZ, 0, 0, 0, getVehiclePlateText(vehicle)),
		elementRadius = 0,
		elementPosition = {cameraPosX, cameraPosY, cameraPosZ},
		elementRotation = {0, 0, 145},
		elementRotationOffsets = {0, 0, 0},
		elementPositionOffsets = {0, 0, 0},
		onScreenPosition = {x, y, w, h},
		alpha = 255,
		zDistanceSpread = -1,
		projection = {x / screenWidth, y / screenHeight, w / screenWidth, h / screenHeight},
		shader = dxCreateShader("vehicle.fx", 0, 0, false, "all"),
		damageView = damageView
	}
	
	if not isElement(screenRenderTarget) then
		screenRenderTarget = dxCreateRenderTarget(screenWidth, screenHeight, true)
	end
	
	setElementAlpha(vehicleData.vehicleElement, 254)
	setElementStreamable(vehicleData.vehicleElement, false)
	setElementFrozen(vehicleData.vehicleElement, true)
	setElementCollisionsEnabled(vehicleData.vehicleElement, false)
	setElementCollidableWith(vehicleData.vehicleElement, getCamera(), false)
	
	setTimer(
		function()
			setVehicleColor(vehicleData.vehicleElement, getVehicleColor(vehicle))
		end,
	100, 1)
	
	for k,v in ipairs(getVehicleUpgrades(vehicle)) do
		addVehicleUpgrade(vehicleData.vehicleElement, v)
	end
	
	if damageView then
		for i = 0, 6 do
			if i <= 5 then
				setVehicleDoorState(vehicleData.vehicleElement, i, getVehicleDoorState(vehicle, i))
			end
		
			setVehiclePanelState(vehicleData.vehicleElement, i, getVehiclePanelState(vehicle, i))
		end
		
		setVehicleWheelStates(vehicleData.vehicleElement, getVehicleWheelStates(vehicle))
	end

	vehicleData.elementRadius = math.max(returnMaxValue({getElementBoundingBox(vehicleData.vehicleElement)}), 1)	

	local tempRadius = getElementRadius(vehicleData.vehicleElement)
	if tempRadius > vehicleData.elementRadius then
		vehicleData.elementRadius = tempRadius
	end
	
	if not vehicleData.shader then
		return
	end
	
	if isElement(screenRenderTarget) then
		dxSetShaderValue(vehicleData.shader, "secondRT", screenRenderTarget)
	end
	
	dxSetShaderValue(vehicleData.shader, "sFov", math.rad(({getCameraMatrix()})[8]))
	dxSetShaderValue(vehicleData.shader, "sAspect", screenHeight / screenWidth)
	engineApplyShaderToWorldTexture(vehicleData.shader, "*", vehicleData.vehicleElement)
	
	addEventHandler("onClientPreRender", getRootElement(), onClientVehicleRender, true, "low-5")

	return vehicleData.vehicleElement
end

function renderTheActiveVehicleImage()
	if vehicleData and isElement(screenRenderTarget) then
		local x, y, w, h = unpack(vehicleData.onScreenPosition)
		return dxDrawImageSection(x, y, w, h, x, y, w, h, screenRenderTarget, 0, 0, 0, tocolor(255, 255, 255, vehicleData.alpha))
	end
end

function onClientVehicleRender()
	if not vehicleData.vehicleElement or not vehicleData.shader then
		return
	end
	
	local projPosX, projPosY, projSizeX, projSizeY = unpack(vehicleData.projection)
	projSizeX, projSizeY = projSizeX * 0.5, projSizeY * 0.5
	projPosX, projPosY = projPosX + projSizeX - 0.5, -(projPosY + projSizeY - 0.5)
	projPosX, projPosY = 2 * projPosX, 2 * projPosY
	
	local cameraMatrix = getElementMatrix(getCamera())
	local rotationMatrix = createElementMatrix({0, 0, 0}, vehicleData.elementRotation)
	local positionMatrix = createElementMatrix(vehicleData.elementRotationOffsets, {0, 0, 0})
	local transformMatrix = matrixMultiply(positionMatrix, rotationMatrix)
		
	local multipliedMatrix = matrixMultiply(transformMatrix, cameraMatrix)
	local distTemp = vehicleData.zDistanceSpread
	
	local posTemp = vehicleData.elementPositionOffsets
	local posX, posY, posZ = getPositionFromMatrixOffset(cameraMatrix, {posTemp[1], 1.6 * vehicleData.elementRadius + distTemp + posTemp[2], posTemp[3]})
	local rotX, rotY, rotZ = getEulerAnglesFromMatrix(multipliedMatrix)

	local velocityX, velocityY, velocityZ = getCameraVelocity()
	local vectorLength = math.sqrt(velocityX * velocityX + velocityY * velocityY + velocityZ * velocityZ)
	local cameraCom = {
		cameraMatrix[2][1] * vectorLength,
		cameraMatrix[2][2] * vectorLength,
		cameraMatrix[2][3] * vectorLength
	}
	
	velocityX, velocityY, velocityZ = velocityX + cameraCom[1], velocityY + cameraCom[2], velocityZ + cameraCom[3] + 5

	setElementPosition(vehicleData.vehicleElement, posX + velocityX, posY + velocityY, posZ + velocityZ)				
	setElementRotation(vehicleData.vehicleElement, rotX, rotY, rotZ, "ZXY")
	
	dxSetShaderValue(vehicleData.shader, "sCameraPosition", cameraMatrix[4])
	dxSetShaderValue(vehicleData.shader, "sCameraForward", cameraMatrix[2])
	dxSetShaderValue(vehicleData.shader, "sCameraUp", cameraMatrix[3])
	dxSetShaderValue(vehicleData.shader, "sElementOffset", 0, -distTemp, 0)
	dxSetShaderValue(vehicleData.shader, "sWorldOffset", -velocityX, -velocityY, -velocityZ)
	dxSetShaderValue(vehicleData.shader, "sMoveObject2D", projPosX, projPosY)
	dxSetShaderValue(vehicleData.shader, "sScaleObject2D", math.min(projSizeX, projSizeY) * 2, math.min(projSizeX, projSizeY) * 2)
	dxSetShaderValue(vehicleData.shader, "sProjZMult", 2)
end

function setSkinProjection(x, y, w, h, skinAlpha)
	if not skinData or not skinData.projection then
		return
	end
	
	skinData.projection = {x / screenWidth, y / screenHeight, w / screenWidth, h / screenHeight}
	skinData.onScreenPosition = {x, y, w, h}
	
	if skinAlpha and skinAlpha >= 0 and skinAlpha <= 255 then
		setElementAlpha(skinData.pedElement, math.min(skinAlpha, 254))
		skinData.alpha = skinAlpha
	end
	
	return renderTheActiveSkinImage()
end

function setSkin(skinId)
	if not skinData or not skinId then
		return
	end
	
	setElementModel(skinData.pedElement, skinId)
	setElementCollidableWith(skinData.pedElement, getCamera(), false)
end

function setSkinAlpha(alpha)
	if not skinData or not alpha or alpha < 0 or alpha > 255 then
		return
	end
	
	setElementAlpha(skinData.pedElement, math.min(alpha, 254))
	skinData.alpha = alpha
end

function rotateSkin(cursorRelativeX)
	if not skinData then
		return
	end
	
	skinData.elementRotation[3] = (skinData.elementRotation[3] - (0.5 - cursorRelativeX) * 50) % 360
end

function processSkinPreview(skinId, x, y, w, h)
	if not skinId then
		if skinData then
			removeEventHandler("onClientPreRender", getRootElement(), onClientSkinRender)
			
			if isElement(skinData.shaderElement) then
				engineRemoveShaderFromWorldTexture(skinData.shader, "*", skinData.pedElement)
				destroyElement(skinData.shader)
			end

			if isElement(skinData.shader) then
				destroyElement(skinData.shader)
			end
			
			if isElement(skinData.pedElement) then
				destroyElement(skinData.pedElement)
			end

			if not vehicleData then
				destroyElement(screenRenderTarget)
			end
			
			skinData = nil
		end
		
		return
	end
	
	if skinData then
		return
	end
	
	local isValidModel = isSkinValid(skinId)
	if not isValidModel then
		return
	end

	local cameraPosX, cameraPosY, cameraPosZ = getCameraMatrix()
	
	skinData = {
		pedElement = createPed(skinId or 0, cameraPosX, cameraPosY, cameraPosZ),
		elementRadius = 0,
		elementPosition = {cameraPosX, cameraPosY, cameraPosZ},
		elementRotation = {0, 0, 180},
		elementRotationOffsets = {0, 0, 0},
		elementPositionOffsets = {0, 0, 0},
		onScreenPosition = {x, y, w, h},
		alpha = 255,
		zDistanceSpread = -1,
		projection = {x / screenWidth, y / screenHeight, w / screenWidth, h / screenHeight},
		shader = dxCreateShader("ped.fx", 0, 0, false, "all")
	}
	
	if not isElement(screenRenderTarget) then
		screenRenderTarget = dxCreateRenderTarget(screenWidth, screenHeight, true)
	end
	
	setPedWalkingStyle(skinData.pedElement, getPedWalkingStyle(localPlayer))
	setElementAlpha(skinData.pedElement, 254)
	setElementStreamable(skinData.pedElement, false)
	setElementFrozen(skinData.pedElement, true)
	setElementCollisionsEnabled(skinData.pedElement, false)
	setElementCollidableWith(skinData.pedElement, getCamera(), false)

	skinData.elementRadius = math.max(returnMaxValue({getElementBoundingBox(skinData.pedElement)}), 1)	

	local tempRadius = getElementRadius(skinData.pedElement)
	if tempRadius > skinData.elementRadius then
		skinData.elementRadius = tempRadius
	end
	if not skinData.shader then
		return
	end
	
	if isElement(screenRenderTarget) then
		dxSetShaderValue(skinData.shader, "secondRT", screenRenderTarget)
	end
	
	dxSetShaderValue(skinData.shader, "sFov", math.rad(({getCameraMatrix()})[8]))
	dxSetShaderValue(skinData.shader, "sAspect", screenHeight / screenWidth)
	engineApplyShaderToWorldTexture(skinData.shader, "*", skinData.pedElement)
	
	addEventHandler("onClientPreRender", getRootElement(), onClientSkinRender, true, "low-5")
	
	return skinData.pedElement
end

function renderTheActiveSkinImage()
	if skinData and isElement(screenRenderTarget) then
		local x, y, w, h = unpack(skinData.onScreenPosition)
		return dxDrawImageSection(x, y, w, h, x, y, w, h, screenRenderTarget, 0, 0, 0, tocolor(255, 255, 255, skinData.alpha))
	end
end

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		if isElement(screenRenderTarget) then
			dxSetRenderTarget(screenRenderTarget, true)
			dxSetRenderTarget()
		end
	end, true, "low-5"
)

function onClientSkinRender()
	if not skinData.pedElement or not skinData.shader then
		return
	end
	
	local projPosX, projPosY, projSizeX, projSizeY = unpack(skinData.projection)
	projSizeX, projSizeY = projSizeX * 0.5, projSizeY * 0.5
	projPosX, projPosY = projPosX + projSizeX - 0.5, -(projPosY + projSizeY - 0.5)
	projPosX, projPosY = 2 * projPosX, 2 * projPosY
	
	local cameraMatrix = getElementMatrix(getCamera())
	local rotationMatrix = createElementMatrix({0, 0, 0}, skinData.elementRotation)
	local positionMatrix = createElementMatrix(skinData.elementRotationOffsets, {0, 0, 0})
	local transformMatrix = matrixMultiply(positionMatrix, rotationMatrix)
	
	local multipliedMatrix = matrixMultiply(transformMatrix, cameraMatrix)
	local distTemp = skinData.zDistanceSpread
	
	local posTemp = skinData.elementPositionOffsets
	local posX, posY, posZ = getPositionFromMatrixOffset(cameraMatrix, {posTemp[1], 1.6 * skinData.elementRadius + distTemp + posTemp[2], posTemp[3]})
	local rotX, rotY, rotZ = getEulerAnglesFromMatrix(multipliedMatrix)

	local velocityX, velocityY, velocityZ = getCameraVelocity()
	local vectorLength = math.sqrt(velocityX * velocityX + velocityY * velocityY + velocityZ * velocityZ)
	local cameraCom = {
		cameraMatrix[2][1] * vectorLength,
		cameraMatrix[2][2] * vectorLength,
		cameraMatrix[2][3] * vectorLength
	}
	
	velocityX, velocityY, velocityZ = velocityX + cameraCom[1], velocityY + cameraCom[2], velocityZ + cameraCom[3]
	
	setElementPosition(skinData.pedElement, posX + velocityX, posY + velocityY, posZ + velocityZ)
	setElementRotation(skinData.pedElement, rotX, rotY, rotZ, "ZXY")
	
	dxSetShaderValue(skinData.shader, "sCameraPosition", cameraMatrix[4])
	dxSetShaderValue(skinData.shader, "sCameraForward", cameraMatrix[2])
	dxSetShaderValue(skinData.shader, "sCameraUp", cameraMatrix[3])
	dxSetShaderValue(skinData.shader, "sElementOffset", 0, -distTemp, 0)
	dxSetShaderValue(skinData.shader, "sWorldOffset", -velocityX, -velocityY, -velocityZ)
	dxSetShaderValue(skinData.shader, "sMoveObject2D", projPosX, projPosY)
	dxSetShaderValue(skinData.shader, "sScaleObject2D", math.min(projSizeX, projSizeY) * 2, math.min(projSizeX, projSizeY) * 2)
	dxSetShaderValue(skinData.shader, "sProjZMult", 2)
end

function getCameraVelocity()
	if getTickCount() - getLastTick < 100 then
		return lastCamVelocity[1], lastCamVelocity[2], lastCamVelocity[3]
	end
	
	local currentCamPos = {getElementPosition(getCamera())}
	lastCamVelocity = {currentCamPos[1] - lastCamPos[1], currentCamPos[2] - lastCamPos[2], currentCamPos[3] - lastCamPos[3]}
	lastCamPos = {currentCamPos[1], currentCamPos[2], currentCamPos[3]}
	
	return lastCamVelocity[1], lastCamVelocity[2], lastCamVelocity[3]
end

function isSkinValid(model)
	local foundSlot = false
	
	local validPedModels = getValidPedModels()
	for i = 1, #validPedModels do
		if validPedModels[i] == model then
			foundSlot = i
			break
		end
	end
	
	return foundSlot
end

function returnMaxValue(inTable)
	local itemCount = #inTable
	local outTable = {}	
	
	for i,v in pairs(inTable) do
		outTable[i] = math.abs(v)
	end
	
	local hasChanged
	repeat
		hasChanged = false
		itemCount = itemCount - 1
		
		for i = 1, itemCount do
			if outTable[i] > outTable[i + 1] then
				outTable[i], outTable[i + 1] = outTable[i + 1], outTable[i]
				hasChanged = true
			end
		end
	until hasChanged == false
	
	return outTable[#outTable]
end

function matrixMultiply(mat1, mat2)
	local matrixOut = {}
	
	for i = 1, #mat1 do
		matrixOut[i] = {}
		
		for j = 1, #mat2[1] do
			local num = mat1[i][1] * mat2[1][j]
			
			for n = 2, #mat1[1] do
				num = num + mat1[i][n] * mat2[n][j]
			end
			
			matrixOut[i][j] = num
		end
	end
	
	return matrixOut
end

function createElementMatrix(pos, rot)
	local rx, ry, rz = math.rad(rot[1]), math.rad(rot[2]), math.rad(rot[3])
	return {
		{math.cos(rz) * math.cos(ry) - math.sin(rz) * math.sin(rx) * math.sin(ry), math.cos(ry) * math.sin(rz) + math.cos(rz) * math.sin(rx) * math.sin(ry), -math.cos(rx) * math.sin(ry), 0},
		{-math.cos(rx) * math.sin(rz), math.cos(rz) * math.cos(rx), math.sin(rx), 0},
		{math.cos(rz) * math.sin(ry) + math.cos(ry) * math.sin(rz) * math.sin(rx), math.sin(rz) * math.sin(ry) - math.cos(rz) * math.cos(ry) * math.sin(rx), math.cos(rx) * math.cos(ry), 0},
		{pos[1], pos[2], pos[3], 1}
	}
end

function getEulerAnglesFromMatrix(mat)
	local nz1, nz2, nz3
	
	nz3 = math.sqrt(mat[2][1] * mat[2][1] + mat[2][2] * mat[2][2])
	nz1 = -mat[2][1] * mat[2][3] / nz3
	nz2 = -mat[2][2] * mat[2][3] / nz3
	
	local vx = nz1 * mat[1][1] + nz2 * mat[1][2] + nz3 * mat[1][3]
	local vz = nz1 * mat[3][1] + nz2 * mat[3][2] + nz3 * mat[3][3]
	
	return math.deg(math.asin(mat[2][3])), -math.deg(math.atan2(vx, vz)), -math.deg(math.atan2(mat[2][1], mat[2][2]))
end

function getPositionFromMatrixOffset(mat, pos)
	return pos[1] * mat[1][1] + pos[2] * mat[2][1] + pos[3] * mat[3][1] + mat[4][1], pos[1] * mat[1][2] + pos[2] * mat[2][2] + pos[3] * mat[3][2] + mat[4][2], pos[1] * mat[1][3] + pos[2] * mat[2][3] + pos[3] * mat[3][3] + mat[4][3]
end