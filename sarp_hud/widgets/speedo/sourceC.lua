local imageSizeX = respc(512)
local imageSizeY = respc(384)

local panelSizeX = respc(492)
local panelSizeY = respc(256)

local imageOffsetX = (imageSizeX - panelSizeX) / 2
local imageOffsetY = (imageSizeY - panelSizeY) / 2

local displaySizeX = respc(384)
local displaySizeY = respc(148)

local vehicleIndicators = {}
local vehicleIndicatorTimers = {}
local vehicleIndicatorStates = {}
local vehicleLightStates = {}
local vehicleOverrideLights = {}

local vehicleEngine = false

local defaultConsumption = 1
local consumptionMultipler = 3
local consumptionValue = 0

local outOfFuel = false
local vehicleFuel = 0

local vehicleDistance = 0
local currDistanceValue = 0

local lastOilChange = 0

local vehicleSaveTimer = false

local handBrakeState = false

local nonSeatBeltVehicles = {
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

local specialVehicles = {
	[457] = true,
	[485] = true,
	[486] = true,
	[530] = true,
	[531] = true,
	[539] = true,
	[571] = true,
	[572] = true
}

local seatBeltState = false
local lastSeatBeltStateChange = 0

local seatBeltSoundTimer = false

local lastSeatBeltTick = 0
local isBeltIconLightning = false

local tempomatSpeed = false

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		loadPlayerVehicleData(localPlayer)
	end
)

addEventHandler("onClientPlayerQuit", getRootElement(),
	function()
		local vehicle = getPedOccupiedVehicle(source)

		if vehicle == getPedOccupiedVehicle(localPlayer) then
			setTimer(checkSeatBelt, 1000, 1, vehicle)
		end
	end
)

addEventHandler("onClientVehicleStartEnter", getRootElement(),
	function (player)
		if player == localPlayer then
			setElementData(localPlayer, "player.seatBelt", false)
		end
	end
)

addEventHandler("onClientPlayerRadioSwitch", getLocalPlayer(),
	function (stationId)
		if stationId ~= 0 then
			setRadioChannel(0)
		end
	end
)

addEventHandler("onClientVehicleEnter", getRootElement(),
	function (player, seat)
		if player == localPlayer then
			setElementData(source, "tempomatSpeed", false)
			tempomatSpeed = false

			loadPlayerVehicleData(localPlayer)

			setRadioChannel(0)
		end

		if source == getPedOccupiedVehicle(localPlayer) and player ~= localPlayer and getPedOccupiedVehicleSeat(localPlayer) == 0 then
			local vehicleId = getElementData(source, "vehicle.dbID") or 0

			if vehicleId > 0 then
				updateVehicle(source, 0, vehicleId, getElementModel(source))
			end
		end
	end
)

addEventHandler("onClientVehicleExit", getRootElement(),
	function (player, seat)
		if player == localPlayer then
			if seat == 0 then
				local vehicleId = getElementData(source, "vehicle.dbID") or 0

				if vehicleId > 0 then
					updateVehicle(source, seat, vehicleId, getElementModel(source), true)
				end
			end

			if isTimer(vehicleSaveTimer) then
				killTimer(vehicleSaveTimer)
			end

			vehicleEngine = false
			outOfFuel = false
		end
	end
)

addEventHandler("onClientPlayerVehicleExit", getRootElement(),
	function (vehicle, seat)
		if vehicle == getPedOccupiedVehicle(localPlayer) or source == localPlayer then
			checkSeatBelt(vehicle)
		end
	end
)

addEventHandler("onClientPlayerWasted", getRootElement(),
	function ()
		if source == localPlayer then
			local occupiedVehicle = getPedOccupiedVehicle(localPlayer)

			if getPedOccupiedVehicleSeat(localPlayer) == 0 then
				local vehicleId = getElementData(occupiedVehicle, "vehicle.dbID") or 0

				if vehicleId > 0 then
					updateVehicle(occupiedVehicle, getPedOccupiedVehicleSeat(localPlayer), vehicleId, getElementModel(occupiedVehicle))
				end
			end

			if isTimer(vehicleSaveTimer) then
				killTimer(vehicleSaveTimer)
			end

			vehicleEngine = false
			outOfFuel = false
		end
	end
)

addEventHandler("onClientElementDestroy", getRootElement(),
	function ()
		if source == getPedOccupiedVehicle(localPlayer) then
			if isTimer(vehicleSaveTimer) then
				killTimer(vehicleSaveTimer)
			end
		end
	end
)

function loadPlayerVehicleData(player)
	local vehicle = getPedOccupiedVehicle(player)

	if vehicle and getPedOccupiedVehicleSeat(localPlayer) < 2 then
		local vehicleModel = getElementModel(vehicle)

		vehicleFuel = getElementData(vehicle, "vehicle.fuel")
		vehicleEngine = getElementData(vehicle, "vehicle.engine")
		vehicleDistance = getElementData(vehicle, "vehicle.distance") or 0
		lastOilChange = getElementData(vehicle, "lastOilChange") or 0

		local capacity = fuelTankSize[vehicleModel] or defaultFuelTankSize

		setElementData(vehicle, "vehicle.maxFuel", capacity)

		if not vehicleFuel or vehicleFuel > capacity then
			setElementData(vehicle, "vehicle.fuel", capacity)
			vehicleFuel = capacity
		end

		consumptionValue = 0
		outOfFuel = false

		if isTimer(vehicleSaveTimer) then
			killTimer(vehicleSaveTimer)
		end

		if getPedOccupiedVehicleSeat(player) == 0 then
			vehicleSaveTimer = setTimer(updateVehicle, 60000, 0)
		end

		handBrakeState = getElementData(vehicle, "vehicle.handBrake")
		
		seatBeltState = getElementData(localPlayer, "player.seatBelt")
		lastSeatBeltTick = getTickCount()
		isBeltIconLightning = false
		checkSeatBelt(vehicle)

		tempomatSpeed = getElementData(vehicle, "tempomatSpeed")
	end
end

function updateVehicle(vehicle, seat, dbID, model, saveToDatabase)
	if not vehicle then
		vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and getPedOccupiedVehicleSeat(localPlayer) == 0 and getVehicleType(vehicle) ~= "BMX" then
			local vehicleId = getElementData(vehicle, "vehicle.dbID") or 0

			if vehicleId > 0 then
				local model = getElementModel(vehicle)
				local consumption = modelConsumptions[model] or defaultConsumption
				local fuel = vehicleFuel - consumptionValue / 10000 * consumption * consumptionMultipler

				if fuel < 0 then
					fuel = 0
				end

				triggerServerEvent("updateVehicle", localPlayer, vehicle, vehicleId, saveToDatabase, fuel, vehicleDistance + currDistanceValue, lastOilChange)
			end
		end
	elseif seat == 0 and dbID and model and getVehicleType(vehicle) ~= "BMX" then
		local model = getElementModel(vehicle)
		local consumption = modelConsumptions[model] or defaultConsumption
		local fuel = vehicleFuel - consumptionValue / 10000 * consumption * consumptionMultipler

		if fuel < 0 then
			fuel = 0
		end

		triggerServerEvent("updateVehicle", localPlayer, vehicle, dbID, saveToDatabase, fuel, vehicleDistance + currDistanceValue, lastOilChange)
	end
end

addEventHandler("onClientPreRender", getRootElement(),
	function (deltaTime)
		local vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and vehicleEngine and not outOfFuel then
			local vehicleSpeed = getVehicleSpeed(vehicle)

			local decimal = 1000 / deltaTime
			local distance = vehicleSpeed / 3600 / decimal

			if distance * 1000 >= 1 / decimal then
				consumptionValue = consumptionValue + distance * 1000
			else
				consumptionValue = consumptionValue + 1 / decimal
			end

			local model = getElementModel(vehicle)
			local consumption = modelConsumptions[model] or defaultConsumption

			consumption = consumptionValue / 10000 * consumption * consumptionMultipler

			currDistanceValue = currDistanceValue + distance

			if getVehicleType(vehicle) == "Automobile" then
				lastOilChange = lastOilChange + distance * 1000

				if lastOilChange > 515000 and getPedOccupiedVehicleSeat(localPlayer) == 0 and getElementHealth(vehicle) > 321 then
					setElementHealth(vehicle, 320)
					triggerServerEvent("setVehicleHealthSync", localPlayer, vehicle, 320)

					exports.sarp_alert:showAlert("error", "Mivel nem cserélted ki a motorolajat, ezért az autód motorja elromlott!")

					vehicleEngine = false
				end
			end

			if vehicleFuel - consumption <= 0 and getPedOccupiedVehicleSeat(localPlayer) == 0 then
				outOfFuel = true

				triggerServerEvent("ranOutOfFuel", localPlayer, vehicle)

				setElementData(vehicle, "vehicle.fuel", 0)
				setElementData(vehicle, "vehicle.engine", false)
			end
		end

		if isElement(vehicle) and getVehicleController(vehicle) == localPlayer then
			if getVehicleType(vehicle) == "Automobile" then
				if getElementHealth(vehicle) <= 600 and math.random(100000) <= 20 and getVehicleEngineState(vehicle) then
					setVehicleEngineState(vehicle, false)
					setElementData(vehicle, "vehicle.engine", false)
					exports.sarp_alert:showAlert("error", "A jármű motorja sérült, ezért a jármű lefulladt!")
				end
			end
		end
	end
)

local function drawSpeedoSprite(x, y, w, h, img, color)
	return dxDrawImage(x, y, w, h, "widgets/speedo/files/" .. img, 0, 0, 0, color)
end

local speedoIconWidth = respc(32)
local speedoIconHeight = respc(27)

local function drawSpeedoIconSprite(x, y, uy, img, color)
	return dxDrawImageSection(x, y, speedoIconWidth, speedoIconHeight, 0, uy, 42, 36, "widgets/speedo/files/" .. img, 0, 0, 0, color)
end

render.speedo = function (x, y)
	if occupiedVehicle and isElement(occupiedVehicle) and (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) then
		local vehicleModel = getElementModel(occupiedVehicle)
		local vehtype = getVehicleType(occupiedVehicle)

		x = math.floor(x - imageOffsetX)
		y = math.floor(y - imageOffsetY)

		drawSpeedoSprite(x, y, imageSizeX, imageSizeY, "mainBg.png")

		local vehicleSpeed = getVehicleSpeed(occupiedVehicle)
		local headLightR, headLightG, headLightB = getVehicleHeadLightColor(occupiedVehicle)
		local headLightExR, headLightExG, headLightExB = headLightR, headLightG, headLightB

		if headLightR >= 200 and headLightG >= 200 and headLightB >= 200 then
			headLightR, headLightG, headLightB = 150, 160, 170
			headLightExR, headLightExG, headLightExB = headLightR, headLightG, headLightB
		end

		if vehicleSpeed > 280 then
			headLightR, headLightG, headLightB = interpolateBetween(headLightExR, headLightExG, headLightExB, 130, 60, 60, (vehicleSpeed - 280) / 40, "Linear")
		end

		drawSpeedoSprite(x, y, imageSizeX, imageSizeY, "ledDisplay.png", tocolor(headLightR, headLightG, headLightB))
		drawSpeedoSprite(x, y, imageSizeX, imageSizeY, "ledDisplay2.png")

		local x2 = x + respc(64)
		local y2 = y + respc(112)

		local currentFuel = vehicleFuel - consumptionValue / 10000 * (modelConsumptions[vehicleModel] or defaultConsumption) * consumptionMultipler
		local fuelTankSize = fuelTankSize[vehicleModel] or defaultFuelTankSize
		local vehicleSpeedInMPH = getMilesByKilometers(vehicleSpeed)

		dxDrawText("Speed: " .. math.floor(tostring(vehicleSpeedInMPH)) .. " MPH [" .. getVehicleGear(occupiedVehicle, vehicleSpeedInMPH) .. "]", x2 + respc(15), y2, 0, y2 + respc(40), tocolor(0, 0, 0), 0.75, LEDCalculator24, "left", "center")
		
		dxDrawText(math.floor((vehicleDistance + currDistanceValue) * 10) / 10 .. " mi", x2, y2, x2 + displaySizeX - respc(15), y2 + respc(40), tocolor(0, 0, 0), 0.75, LEDCalculator24, "right", "center")
		
		dxDrawRectangle(x2 + respc(10), y2 + respc(40), displaySizeX - respc(20), 2, tocolor(0, 0, 0))

		dxDrawText("Fuel: " .. math.floor(currentFuel * 10) / 10 .. "/" .. math.floor(fuelTankSize * 10) / 10 .. " GAL", x2 + respc(15), y2 + respc(70), 0, y2 + respc(40), tocolor(0, 0, 0), 0.75, LEDCalculator24, "left", "center")
		
		dxDrawRectangle(x2 + respc(10), y2 + respc(70), displaySizeX - respc(20), 2, tocolor(0, 0, 0))

		local kilometersToChangeOil = 500 - math.floor(math.floor(lastOilChange or 0) / 1000)

		if vehtype == "Automobile" then
			if kilometersToChangeOil <= 0 then
				dxDrawText("- OIL CHANGE NEEDED -", x2, y2 + respc(73), x2 + displaySizeX, 0, tocolor(0, 0, 0), 0.75, LEDCalculator24, "center", "top")
			else
				dxDrawText("Next oil change: " .. kilometersToChangeOil .. " mi", x2, y2 + respc(73), x2 + displaySizeX, 0, tocolor(0, 0, 0), 0.75, LEDCalculator24, "center", "top")
			end
		else
			local timenow = getRealTime()

			dxDrawText(string.format("%04d.%02d.%02d - %02d:%02d:%02d", timenow.year + 1900, timenow.month + 1, timenow.monthday, timenow.hour, timenow.minute, timenow.second), x2, y2 + respc(73), x2 + displaySizeX, 0, tocolor(0, 0, 0), 0.75, LEDCalculator24, "center", "top")
		end

		dxDrawRectangle(x2 + respc(10), y2 + respc(110), displaySizeX - respc(20), 2, tocolor(0, 0, 0))

		if getElementHealth(occupiedVehicle) <= 550 then
			dxDrawText("- CHECK ENGINE -", x2, y2 + displaySizeY - respc(40), x2 + displaySizeX, y2 + displaySizeY, tocolor(0, 0, 0), 0.75, LEDCalculator24, "center", "center")
		elseif tempomatSpeed then
			local speed = math.floor(getMilesByKilometers(tempomatSpeed))

			dxDrawText("- TEMPOMAT: " .. speed .. " MPH -", x2 + 1, y2 + 1 + displaySizeY - respc(40), x2 + 1 + displaySizeX, y2 + 1 + displaySizeY, tocolor(0, 0, 0), 0.75, LEDCalculator24, "center", "center")
			dxDrawText("- TEMPOMAT: " .. speed .. " MPH -", x2, y2 + displaySizeY - respc(40), x2 + displaySizeX, y2 + displaySizeY, tocolor(50, 179, 239), 0.75, LEDCalculator24, "center", "center")
		end

		local x3 = x + respc(21)
		local y3 = y + respc(129)
		local x4 = x + respc(459)

		if vehicleIndicators[occupiedVehicle] then
			if vehicleIndicators[occupiedVehicle].left and not vehicleIndicatorStates[occupiedVehicle] then
				drawSpeedoIconSprite(x3, y3, 0, "lefticons_glow.png")
			end

			if vehicleIndicators[occupiedVehicle].right and not vehicleIndicatorStates[occupiedVehicle] then
				drawSpeedoIconSprite(x4, y3, 0, "righticons_glow.png")
			end

			if vehicleIndicators[occupiedVehicle].left and vehicleIndicators[occupiedVehicle].right and not vehicleIndicatorStates[occupiedVehicle] then
				drawSpeedoIconSprite(x3, y3, 0, "lefticons_glow.png")
				drawSpeedoIconSprite(x4, y3, 0, "righticons_glow.png")
			end
		end

		if getVehicleOverrideLightsEx(occupiedVehicle) == 2 then
			drawSpeedoIconSprite(x3, y3 + respc(27), 36, "lefticons_glow.png")
		end

		if handBrakeState then
			drawSpeedoIconSprite(x3, y3 + respc(27 * 2), 36 * 2, "lefticons_glow.png")
		end

		if vehtype == "Automobile" and not nonSeatBeltVehicles[vehicleModel] then
			if not seatBeltState then
				if getTickCount() - lastSeatBeltTick >= 1024 then
					lastSeatBeltTick = getTickCount()
					isBeltIconLightning = not isBeltIconLightning
				end

				if isBeltIconLightning then
					drawSpeedoIconSprite(x3, y3 + respc(27 * 3), 36 * 3, "lefticons_glow.png")
				end
			end
		end

		if currentFuel / fuelTankSize < 0.1 then
			drawSpeedoIconSprite(x4, y3 + respc(27), 36, "righticons_glow.png")
		end

		if getElementHealth(occupiedVehicle) <= 550 then
			drawSpeedoIconSprite(x4, y3 + respc(27 * 2), 36 * 2, "righticons_glow.png")
		end

		if vehtype == "Automobile" and kilometersToChangeOil <= 0 then
			drawSpeedoIconSprite(x4, y3 + respc(27 * 3), 36 * 3, "righticons_glow.png")
		end

		return true
	end

	return false
end

function seatbeltFunction()
	local vehicle = getPedOccupiedVehicle(localPlayer)

	if isElement(vehicle) and (getVehicleType(vehicle) or "N/A") == "Automobile" then
		local model = getElementModel(vehicle)

		if not nonSeatBeltVehicles[model] then
			if getTickCount() - lastSeatBeltStateChange >= 5000 then
				local seatBelt = getElementData(localPlayer, "player.seatBelt")

				setElementData(localPlayer, "player.seatBelt", not seatBelt)

				if seatBelt then
					exports.sarp_chat:sendLocalMeAction(localPlayer, "kicsatolja a biztonsági övét.")
					playSound(":sarp_assets/audio/vehicles/ovki.ogg", false)
				else
					exports.sarp_chat:sendLocalMeAction(localPlayer, "becsatolja a biztonsági övét.")
					playSound(":sarp_assets/audio/vehicles/ovbe.ogg", false)
				end

				lastSeatBeltStateChange = getTickCount()
			else
				exports.sarp_hud:showAlert("error", "Csak 5 másodpercenként csatolhatod ki/be az öved.")
			end
		end
	end
end
addCommandHandler("ov", seatbeltFunction)
addCommandHandler("öv", seatbeltFunction)
addCommandHandler("seatbelt", seatbeltFunction)
bindKey("F6", "down", "öv")

function seatBeltSound()
	local vehicle = getPedOccupiedVehicle(localPlayer)

	if vehicle then
		playSound("widgets/speedo/files/seatbelt.wav", false)
	else
		if isTimer(seatBeltSoundTimer) then
			killTimer(seatBeltSoundTimer)
		end

		if getElementData(localPlayer, "player.seatBelt") then
			setElementData(localPlayer, "player.seatBelt", false)
		end
	end
end

function checkSeatBelt(vehicle)
	if isElement(vehicle) then
		if getVehicleType(vehicle) == "Automobile" and not nonSeatBeltVehicles[getElementModel(vehicle)] then
			local playSound = false

			for k, v in pairs(getVehicleOccupants(vehicle)) do
				if getElementType(v) == "player" and not getElementData(v, "player.seatBelt") then
					playSound = true
					break
				end
			end
	
			if not playSound then
				if isTimer(seatBeltSoundTimer) then
					killTimer(seatBeltSoundTimer)
				end
			elseif not isTimer(seatBeltSoundTimer) then
				seatBeltSoundTimer = setTimer(seatBeltSound, 1024, 0)
			end
		elseif isTimer(seatBeltSoundTimer) then
			killTimer(seatBeltSoundTimer)
		end
	end
end

addEventHandler("onClientKey", getRootElement(),
	function (key, pressDown)
		local vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and getPedOccupiedVehicleSeat(localPlayer) == 0 and not isCursorShowing() and not isConsoleActive() then
			local vehicleType = getVehicleType(vehicle)
			local model = getElementModel(vehicle)

			if vehicleType == "Automobile" or vehicleType == "Quad" or specialVehicles[model] then
				if pressDown then
					if key == "mouse1" then
						setElementData(vehicle, "emergencyIndicator", false)
						setElementData(vehicle, "rightIndicator", false)
						setElementData(vehicle, "leftIndicator", not getElementData(vehicle, "leftIndicator"))
					elseif key == "mouse2" then
						setElementData(vehicle, "emergencyIndicator", false)
						setElementData(vehicle, "leftIndicator", false)
						setElementData(vehicle, "rightIndicator", not getElementData(vehicle, "rightIndicator"))
					elseif key == "F2" then
						setElementData(vehicle, "leftIndicator", false)
						setElementData(vehicle, "rightIndicator", false)
						setElementData(vehicle, "emergencyIndicator", not getElementData(vehicle, "emergencyIndicator"))
					end
				end
			end
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if source == localPlayer and dataName == "player.seatBelt" then
			seatBeltState = getElementData(localPlayer, "player.seatBelt")
			lastSeatBeltTick = getTickCount()
			isBeltIconLightning = false
		end

		if dataName == "player.seatBelt"then
			local localVehicle = getPedOccupiedVehicle(localPlayer)
			local sourceVehicle = getPedOccupiedVehicle(source)

			if localVehicle and sourceVehicle and localVehicle == sourceVehicle then
				if source ~= localPlayer then
					if getElementData(source, "player.seatBelt") then
						playSound(":sarp_assets/audio/vehicles/ovbe.ogg", false)
					else
						playSound(":sarp_assets/audio/vehicles/ovki.ogg", false)
					end
				end

				checkSeatBelt(localVehicle)
			end
		end

		if isElement(source) and getPedOccupiedVehicle(localPlayer) == source then
			local dataValue = getElementData(source, dataName)

			if dataName == "vehicle.fuel" then
				if dataValue then
					vehicleFuel = tonumber(dataValue)
					consumptionValue = 0

					if vehicleFuel <= 0 then
						vehicleFuel = 0
						outOfFuel = true

						triggerServerEvent("ranOutOfFuel", localPlayer, source)
						setElementData(source, "vehicle.fuel", 0)
						setElementData(source, "vehicle.engine", false)

						exports.sarp_alert:showAlert("error", "Kifogyott az üzemanyag!")
					else
						outOfFuel = false
					end
				end
			elseif dataName == "vehicle.distance" then
				if dataValue then
					vehicleDistance = tonumber(dataValue)
					currDistanceValue = 0
				end
			elseif dataName == "vehicle.engine" then
				vehicleEngine = getElementData(source, "vehicle.engine") or false
			elseif dataName == "lastOilChange" then
				if dataValue then
					lastOilChange = tonumber(dataValue)
				end
			elseif dataName == "vehicle.handBrake" then
				handBrakeState = getElementData(source, "vehicle.handBrake")
			elseif dataName == "tempomatSpeed" then
				tempomatSpeed = getElementData(source, "tempomatSpeed")
			end
		end

		if dataName == "leftIndicator" then
			if not vehicleIndicators[source] then
				vehicleIndicators[source] = {}
			end

			if not vehicleLightStates[source] then
				vehicleLightStates[source] = {}

				for i = 0, 3 do
					vehicleLightStates[source][i] = 0
				end
			end

			if not vehicleOverrideLights[source] then
				local lightState = getElementData(source, "vehicle.light")

				if not lightState then
					vehicleOverrideLights[source] = 1
				else
					vehicleOverrideLights[source] = 2
				end
			end

			if getElementData(source, dataName) then
				vehicleIndicators[source].left = true

				vehicleLightStates[source][0] = getVehicleLightState(source, 0)
				vehicleLightStates[source][3] = getVehicleLightState(source, 3)
				vehicleOverrideLights[source] = getVehicleOverrideLights(source)

				setVehicleOverrideLights(source, 2)

				if not vehicleIndicatorTimers[source] then
					processIndicatorEffect(source)
					vehicleIndicatorTimers[source] = setTimer(processIndicatorEffect, 350, 0, source)

					vehicleLightStates[source][1] = getVehicleLightState(source, 1)
					vehicleLightStates[source][2] = getVehicleLightState(source, 2)
				end

				if vehicleOverrideLights[source] ~= 2 then
					setVehicleLightState(source, 1, 1)
					setVehicleLightState(source, 2, 1)
				end

				vehicleIndicatorStates[source] = true
			else
				vehicleIndicators[source].left = false

				setVehicleLightState(source, 0, vehicleLightStates[source][0] or 0)
				setVehicleLightState(source, 3, vehicleLightStates[source][3] or 0)

				if not vehicleIndicators[source].left then
					setVehicleOverrideLights(source, vehicleOverrideLights[source])

					setVehicleLightState(source, 1, vehicleLightStates[source][1] or 0)
					setVehicleLightState(source, 2, vehicleLightStates[source][2] or 0)

					if isTimer(vehicleIndicatorTimers[source]) then
						killTimer(vehicleIndicatorTimers[source])
						vehicleIndicatorTimers[source] = nil
					end

					vehicleIndicatorStates[source] = false
				end
			end
		end

		if dataName == "rightIndicator" then
			if not vehicleIndicators[source] then
				vehicleIndicators[source] = {}
			end

			if not vehicleLightStates[source] then
				vehicleLightStates[source] = {}

				for i = 0, 3 do
					vehicleLightStates[source][i] = 0
				end
			end

			if not vehicleOverrideLights[source] then
				local lightState = getElementData(source, "vehicle.light")

				if not lightState then
					vehicleOverrideLights[source] = 1
				else
					vehicleOverrideLights[source] = 2
				end
			end

			if getElementData(source, dataName) then
				vehicleIndicators[source].right = true

				vehicleLightStates[source][1] = getVehicleLightState(source, 1)
				vehicleLightStates[source][2] = getVehicleLightState(source, 2)
				vehicleOverrideLights[source] = getVehicleOverrideLights(source)

				setVehicleOverrideLights(source, 2)

				if not vehicleIndicatorTimers[source] then
					processIndicatorEffect(source)
					vehicleIndicatorTimers[source] = setTimer(processIndicatorEffect, 350, 0, source)

					vehicleLightStates[source][0] = getVehicleLightState(source, 0)
					vehicleLightStates[source][3] = getVehicleLightState(source, 3)
				end

				if vehicleOverrideLights[source] ~= 2 then
					setVehicleLightState(source, 0, 1)
					setVehicleLightState(source, 3, 1)
				end

				vehicleIndicatorStates[source] = true
			else
				vehicleIndicators[source].right = false

				setVehicleLightState(source, 1, vehicleLightStates[source][1] or 0)
				setVehicleLightState(source, 2, vehicleLightStates[source][2] or 0)

				if not vehicleIndicators[source].right then
					setVehicleOverrideLights(source, vehicleOverrideLights[source])
					setVehicleLightState(source, 0, vehicleLightStates[source][0] or 0)
					setVehicleLightState(source, 3, vehicleLightStates[source][3] or 0)

					if isTimer(vehicleIndicatorTimers[source]) then
						killTimer(vehicleIndicatorTimers[source])
						vehicleIndicatorTimers[source] = nil
					end

					vehicleIndicatorStates[source] = false
				end
			end
		end

		if dataName == "emergencyIndicator" then
			if not vehicleIndicators[source] then
				vehicleIndicators[source] = {}
			end

			if not vehicleLightStates[source] then
				vehicleLightStates[source] = {}

				for i = 0, 3 do
					vehicleLightStates[source][i] = 0
				end
			end

			if not vehicleOverrideLights[source] then
				local lightState = getElementData(source, "vehicle.light")

				if not lightState then
					vehicleOverrideLights[source] = 1
				else
					vehicleOverrideLights[source] = 2
				end
			end

			if getElementData(source, dataName) then
				vehicleIndicators[source].left = true
				vehicleIndicators[source].right = true

				for i = 0, 3 do
					vehicleLightStates[source][i] = getVehicleLightState(source, i)
				end

				vehicleOverrideLights[source] = getVehicleOverrideLights(source)

				setVehicleOverrideLights(source, 2)

				if not vehicleIndicatorTimers[source] then
					processIndicatorEffect(source)
					vehicleIndicatorTimers[source] = setTimer(processIndicatorEffect, 350, 0, source)
				end

				if vehicleOverrideLights[source] ~= 2 then
					for i = 0, 3 do
						setVehicleLightState(source, i, 1)
					end
				end

				vehicleIndicatorStates[source] = true
			else
				vehicleIndicators[source].left = false
				vehicleIndicators[source].right = false

				for i = 0, 3 do
					setVehicleLightState(source, i, vehicleLightStates[source][i] or 0)
				end

				setVehicleOverrideLights(source, vehicleOverrideLights[source])

				if isTimer(vehicleIndicatorTimers[source]) then
					killTimer(vehicleIndicatorTimers[source])
					vehicleIndicatorTimers[source] = nil
				end

				vehicleIndicatorStates[source] = false
			end
		end
	end
)

function processIndicatorEffect(vehicle)
	if isElement(vehicle) then
		if vehicleIndicators[vehicle].left then
			if vehicleLightStates[vehicle][0] ~= 1 then
				if vehicleIndicatorStates[vehicle] then
					setVehicleLightState(vehicle, 0, 0)
				else
					setVehicleLightState(vehicle, 0, 1)
				end
			end

			if vehicleLightStates[vehicle][3] ~= 1 then
				if vehicleIndicatorStates[vehicle] then
					setVehicleLightState(vehicle, 3, 0)
				else
					setVehicleLightState(vehicle, 3, 1)
				end
			end

			if vehicle == getPedOccupiedVehicle(localPlayer) then
				currentIndicatorState = vehicleIndicatorStates[vehicle]
			end
		end

		if vehicleIndicators[vehicle].right then
			if vehicleLightStates[vehicle][1] ~= 1 then
				if vehicleIndicatorStates[vehicle] then
					setVehicleLightState(vehicle, 1, 0)
				else
					setVehicleLightState(vehicle, 1, 1)
				end
			end

			if vehicleLightStates[vehicle][2] ~= 1 then
				if vehicleIndicatorStates[vehicle] then
					setVehicleLightState(vehicle, 2, 0)
				else
					setVehicleLightState(vehicle, 2, 1)
				end
			end

			if vehicle == getPedOccupiedVehicle(localPlayer) then
				currentIndicatorState = vehicleIndicatorStates[vehicle]
			end
		end

		if vehicle == getPedOccupiedVehicle(localPlayer) and vehicleIndicatorStates[vehicle] then
			playSound(":sarp_vehicles/files/turnsignal.ogg")
		end

		vehicleIndicatorStates[vehicle] = not vehicleIndicatorStates[vehicle]
	else
		killTimer(sourceTimer)
	end
end

function getVehicleOverrideLightsEx(vehicle)
	if vehicleIndicators[vehicle] and (vehicleIndicators[vehicle].right or vehicleIndicators[vehicle].left) then
		return vehicleIndicatorStates[vehicle]
	end

	return getVehicleOverrideLights(vehicle)
end

function getConsumption(model)
	return modelConsumptions[model] or defaultConsumption
end

function getBoardDatas(model)
	local consumption = modelConsumptions[model] or defaultConsumption

	return math.floor(vehicleFuel - consumptionValue / 10000 * consumption * consumptionMultipler), math.floor(vehicleDistance + currDistanceValue), lastOilChange
end

function getMilesByKilometers(kilometers)
	return kilometers * 0.621371192
end

function getKilometersByMiles(miles)
	return miles * 1.609344
end

function getGallonByLiter(liter)
	return liter * 0.264172052
end

function getLiterByGallon(gallon)
	return gallon * 3.78541178
end

function getVehicleSpeed(vehicle)
	if isElement(vehicle) then
		return getDistanceBetweenPoints3D(0, 0, 0, getElementVelocity(vehicle)) * 180
	end
end

function round(number)
	return math.floor(number * 10 ^ 0 + 0.5) / 10 ^ 0
end

function getVehicleGear(vehicle, speed)
	if vehicle then
		local currentGear = getVehicleCurrentGear(vehicle)
		
		if speed == 0 then
			return "N"
		else
			if currentGear == 0 then
				return "R"
			else
				return tostring(currentGear)
			end
		end
	end
end