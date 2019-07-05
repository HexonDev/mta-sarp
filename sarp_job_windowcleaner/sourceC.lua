local screenX, screenY = guiGetScreenSize()

local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

local platformDefaultPosition = {1462.5849609375, -1357.1790771484, 152.55760192871, 270}
local platformZeroPosition = {}
local platformWidth = 5.20

local buildingLevels = 14
local buildingOffset = 6.7

local speedPerLevel = 500

local objectID = 8286
local currentObject = nil

function getElevatorID()
	return objectID
end

local jobPed = nil
local jobActive = false

local jobBlip = nil
local jobMarker = nil

local lastWindows = 0

addEventHandler("onClientResourceStart", resourceRoot, function ()
	jobPed = createPed(20, 1465.8736572266, -1357.0882568359, 13.7421875, 180)
	setElementFrozen(jobPed, true)
	setElementData(jobPed, "invulnerable", true)
	setElementData(jobPed, "visibleName", "Műszakvezető")
	setElementData(jobPed, "pedNameType", "Ablaktisztító Munka")
	setPedAnimation(jobPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
end)


function startJob()
	exports.sarp_hud:showAlert("info", "Sikeresen elkezdted az ablaktisztítást!", "Várd meg a felvonót, majd kattints rá, és szálj be")
	createJobBlip()
	--createJobMarker()
    jobActive = true
end

function stopJob()
	exports.sarp_hud:showAlert("info", "Befejezted az ablaktisztítást")
	destroyJobBlip()
	--destroyJobMarker()
	if isElement(currentObject) then
		destroyPlatform()
		--stopWindowCleaning()
	end
	jobActive = false
	showWindow = false
end

local showWindow = false

local windowW, windowH = respc(550), respc(400)
local windowX, windowY = (screenX - windowW) * 0.5, (screenY - windowH) * 0.5
local windowA = 255

local hitX, hitY = -100, -100
local hitS = respc(40)

addEventHandler("onClientRender", root, function()
	if showWindow then
	    dxDrawImage(windowX, windowY, windowW, windowH, "window.png")
		dxDrawImage(windowX, windowY, windowW, windowH, "dirt.png", 0, 0, 0, tocolor(255, 255, 255, windowA))
		dxDrawImage(hitX, hitY, hitS, hitS, ":sarp_assets/images/jobs/miner/crosshair.png")
	end

	if isElement(currentObject) then
		local oX, oY, oZ = getElementPosition(currentObject)
		--dxDrawLine3D( float startX, float startY, float startZ, float endX, float endY, float endZ, int color[, int width, bool postGUI ] )
		dxDrawLine3D(oX + 0.53, oY + 2.35, oZ + 0.9, oX + 0.53, oY + 2.35, oZ + 150, tocolor(0, 0, 0, 255), 5)
		dxDrawLine3D(oX + 0.53, oY - 2.35, oZ + 0.9, oX + 0.53, oY - 2.35, oZ + 150, tocolor(0, 0, 0, 255), 5)
	end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
    if getElementData(localPlayer, "char.Job") == 5 then
        if button == "left" and state == "down" then
			
			if showWindow then
				if cursorInBox(hitX, hitY, hitS, hitS) then
					print("Ablak törlése")
					cleanWindow()
				end
			end

            if clickedWorld == jobPed then
                local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local pedPosX, pedPosY, pedPosZ = getElementPosition(jobPed)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 3 then
                    print("asd")
                    if jobActive then
                        stopJob(); print("stopJob:OnClientClick");
                    else
						startJob()
						createPlatform()
                    end
                end
            end
        end
    end
end)

addEvent("enterElevator", true)
addEventHandler("enterElevator", root, function()
	setElementPosition(localPlayer, 1462.4755859375, -1357.2874755859, 14.15625)
	movePlatform(math.random(1, buildingLevels))
end)

addEventHandler("onClientMarkerHit", root, function(hitPlayer)
	if hitPlayer == localPlayer then
		if source == jobMarker then
			createPlatform()
		end
	end
end)


function generateHitPoint()
	hitX, hitY = generateRandomPointBetween(windowX, windowY, windowW, windowH, hitS, hitS)
end

function cleanWindow()

	windowA = windowA - math.random(20, 60)
	if windowA > 0 then
		generateHitPoint()
	elseif windowA <= 0 then
		lastWindows = lastWindows - 1
		showWindow = false
		windowA = 255
		if lastWindows == 0 then
			stopWindowCleaning()
			exports.sarp_hud:showAlert("info", "Sikeresen megtisztítottad az ablakot!", "10$-t kaptál a munkádért.")
			return
		end
		exports.sarp_hud:showAlert("info", "Sikeresen megtisztítottad az ablakot!", "10$-t kaptál a munkádért. Még " .. lastWindows .. " ablak van hátra.")
		movePlatform(math.random(1, buildingLevels))
	end
	generateHitPoint()
end

function stopWindowCleaning()
	setElementPosition(localPlayer, 1463.1818847656, -1359.9652099609, 13.546875)
	stopJob(); print("stopJob:stopWindowCleaning");
	destroyPlatform()
	showWindow = false
end

function createPlatform()
	lastWindows = math.random(5, 10)

	local v = platformDefaultPosition
	currentObject = createObject(objectID, v[1], v[2], v[3] - (buildingOffset * 1), 0, 0, v[4])

	generateHitPoint()

	--setElementPosition(localPlayer, 1462.5124511719, -1356.9193115234, 145.46697998047)
	setElementData(currentObject, "isInteractable", true)
	setElementData(currentObject, "object.name", "Felvonó")
	moveObject(currentObject, 5000, v[1], v[2], 14.546875)
end

function destroyPlatform()
	if isElement(currentObject) then
		destroyElement(currentObject)
	end
end

local lastLevel = 1
function movePlatform(level)
	local level = tonumber(level)
	local v = platformDefaultPosition
	print("Elöző szint: " .. lastLevel .. " Következő szint: " .. level)
	if lastLevel ~= level then
		moveObject(currentObject, speedPerLevel * level, v[1], v[2], v[3] - (buildingOffset * level))
		lastLevel = level
		setTimer(function()
			showWindow = true
		end, speedPerLevel * level, 1)
	else
		movePlatform(math.random(1, buildingLevels))
	end
end

function createJobBlip()
	if isElement(jobBlip) then
		destroyElement(jobBlip)
	end
	jobBlip = createBlip(1475.1215820313, -1360.5751953125, 11.8828125)
end

function destroyJobBlip()
	if isElement(jobBlip) then
		destroyElement(jobBlip)
	end
end

function createJobMarker()
	if isElement(jobMarker) then
		destroyElement(jobMarker)
	end
	jobMarker = createMarker(1475.1215820313, -1360.5751953125, 11.8828125 - 1, "cylinder", 1)
end

function destroyJobMarker()
	if isElement(jobMarker) then
		destroyElement(jobMarker)
	end
end

function cursorInBox(x, y, w, h)
	if x and y and w and h then
		if isCursorShowing() then
			if not isMTAWindowActive() then
				local cursorX, cursorY = getCursorPosition()
				
				cursorX, cursorY = cursorX * screenX, cursorY * screenY
				
				if cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
					return true
				end
			end
		end
	end
	
	return false
end

function generateRandomPointBetween(x, y, w1, h1, w2, h2)
    x = x + math.floor(math.random() * ((x + w1 - w2) - x))
    y = y + math.floor(math.random() * ((y + h1 - h2) - y))
    return x, y
end
