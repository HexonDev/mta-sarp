local screenX, screenY = guiGetScreenSize()

local nonSeatBeltsVehicle = {
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true,

	[581] = true,
	[509] = true,
	[481] = true,
	[462] = true,
	[521] = true,
	[463] = true,
	[510] = true,
	[522] = true,
	[461] = true,
	[448] = true,
	[468] = true,
	[586] = true,

	[432] = true,
	[531] = true,
	[583] = true,
}

addCommandHandler("oldcar",
	function ()
		outputChatBox(exports.sarp_core:getServerTag("info") .. "Előző járműved: #ffff99" .. getElementData(localPlayer, "theOldCar") or "-", 0, 0, 0, true)
	end
)

function windowsFunction()
	local vehicle = getPedOccupiedVehicle(localPlayer)

	if isElement(vehicle) and not nonSeatBeltsVehicle[getElementModel(vehicle)] then
		local windowState = getElementData(vehicle, "vehicle.windowState")

		if not windowState then
			windowState = true
			setElementData(vehicle, "vehicle.windowState", true)
			exports.sarp_chat:sendLocalMeAction(localPlayer, "lehúzza a jármű ablakait.")
		else
			windowState = false
			setElementData(vehicle, "vehicle.windowState", false)
			exports.sarp_chat:sendLocalMeAction(localPlayer, "felhúzza a jármű ablakait.")
		end

		for i = 2, 5 do
			setVehicleWindowOpen(vehicle, i, windowState)
		end
	end
end
addCommandHandler("ablak", windowsFunction)
addCommandHandler("window", windowsFunction)

addEvent("onVehicleLockEffect", true)
addEventHandler("onVehicleLockEffect", getRootElement(),
	function ()
		if isElement(source) then
			processLockEffect(source)
		end
	end
)

function processLockEffect(vehicle)
	if isElement(vehicle) then
		if getVehicleOverrideLights(vehicle) == 0 or getVehicleOverrideLights(vehicle) == 1 then
			setVehicleOverrideLights(vehicle, 2)
		else
			setVehicleOverrideLights(vehicle, 1)
		end
		
		setTimer(
			function()
				if getVehicleOverrideLights(vehicle) == 0 or getVehicleOverrideLights(vehicle) == 1 then
					setVehicleOverrideLights(vehicle, 2)
				else
					setVehicleOverrideLights(vehicle, 1)
				end
			end,
		250, 3)
	end
end

bindKey("k", "down",
	function ()
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
		local playerInterior = getElementInterior(localPlayer)
		local playerDimension = getElementDimension(localPlayer)

		local vehicleFound = getPedOccupiedVehicle(localPlayer)
		local lastMinDistance = math.huge

		if not isElement(vehicleFound) then
			local vehicles = getElementsByType("vehicle", getRootElement(), true)

			for i = 1, #vehicles do
				local vehicle = vehicles[i]

				if isElement(vehicle) and getElementInterior(vehicle) == playerInterior and getElementDimension(vehicle) == playerDimension then
					local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, getElementPosition(vehicle))

					if distance <= 5 and distance < lastMinDistance then
						lastMinDistance = distance
						vehicleFound = vehicle
					end
				end
			end
		end

		if isElement(vehicleFound) then
			triggerServerEvent("toggleVehicleLock", localPlayer, vehicleFound, getElementsByType("player", getRootElement(), true), {getPedTask(localPlayer, "primary", 3)})
		end
	end
)

local engineStartTimer = false
local preEngineStart = false
local lastEngineStart = 0

bindKey("j", "both",
	function (key, state)
		if not getElementData(localPlayer, "loggedIn") then
			return
		end

		local playerVehicle = getPedOccupiedVehicle(localPlayer)

		if playerVehicle then
			if getVehicleOccupant(playerVehicle) == localPlayer then
				if getVehicleType(playerVehicle) ~= "BMX" then
					if state == "down" then
						if not getElementData(playerVehicle, "vehicle.engine") then
							preEngineStart = true
						else
							triggerServerEvent("toggleVehicleEngine", localPlayer, playerVehicle, false)
						end
					elseif state == "up" then
						preEngineStart = false
					end
				end
			end
		end
	end
)

bindKey("space", "both",
	function (key, state)
		if not getElementData(localPlayer, "loggedIn") then
			return
		end

		if preEngineStart then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)

			if playerVehicle then
				if getVehicleOccupant(playerVehicle) == localPlayer then
					if getVehicleType(playerVehicle) ~= "BMX" then
						if state == "down" then
							if not isTimer(engineStartTimer) and getTickCount() - lastEngineStart >= 1500 then
								triggerServerEvent("syncVehicleSound", playerVehicle, "3d", ":sarp_assets/audio/vehicles/starter.ogg", getElementsByType("player", root, true))

								engineStartTimer = setTimer(
									function()
										triggerServerEvent("toggleVehicleEngine", localPlayer, playerVehicle, true)

										lastEngineStart = getTickCount()
									end,
								1300, 1)
							end
						elseif state == "up" then
							preEngineStart = false
						end
					end
				end
			end
		end
	end
)

bindKey("l", "down",
	function ()
		if isPedInVehicle(localPlayer) then
			local vehicle = getPedOccupiedVehicle(localPlayer)

			if getVehicleType(vehicle) ~= "BMX" and getVehicleOccupant(vehicle) == localPlayer then
				if not getElementData(vehicle, "emergencyIndicator") and not getElementData(vehicle, "leftIndicator") and not getElementData(vehicle, "rightIndicator") then
					triggerServerEvent("toggleVehicleLights", localPlayer, vehicle)
				end
			end
		end
	end
)

addEvent("playVehicleSound", true)
addEventHandler("playVehicleSound", getRootElement(),
	function (type, path)
		if isElement(source) then
			if type == "3d" then
				local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
				local sourceInterior = getElementInterior(source)
				local sourceDimension = getElementDimension(source)
				local soundElement = playSound3D(path, sourcePosX, sourcePosY, sourcePosZ)

				if isElement(soundElement) then
					setElementInterior(soundElement, sourceInterior)
					setElementDimension(soundElement, sourceDimension)

					attachElements(soundElement, source)
				end
			else
				playSound(path)
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		if getElementData(localPlayer, "loggedIn") then
			--setTimer(triggerServerEvent, 2000, 1, "loadPlayerVehicles", localPlayer, getElementData(localPlayer, "char.ID"))
		end
	end
)

addEventHandler("onClientVehicleEnter", getRootElement(),
	function (player, seat)
		setVehicleDoorOpenRatio(source, 2, 0, 0)
		setVehicleDoorOpenRatio(source, 3, 0, 0)
		setVehicleDoorOpenRatio(source, 4, 0, 0)
		setVehicleDoorOpenRatio(source, 5, 0, 0)

		if getVehicleOverrideLights(source) == 0 then
			setVehicleOverrideLights(source, 1)
			setElementData(source, "vehicle.light", false)
		end

		if player == localPlayer then
			if getVehicleType(source) == "BMX" then
				setVehicleEngineState(source, true)
			end

			setElementData(localPlayer, "theOldCar", getElementData(source, "vehicle.dbID"))

			if seat == 0 then
				if getElementData(source, "vehicle.wheelClamp") then
					toggleHandBrakeInfo(true, true)
				elseif getElementData(source, "vehicle.handBrake") then
					toggleHandBrakeInfo(true)
				end

				outputChatBox(exports.sarp_core:getServerTag().."A járművet a J + SPACE egyidejű lenyomásával tudod beindítani, a biztonsági övet pedig az F6 lenyomásával tudod bekötni.",255,255,255,true)
			else
				outputChatBox(exports.sarp_core:getServerTag().."A biztonsági övet az F6 lenyomásával tudod bekötni.",255,255,255,true)
			end
		end
	end
)

addEventHandler("onClientVehicleStartEnter", getRootElement(),
	function (player, seat, door)
		if player == localPlayer then
			if getVehicleType(source) == "Bike" or getVehicleType(source) == "BMX" or getVehicleType(source) == "Boat" then
				if getElementData(source, "vehicle.locked") then
					cancelEvent()
					exports.sarp_hud:showAlert("error", "Ez a jármű zárva van!")
				end
			end
		end
	end
)

addEventHandler("onClientVehicleStartExit", getRootElement(),
	function (player, seat, door)
		if seat == 0 and player == localPlayer then
			toggleHandBrakeInfo()
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" then
			setVehicleDoorOpenRatio(source, 2, 0, 0)
			setVehicleDoorOpenRatio(source, 3, 0, 0)
			setVehicleDoorOpenRatio(source, 4, 0, 0)
			setVehicleDoorOpenRatio(source, 5, 0, 0)
			
			for i = 0, 6 do
				setVehiclePanelState(source, i, getVehiclePanelState(source, i))
			end
		end
	end
)

local brakePanelState = false
local brakePanelWidth = 10
local brakePanelHeight = 250
local brakePanelPosX = screenX - brakePanelWidth - 12
local brakePanelPosY = screenY / 2 - brakePanelHeight / 2
local brakeState = 1
local brakeLastState = false
local brakeInfoBinded = false

function informatePlayerAboutHandbrake()
	local playerVehicle = getPedOccupiedVehicle(localPlayer)

	if isElement(playerVehicle) and getVehicleEngineState(playerVehicle) then
		exports.sarp_hud:showInfobox("error", "Amíg be van húzva a kézifék, nem indulhatsz el.")
	end
end

function informatePlayerAboutWheelClamp()
	local playerVehicle = getPedOccupiedVehicle(localPlayer)

	if isElement(playerVehicle) and getVehicleEngineState(playerVehicle) then
		exports.sarp_hud:showInfobox("error", "Amíg kerékbilincs van a járművön nem indulhatsz el.")
	end
end

function toggleHandBrakeInfo(state, wheelClamp)
	if state and not brakeInfoBinded then
		toggleControl("accelerate", false)
		toggleControl("brake_reverse", false)

		if not wheelClamp then
			bindKey("accelerate", "down", informatePlayerAboutHandbrake)
			bindKey("brake_reverse", "down", informatePlayerAboutHandbrake)
		else
			bindKey("accelerate", "down", informatePlayerAboutWheelClamp)
			bindKey("brake_reverse", "down", informatePlayerAboutWheelClamp)
		end

		brakeInfoBinded = true
	else
		toggleControl("accelerate", true)
		toggleControl("brake_reverse", true)

		if not wheelClamp then
			unbindKey("accelerate", "down", informatePlayerAboutHandbrake)
			unbindKey("brake_reverse", "down", informatePlayerAboutHandbrake)
		else
			unbindKey("accelerate", "down", informatePlayerAboutWheelClamp)
			unbindKey("brake_reverse", "down", informatePlayerAboutWheelClamp)
		end

		brakeInfoBinded = false
	end
end

addEventHandler("onClientCursorMove", getRootElement(),
	function (relX, relY, absX, absY)
		if not isMTAWindowActive() and getKeyState("lalt") and brakePanelState then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)
			local vehicleType = getVehicleType(playerVehicle)
			local handBrake = getElementData(playerVehicle, "vehicle.handBrake")
			
			if not brakeLastState then
				if handBrake then
					brakeLastState = 1
					relY = 2
					setCursorPosition(screenX / 2, screenY)
				else
					brakeLastState = 0
					relY = 0
					setCursorPosition(screenX / 2, 0)
				end
			end

			local y = relY * 2

			if y < 0.25 then
				if handBrake and not getElementData(playerVehicle, "vehicle.wheelClamp") then
					if vehicleType == "Automobile" then
						setPedControlState(localPlayer, "handbrake", false)
						triggerServerEvent("onVehicleHandbrakeStateChange", playerVehicle, false, true)
					else
						triggerServerEvent("onVehicleHandbrakeStateChange", playerVehicle, false)
					end

					toggleHandBrakeInfo()
				end

				if y < 0 then
					y = 0
				end
			elseif y > 1.75 then
				if not handBrake and not getElementData(playerVehicle, "vehicle.wheelClamp") then
					if vehicleType == "Automobile" then
						setPedControlState(localPlayer, "handbrake", true)
						triggerServerEvent("onVehicleHandbrakeStateChange", playerVehicle, true, true)
					else
						triggerServerEvent("onVehicleHandbrakeStateChange", playerVehicle, true)
					end

					toggleHandBrakeInfo(true)
				end

				if y > 2 then
					y = 2
				end
			end

			brakeState = y
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if dataName == "vehicle.handBrake" then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)

			if playerVehicle == source then
				if getElementData(source, "vehicle.handBrake") then
					playSound("files/handbrake.wav")
				end
			end
		elseif dataName == "vehicle.wheelClamp" then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)

			if playerVehicle == source and getVehicleController(source) == localPlayer then
				if getElementData(source, "vehicle.wheelClamp") then
					toggleHandBrakeInfo(true, true)
				elseif not getElementData(source, "vehicle.handBrake") then
					toggleHandBrakeInfo()
				else
					toggleHandBrakeInfo()
					toggleHandBrakeInfo(true)
				end
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local playerVehicle = getPedOccupiedVehicle(localPlayer)

		if playerVehicle and getPedOccupiedVehicleSeat(localPlayer) == 0 then
			local vehicleType = getVehicleType(playerVehicle)
			local task = getPedSimplestTask(localPlayer)

			if getKeyState("lalt") and task == "TASK_SIMPLE_CAR_DRIVE" and not getElementData(playerVehicle, "vehicle.wheelClamp") then
				local velocityX, velocityY, velocityZ = getElementVelocity(playerVehicle)
				local speed = getDistanceBetweenPoints3D(0, 0, 0, velocityX, velocityY, velocityZ) * 180

				if (vehicleType ~= "Automobile" and speed <= 5) or vehicleType == "Automobile" then
					brakePanelState = true
					showCursor(true)
					setCursorAlpha(0)
				end
			else
				brakePanelState = false
				showCursor(false)
				setCursorAlpha(255)
				brakeLastState = false
			end

			if brakePanelState then
				local sizeForZone = brakePanelHeight / 3

				dxDrawRectangle(brakePanelPosX, brakePanelPosY, brakePanelWidth, brakePanelHeight, tocolor(0, 0, 0, 200))

				dxDrawRectangle(brakePanelPosX + 2, brakePanelPosY + 2, brakePanelWidth - 4, sizeForZone - 4, tocolor(50, 200, 50))

				dxDrawRectangle(brakePanelPosX + 2, brakePanelPosY + 2 + brakePanelHeight - sizeForZone, brakePanelWidth - 4, sizeForZone - 4, tocolor(200, 50, 50))

				dxDrawRectangle(brakePanelPosX + 2, brakePanelPosY + 2 + sizeForZone * brakeState, brakePanelWidth - 4, sizeForZone - 4, tocolor(255, 255, 255, 160))
			end

			if vehicleType == "Automobile" then
				if getElementData(playerVehicle, "vehicle.handBrake") then
					local velocityX, velocityY, velocityZ = getElementVelocity(playerVehicle)
					local speed = getDistanceBetweenPoints3D(0, 0, 0, velocityX, velocityY, velocityZ) * 180

					if speed <= 5 then
						setElementFrozen(playerVehicle, true)
					else
						setPedControlState(localPlayer, "handbrake", true)
					end
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("nearbyvehicles", 1, "Közelben lévő járművek")
addCommandHandler("nearbyvehicles",
	function (cmd, distance)
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if not distance then
				distance = 15
			elseif tonumber(distance) then
				distance = tonumber(distance)
			end

			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local nearbyVehicles = {}
			
			for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
				local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(v)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, vehiclePosX, vehiclePosY, vehiclePosZ) <= distance then
					local model = getElementModel(v)

					table.insert(nearbyVehicles, {
						model,
						exports.sarp_mods_veh:getVehicleNameFromModel(model),
						getElementData(v, "vehicle.dbID") or 0,
						getVehiclePlateText(v)
					})
				end
			end
			
			if #nearbyVehicles > 0 then
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Közeledben lévő járművek #ffff99(" .. distance .. " yard):", 0, 0, 0, true)

				for k, v in ipairs(nearbyVehicles) do
					outputChatBox("    * #d75959Típus: #ffffff" .. v[1] .. " (" .. v[2] .. ") | #d75959Azonosító: #ffffff" .. (v[3] == 0 and "Nincs (ideiglenes)" or v[3]) .. " | #d75959Rendszám: #ffffff" .. (v[4] or "Nincs"), 255, 255, 255, true)
				end
			else
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Nincs egyetlen jármű sem a közeledben.", 0, 0, 0, true)
			end
		end
	end
)

local vehicleStatsHandled = false
local RobotoFont = false
local RobotoBolderFont = false

exports.sarp_admin:addAdminCommand("dl", 1, "Jármű adatok mutatása a járművek felett")
addCommandHandler("dl",
	function()
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if vehicleStatsHandled then
				removeEventHandler("onClientRender", getRootElement(), renderVehicleStats)

				if isElement(RobotoFont) then
					destroyElement(RobotoFont)
					RobotoFont = nil
				end

				if isElement(RobotoBolderFont) then
					destroyElement(RobotoBolderFont)
					RobotoBolderFont = nil
				end

				vehicleStatsHandled = false
			else
				RobotoFont = dxCreateFont("files/Roboto.ttf", 10, false, "antialiased")
				RobotoBolderFont = dxCreateFont("files/RobotoB.ttf", 14, false, "antialiased")

				addEventHandler("onClientRender", getRootElement(), renderVehicleStats)

				vehicleStatsHandled = true
			end
		end
	end)

function renderVehicleStats()
	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
	local vehicles = getElementsByType("vehicle", getRootElement(), true)

	for k = 1, #vehicles do
		v = vehicles[k]

		if isElement(v) and isElementOnScreen(v) then
			local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(v)

			if isLineOfSightClear(playerPosX, playerPosY, playerPosZ, vehiclePosX, vehiclePosY, vehiclePosZ, true, false, false, true, false, false, false, localPlayer) then
				local dist = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, vehiclePosX, vehiclePosY, vehiclePosZ)

				if dist <= 75 then
					local screenPosX, screenPosY = getScreenFromWorldPosition(vehiclePosX, vehiclePosY, vehiclePosZ)

					if screenPosX and screenPosY then
						local scaleFactor = 1 - dist / 75

						local vehicleId = getElementData(v, "vehicle.dbID") or "Ideiglenes"
						local vehicleName = getVehicleName(v)
						local vehicleModel = getElementModel(v)

						local sx = dxGetTextWidth(vehicleName .. " (" .. vehicleModel .. ")", scaleFactor, RobotoBolderFont) + 100 * scaleFactor
						local sy = 80 * scaleFactor

						local x = screenPosX - sx / 2
						local y = screenPosY - sy / 2

						dxDrawRectangle(x - 7, y - 7, sx + 14, sy + 14, tocolor(0, 0, 0, 150))
						dxDrawRectangle(x - 5, y - 5, sx + 10, sy + 10, tocolor(0, 0, 0, 125))

						dxDrawText("#32b3ef" .. vehicleName .. " #7cc576(" .. vehicleModel .. ")", x, y, x + sx, y, tocolor(255, 255, 255), scaleFactor, RobotoBolderFont, "center", "top", false, false, false, true)
							
						dxDrawText("Adatbázis ID:", x, y + 25 * scaleFactor, x + sx, 0, tocolor(255, 255, 255), scaleFactor, RobotoFont, "left", "top")
						dxDrawText(vehicleId, x, y + 25 * scaleFactor, x + sx, 0, tocolor(215, 89, 89), scaleFactor, RobotoFont, "right", "top")

						dxDrawRectangle(x, y + 41.5 * scaleFactor, sx, 2, tocolor(255, 255, 255, 50))

						dxDrawText("Rendszám:", x, y + 45 * scaleFactor, x + sx, 0, tocolor(255, 255, 255), scaleFactor, RobotoFont, "left", "top")
						dxDrawText(getVehiclePlateText(v), x, y + 45 * scaleFactor, x + sx, 0, tocolor(50, 179, 239), scaleFactor, RobotoFont, "right", "top")

						dxDrawRectangle(x, y + 61.5 * scaleFactor, sx, 2, tocolor(255, 255, 255, 50))

						dxDrawText("Állapot:", x, y + 65 * scaleFactor, x + sx, 0, tocolor(255, 255, 255), scaleFactor, RobotoFont, "left", "top")
						dxDrawText(math.floor(getElementHealth(v) / 10) .. "%", x, y + 65 * scaleFactor, x + sx, 0, tocolor(50, 179, 239), scaleFactor, RobotoFont, "right", "top")
					end
				end
			end
		end
	end
end