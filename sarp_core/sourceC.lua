local screenX, screenY = guiGetScreenSize()

addEvent("vehicleSpawnProtect", true)
addEventHandler("vehicleSpawnProtect", getRootElement(),
	function (vehicle)
		if isElement(vehicle) then
			local cols = {}

			setElementAlpha(vehicle, 150)

			for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
				setElementCollidableWith(vehicle, v, false)

				table.insert(cols, v)
			end

			for k, v in ipairs(getElementsByType("player", getRootElement(), true)) do
				setElementCollidableWith(vehicle, v, false)

				table.insert(cols, v)
			end

			setTimer(
				function ()
					if isElement(vehicle) then
						for i = 1, #cols do
							if isElement(cols[i]) then
								v = cols[i]
								
								setElementCollidableWith(vehicle, v, true)
							end
						end

						setElementAlpha(vehicle, 255)
					end
				end,
			15000, 1)
		end
	end
)

local quitReasons = {
	unknown = "Ismeretlen",
	quit = "Lecsatlakozott",
	kicked = "Kirúgva",
	banned = "Kitiltva",
	["bad connection"] = "Rossz kapcsolat",
	["timed out"] = "Időtúllépés"
}

addEventHandler("onClientPlayerQuit", getRootElement(),
	function (reason)
		if getElementData(source, "loggedIn") then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
			local distance =  getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, sourcePosX, sourcePosY, sourcePosZ)

			if distance <= 20 then
				local playerName = getElementData(source, "visibleName"):gsub("_", " ")
				local quitReason = quitReasons[string.lower(reason)]

				outputChatBox(">> " .. playerName .. " kilépett a közeledben. [" .. quitReason .. "] Távolság: " .. math.floor(distance) .. " yard", 215, 89, 89, true)
			end
		end
	end
)

local currentDimension = getElementDimension(localPlayer)
local currentInterior = getElementInterior(localPlayer)

addEvent("onClientDimensionChange", true)
addEvent("onClientInteriorChange", true)

local playerDoingAnimation = false
local attachedElementStartRot = false
local rotateableAnims = {}

addEventHandler("onClientRender", getRootElement(),
	function ()
		local activeInterior = getElementInterior(localPlayer)
		local activeDimension = getElementDimension(localPlayer)

		if currentInterior ~= activeInterior then
			triggerEvent("onClientInteriorChange", localPlayer, activeInterior, currentInterior)
			currentInterior = activeInterior
		end

		if currentDimension ~= activeDimension then
			triggerEvent("onClientDimensionChange", localPlayer, activeDimension, currentDimension)
			currentDimension = activeDimension
		end

		local block, anim = getPedAnimation(localPlayer)

		if block then
			playerDoingAnimation = true

			if block == "ped" and rotateableAnims[anim] then
				local cx, cy, cz, lx, ly = getCameraMatrix()
				local angle = math.deg(math.atan2(ly - cy, lx - cx)) - 90

				setPedRotation(localPlayer, angle)
			end
		elseif not block and playerDoingAnimation then
			playerDoingAnimation = false
			toggleAllControls(true, true, false)
		end

		local attachedTo = getElementAttachedTo(localPlayer)

		if attachedTo and getElementType(attachedTo) == "vehicle" then
			local rx, ry, rz = getElementRotation(attachedTo)

			if attachedElementStartRot then
				setPedRotation(localPlayer, rz + attachedElementStartRot)
			else
				attachedElementStartRot = getPedRotation(localPlayer) - rz
			end
		elseif attachedElementStartRot then
			attachedElementStartRot = false
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		setHeatHaze(0)
		setBlurLevel(0)
		setCloudsEnabled(false)
		setBirdsEnabled(false)
		setInteriorSoundsEnabled(false)
		setPedTargetingMarkerEnabled(false)
		setPlayerHudComponentVisible("all", false)
		setPlayerHudComponentVisible("crosshair", true)
		setWorldSpecialPropertyEnabled("randomfoliage", false)
		setWorldSpecialPropertyEnabled("extraairresistance", false)
		
		for k, v in ipairs(getElementsByType("player")) do
			setPedVoice(v, "PED_TYPE_DISABLED")
			setPlayerNametagShowing(v, false)
		end
		
		for k, v in ipairs(getElementsByType("ped")) do
			setPedVoice(v, "PED_TYPE_DISABLED")
		end
		
		setAmbientSoundEnabled("general", true)
		setAmbientSoundEnabled("gunfire", false)
		
		if getElementData(localPlayer, "loggedIn") then
			fadeCamera(true)
		end

		toggleControl("next_weapon", false)
		toggleControl("previous_weapon", false)

		setTimer(
			function()
				setPedControlState("walk", true)
			end,
		500, 0)

		setWorldSoundEnabled(0, 0, false, true)
		setWorldSoundEnabled(0, 29, false, true)
		setWorldSoundEnabled(0, 30, false, true)
	end
)

addEventHandler("onClientPlayerJoin", getRootElement(),
	function ()
		setPlayerNametagShowing(source, false)
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "ped" or getElementType(source) == "player" then
			setPedVoice(source, "PED_TYPE_DISABLED")
		end
	end
)

bindKey("m", "down",
	function ()
		showCursor(not isCursorShowing())
	end
)

addEventHandler("onClientGUIBlur", getRootElement(),
	function ()
		guiSetInputMode("no_binds_when_editing")
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if source == localPlayer then
			if dataName == "acc.adminLevel" then
				if getElementData(source, dataName) >= 9 then
					setDevelopmentMode(true)
				else
					setDevelopmentMode(false)
				end
			elseif dataName == "adminDuty" then
				if getElementData(source, "acc.adminLevel") >= 9 then
					setDevelopmentMode(true)
				else
					setDevelopmentMode(false)
				end
			end
		end
	end
)

local currentPlayingSound = false
local currentPlayingSound3D = false

addEvent("playClientSound", true)
addEventHandler("playClientSound", getRootElement(),
	function (audioPath)
		if isElement(currentPlayingSound) then
			stopSound(currentPlayingSound)
		end

		currentPlayingSound = playSound(audioPath)
		setSoundVolume(currentPlayingSound, 1.5)
	end
)

function playSoundForElement(element, path)
	triggerEvent("playClientSound", element, path)
end

addEvent("playClient3DSound", true)
addEventHandler("playClient3DSound", getRootElement(),
	function (audioPath, x, y, z, looped, elementCheck)
		if isElement(currentPlayingSound3D) and elementCheck then
			stopSound(currentPlayingSound3D)
		end
		
		currentPlayingSound3D = playSound3D(audioPath, x, y, z, looped)
	end
)

function minutesToHours(minutes)
	local totalMin = tonumber(minutes)
	if totalMin then
		local hours = math.floor(totalMin/60)
		local minutes = totalMin - hours*60
		if hours and minutes then
			return hours,minutes
		else
			return 0,0
		end
	end
end

function milisecondsToSeconds(miliseconds)
	local totalMilisecs = tonumber(miliseconds)
	if totalMilisecs then
		local secs = math.floor(totalMilisecs/1000)
		local milisecs = totalMilisecs - secs*1000
		if secs and milisecs then
			return secs,milisecs
		else
			return 0,0
		end
	end
end

function secondsToMinutes(seconds)
	local totalSec = tonumber(seconds)
	if totalSec then
		local seconds = math.fmod(math.floor(totalSec), 60)
		local minutes = math.fmod(math.floor(totalSec/60), 60)
		if seconds and minutes then
			return seconds,minutes
		end
	end
end

addEvent("onCoreStarted", true)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		triggerEvent("onCoreStarted", localPlayer, interfaceFunctions())
	end
)

--[[

*********** Interface elementek meghívása (szkriptek elejére): ***********

	pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

*********** Szükséges elemek onClientRender-be: ***********
	
	buttons = {}

	-- ide jön a te kódod, e két kis rész közé.
	-- csekkolni, hogy aktív-e a gomb: if activeButton == "btn:gombNeve" then -- a btn: előtagot minden gomb elé odateszi!
	-- inputnál: if activeInput == "input:inputNeve" then -- input: előtagot mindig oda teszi automatikusan!!

	local relX, relY = getCursorPosition()

	activeButton = false

	if relX and relY then
		relX = relX * screenX
		relY = relY * screenY

		for k, v in pairs(buttons) do
			if relX >= v[1] and relY >= v[2] and relX <= v[1] + v[3] and relY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end

]]

function interfaceFunctions()
	return {"colorInterpolation", "drawButton", "drawInput", "drawButton2"}
end

local wErTzu666iop = base64Encode
function getInterfaceElements()
	return wErTzu666iop([[

	buttons = {}
	activeButton = false

	local inputLineGetStart = {}
	local inputLineGetInverse = {}

	local inputCursorState = false
	local lastChangeCursorState = 0

	local repeatTimer = false
	local repeatStartTimer = false

	fakeInputs = {}
	selectedInput = false

	function drawInput(key, label, x, y, sx, sy, font, fontScale, a)
		a = a or 1

		if not fakeInputs[key] then
			fakeInputs[key] = ""
		end

		dxDrawRectangle(x, y, sx, sy, tocolor(0, 0, 0, 75 * a))

		local borderColor

		if selectedInput == key then
			borderColor = {colorInterpolation("input:" .. key, 117, 117, 117, 255)}
		elseif activeButton == "input:" .. key then
			borderColor = {colorInterpolation("input:" .. key, 117, 117, 117, 255)}
		else
			borderColor = {colorInterpolation("input:" .. key, 75, 75, 75, 255)}
		end

		if selectedInput == key then
			if not inputLineGetStart[key] then
				inputLineGetInverse[key] = false
				inputLineGetStart[key] = getTickCount()
			end
		elseif inputLineGetStart[key] then
			inputLineGetInverse[key] = getTickCount()
			inputLineGetStart[key] = false
		end

		local lineProgress = 0

		if inputLineGetStart[key] then
			local elapsedTime = getTickCount() - inputLineGetStart[key]
			local progress = elapsedTime / 300

			lineProgress = interpolateBetween(
				0, 0, 0,
				1, 0, 0,
				progress, "Linear")
		elseif inputLineGetInverse[key] then
			local elapsedTime = getTickCount() - inputLineGetInverse[key]
			local progress = elapsedTime / 300

			lineProgress = interpolateBetween(
				1, 0, 0,
				0, 0, 0,
				progress, "Linear")
		end

		lineProgress = sx / 2 * lineProgress

		local activeColor = tocolor(36, 119, 159, 255 * a)
		dxDrawRectangle(x, y + sy - 2, sx, 2, tocolor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] * a))
		dxDrawRectangle(x + sx / 2, y + sy - 2, -lineProgress, 2, activeColor)
		dxDrawRectangle(x + sx / 2, y + sy - 2, lineProgress, 2, activeColor)

		sy = sy - 2

		if utf8.len(fakeInputs[key]) > 0 then
			dxDrawText(fakeInputs[key], x + 3, y, x + sx - 3, y + sy, tocolor(255, 255, 255, 230 * a), fontScale, font, "left", "center", true)
		elseif label then
			dxDrawText(label, x + 3, y, x + sx - 3, y + sy, tocolor(100, 100, 100, 200 * a), fontScale, font, "left", "center", true)
		end

		if selectedInput == key then
			if inputCursorState then
				local contentSizeX = dxGetTextWidth(fakeInputs[key], fontScale, font)

				dxDrawLine(x + 3 + contentSizeX, y + 5, x + 3 + contentSizeX, y + sy - 5, tocolor(230, 230, 230, 255 * a))
			end

			if getTickCount() - lastChangeCursorState >= 500 then
				inputCursorState = not inputCursorState
				lastChangeCursorState = getTickCount()
			end
		end

		buttons["input:" .. key] = {x, y, sx, sy}
	end

	function drawButton(key, text, x, y, w, h, r, g, b, a, font, fontScale, icon, iconFont, iconScale)
		local buttonR, buttonG, buttonB, buttonA
		local borderR, borderG, borderB

		a = a or 1
		font = font or "default-bold"
		fontScale = fontScale or 1

		if activeButton == "btn:" .. key then
			if getKeyState("mouse1") then
				buttonR, buttonG, buttonB, buttonA = colorInterpolation("btn:" .. key, r, g, b, 200, 250)
			else
				buttonR, buttonG, buttonB, buttonA = colorInterpolation("btn:" .. key, r, g, b, 255)
			end

			borderR, borderG, borderB = colorInterpolation("btnBorder:" .. key, r, g, b, 255)
		else
			buttonR, buttonG, buttonB, buttonA = colorInterpolation("btn:" .. key, 59, 59, 59, 255)
			borderR, borderG, borderB = colorInterpolation("btnBorder:" .. key, 117, 117, 117, 255)
		end

		local borderColor = tocolor(borderR, borderG, borderB, 255 * a)

		dxDrawRectangle(x + 1, y + 2, w - 2, h - 4, tocolor(buttonR, buttonG, buttonB, buttonA * a))
		dxDrawRectangle(x, y, w, 2, borderColor)
		dxDrawRectangle(x, y + h - 2, w, 2, borderColor)
		dxDrawRectangle(x - 1, y + 1, 2, h - 2, borderColor)
		dxDrawRectangle(x + w - 1, y + 1, 2, h - 2, borderColor)

		if not icon then
			dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "center", "center")
		elseif not iconFont then
			iconScale = iconScale or h - 5

			local iconWidth = iconScale + 10
			local textWidth = dxGetTextWidth(text, fontScale, font)
			local labelStartX = x + (w - (iconWidth + textWidth)) / 2

			dxDrawImage(math.floor(labelStartX), math.floor(y + (h - iconScale) / 2), iconScale, iconScale, icon, 0, 0, 0, tocolor(255, 255, 255, 255 * a))
			dxDrawText(text, labelStartX + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "left", "center")
		elseif iconFont then
			iconScale = iconScale or fontScale

			local iconWidth = dxGetTextWidth(icon, iconScale, iconFont) + 10
			local textWidth = dxGetTextWidth(text, iconScale, font)
			local labelStartX = x + (w - (iconWidth + textWidth)) / 2

			dxDrawText(icon, labelStartX, y, 0, y + h, tocolor(255, 255, 255, 255 * a), iconScale, iconFont, "left", "center")
			dxDrawText(text, labelStartX + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "left", "center")
		end

		buttons["btn:" .. key] = {x, y, w, h}
	end

	function drawButton2(key, text, x, y, w, h, r, g, b, a, font, fontScale, icon, iconFont, iconScale)
		local buttonR, buttonG, buttonB, buttonA

		if activeButton == key then
			if getKeyState("mouse1") then
				buttonR, buttonG, buttonB, buttonA = colorInterpolation(key, r, g, b, 200, 250)
			else
				buttonR, buttonG, buttonB, buttonA = colorInterpolation(key, r, g, b, 175)
			end
		else
			buttonR, buttonG, buttonB, buttonA = colorInterpolation(key, r, g, b, 125)
		end

		local alphaDifference = 175 - buttonA

		dxDrawRectangle(x, y, w, h, tocolor(buttonR, buttonG, buttonB, (175 - alphaDifference) * a))

		local marginColor = tocolor(buttonR, buttonG, buttonB, (125 + alphaDifference) * a)

		dxDrawLine(x, y, x + w, y, marginColor, 2)
		dxDrawLine(x, y + h, x + w, y + h, marginColor, 2)
		dxDrawLine(x, y, x, y + h, marginColor, 2)
		dxDrawLine(x + w, y, x + w, y + h, marginColor, 2)

		font = font or "default-bold"
		fontScale = fontScale or 1

		if not text and icon then
			iconScale = iconScale or fontScale

			dxDrawText(icon, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * a), iconScale, iconFont, "center", "center")
		elseif not icon then
			dxDrawText(text, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "center", "center")
		elseif not iconFont then
			iconScale = iconScale or h - 5

			local iconWidth = iconScale + 10
			local textWidth = dxGetTextWidth(text, fontScale, font)
			local labelStartX = x + (w - (iconWidth + textWidth)) / 2

			dxDrawImage(math.floor(labelStartX), math.floor(y + (h - iconScale) / 2), iconScale, iconScale, icon, 0, 0, 0, tocolor(255, 255, 255, 255 * a))
			dxDrawText(text, labelStartX + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "left", "center")
		elseif iconFont then
			iconScale = iconScale or fontScale

			local iconWidth = dxGetTextWidth(icon, iconScale, iconFont) + 10
			local textWidth = dxGetTextWidth(text, iconScale, font)
			local labelStartX = x + (w - (iconWidth + textWidth)) / 2

			dxDrawText(icon, labelStartX, y, 0, y + h, tocolor(255, 255, 255, 255 * a), iconScale, iconFont, "left", "center")
			dxDrawText(text, labelStartX + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * a), fontScale, font, "left", "center")
		end

		buttons[key] = {x, y, w, h}
	end

	local colorInterpolationValues = {}
	local lastColorInterpolationValues = {}
	local colorInterpolationTicks = {}

	function colorInterpolation(key, r, g, b, a, duration)
		if not colorInterpolationValues[key] then
			colorInterpolationValues[key] = {r, g, b, a}
			lastColorInterpolationValues[key] = r .. g .. b .. a
		end

		if lastColorInterpolationValues[key] ~= (r .. g .. b .. a) then
			lastColorInterpolationValues[key] = r .. g .. b .. a
			colorInterpolationTicks[key] = getTickCount()
		end

		if colorInterpolationTicks[key] then
			local progress = (getTickCount() - colorInterpolationTicks[key]) / (duration or 500)
			local red, green, blue = interpolateBetween(colorInterpolationValues[key][1], colorInterpolationValues[key][2], colorInterpolationValues[key][3], r, g, b, progress, "Linear")
			local alpha = interpolateBetween(colorInterpolationValues[key][4], 0, 0, a, 0, 0, progress, "Linear")

			colorInterpolationValues[key][1] = red
			colorInterpolationValues[key][2] = green
			colorInterpolationValues[key][3] = blue
			colorInterpolationValues[key][4] = alpha

			if progress >= 1 then
				colorInterpolationTicks[key] = false
			end
		end

		return colorInterpolationValues[key][1], colorInterpolationValues[key][2], colorInterpolationValues[key][3], colorInterpolationValues[key][4]
	end

	]])
end