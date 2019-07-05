local screenX, screenY = guiGetScreenSize()

local minigameState = false
local minigameData = {}

--[[

	PÉLDÁK

	startMinigame("buttons", "successPlayerHelpup", "failedPlayerHelpup", 0.15, 0.2, 115, 40)
	=> Argok: sikeres event, sikertelen event, sebesség, befejezési sebesség, sűrűség, gomb mennyiség

	startMinigame("balance", "successPlayerHelpup", "failedPlayerHelpup", 1, 10000)
	-- Argok: sikeres event, sikertelen event, irányíthatóság (minél nagyobb annál irányíthatóbb), hány millisecondig kelljen egyensúlyozni

]]

addCommandHandler("minigame",
	function ()
		startMinigame("balance", "igen", "nem")
		--startMinigame("buttons", "igen", "nem", 0.15, 0.75, 115, 40)
	end
)

addEvent("igen", true)
addEventHandler("igen", getRootElement(),
	function ()
		exports.sarp_hud:showInfobox("success", "Siker :)")
	end
)

addEvent("nem", true)
addEventHandler("nem", getRootElement(),
	function ()
		exports.sarp_hud:showInfobox("error", "Elcseszted :(")
	end
)

function stopMinigame()
	if minigameData then
		if minigameState == "buttons" then
			if isTimer(minigameData.spawnNextButtonTimer) then
				killTimer(minigameData.spawnNextButtonTimer)
				minigameData.spawnNextButtonTimer = nil
			end

			if isElement(minigameData.renderTarget) then
				destroyElement(minigameData.renderTarget)
				minigameData.renderTarget = nil
			end

			if isElement(minigameData.RobotoFont) then
				destroyElement(minigameData.RobotoFont)
				minigameData.RobotoFont = nil
			end
		end
	end

	minigameState = false
	minigameData = {}
end

function startMinigame(gameType, successEvent, failEvent, ...)
	stopMinigame()

	local args = {...}
	minigameData = {}

	if gameType == "buttons" then
		minigameData.buttons = {}
		minigameData.spawnedButtons = 0

		minigameData.renderTarget = dxCreateRenderTarget(622, 55, true)
		minigameData.RobotoFont = dxCreateFont("files/Roboto.ttf", 12, false, "antialiased")

		minigameData.speed = args[1] or 0.15
		minigameData.endSpeed = (args[2] or 0.2) - minigameData.speed
		minigameData.density = args[3] or 105
		minigameData.maxButtonNum = args[4] or 75

		minigameData.interpolateSpeedSet = false
		minigameData.currentBtn = false
		minigameData.btnInKey = false
		minigameData.failCount = 0
		minigameData.successCount = 0
		minigameData.lastRing = false

		minigameData.spawnNextButtonTimer = setTimer(spawnNextButton, 2000, 1)
	elseif gameType == "balance" then
		minigameData.difficulty = args[1] or 1
		minigameData.accelerationMultipler = 0.5
		minigameData.startGame = getTickCount() + 1000
		minigameData.direction = false
		minigameData.lastKey = false
		minigameData.currentX = 10
		minigameData.acceleration = 0.3
		minigameData.endGameTime = args[2] or 10000

		if math.random(10) <= 5 then
			minigameData.currentX = minigameData.currentX * -1
			minigameData.acceleration = minigameData.acceleration * -1
		end
	end

	if successEvent then
		minigameData.successEvent = successEvent
	end

	if failEvent then
		minigameData.failEvent = failEvent
	end

	minigameState = gameType
end

function endMinigame(...)
	local args = {...}

	if minigameState == "buttons" then
		if args[1] >= 0.75 then
			if minigameData.successEvent then
				triggerEvent(minigameData.successEvent, localPlayer)
			end
		else
			if minigameData.failEvent then
				triggerEvent(minigameData.failEvent, localPlayer)
			end
		end
	elseif minigameState == "balance" then
		if args[1] == "success" then
			if minigameData.successEvent then
				triggerEvent(minigameData.successEvent, localPlayer)
			end
		else
			if minigameData.failEvent then
				triggerEvent(minigameData.failEvent, localPlayer)
			end
		end
	end

	stopMinigame()
end

function spawnNextButton()
	if minigameState == "buttons" then
		minigameData.spawnedButtons = minigameData.spawnedButtons + 1

		table.insert(minigameData.buttons, {string.char(math.random(97, 122)), 0, false})

		local stopInterpolate = minigameData.speed + minigameData.endSpeed / minigameData.maxButtonNum
		local duration = minigameData.density / stopInterpolate

		minigameData.interpolateSpeedSet = {getTickCount(), minigameData.speed, stopInterpolate, duration}

		if minigameData.spawnedButtons < minigameData.maxButtonNum then
			minigameData.spawnNextButtonTimer = setTimer(spawnNextButton, duration + 50, 1)
		end
	end
end

addEventHandler("onClientKey", getRootElement(),
	function (key, state)
		if minigameData then
			if minigameState == "buttons" then
				cancelEvent()

				if state and minigameData.currentBtn and not minigameData.buttons[minigameData.currentBtn][3] and (string.byte(key) >= 97 and string.byte(key) <= 122) then
					if minigameData.currentBtn == minigameData.btnInKey then
						if minigameData.buttons[minigameData.currentBtn][1] == key then
							minigameData.buttons[minigameData.currentBtn][3] = "success"
							minigameData.successCount = minigameData.successCount + 1
							minigameData.lastRing = "success"
							playSound("files/correct.wav")
						else
							minigameData.buttons[minigameData.currentBtn][3] = "fail"
							minigameData.failCount = minigameData.failCount + 1
							minigameData.lastRing = "fail"
							playSound("files/wrong.wav")
						end
					else
						minigameData.buttons[minigameData.currentBtn][3] = "fail"
						minigameData.failCount = minigameData.failCount + 1
						minigameData.lastRing = "fail"
						playSound("files/wrong.wav")
					end
				end
			elseif minigameState == "balance" then
				cancelEvent()

				if state then
					if not minigameData.direction then
						local rand = math.random(0.9, 1)

						if key == "a" or key == "arrow_l" then
							minigameData.lastKey = key
							minigameData.direction = -0.175 * minigameData.accelerationMultipler * rand
							minigameData.accelerationMultipler = minigameData.accelerationMultipler + 0.2
						elseif key == "d" or key == "arrow_r" then
							minigameData.lastKey = key
							minigameData.direction = 0.175 * minigameData.accelerationMultipler * rand
							minigameData.accelerationMultipler = minigameData.accelerationMultipler + 0.2
						end
					end
				elseif minigameData.direction then
					if key == minigameData.lastKey then
						minigameData.direction = false
						minigameData.lastKey = false
					end
				end
			end
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function (timeSlice)
		if minigameData then
			if minigameState == "balance" then
				local sx, sy = 350, 12
				local x = (screenX - sx) / 2
				local y = screenY - sy - 125

				dxDrawRectangle(x, y, sx, 2, tocolor(0, 0, 0, 200)) -- felső
				dxDrawRectangle(x, y + sy - 2, sx, 2, tocolor(0, 0, 0, 200)) -- alsó
				dxDrawRectangle(x, y + 2, 2, sy - 4, tocolor(0, 0, 0, 200)) -- bal
				dxDrawRectangle(x + sx - 2, y + 2, 2, sy - 4, tocolor(0, 0, 0, 200)) -- jobb
				dxDrawRectangle(x + 2, y + 2, sx - 4, sy - 4, tocolor(0, 0, 0, 155)) -- háttér
				dxDrawImage(x + 2, y + 2, sx - 4, sy - 4, "files/white2.png", 0, 0, 0, tocolor(200, 50, 50))
				dxDrawImage(x + (sx - 24) / 2 + minigameData.currentX, y - 24, 24, 24, "files/pointer.png")

				if getTickCount() >= minigameData.startGame then
					local elapsedTime = getTickCount() - minigameData.startGame
					local progress = elapsedTime / minigameData.endGameTime

					if progress > 1 then
						endMinigame("success")
					elseif math.abs(minigameData.currentX) <= sx / 2 then
						if minigameData.direction then
							minigameData.acceleration = minigameData.acceleration + minigameData.direction * minigameData.difficulty
						end

						minigameData.acceleration = minigameData.acceleration + minigameData.currentX / 780
						minigameData.currentX = minigameData.currentX + minigameData.acceleration * timeSlice / 100

						if minigameData.currentX < -sx then
							minigameData.currentX = -sx
						end

						if minigameData.currentX > sx then
							minigameData.currentX = sx
						end

						if minigameData.currentX == 0 then
							minigameData.currentX = math.random(-1, 1)
						end

						y = y + sy * 1.25

						dxDrawRectangle(x, y, sx, 2, tocolor(0, 0, 0, 200)) -- felső
						dxDrawRectangle(x, y + sy - 2, sx, 2, tocolor(0, 0, 0, 200)) -- alsó
						dxDrawRectangle(x, y + 2, 2, sy - 4, tocolor(0, 0, 0, 200)) -- bal
						dxDrawRectangle(x + sx - 2, y + 2, 2, sy - 4, tocolor(0, 0, 0, 200)) -- jobb
						dxDrawRectangle(x + 2, y + 2, sx - 4, sy - 4, tocolor(0, 0, 0, 155)) -- háttér
						dxDrawRectangle(x + 2, y + 2, (sx - 4) - (sx - 4) * progress, sy - 4, tocolor(50, 179, 239)) -- állapot
					else
						endMinigame("fail")
					end
				end
			elseif minigameState == "buttons" then
				local sx, sy = 622, 55
				local x = (screenX - sx) / 2
				local y = screenY - sy - 125

				minigameData.btnInKey = false
				minigameData.currentBtn = false
				minigameData.lastCurrent = minigameData.currentBtn

				local minigameSpeed = 0
				local onScreenNum = 0

				if minigameData.interpolateSpeedSet then
					minigameSpeed = interpolateBetween(minigameData.interpolateSpeedSet[2], 0, 0, minigameData.interpolateSpeedSet[3], 0, 0, (getTickCount() - minigameData.interpolateSpeedSet[1]) / minigameData.interpolateSpeedSet[4], "Linear")
				end

				if isElement(minigameData.renderTarget) then
					dxSetRenderTarget(minigameData.renderTarget, true)

					dxDrawImage(0, 0, sx, sy, "files/white.png", 0, 0, 0, tocolor(0, 0, 0, 180))

					for i = 1, #minigameData.buttons do
						if minigameData.buttons[i] then
							onScreenNum = onScreenNum + 1

							local progress = minigameData.buttons[i][2] + minigameSpeed * timeSlice / 1000

							if progress >= 1 then
								progress = 1
							end

							minigameData.buttons[i][2] = progress

							local alpha = 200 * (1 - math.abs(0.5 - progress) * 2) + 50
							local r, g, b = 255, 255, 255
							local r2, g2, b2 = 0, 0, 0

							if minigameData.buttons[i][3] then
								if minigameData.buttons[i][3] == "fail" then
									r, g, b = 215, 89, 89
								elseif minigameData.buttons[i][3] == "success" then
									r, g, b = 50, 179, 239
									r2, g2, b2 = 255, 255, 255
								end
							end

							if not minigameData.currentBtn and progress <= 0.575 then
								minigameData.currentBtn = i
							end

							if progress >= 0.425 and progress <= 0.5 then
								minigameData.btnInKey = i
							end

							dxDrawRectangle(-30 + 712 * progress, 12.5, 30, 30, tocolor(r, g, b, alpha))

							dxDrawText(string.upper(minigameData.buttons[i][1]), -30 + 712 * progress, 12.5, 712 * progress, 30 + 12.5, tocolor(r2, g2, b2, alpha), 1, minigameData.RobotoFont, "center", "center")

							if progress > 0.5 then
								if minigameData.lastCurrent == i then
									minigameData.lastRing = false
								end

								if not minigameData.buttons[i][3] then
									minigameData.buttons[i][3] = "fail"
									minigameData.failCount = minigameData.failCount + 1
									minigameData.lastRing = "fail"
									playSound("files/wrong.wav")
								end
							end

							if progress >= 1 then
								minigameData.buttons[i] = false
							end
						end
					end

					--dxDrawRectangle(622 * 0.425, 0, 1, 55, tocolor(0, 255, 0))
					--dxDrawRectangle(622 * 0.5, 0, 1, 55, tocolor(255, 0, 0))
					--dxDrawRectangle(622 * 0.575, 0, 1, 55, tocolor(255, 255, 255))

					dxSetRenderTarget()

					if minigameData.renderTarget then
						dxDrawImage(x, y, sx, sy, minigameData.renderTarget)
					end
				end

				if onScreenNum <= 0 and minigameData.successCount + minigameData.failCount > 1 then
					endMinigame(minigameData.successCount / (minigameData.successCount + minigameData.failCount))
				end

				local holderSize = 70
				x = x + (sx - holderSize) / 2
				y = y + (sy - holderSize) / 2

				local r, g, b = 75, 75, 75
				if minigameData.lastRing then
					if minigameData.lastRing == "success" then
						r, g, b = 50, 179, 239
					else
						r, g, b = 215, 89, 89
					end
				end

				local borderColor = tocolor(r, g, b)

				dxDrawRectangle(x, y, holderSize, holderSize, tocolor(r, g, b, 40))
				dxDrawRectangle(x, y, holderSize, 2, borderColor) -- felső
				dxDrawRectangle(x, y + holderSize - 2, holderSize, 2, borderColor) -- alsó
				dxDrawRectangle(x - 1, y + 1, 2, holderSize - 2, borderColor) -- bal
				dxDrawRectangle(x + holderSize - 1, y + 1, 2, holderSize - 2, borderColor) -- jobb
			end
		end
	end, true, "low-1000"
)