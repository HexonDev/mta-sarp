local screenX, screenY = guiGetScreenSize()
local responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

local function resp(value)
	return value * responsiveMultipler
end

local function respc(value)
	return math.ceil(value * responsiveMultipler)
end

local tableObject = {}
local tableColShape = {}
local tableAreaPos = {}

local tableBalls = {}
local tableBallIds = {}
local cueBallOrigin = {}
local frozenBalls = {}
local ballForces = {}

local tableHolePoses = {}
local ballsInHole = {}

local poolTableObj = false
local poolTableId = false
local playTheGame = false

local crosshairState = false
local crosshairColor = false
local crosshairInUse = false

local playerRotation = 0
local cueDistForDraw = "med"
local lastAnimSyncTick = 0

local rotCorrection = false

local cueMinDistance = 0.6
local cueMaxDistance = 1.65

local restitution = 0.9
local bounceFactor = restitution / 1.95

local lastElementHit = false
local selectedBall = false

local pushForceState = 0
local pushForceInterpolate = 0
local pushVelocity = {0, 0}

local forcedTableId = false

local syncableBalls = {}
local droppedBalls = {}

local startShowdown = {}
local renderHoleBall = {}

local tableHistory = {}
local historyRenderTarget = false

local requestTableSync = {}

local placedTable = false

local debugMode = false

local ballNumbers = {
	[2995] = 9,
	[2996] = 10,
	[2997] = 11,
	[2998] = 12,
	[2999] = 13,
	[3000] = 14,
	[3001] = 15,
	[3002] = 1,
	[3003] = 16,
	[3100] = 2,
	[3101] = 3,
	[3102] = 4,
	[3103] = 5,
	[3104] = 6,
	[3105] = 7,
	[3106] = 8,
}

local ballNames = {
	[2995] = "9-es (csíkos-#f2b012sárga#ffffff)",
	[2996] = "10-es (csíkos-#0a27a3kék#ffffff)",
	[2997] = "11-es (csíkos-#b70c0apiros#ffffff)",
	[2998] = "12-es (csíkos-#160e41lila#ffffff)",
	[2999] = "13-as (csíkos-#ca4414narancs#ffffff)",
	[3000] = "14-es (csíkos-#085d21zöld#ffffff)",
	[3001] = "15-ös (csíkos-#6c1608bordó#ffffff)",
	[3002] = "1-es (#f2b012sárga#ffffff)",
	[3003] = "fehér",
	[3100] = "2-es (#0a27a3kék#ffffff)",
	[3101] = "3-as (#b70c0apiros#ffffff)",
	[3102] = "4-es (#160e41lila#ffffff)",
	[3103] = "5-ös (#ca4414narancs#ffffff)",
	[3104] = "6-os (#085d21zöld#ffffff)",
	[3105] = "7-es (#6c1608bordó#ffffff)",
	[3106] = "8-as (#000000fekete#ffffff)"
}

function loadFonts()
	local fonts = {
		Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
		Roboto10 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(10), false, "antialiased"),
		RobotoB10 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(10), false, "antialiased"),
	}

	for k,v in pairs(fonts) do
		_G[k] = v
		_G[k .. "H"] = dxGetFontHeight(1, _G[k])
	end
end

setTimer(engineImportTXD, 2000, 1, engineLoadTXD("files/k_pool.txd"), 2964)

for k,v in ipairs({2995, 2996, 2997, 2998, 2999, 3000, 3001, 3002, 3003, 3100, 3101, 3102, 3103, 3104, 3105, 3106, 2964, 338}) do
	for i = 0, 50 do
		removeWorldModel(v, 1000000, 0, 0, 0, i)
	end
end

addEventHandler("onAssetsLoaded", getRootElement(),
	function ()
		loadFonts()
	end
)

exports.sarp_admin:addAdminCommand("debugbilliard", 9, "Biliárd debugolása (fejlesztő mód)")
addCommandHandler("debugbilliard",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 9 then
			debugMode = not debugMode

			if debugMode then
				setDevelopmentMode(true)
			end
		end
	end
)

addEventHandler("onClientResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_hud" then
			responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()
		elseif source == getResourceRootElement() then
			local sarp_hud = getResourceFromName("sarp_hud")

			if sarp_hud and getResourceState(sarp_hud) == "running" then
				responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()
			end

			loadFonts()

			setTimer(triggerServerEvent, 2000, 1, "syncTheTables", localPlayer)
		end
	end
)

addEventHandler("onClientPlayerQuit", getRootElement(),
	function ()
		if source == localPlayer and poolTableObj then
			if getElementData(poolTableObj, "poolTableInUse") == localPlayer then
				setElementData(poolTableObj, "poolTableInUse", false)
			end
		end
	end
)

addEventHandler("onClientPlayerWasted", getLocalPlayer(),
	function ()
		if source == localPlayer and poolTableObj then
			if getElementData(poolTableObj, "poolTableInUse") == localPlayer then
				setElementData(poolTableObj, "poolTableInUse", false)
			end
		end
	end
)

addEventHandler("onClientColShapeHit", getRootElement(),
	function (hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension and source and isElement(source) and getElementData(source, "poolTableCol") and not poolTableObj then
			poolTableObj = getElementData(source, "poolTableCol")
			poolTableId = getElementData(poolTableObj, "poolTableId")

			redrawHistory()

			setElementData(poolTableObj, "isInteractable", true, false)
			setElementData(poolTableObj, "object.name", "Biliárd", false)

			--triggerServerEvent("givePoolStick", localPlayer, true)
			--addEventHandler("onClientKey", getRootElement(), playerPressedKey, true, "high+99999")
		end
	end
)

addEventHandler("onClientColShapeLeave", getRootElement(),
	function (hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension and getElementData(source, "poolTableCol") and poolTableObj then
			if getElementData(source, "poolTableInUse") == localPlayer then
				setElementData(source, "poolTableInUse", false)
			end

			poolTableObj = false
			poolTableId = false
			playTheGame = false

			redrawHistory()

			triggerServerEvent("givePoolStick", localPlayer, false)
			removeEventHandler("onClientKey", getRootElement(), playerPressedKey)
		end
	end
)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if getElementModel(source) == 2964 then
			local tableId = getElementData(source, "poolTableId")
			if tableId then
				print("stream out the billiard table")
				triggerEvent("syncTheTable", localPlayer, tableId)
			end
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementModel(source) == 2964 then
			for k, v in pairs(requestTableSync) do
				if v then
					print("stream in & sync the billiard table")
					requestTableSync[k] = nil
					triggerServerEvent("syncTheTable", localPlayer, k)
				end
			end
		end
	end
)

function getCurrentInteractionList()
	if poolTableObj and poolTableId then
		return {{"Beszállás a játékba", ":sarp_billiard/files/startgame.png", "startPlayBilliard"}}
	end

	return {}
end

addEvent("startPlayBilliard", true)
addEventHandler("startPlayBilliard", getRootElement(),
	function (sourceElement)
		if poolTableObj and poolTableId then
			setElementData(poolTableObj, "isInteractable", false, false)
			setElementData(poolTableObj, "object.name", false, false)
			
			playTheGame = true

			triggerServerEvent("givePoolStick", localPlayer, true)

			addEventHandler("onClientKey", getRootElement(), playerPressedKey, true, "high+99999")
		end
	end
)

function playerPressedKey(button, state)
	if not playTheGame then
		return
	end

	if button == "mouse2" then
		if state ~= crosshairState then
			if state and ballForces[poolTableId] > 0 then
				cancelEvent()
				return
			end

			if state and forcedTableId then
				exports.sarp_hud:showAlert("error", "Várd meg, amíg a másik asztalon véget ér a játék!")
				cancelEvent()
				return
			end

			if state then
				local playerX, playerY, playerZ = getElementPosition(localPlayer)
				local tableX, tableY, tableZ = getElementPosition(poolTableObj)

				if getDistanceBetweenPoints3D(playerX, playerY, playerZ, tableX, tableY, tableZ) <= getElementRadius(poolTableObj) * 1.5 then
					if math.abs(playerZ - tableZ) - 0.47832541465757 >= 1 then
						cancelEvent()
						exports.sarp_hud:showAlert("error", "Előbb szállj le a földre!")
						return
					end

					local playerRX, playerRY, playerRZ = getElementRotation(localPlayer)
					local rotationBetweenPoints = math.deg(math.atan2(tableY - playerY, tableX - playerX)) + (180 - playerRZ)
					
					if rotationBetweenPoints < 0 then
						rotationBetweenPoints = rotationBetweenPoints + 360
					end

					if rotationBetweenPoints < 180 then
						cancelEvent()
						exports.sarp_hud:showAlert("error", "Állj szembe az asztallal!")
						return
					end

					local poolTableInUse = getElementData(poolTableObj, "poolTableInUse") or localPlayer

					if isElement(poolTableInUse) and poolTableInUse ~= localPlayer then
						cancelEvent()
						exports.sarp_hud:showAlert("error", "Várj egy kicsit, már valaki más céloz!")
						return
					end

					setElementData(poolTableObj, "poolTableInUse", localPlayer)

					triggerServerEvent("setPoolAnimation", localPlayer, "pool_" .. cueDistForDraw .. "_start", true)
					setElementFrozen(localPlayer, true)

					playerRotation = getPedRotation(localPlayer)
					crosshairColor = {255, 0, 0}
					crosshairState = state

					setCursorPosition(screenX / 2, screenY / 2)
					showCursor(state)
					setCursorAlpha(state and 0 or 255)
				end
			else
				if getElementData(poolTableObj, "poolTableInUse") == localPlayer then
					setElementData(poolTableObj, "poolTableInUse", false)
				end

				triggerServerEvent("setPoolAnimation", localPlayer, "pool_" .. cueDistForDraw .. "_start", false)

				setElementFrozen(localPlayer, false)

				crosshairState = state
				showCursor(state)
				setCursorAlpha(state and 0 or 255)
			end

			selectedBall = false
			crosshairInUse = false
		end

		cancelEvent()
	end

	if button == "mouse1" then
		if state ~= crosshairInUse then
			if state and not selectedBall then
				cancelEvent()
				return
			end

			crosshairInUse = state
			pushForceInterpolate = getTickCount()

			if not state and selectedBall and poolTableObj then
				local poolTableInUse = getElementData(poolTableObj, "poolTableInUse") or localPlayer

				if isElement(poolTableInUse) and poolTableInUse == localPlayer then
					triggerServerEvent("forceABall", localPlayer, poolTableId, selectedBall, pushVelocity, cueDistForDraw)

					exports.sarp_chat:sendLocalMeAction(localPlayer, "meglök egy golyót.")
				end

				setElementFrozen(localPlayer, false)

				selectedBall = false
				crosshairInUse = false
				crosshairState = false

				showCursor(false)
				setCursorAlpha(255)
			end

			pushVelocity = {0, 0}
		end

		cancelEvent()
	end
end

addEvent("syncTheTable", true)
addEventHandler("syncTheTable", getRootElement(),
	function (id, obj, balls, bounds, history)
		if balls then
			tableObject[id] = obj

			if tableBalls[id] then
				for k = 1, #tableBalls[id] do
					v = tableBalls[id][k].obj

					if isElement(v) then
						destroyElement(v)
					end
				end
			end

			if isElement(tableColShape[id]) then
				destroyElement(tableColShape[id])
			end

			tableBalls[id] = nil
			tableColShape[id] = nil

			frozenBalls[id] = {}
			cueBallOrigin[id] = {}
			ballsInHole[id] = {}
			droppedBalls[id] = {}
			tableHolePoses[id] = {}

			tableAreaPos[id] = bounds
			tableHistory[id] = history

			ballForces[id] = 0
			startShowdown[id] = false
			requestTableSync[id] = false

			redrawHistory()

			initBalls(id, obj, balls)
		else
			if obj then
				if poolTableId == id then
					removeEventHandler("onClientKey", getRootElement(), playerPressedKey)

					triggerServerEvent("givePoolStick", localPlayer, false, true)

					setElementFrozen(localPlayer, false)

					poolTableObj = false
					poolTableId = false
					playTheGame = false

					selectedBall = false
					crosshairInUse = false
					crosshairState = false

					showCursor(false)
					setCursorAlpha(255)
				end

				requestTableSync[id] = nil
				unloadTable(id)
			else
				requestTableSync[id] = true

				if poolTableId ~= id then
					unloadTable(id)
				end
			end
		end
	end
)

function unloadTable(id)
	if tableBalls[id] then
		for k = 1, #tableBalls[id] do
			v = tableBalls[id][k].obj

			if isElement(v) then
				destroyElement(v)
			end
		end
	end

	if isElement(tableColShape[id]) then
		destroyElement(tableColShape[id])
	end

	tableBalls[id] = nil
	tableColShape[id] = nil
	tableObject[id] = nil
	droppedBalls[id] = nil
	tableAreaPos[id] = nil
	ballForces[id] = nil
	startShowdown[id] = nil
	frozenBalls[id] = nil
	cueBallOrigin[id] = nil
	tableHolePoses[id] = nil
	ballsInHole[id] = nil
	tableHistory[id] = nil
end

function initBalls(id, sourceobj, balls)
	local tablePosX, tablePosY, tablePosZ = getElementPosition(sourceobj)
	local tableInterior = getElementInterior(sourceobj)
	local tableDimension = getElementDimension(sourceobj)

	local colShape = createColSphere(tablePosX, tablePosY, tablePosZ + 0.9, 3)

	if isElement(colShape) then
		setElementInterior(colShape, tableInterior)
		setElementDimension(colShape, tableDimension)

		tableColShape[id] = colShape

		setElementData(colShape, "poolTableCol", sourceobj)
	end

	local matrix = getElementMatrix(sourceobj)
	local x, y, z = getPositionFromElementOffset(matrix, 0.5, 0, 0.95)

	cueBallOrigin[id] = {x, y, z}
	tableHolePoses[id] = {}

	x, y, z = getPositionFromElementOffset(matrix, -1, -0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.13, z + 0.9})

	x, y, z = getPositionFromElementOffset(matrix, -1, 0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.13, z + 0.9})

	x, y, z = getPositionFromElementOffset(matrix, 1, 0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.13, z + 0.9})

	x, y, z = getPositionFromElementOffset(matrix, 1, -0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.13, z + 0.9})

	x, y, z = getPositionFromElementOffset(matrix, 0, 0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.075, z + 0.9})

	x, y, z = getPositionFromElementOffset(matrix, 0, -0.55, 0)

	table.insert(tableHolePoses[id], {x, y, 0.075, z + 0.9})

	tableBalls[id] = {}
	frozenBalls[id] = {}
	ballForces[id] = 0

	for k = 1, #balls do
		v = balls[k]

		if v then
			table.insert(tableBalls[id], {
				obj = createObject(v[1], v[2], v[3], v[4]),
				pos = {v[2], v[3], v[4]},
				velocity = {0, 0},
				rot = {0, 0, 90},
				radius = 0.035,
				mass = 1,
				num = ballNumbers[v[1]],
				model = v[1],
				frozen = v[5]
			})
		end
	end
	
	for k = 1, #tableBalls[id] do
		v = tableBalls[id][k]

		if v then
			tableBallIds[v.obj] = k

			setElementCollidableWith(v.obj, sourceobj, false)
			setElementInterior(v.obj, tableInterior)
			setElementDimension(v.obj, tableDimension)
			
			if v.frozen then
				frozenBalls[id][v.num] = true
			end
		end
	end
end

addEvent("forceABall", true)
addEventHandler("forceABall", getRootElement(),
	function (tableId, id, force)
		if source == localPlayer then
			forcedTableId = tableId
		end

		if tableBalls[tableId] then
			tableBalls[tableId][id].velocity = force
		end

		if source == localPlayer then
			local actions = {}
			local total = #tableHistory[tableId]

			if total > 15 then
				total = 15
			end

			table.insert(actions, {getPlayerName(source), tableBalls[tableId][id].model})

			for i = 1, total do
				table.insert(actions, tableHistory[tableId][i])
			end

			tableHistory[tableId] = actions

			redrawHistory()

			if poolTableObj and poolTableId == tableId then
				setElementData(poolTableObj, "poolTableInUse", false)
			end

			triggerServerEvent("syncActions", localPlayer, tableId, tableHistory[tableId])
		end

		if tableObject[tableId] then
			local interior = getElementInterior(tableBalls[tableId][id].obj)
			local dimension = getElementDimension(tableBalls[tableId][id].obj)
			local stickSound = playSound3D("files/sounds/stick.wav", tableBalls[tableId][id].pos[1], tableBalls[tableId][id].pos[2], tableBalls[tableId][id].pos[3])

			setElementInterior(stickSound, interior)
			setElementDimension(stickSound, dimension)
			setSoundMaxDistance(stickSound, 50)
		end
	end
)

addEvent("syncPoolBalls", true)
addEventHandler("syncPoolBalls", getRootElement(),
	function (tableId, curBalls, dropBalls, history, inHole)
		if isElement(source) and tableObject[tableId] then
			ballsInHole[tableId] = {}

			droppedBalls[tableId] = dropBalls
			tableHistory[tableId] = history

			redrawHistory()

			startShowdown[tableId] = getTickCount()

			for k = 1, #curBalls do
				v = curBalls[k]

				if v then
					local ball = tableBalls[tableId][k]

					ball.velocity = {0, 0}
					ball.frozen = true
					ball.inhole = v[5]
					ball.pos = {v[1], v[2], v[3]}

					moveObject(ball.obj, 175, v[1], v[2], v[3])
				end
			end

			if #inHole > 0 then
				for k = 1, #inHole do
					v = inHole[k]

					if v[1] then
						local holeId = v[1]

						if not ballsInHole[tableId][holeId] then
							ballsInHole[tableId][holeId] = {}
						end

						table.insert(ballsInHole[tableId][holeId], v[2])
					end
				end
			end

			setTimer(
				function()
					for k = 1, #curBalls do
						v = curBalls[k]

						if v then
							local num = tableBalls[tableId][k].num

							tableBalls[tableId][k].frozen = v[4]

							frozenBalls[tableId][num] = v[4]
						end
					end
				end,
			200, 1)
		end
	end
)

addEvent("syncActions", true)
addEventHandler("syncActions", getRootElement(),
	function (tableId, history)
		if isElement(source) and tableObject[tableId] then
			tableHistory[tableId] = history

			redrawHistory()
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function (timeSlice)
		local microsecond = timeSlice / 1000

		if poolTableObj then
			if not playTheGame then
				local tableX, tableY, tableZ = getElementPosition(poolTableObj)
				local cameraX, cameraY, cameraZ = getCameraMatrix()
				local dist = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, tableX, tableY, tableZ)

				if dist <= 15 then
					local screenPosX, screenPosY = getScreenFromWorldPosition(tableX, tableY, tableZ + 1)

					if screenPosX and screenPosY then
						local scaleFactor = 1 - dist / 75
						local theText = "A biliárdozáshoz jobb klikk az asztalra"
						local textWidth = dxGetTextWidth(theText, scaleFactor, Roboto14)

						dxDrawText(theText, screenPosX - textWidth / 2 + 2, screenPosY + 2, screenPosX + textWidth / 2 + 2, 2, tocolor(0, 0, 0), scaleFactor, Roboto14, "center", "top", false, false, false, false, true)
						dxDrawText(theText, screenPosX - textWidth / 2, screenPosY, screenPosX + textWidth / 2, 0, tocolor(255, 255, 255), scaleFactor, Roboto14, "center", "top", false, false, false, false, true)
					end
				end
			else
				if ballForces[poolTableId] <= 0 then
					if not selectedBall then
						dxDrawText("Célzás: #32b3efjobb klikk #ffffffnyomva tartva", 0, 0, screenX, screenY - 90, tocolor(255, 255, 255), 1, Roboto14, "center", "bottom", false, false, false, true)
					else
						dxDrawText("Lövés: #32b3efbal klikk#ffffff nyomva tartva, korrekció: #32b3efA #ffffffés #32b3efD", 0, 0, screenX, screenY - 90, tocolor(255, 255, 255), 1, Roboto14, "center", "bottom", false, false, false, true)
					end
				else
					dxDrawText("Golyók mozgásban...", 0, 0, screenX, screenY - 90, tocolor(255, 255, 255), 1, Roboto14, "center", "bottom")
				end

				if crosshairState then
					selectedBall = false

					local cursorX, cursorY = getCursorPosition()

					if tonumber(cursorX) and tonumber(cursorY) then
						local playerX, playerY, playerZ = getElementPosition(localPlayer)
						local cameraX, cameraY, cameraZ = getCameraMatrix()

						local worldX, worldY, worldZ = getWorldFromScreenPosition(cursorX * screenX, cursorY * screenY, 100)
						local hit, hitX, hitY, hitZ, hitElement = processLineOfSight(cameraX, cameraY, cameraZ, worldX, worldY, worldZ, false, false, false, true, false)

						if lastElementHit then
							hit = true
							hitElement = lastElementHit
						end

						if hit then
							local tableX, tableY, tableZ = getElementPosition(poolTableObj)

							tableZ = tableZ + 0.95

							if tableBallIds[hitElement] then
								hitX, hitY = getElementPosition(hitElement)
							end

							local cueDist = math.floor(getDistanceBetweenPoints3D(hitX, hitY, tableZ, playerX, playerY, tableZ) * 100) / 100
							
							if debugMode then
								dxDrawText("cue dist: " .. cueDist, 500, 475)
							end

							if cueDist >= cueMinDistance and cueDist <= cueMaxDistance then
								local distanceText = "long"

								if cueDist < 0.8 then
									distanceText = "short"
								elseif cueDist >= 0.8 and cueDist < 1.3 then
									distanceText = "med"
								end

								if cueDistForDraw ~= distanceText then
									cueDistForDraw = distanceText
									
									if getTickCount() - lastAnimSyncTick < 500 then
										setPedAnimation(localPlayer, "pool", "pool_" .. distanceText .. "_start", -1, false, false, false, true)
									else
										triggerServerEvent("setPoolAnimation", localPlayer, "pool_" .. cueDistForDraw .. "_start", true)

										lastAnimSyncTick = getTickCount()
									end
								end

								if hitElement == poolTableObj then
									if debugMode then
										dxDrawLine3D(hitX, hitY, tableZ, hitX, hitY, tableZ + 0.5, tocolor(240, 200, 80), 1)
									end

									crosshairColor = {255, 0, 0}
								end

								if tableBallIds[hitElement] then
									selectedBall = tableBallIds[hitElement]

									if debugMode then
										dxDrawLine3D(hitX, hitY, tableZ, hitX, hitY, tableZ + 0.5, tocolor(240, 200, 80), 1)
									end

									if crosshairInUse then
										crosshairColor = {0, 255, 0}
									else
										crosshairColor = {255, 255, 255}
									end

									if not rotCorrection then
										rotCorrection = 0
									end
								else
									rotCorrection = false
								end

								local crossX = false
								local crossY = false

								if selectedBall then
									crossX, crossY = getScreenFromWorldPosition(hitX, hitY, tableZ)
								else
									crossX, crossY = getScreenFromWorldPosition(hitX, hitY, hitZ)
								end

								if crossX and crossY then
									dxDrawImage(crossX - 8, crossY - 8, 16, 16, "files/images/cross.png", 0, 0, 0, tocolor(crosshairColor[1], crosshairColor[2], crosshairColor[3]))
								end

								if debugMode then
									dxDrawLine3D(hitX, hitY, playerZ + 0.5, playerX, playerY, playerZ + 0.5, tocolor(240, 200, 80), 1)
								end

								local angle = math.atan2(playerY - hitY, playerX - hitX)

								if rotCorrection then
									if debugMode then
										dxDrawText("rotCorrection: " .. math.deg(rotCorrection), 500, 525)
									end

									if getKeyState("arrow_r") or getKeyState("d") then
										if rotCorrection > -math.rad(7.5) then
											rotCorrection = rotCorrection - math.rad(20) * microsecond
										end

										lastElementHit = hitElement
									elseif getKeyState("arrow_l") or getKeyState("a") then
										if rotCorrection < math.rad(7.5) then
											rotCorrection = rotCorrection + math.rad(20) * microsecond
										end

										lastElementHit = hitElement
									elseif lastElementHit then
										lastElementHit = false
									end
								end

								playerRotation = math.deg(angle) + 180 + 270 - 5

								if tableBallIds[hitElement] then
									local linearProgress = 0
									
									if crosshairInUse then
										local elapsedTime = getTickCount() - pushForceInterpolate
										local progress = elapsedTime / 850
										local state = pushForceState

										if progress > 1 then
											pushForceInterpolate = getTickCount()
											
											if pushForceState == 0 then
												pushForceState = 1
											else
												pushForceState = 0
											end
										end

										linearProgress = interpolateBetween(
											state, 0, 0,
											1 - state, 0, 0,
											progress, "Linear"
										)
									end

									angle = angle + math.rad(176)

									cueDist = cueDist / cueMaxDistance

									local forceLength, force = interpolateBetween(
										2, 0.25 - cueDist * 0.15, 0,
										30, 6 - cueDist * 3.5, 0,
										linearProgress, "InQuad"
									)

									if debugMode then
										dxDrawText("cue force: " .. force, 500, 450)
									end
									
									local angle2 = rotCorrection or 0
									local rotatedX = math.cos(angle + angle2)
									local rotatedY = math.sin(angle + angle2)

									local startX, startY = hitX, hitY
									local stopX, stopY = rotatedX * force, rotatedY * force

									local realCueDist = 0.9 - cueDist * 0.65

									playerZ = playerZ - 0.025

									if debugMode then
										dxDrawLine3D(hitX, hitY, playerZ, hitX + stopX, hitY + stopY, playerZ, tocolor(240, 200, 80), 1)
									end

									pushVelocity = {stopX, stopY}

									for i = 0, 30 do
										stopX = hitX + realCueDist / 30 * i * rotatedX
										stopY = hitY + realCueDist / 30 * i * rotatedY

										local r, g, b = 255, 255, 255
										
										if crosshairInUse and forceLength >= i then
											r, g, b = interpolateBetween(
												0, 255, 0,
												255, 0, 0,
												i / 19.5, "Linear")
										end

										dxDrawLine3D(startX, startY, playerZ, stopX, stopY, playerZ, tocolor(r, g, b, 255 - 8.5 * i + 25), (30 - i) / 15)

										startX, startY = stopX, stopY
									end
								end
							end
						end
					end

					if cueDistForDraw == "short" then
						setElementRotation(localPlayer, 0, 0, playerRotation - 16, "default", true)
					elseif cueDistForDraw == "long" then
						setElementRotation(localPlayer, 0, 0, playerRotation - 4, "default", true)
					else
						setElementRotation(localPlayer, 0, 0, playerRotation, "default", true)
					end
				end
			end
		end

		for tableId in pairs(tableObject) do
			local tableX, tableY = getElementPosition(tableObject[tableId])

			for boundId = 1, #tableAreaPos[tableId] do
				local bound = tableAreaPos[tableId][boundId]

				if debugMode then
					dxDrawLine3D(bound[1], bound[2], bound[5], bound[3], bound[4], bound[5], tocolor(50, 179, 239), 1)
				end

				local wallAngle = math.deg(math.atan2(bound[4] - bound[2], bound[3] - bound[1])) + 180

				if wallAngle > 180 then
					wallAngle = wallAngle - 180
				end

				for ballId = 1, #tableBalls[tableId] do
					local ball = tableBalls[tableId][ballId]

					if not ball.frozen then
						local intersecting = circleSegmentIntersect(ball.pos[1], ball.pos[2], ball.radius, bound[1], bound[2], bound[3], bound[4])

						if tonumber(intersecting) then
							local distance = getDistanceBetweenPoints2D(0, 0, ball.velocity[1], ball.velocity[2]) * restitution

							if distance > 0 then
								local incomingAngle = math.deg(math.atan2(ball.velocity[2], ball.velocity[1])) + 180 - wallAngle
								local outgoingAngle = math.rad(wallAngle + 180 - incomingAngle)
								
								ball.velocity[1] = math.cos(outgoingAngle) * distance
								ball.velocity[2] = math.sin(outgoingAngle) * distance

								ball.pos[1] = ball.pos[1] + ball.velocity[1] * microsecond
								ball.pos[2] = ball.pos[2] + ball.velocity[2] * microsecond

								if math.abs(ball.velocity[1]) + math.abs(ball.velocity[2]) > 0.15 then
									local interior = getElementInterior(ball.obj)
									local dimension = getElementDimension(ball.obj)
									local wallSound = playSound3D("files/sounds/wall.wav", ball.pos[1], ball.pos[2], ball.pos[3])

									setElementInterior(wallSound, interior)
									setElementDimension(wallSound, dimension)
									setSoundMaxDistance(wallSound, 50)
								end
							end
						end
					end
				end
			end

			ballForces[tableId] = 0

			for ballId = 1, #tableBalls[tableId] do
				local ball = tableBalls[tableId][ballId]

				if not ball.frozen then
					ball.velocity[1] = ball.velocity[1] - ball.velocity[1] * bounceFactor * microsecond
					ball.velocity[2] = ball.velocity[2] - ball.velocity[2] * bounceFactor * microsecond

					local force = math.abs(ball.velocity[1]) + math.abs(ball.velocity[2])

					if force > 0 then
						setElementCollisionsEnabled(ball.obj, false)
					else
						setElementCollisionsEnabled(ball.obj, true)
					end

					ballForces[tableId] = ballForces[tableId] + force

					ball.pos[1] = ball.pos[1] + ball.velocity[1] * microsecond
					ball.pos[2] = ball.pos[2] + ball.velocity[2] * microsecond

					if getDistanceBetweenPoints2D(ball.pos[1], ball.pos[2], tableX, tableY) >= 1.15 then
						if forcedTableId then
							table.insert(droppedBalls[tableId], {ball.model, true})
						end

						if ball.model == 3003 then
							ball.pos = {cueBallOrigin[tableId][1], cueBallOrigin[tableId][2], cueBallOrigin[tableId][3]}
							ball.velocity = {0, 0}
						else
							ball.frozen = true
							ball.pos = {tableHolePoses[tableId][1][1], tableHolePoses[tableId][1][2], tableHolePoses[tableId][1][4] - 0.2}
							ball.velocity = {0, 0}

							moveObject(ball.obj, 100, tableHolePoses[tableId][1][1], tableHolePoses[tableId][1][2], tableHolePoses[tableId][1][4] - 0.2)
						end
					end

					if debugMode then
						dxDrawLine3D(ball.pos[1], ball.pos[2], ball.pos[3], ball.pos[1] + ball.velocity[1], ball.pos[2] + ball.velocity[2], ball.pos[3], tocolor(255, 150, 0))
					end

					ball.rot[1] = ball.rot[1] + 2500 * microsecond * ball.velocity[1]
					ball.rot[2] = ball.rot[2] + 2500 * microsecond * ball.velocity[2]
					ball.rot[3] = 90

					for nextBallId = 1, #tableBalls[tableId] do
						if ballId ~= nextBallId and not tableBalls[tableId][ballId].frozen and colliding(tableId, ballId, nextBallId) then
							resolveCollision(tableId, ballId, nextBallId)
						end
					end

					setElementPosition(ball.obj, ball.pos[1], ball.pos[2], ball.pos[3])
					setElementRotation(ball.obj, ball.rot[1], ball.rot[2], ball.rot[3])
				end
			end

			ballForces[tableId] = math.floor(ballForces[tableId] * 500) / 500

			if debugMode then
				dxDrawText("ballForces[tableId]: " .. ballForces[tableId], 500, 500)
			end

			if ballForces[tableId] <= 0.01 then
				ballForces[tableId] = 0

				if forcedTableId == tableId then
					forcedTableId = false
					syncableBalls = {}

					for ballId = 1, #tableBalls[tableId] do
						local ball = tableBalls[tableId][ballId]

						ball.velocity = {0, 0}
						table.insert(syncableBalls, {ball.pos[1], ball.pos[2], ball.pos[3], ball.frozen, ball.inhole, ball.model, ball.num})
						ball.inhole = nil
					end

					triggerServerEvent("syncPoolBalls", localPlayer, tableId, syncableBalls, droppedBalls[tableId] or {})

					syncableBalls = {}
					droppedBalls[tableId] = {}
				end
			end

			for holeId = 1, #tableHolePoses[tableId] do
				local hole = tableHolePoses[tableId][holeId]

				for ballId = #tableBalls[tableId], 1, -1 do
					local ball = tableBalls[tableId][ballId]

					if not ball.frozen and inCircle(ball.pos[1], ball.pos[2], hole[1], hole[2], hole[3]) then
						if forcedTableId then
							table.insert(droppedBalls[tableId], ball.model)
						end

						local interior = getElementInterior(ball.obj)
						local dimension = getElementDimension(ball.obj)
						local fallSound = playSound3D("files/sounds/fall.wav", ball.pos[1], ball.pos[2], ball.pos[3])

						if isElement(fallSound) then
							setElementDimension(fallSound, dimension)
							setElementInterior(fallSound, interior)
							setSoundMaxDistance(fallSound, 50)
						end

						if ball.model == 3003 then
							ball.pos = {cueBallOrigin[tableId][1], cueBallOrigin[tableId][2], cueBallOrigin[tableId][3]}
							ball.velocity = {0, 0}
							ball.inhole = holeId
						else
							ball.frozen = true
							ball.inhole = holeId
							ball.pos = {hole[1], hole[2], hole[4] - 0.2}
							ball.velocity = {0, 0}

							moveObject(ball.obj, 100, hole[1], hole[2], hole[4] - 0.2)
						end
					end
				end

				if hole and startShowdown[tableId] then
					local k = tableId .. ";" .. holeId

					if not renderHoleBall[k] then
						renderHoleBall[k] = hole
					end
				end

				if debugMode then
					dxDrawLine3D(hole[1], hole[2], hole[4], hole[1], hole[2], hole[4] + 0.15, tocolor(215, 89, 89), 1)

					for i = 0, 360, 10 do
						local r = math.rad(i)
						local r2 = math.rad(i - 10)

						dxDrawLine3D(math.cos(r) * hole[3] + hole[1], math.sin(r) * hole[3] + hole[2], hole[4], math.cos(r2) * hole[3] + hole[1], math.sin(r2) * hole[3] + hole[2], hole[4], tocolor(215, 89, 89), 1)
					end
				end
			end
		end
	end
)

function redrawHistory()
	if isElement(historyRenderTarget) then
		destroyElement(historyRenderTarget)
	end

	if poolTableId then
		local sx = respc(450)
		local sy = respc(20)
		local iconSize = respc(18)

		historyRenderTarget = dxCreateRenderTarget(sx, 10 * sy, true)

		if isElement(historyRenderTarget) then
			dxSetRenderTarget(historyRenderTarget)
			dxSetBlendMode("modulate_add")
			
			for k = 1, 10 do
				v = tableHistory[poolTableId][k]

				if v then
					local y = (k - 1) * sy
					local model = 3003
					local text = ""

					if v == "roundend" then
						dxDrawRectangle(0, y, sx, sy, tocolor(50, 50, 50, 50))
						dxDrawText("*** Kör vége ***", 0, y, sx, y + sy, tocolor(145, 145, 145, 175), 1, RobotoB10, "center", "center")
					elseif v == "newgame" then
						dxDrawRectangle(0, y, sx, sy, tocolor(50, 179, 239, 50))
						dxDrawText("*** Új játék kezdődött ***", 0, y, sx, y + sy, tocolor(50, 179, 239), 1, RobotoB10, "center", "center")
					elseif type(v) == "table" then
						if tonumber(v[2]) then
							model = v[2]

							if model == 3002 or model == 3103 then
								text = "#8a8a8a" .. v[1]:gsub("_", " ") .. "#ffffff meglökte az " .. ballNames[model] .. " golyót."
							else
								text = "#8a8a8a" .. v[1]:gsub("_", " ") .. "#ffffff meglökte a " .. ballNames[model] .. " golyót."
							end
						else
							model = v[1]

							if model == 3002 or model == 3103 then
								text = "Az " .. ballNames[model] .. " golyó leesett a földre."
							else
								text = "A " .. ballNames[model] .. " golyó leesett a földre."
							end
						end
					else
						model = v

						if model == 3002 or model == 3103 then
							text = "Az " .. ballNames[model] .. " golyó leesett."
						else
							text = "A " .. ballNames[model] .. " golyó leesett."
						end
					end

					if v ~= "roundend" and v ~= "newgame" then
						dxDrawImage(2, math.floor(y + (sy - iconSize) / 2), iconSize, iconSize, "files/images/" .. ballNumbers[model] .. ".png")
					
						dxDrawText(text, 5 + iconSize + 2, y, sx, y + sy, tocolor(255, 255, 255), 1, Roboto10, "left", "center", false, false, false, true)
					end
				end
			end

			dxSetBlendMode("blend")
			dxSetRenderTarget()
		end
	else
		historyRenderTarget = nil
	end
end
addEventHandler("onClientRestore", getRootElement(), redrawHistory)

addEventHandler("onClientRender", getRootElement(),
	function ()
		if poolTableObj and poolTableId then
			local sx = respc(450)
			local sy = respc(20)
			local x = screenX - sx - 15
			local y = screenY - respc(220)

			dxDrawRectangle(x - 5, y - respc(40), sx + 10, respc(40) + respc(200) + 5, tocolor(0, 0, 0, 200))
			dxDrawImage(math.floor(x), math.floor(y - respc(40) + (respc(40) - respc(459 * 0.07)) / 2), respc(403 * 0.07), respc(459 * 0.07), ":sarp_assets/images/sarplogo_big.png", 0, 0, 0, tocolor(50, 179, 239))
			dxDrawText("Biliárd", x + respc(5 + 28.21), y - respc(40), 0, y, tocolor(255, 255, 255), 1, Roboto14, "left", "center")

			for i = 1, 10 do
				local y = y + (i - 1) * sy

				if i % 2 == 0 then
					dxDrawRectangle(x, y, sx, sy, tocolor(0, 0, 0, 125))
				else
					dxDrawRectangle(x, y, sx, sy, tocolor(0, 0, 0, 75))
				end
			end

			if isElement(historyRenderTarget) then
				dxDrawImage(x, y, sx, 10 * sy, historyRenderTarget)
			end
		end

		for key, hole in pairs(renderHoleBall) do
			local splt = split(key, ";")

			if splt then
				local tableId = tonumber(splt[1])
				local holeId = tonumber(splt[2])

				if tableObject[tableId] and tableHolePoses[tableId] and tableHolePoses[tableId][holeId] then
					if hole and startShowdown[tableId] then
						local holeX, holeY = getScreenFromWorldPosition(hole[1], hole[2], hole[4] + 0.15)

						if holeX and holeY then
							local elapsedTime = getTickCount() - startShowdown[tableId]
							local progress = 255
							
							if elapsedTime < 500 then
								progress = 255 * elapsedTime / 500
							end

							if elapsedTime > 5000 then
								progress = 255 - (255 * (elapsedTime - 5000) / 500)

								if progress < 0 then
									progress = 0
								end

								if elapsedTime > 5500 then
									ballsInHole[tableId][holeId] = nil
									renderHoleBall[key] = nil
								end
							end

							if ballsInHole[tableId][holeId] then
								local camX, camY, camZ = getCameraMatrix()
								local dist = getDistanceBetweenPoints3D(camX, camY, camZ, getElementPosition(tableObject[tableId]))

								if dist <= 12 then
									local imgSize = 220 / dist

									for i = 1, #ballsInHole[tableId][holeId] do
										dxDrawImage(holeX - imgSize / 2, holeY - imgSize / 2 - (imgSize * (i - 1)), imgSize, imgSize, "files/images/" .. ballsInHole[tableId][holeId][i] .. ".png", 0, 0, 0, tocolor(255, 255, 255, progress))
									end
								end
							end
						end
					end
				else
					renderHoleBall[key] = nil
				end
			end
		end
	end
)

function colliding(tableId, circleA, circleB)
	circleA = tableBalls[tableId][circleA]
	circleB = tableBalls[tableId][circleB]

	local deltaX = circleA.pos[1] - circleB.pos[1]
	local deltaY = circleA.pos[2] - circleB.pos[2]

	return math.pow(circleA.radius + circleB.radius, 2) >= deltaX * deltaX + deltaY * deltaY
end

function vectorSub(x1, y1, x2, y2)
	return x1 - x2, y1 - y2
end

function normalizeVector(x, y)
	local dist = getDistanceBetweenPoints2D(0, 0, x, y)
	
	if dist ~= 0 then
		x = x / dist
		y = y / dist
	else
		x, y = 0, 0
	end
	
	return x, y
end

function resolveCollision(tableId, circleA, circleB)
	circleA = tableBalls[tableId][circleA]
	circleB = tableBalls[tableId][circleB]

	if circleB.velocity[1] + circleB.velocity[2] == 0 then
		return
	end

	local x, y = vectorSub(circleA.pos[1], circleA.pos[2], circleB.pos[1], circleB.pos[2])
	local dist = getDistanceBetweenPoints2D(0, 0, x, y)

	local x2 = x * (circleA.radius + circleB.radius - dist) / dist
	local y2 = y * (circleA.radius + circleB.radius - dist) / dist

	local inverseMassA = 1 / circleA.mass
	local inverseMassB = 1 / circleB.mass
	local inverseMass = inverseMassA + inverseMassB

	circleA.pos[1] = circleA.pos[1] + x2 * (inverseMassA / inverseMass)
	circleA.pos[2] = circleA.pos[2] + y2 * (inverseMassA / inverseMass)

	x2, y2 = normalizeVector(x2, y2)

	dist = x2 * (circleA.velocity[1] - circleB.velocity[1]) + y2 * (circleA.velocity[2] - circleB.velocity[2])

	if dist > 0 then
		return
	end

	local power = (-(1 + restitution) * dist) / inverseMass

	x2 = x2 * power
	y2 = y2 * power

	circleA.velocity[1] = circleA.velocity[1] + x2 * inverseMassA
	circleA.velocity[2] = circleA.velocity[2] + y2 * inverseMassA

	circleB.velocity[1] = circleB.velocity[1] - x2 * inverseMassB
	circleB.velocity[2] = circleB.velocity[2] - y2 * inverseMassB

	dist = math.abs(dist) + 1

	local interior = getElementInterior(circleA.obj)
	local dimension = getElementDimension(circleA.obj)
	local hitSound = playSound3D("files/sounds/hit.wav", circleA.pos[1], circleA.pos[2], circleA.pos[3])

	if isElement(hitSound) then
		setElementDimension(hitSound, dimension)
		setElementInterior(hitSound, interior)

		setSoundMaxDistance(hitSound, 50 * dist)
	end
end

function circleSegmentIntersect(circleX, circleY, radius, x, y, x2, y2)
	local vectorX, vectorY = vectorSub(x2, y2, x, y)
	local disc = (vectorX * (circleX - x) + vectorY * (circleY - y)) / (vectorX * vectorX + vectorY * vectorY)

	if disc < 0 then
		disc = 0
	elseif disc > 1 then
		disc = 1
	end

	x2 = x + disc * vectorX
	y2 = y + disc * vectorY

	local segmentX = x2 - circleX
	local segmentY = y2 - circleY

	if radius * radius <= segmentX * segmentX + segmentY * segmentY then
		return false, false
	else
		return x2, y2
	end
end

function inCircle(x1, y1, x2, y2, radius)
	local w = math.abs(x1 - x2)
	if radius < w then
		return false
	end

	local h = math.abs(y1 - y2)
	if radius < h then
		return false
	end

	if w + h <= radius then
		return true
	end

	return w * w + h * h <= radius * radius
end

function getPositionFromElementOffset(matrix, x, y, z)
	return x * matrix[1][1] + y * matrix[2][1] + z * matrix[3][1] + matrix[4][1],
		x * matrix[1][2] + y * matrix[2][2] + z * matrix[3][2] + matrix[4][2],
		x * matrix[1][3] + y * matrix[2][3] + z * matrix[3][3] + matrix[4][3]
end

function poolTableCommandHandler(command)
	if getElementData(localPlayer, "acc.adminLevel") >= 7 then
		if not placedTable then
			if isElement(placedTable) then
				destroyElement(placedTable)
			end

			local playerInterior = getElementInterior(localPlayer)
			local playerDimension = getElementDimension(localPlayer)

			placedTable = createObject(2964, 0, 0, 0)
			setElementCollisionsEnabled(placedTable, false)
			setElementAlpha(placedTable, 175)
			setElementInterior(placedTable, playerInterior)
			setElementDimension(placedTable, playerDimension)

			addEventHandler("onClientRender", getRootElement(), tablePlaceRender)
			addEventHandler("onClientKey", getRootElement(), tablePlaceKey)

			outputChatBox(exports.sarp_core:getServerTag("admin") .. "Biliárd asztal létrehozás mód #7cc576bekapcsolva!", 255, 255, 255, true)
			outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az asztal #7cc576lerakásához #ffffffnyomd meg a #FFA600BAL ALT #ffffffgombot.", 255, 255, 255, true)
			outputChatBox(exports.sarp_core:getServerTag("admin") .. "A #d75959kilépéshez #ffffffírd be a #d75959/" .. command .. " #ffffffparancsot.", 255, 255, 255, true)
		else
			removeEventHandler("onClientRender", getRootElement(), tablePlaceRender)
			removeEventHandler("onClientKey", getRootElement(), tablePlaceKey)

			if isElement(placedTable) then
				destroyElement(placedTable)
			end

			placedTable = false

			outputChatBox(exports.sarp_core:getServerTag("admin") .. "Biliárd asztal létrehozás mód #d75959kikapcsolva!", 255, 255, 255, true)
		end
	end
end
addCommandHandler("createpool", poolTableCommandHandler)
addCommandHandler("createbilliard", poolTableCommandHandler)
exports.sarp_admin:addAdminCommand("createbilliard", 7, "Biliárd asztal létrehozása, elérhető még: /createpool")

function tablePlaceKey(button, state)
	if isElement(placedTable) then
		if button == "lalt" and state then
			outputChatBox(exports.sarp_core:getServerTag("admin") .. "#7cc576Sikeresen leraktál egy biliárd asztalt!", 255, 255, 255, true)

			local tablePosX, tablePosY, tablePosZ = getElementPosition(placedTable)
			local tableRotX, tableRotY, tableRotZ = getElementRotation(placedTable)

			local playerInterior = getElementInterior(localPlayer)
			local playerDimension = getElementDimension(localPlayer)

			triggerServerEvent("placeThePoolTable", localPlayer, {tablePosX, tablePosY, tablePosZ, tableRotZ, playerInterior, playerDimension})

			if isElement(placedTable) then
				destroyElement(placedTable)
			end

			placedTable = false

			removeEventHandler("onClientRender", getRootElement(), tablePlaceRender)
			removeEventHandler("onClientKey", getRootElement(), tablePlaceKey)
		end
	end
end

function tablePlaceRender()
	if placedTable then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
		local playerRotX, playerRotY, playerRotZ = getElementRotation(localPlayer)
		
		setElementPosition(placedTable, playerPosX, playerPosY, playerPosZ - 1)
		setElementRotation(placedTable, 0, 0, math.floor(playerRotZ / 90) * 90)
	end
end

exports.sarp_admin:addAdminCommand("nearbybilliard", 7, "Közelben lévő biliárd asztalok listázása")
addCommandHandler("nearbybilliard",
	function (command, distance)
		if getElementData(localPlayer, "acc.adminLevel") >= 7 then
			distance = tonumber(distance) or 15

			local playerX, playerY, playerZ = getElementPosition(localPlayer)
			local nearbyTables = {}
			
			for k,v in pairs(getElementsByType("object", getResourceRootElement(), true)) do
				local tableId = getElementData(v, "poolTableId")

				if tableId then
					local distanceBetweenTable = getDistanceBetweenPoints3D(playerX, playerY, playerZ, getElementPosition(v))

					if distanceBetweenTable <= distance then
						table.insert(nearbyTables, {tableId, math.floor(distanceBetweenTable * 1000) / 1000})
					end
				end
			end
			
			if #nearbyTables > 0 then
				outputChatBox("#cdcdcd>> Biliárd: #ffffffKözeledben lévő asztalok (#ffff99" .. distance .. " yard#ffffff):", 255, 255, 255, true)

				for k,v in ipairs(nearbyTables) do
					outputChatBox("    > #32b3efAzonosító: #ffffff" .. v[1] .. " | #32b3efTávolság: #ffffff" .. v[2] .. " yard", 255, 255, 255, true)
				end
			else
				outputChatBox("#cdcdcd>> Biliárd: #ff4646Nincs egyetlen asztal sem a közeledben.", 255, 255, 255, true)
			end
		end
	end
)