local JOB_ID = 3

local screenX, screenY = guiGetScreenSize()

local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

function loadFonts()
    fonts = {
		Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
		Roboto13 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(13), false, "antialiased"),
        Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
        Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(16), false, "cleartype"),
        Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
        RobotoL = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL14 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(14), false, "cleartype"),
        RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
        RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL24 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(24), false, "cleartype"),
        RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
        RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
        RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
    }
end

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

local mineColshape = createColRectangle(-820.41381835938, -1932.8894042969, 150, 100)

local receivedOres = {}
local oreW, oreH = respc(100), respc(100)


local jobPed = nil
local dropPed = nil
local jobActive = false
local currentMiningValue = 0
local lastMiningValue = 0
local showMinigame = false
local showOres = false

addEventHandler("onClientResourceStart", resourceRoot, function ()
	loadFonts()
	jobPed = createPed(260, -826.30041503906, -1898.1466064453, 11.811317443848, 180)
	setElementFrozen(jobPed, true)
	setElementData(jobPed, "invulnerable", true)
	setElementData(jobPed, "visibleName", "Műszakvezető")
	setElementData(jobPed, "pedNameType", "Bányász Munka")
    setPedAnimation(jobPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
    
    dropPed = createPed(27, 2767.3522949219, -1611.0777587891, 10.921875, 270)
	setElementFrozen(dropPed, true)
	setElementData(dropPed, "invulnerable", true)
	setElementData(dropPed, "visibleName", "Leadási hely")
	setElementData(dropPed, "pedNameType", "Bányász Munka")
    setPedAnimation(dropPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
end)

function startJob()
    exports.sarp_hud:showAlert("info", "Sikeresen elkezdted a bányászatot! Menj a bányába", "majd kezd el a bányászatot a megfelelő helyen")
    jobActive = true
end

function stopJob()
    exports.sarp_hud:showAlert("info", "Befejezted a bányászatot!")
    jobActive = false
end

local startTick = nil

function startMining()
    if currentMiningValue < 100 then
        startTick = getTickCount()
        lastMiningValue = currentMiningValue
        currentMiningValue = currentMiningValue + math.random(5, 15)
        triggerServerEvent("sarp_miningS:startMining", localPlayer)
        if currentMiningValue >= 100 then
            currentMiningValue = 100
            setTimer(function()
                stopMining()
            end, 1500, 1)
        end
    end
end

function stopMining()
    triggerServerEvent("sarp_miningS:stopMining", localPlayer)
    --print("STOP")
    showMiningGame()
end

local stoneState = 0
local clickCounter = 0
local lastClickTick = 0

function showMiningGame()
    stoneState = 0
    showMinigame = true
    clickCounter = 0
    changeStoneCrosshair()
end

function hideMiningGame()
    showMinigame = false
end

addCommandHandler("mine", function()
    startMining()
end)

registerEvent("sarp_miningC:playMiningSound", root, function()
    local x, y, z = getElementPosition(source)
	playSound3D(":sarp_assets/audio/jobs/miner/mining.mp3", x, y, z)
end)


local lastHit = getTickCount()
local coolDown = 1500 

addEventHandler("onClientKey", root, function(button, press)
    if isElementWithinColShape(localPlayer, mineColshape) and jobActive then
        if getPedWeapon(localPlayer) == 6 then
            if button == "mouse1" and press then
                if lastHit < getTickCount() - coolDown then
                    lastHit = getTickCount()
                    startMining()   
                end
            end
        end
    end
end)

local barW, barH = 251, 10
local barX, barY = (screenX - barW) * 0.5, screenY - 5 - 46 - barH - 5

local crosshairW, crosshairH = respc(40), respc(40)
local crosshairX, crosshairY = 0, 0

local stoneW, stoneH = respc(400), respc(200)
local stoneX, stoneY = (screenX / 2) - (stoneW / 2), (screenY / 2) - (stoneH / 2)

local pickaxeW, pickaxeH = respc(40), respc(40)

addEventHandler("onClientRender", root, function()
    if isElementWithinColShape(localPlayer, mineColshape) and jobActive and not showMinigame and not showOres then
        dxDrawRectangle(barX, barY, barW, barH, tocolor(31, 31, 31, 240))  

        if startTick then
            local currentTick = getTickCount()
            local elapsedTick = currentTick - startTick
            local endTick = startTick + 1200
            local duration = endTick - startTick
            local barProgress = elapsedTick / duration
            local barFill = interpolateBetween(
                lastMiningValue / 100, 0, 0,
                currentMiningValue / 100, 0, 0,
                barProgress, "Linear"
            )
            --print(barFill .. " :: " .. currentMiningValue .. " :: " .. currentMiningValue / 100 .. " :: " .. (barW - 4) * barFill)
            dxDrawRectangle(barX + 2, barY + 2, (barW - 4) * barFill, barH - 4, tocolor(7, 112, 196, 240))  
        end  
    end

    if showMinigame then
        dxDrawImage(stoneX, stoneY, stoneW, stoneH, "files/stone" .. stoneState .. ".png")
		dxDrawImage(crosshairX, crosshairY, crosshairW, crosshairH, "files/crosshair.png")
        
        
		--> Kurzor megváltozatása
		if isCursorShowing() then
			local relX, relY = getCursorPosition()
			local cursorX, cursorY = relX * screenX, relY * screenY
            setCursorAlpha(0)
            local pickaxeRX = 0
            if getKeyState("mouse1") then
                pickaxeRX = -30
            end
			dxDrawImage(cursorX - respc(10), cursorY - respc(10), pickaxeW, pickaxeH, "files/pickaxe.png", pickaxeRX, 0, 0)
        end
        
    elseif showOres then
        
        --> Ércek kirajzolása
		for k, v in pairs(receivedOres) do
			--outputChatBox(k .. " " .. v)
			dxDrawImage(v[2], v[3], oreW, oreH, ores[v[1]][2])
		end
		
		--> Kurzor megváltozatása
		if isCursorShowing() then
			local relX, relY = getCursorPosition()
			local cursorX, cursorY = relX * screenX, relY * screenY
			setCursorAlpha(0)
			dxDrawImage(cursorX - respc(10), cursorY - respc(10), pickaxeW, pickaxeH, ":sarp_assets/images/jobs/miner/zsak.png", pickaxeRX, 0, 0)
		end

    end
end)

addEventHandler("onClientColShapeHit", root, function(element)
    if element == localPlayer then
        if source == mineColshape and jobActive then
            --print("Üdv a bányában") 
        end
    end
end)

addEventHandler("onClientColShapeLeave", root, function(element)
    if element == localPlayer then
        if source == mineColshape and jobActive then
            --print("Bye bye bánya")
        end
    end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
    if getElementData(localPlayer, "char.Job") == JOB_ID then
        if button == "left" and state == "down" then
            if clickedWorld == jobPed then
                local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local pedPosX, pedPosY, pedPosZ = getElementPosition(jobPed)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 3 then

                    if jobActive then
                        stopJob()
                    else
                        startJob()
                    end
                end
            end

            if clickedWorld == dropPed then
                local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local pedPosX, pedPosY, pedPosZ = getElementPosition(dropPed)

                if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 3 then
                    local hasOres = false
                    for k, v in pairs(ores) do
                        local itemID = v[4]
                        if exports.sarp_inventory:hasItem(itemID) then
                            triggerServerEvent("sarp_miningS:takeOres", localPlayer) 
                            hasOres = true
                            break
                        end
                    end    
                    
                    if not hasOres then
                        exports.sarp_alert:showAlert("error", "Nincs nálad semmilyen érc")
                    end
                end
            end
        end

        if showMinigame then
            if state == "down" then
                if cursorInBox(crosshairX, crosshairY, crosshairW, crosshairH) then
                    if getTickCount() - lastClickTick >= 350 then -- 250 ms
                        lastClickTick = getTickCount() -- új tick beállítása
                        -- Kő zúzása
                        playSound(":sarp_assets/audio/jobs/miner/pickaxe.mp3")
                        clickCounter = clickCounter + 1
                        if clickCounter % 2 == 0 then
                            changeStoneCrosshair()
                            changeStoneState()
                        end
                    end
                end
            end
        elseif showOres then
            for k, v in pairs(receivedOres) do
                dxDrawImage(v[2], v[3], oreW, oreH, ores[v[1]][2])
                if cursorInBox(v[2], v[3], oreW, oreH) then
                    if #receivedOres == 1 then
                        showOres = false
                        setCursorAlpha(255)
                        lastMiningValue = 0
                        currentMiningValue = 0
                        
                    end
                    --outputChatBox("Összeszedtél egy " .. ores[v[1]][1] .. " nevű cuccot")
                    table.remove(receivedOres, k)
                    triggerServerEvent("sarp_miningS:giveOre", localPlayer, ores[v[1]][4])
                end
            end
        end
    end
end)

function dropOresFromStone()
	showOres = true
	local count = math.random(1, 4)
	
	for i = 1, count do
		local chance = math.random(1, #ores)
		local randomX, randomY = generateRandomPointBetween(0, 0, screenX, screenY, oreW, oreH)
		receivedOres[i] = {chance, randomX, randomY}
	end
	
	--outputConsole(inspect(receivedOres))
end

function changeStoneState()
	if clickCounter == 10 then -- 10
		stoneState = 1
	elseif clickCounter == 20 then -- 20
		stoneState = 2
	elseif clickCounter == 26 then -- 26
		-- Kő összetörése, ércek szétszórása
		hideMiningGame()
		dropOresFromStone()
	end
end

function changeStoneCrosshair()
	if showMinigame then
		crosshairX, crosshairY = generateRandomPointBetween(stoneX + respc(25), stoneY, stoneW - respc(105), stoneH - respc(20), crosshairW, crosshairH)
		--clickCounter = 0
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
