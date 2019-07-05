local JOB_ID = 2

local screenX, screenY = guiGetScreenSize()
local panelState = false
local interpolateTable = {}
local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()
--carspawn 1004.2019042969, -1349.3253173828, 13.34313583374
local loadPoint = {992.74938964844, -1353.0140380859, 13.354413032532}
local sellPoints = {

    {1891.3048095703, -2419.9035644531, 13.53911781311},
	{1948.505859375, -2145.1328125, 13.544631004333},
	{1812.04296875, -1673.7155761719, 13.546875},
	{1419.3322753906, -1674.4869384766, 13.539485931396},
	{1561.8634033203, -1821.9029541016, 13.546875},
	--{1561.8642578125, -1821.8967285156, 13.546875},
	{822.46716308594, -1801.7375488281, 13.274072647095},
	{407.63345336914, -1780.3353271484, 5.5641012191772},
	{1100.1680908203, -1153.5659179688, 23.199905395508},
	{1962.9100341797, -1181.9782714844, 25.594654083252},
	{1840.1961669922, -1363.6138916016, 13.104331970215},
	{2177.8063964844, -1737.2103271484, 13.086091041565},
	{2380.8591308594, -1739.3850097656, 13.089570045471},
	{2870.3181152344, -1991.5443115234, 10.647377967834},
	{2447.0786132813, -1924.4530029297, 13.086032867432},
	{2118.8181152344, -1901.4801025391, 13.089451789856},
	{1814.1696777344, -1916.1767578125, 13.110919952393},
	{1689.4267578125, -1862.0960693359, 13.088425636292},
	{1406.9801025391, -1233.3804931641, 13.112752914429},
	{1172.3620605469, -1288.0207519531, 13.108327865601},
	{736.66510009766, -1313.1745605469, 13.111231803894},
	{620.61932373047, -1370.0675048828, 13.209349632263},
	{481.1833190918, -1530.1076660156, 19.278604507446},
	{1144.7414550781, -911.23681640625, 42.602771759033},
	{797.53820800781, -522.92797851563, 15.902309417725},
	{802.38305664063, -522.97552490234, 15.898872375488},
	{617.35131835938, -537.63854980469, 15.898483276367},
	{1003.7386474609, -1229.0172119141, 16.487812042236},
	{1016.6665039063, -1483.5496826172, 13.162384033203},
	{1095.2913818359, -1705.0572509766, 13.11026763916},
	{1320.0328369141, -1692.0903320313, 13.109445571899},
	{2111.69140625, -1622.5885009766, 13.133508682251},
	{2265.3530273438, -1237.7125244141, 23.540786743164},
	{2125.3537597656, -1102.46875, 24.881496429443},
	{2196.4770507813, -1019.1200561523, 61.630630493164},
	{2869.6003417969, -1593.8519287109, 10.626825332642},
	{2865.970703125, -1605.744140625, 10.633337974548},
	{2650.1184082031, -1759.7845458984, 10.44492816925},
	{2427.7258300781, -1666.8671875, 13.080974578857},
	{2334.7790527344, -1534.7380371094, 23.536851882935},
	{2501.8210449219, -1512.8381347656, 23.537155151367},
	{2751.1430664063, -1100.0737304688, 69.120216369629},
	{2001.7614746094, -1268.8664550781, 23.524696350098},
	{828.71295166016, -1595.4182128906, 13.093005180359},
	{353.65243530273, -1549.5596923828, 32.78897857666},
	{376.24011230469, -1973.9875488281, 7.3760652542114},
	{160.55871582031, -1782.1633300781, 3.7145550251007},
	{-112.11692047119, -1144.8408203125, 1.2794790267944},
}
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

local jobPed = nil

addEventHandler("onClientResourceStart", resourceRoot, function ()
	loadFonts()
	jobPed = createPed(20,  1027.8881835938, -1358.2156982422, 13.7265625, 90)
	setElementFrozen(jobPed, true)
	setElementData(jobPed, "invulnerable", true)
	setElementData(jobPed, "visibleName", "Műszakvezető")
	setElementData(jobPed, "pedNameType", "Fagylaltos Munka")
	setPedAnimation(jobPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
end)


--local statusHeight = defHeight * (1 - progress / 100)
--dxDrawImageSection(x, y + statusHeight, defWidth, defHeight - statusHeight, 0, 0, defWidth, defHeight - statusHeight, "image")
local activeContainer = false
local containers = {}

local scoopInHand = nil
local activeCone = false
local selectedCone = false
local cones = {}

local scoops = {}

local currentOrder = nil
local maxCustomers = math.random(1, 4)
local currentCustomer = 0

local sellMarker = nil
local fillMarker = nil
local sellBlip = nil
local fillBlip = nil

local inSellingMode = false
local jobActive = false

local pedElement

local iceCreams = {
	{"Csokoládé", "files/chocolate.png", {150, 56, 39}, 100},
	{"Vanília", "files/vanilla.png", {246, 203, 94}, 100},
	{"Eper", "files/strawberry.png", {238, 168, 187}, 100},
	{"Citrom", "files/lemon.png", {240, 232, 216}, 100},
	{"Zöld alma", "files/greenapple.png", {145, 189, 50}, 100},
	{"Mangó", "files/mango.png", {241, 180, 124}, 100}
}

local iceCreamCones = {
	{"Rendes tölcsér", "files/cone1.png", 10},
	{"Talpas tölcsér", "files/cone2.png", 10},
}

local barW, barH = screenX, respc(200)
local barX, barY = 0, screenY - barH

local scoopW, scoopH = respc(100), respc(100)
--local scoopY = barY + (barH - scoopH) * 0.5
local scoopM = respc(10)

local containerW, containerH = respc(150), barH - respc(20)
local containerY = barY + (barH - containerH) * 0.5

local coneW, coneH = respc(100), respc(100)
local coneY = barY + (barH - coneH) * 0.5
local coneM = respc(10)

local iceCreamSize = respc(200)
local iceCreamX, iceCreamY = screenX - iceCreamSize, (screenY - iceCreamSize) * 0.5 

local panelW, panelH = respc(250), respc(300)
local panelX, panelY = respc(20), (screenY - panelH) * 0.5 

local orderX = panelX + respc(10)

local fixedPositions = {
	[1] = {iceCreamX + respc(42), iceCreamY - respc(75), respc(100), respc(100), respc(200)},
	[2] = {iceCreamX + respc(7), iceCreamY - respc(55), respc(100), respc(100), respc(120)},
}

function startIceCreamJob()
	exports.sarp_hud:showAlert("info", "Sikeresen felvetted a fagylaltos munkát! Menj a telepre, szállj be egy járműbe", "majd kezd el a fagylaltok árúsítását a megfelelő helyen")
	generateFillPoint()
	generateSellPoint()
	jobActive = true
	exports.sarp_jobs:createVehiclePoint(2, 1015.725402832, -1355.8988037109, 13.373134613037, 423, {255, 255, 255}, 2)
end

function stopIceCreamJob()
	destroyFillPoint()
	destroySellPoint()
	destroyFillBlip()
	destroySellBlip()
	setPlayerMode("normal")
	exports.sarp_jobs:destroyVehiclePoint()
	jobActive = false
end

function getPositionFromElementOffset(element, x, y, z)
	local elementMatrix = getElementMatrix(element)
	
	local offsetX = x * elementMatrix[1][1] + y * elementMatrix[2][1] + z * elementMatrix[3][1] + elementMatrix[4][1]
	local offsetY = x * elementMatrix[1][2] + y * elementMatrix[2][2] + z * elementMatrix[3][2] + elementMatrix[4][2]
	local offsetZ = x * elementMatrix[1][3] + y * elementMatrix[2][3] + z * elementMatrix[3][3] + elementMatrix[4][3]
	
	return offsetX, offsetY, offsetZ
end

function setPlayerMode(mode)
	if mode == "selling" then
		if isPedInVehicle(localPlayer) then
			maxCustomers = math.random(1, 4)
			
			local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
			
			local cameraX, cameraY, cameraZ = getPositionFromElementOffset(occupiedVehicle, -1, -1, 1)
			local looKAtX, lookAtY, lookAtZ = getPositionFromElementOffset(occupiedVehicle, 1, -1, 1)

			setCameraMatrix(cameraX, cameraY, cameraZ, looKAtX, lookAtY, lookAtZ, 0, 60)

			exports.sarp_hud:toggleHUD(false)
			showChat(false)

			setElementFrozen(occupiedVehicle, true)

			inSellingMode = true
		end
	elseif mode == "normal" then
		setCameraTarget(localPlayer)
		exports.sarp_hud:toggleHUD(true)
		showChat(true)
		local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
		if occupiedVehicle then
			setElementFrozen(occupiedVehicle, false)
		end
		inSellingMode = false
	end
end

addEventHandler("onClientRender", root, function()
	if not inSellingMode  then
		return
	end
	
	dxDrawRectangle(barX, barY, barW, barH, tocolor(30, 30, 30, 200))
	dxDrawMetroButtonWithBorder("button:noserve", "Nem szolgálom ki", barX, barY - respc(30), respc(150), respc(30), {200, 50, 50, 125}, {200, 50, 50, 175}, {255, 255, 255, 255}, fonts.Roboto13, "center", "center")

	if selectedCone then 
		dxDrawImage(iceCreamX, iceCreamY, fixedPositions[selectedCone][5], fixedPositions[selectedCone][5], iceCreamCones[selectedCone][2])
		for k, v in pairs(scoops) do
			local scoopY = fixedPositions[selectedCone][2] - (respc(25) * (k - 1)) 
			dxDrawImage(fixedPositions[selectedCone][1], scoopY, fixedPositions[selectedCone][3], fixedPositions[selectedCone][4], iceCreams[v][2])
		end

		dxDrawMetroButtonWithBorder("button:okay", "Átadás", iceCreamX, iceCreamY + fixedPositions[selectedCone][5] + respc(10), respc(150), respc(30), {7, 112, 196, 125}, {7, 112, 196, 175}, {255, 255, 255, 255}, fonts.Roboto13, "center", "center")
		dxDrawMetroButtonWithBorder("button:clear", "Törlés", iceCreamX, iceCreamY + fixedPositions[selectedCone][5] + respc(10) + respc(30) + respc(5), respc(150), respc(30), {200, 50, 50, 125}, {200, 50, 50, 175}, {255, 255, 255, 255}, fonts.Roboto13, "center", "center")
	end

	
	for k, v in pairs(iceCreams) do
		local containerX = respc(20) + ((scoopM + containerW) * (k - 1))
		local statusHeight = containerH * (1 - v[4] / 100)
		dxDrawRectangle(containerX - respc(3), containerY - respc(3), containerW + respc(6), containerH + respc(6), tocolor(90, 90, 90, 200))
		dxDrawImageSection(containerX, containerY + statusHeight, containerW, containerH - statusHeight, 0, 0, containerW, containerH - statusHeight, "files/texture.jpg", 0, 0, 0, tocolor(v[3][1], v[3][2], v[3][3], 200))
		
		if activeContainer == k then
			dxDrawText(v[1], containerX, containerY, containerX + containerW, containerY + containerH, tocolor(255, 255, 255, 255), 1, fonts.Roboto14, "center", "center")
		end

		containers[k] = {containerX, containerY, containerW, containerH}
	end

	for k, v in pairs(iceCreamCones) do
		local coneX = (barX + barW) - respc(10) - (coneW * k) 
		dxDrawImage(coneX, coneY, coneW, coneH, v[2])
		cones[k] = {coneX, coneY, coneW, coneH}
	end

	if currentOrder then
		dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(31, 31, 31, 240))
		dxDrawText("Rendelés", panelX, panelY + respc(7), panelX + panelW, panelY + panelH, tocolor(255, 255, 255, 255), 1, fonts.RobotoB18, "center")
		dxDrawText(iceCreamCones[currentOrder.cone][1], orderX, panelY + respc(45), orderX, orderY, tocolor(255, 255, 255, 255), 1, fonts.Roboto14)
		for k, v in pairs(currentOrder.scoops) do
			local orderY = panelY + respc(70) + (dxGetFontHeight(1, fonts.Roboto14) * (k - 1))
			dxDrawText(k .. ". " .. iceCreams[v][1], orderX, orderY, orderX, orderY, tocolor(255, 255, 255, 255), 1, fonts.Roboto14)
		end

		--dxDrawMetroButtonWithBorder("button:noserve", "Nem szolgálom ki", panelX, panelY + panelH + respc(15), panelW, respc(30), {200, 50, 50, 125}, {200, 50, 50, 175}, {255, 255, 255, 255}, fonts.Roboto13, "center", "center")
	end

	local cx, cy = getCursorPosition() -- lekérjük a relatív kurzor pozíciót

	if tonumber(cx) and tonumber(cy) then -- ha számot kapunk, tehát a kurzor elő van hozva
		cx, cy = cx * screenX, cy * screenY -- átalakítjuk abszolút értékekre
		cursorX, cursorY = cx, cy -- eltároljuk a változóba a kurzor abszolút pozícióit

		if scoopInHand then
			dxDrawImage(cursorX - (scoopW * 0.5), cursorY - (scoopH * 0.5), scoopW, scoopH, iceCreams[scoopInHand][2])
		end

		activeContainer = false -- ha nem találna szarságot akkor nincs kijelölve semmi, tehát false
		activeCone = false

		for k, v in pairs(containers) do -- végigmegyünk a létrehozott gombokon
			if cx >= v[1] and cy >= v[2] and cx <= v[1] + v[3] and cy <= v[2] + v[4] then -- benne van-e a boxban
				activeContainer = k -- eltároljuk az aktív kijelölt gombot
				break -- megállítjuk a loopot
			end
		end

		for k, v in pairs(cones) do -- végigmegyünk a létrehozott gombokon
			if cx >= v[1] and cy >= v[2] and cx <= v[1] + v[3] and cy <= v[2] + v[4] then -- benne van-e a boxban
				activeCone = k -- eltároljuk az aktív kijelölt gombot
				break -- megállítjuk a loopot
			end
		end
	else -- ha nincs előhozva a kurzor
		activeContainer = false -- nincs kijelölve semmi
		activeCone = false
		cursorX, cursorY = -10, -10 -- kurzor a képernyőn kívülre, hogy a render ne érzékelje
	end

	activeButtonChecker()
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
	if button == "left" and state == "down" then
		if inSellingMode then
			for k, v in pairs(containers) do
				if activeContainer == k then
					if iceCreams[k][4] > 0 then 
						if selectedCone then
							if scoopInHand then
								exports.sarp_hud:showInfobox("error", "Már van egy gombóc a kezedben")
							else
								iceCreams[k][4] = iceCreams[k][4] - 10	
								scoopInHand = k
							end
						else 
							exports.sarp_hud:showInfobox("error", "Először válasz tölcsért")
						end
					else
						exports.sarp_hud:showInfobox("error", "Ez az ízű fagylalt elfogyott, menj vissza a telepre és töltsd fel a készleteidet!")
					end
				end
			end

			for k, v in pairs(cones) do
				if activeCone == k then
					if iceCreamCones[k][3] > 0 then
						iceCreamCones[k][3] = iceCreamCones[k][3] - 1
						clearIceCream()
						selectedCone = k
					else
						exports.sarp_hud:showInfobox("error", "Ez a tölcsér elfogyott")
					end
					break
				end
			end

			if activeButton == "button:clear" then
				clearIceCream()
			end
			
			if activeButton == "button:okay" then
				giveIceCreamToCustomer()
			end

			if activeButton == "button:noserve" then
				print("asd")
				generateSellPoint()
				setPlayerMode("normal")
				scoops = {}
				selectedCone = nil
				scoopInHand = nil
				exports.sarp_hud:showInfobox("info", "Nem szolgáltad ki a vevőket")
				currentOrder = nil
				if isElement(pedElement) then
					destroyElement(pedElement)
				end
			end

			if selectedCone then
				if cursorInBox(iceCreamX, iceCreamY, iceCreamSize, iceCreamSize) then
					if #scoops >= 6 then
						exports.sarp_hud:showInfobox("error", "Több gombócot már nem tudsz rátenni")
						clearHand()
					else
						addScoope(scoopInHand)
					end
				end
			end
		end
		

		if clickedWorld == jobPed then
			if getElementData(localPlayer, "char.Job") == JOB_ID then
				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local pedPosX, pedPosY, pedPosZ = getElementPosition(jobPed)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 5 then
					if jobActive then
						stopIceCreamJob()
						exports.sarp_hud:showAlert("info", "Befejezted a munkát!")
					else
						startIceCreamJob()
					end
				end
			else
				exports.sarp_hud:showAlert("error", "Nem vagy fagylaltos!")
			end
		end
 	end
end)

addEventHandler("onClientElementDataChange", getRootElement(), function(dataName, oldValue)
	if source == localPlayer then
		if dataName == "char.Job" then
			if oldValue == JOB_ID then
				stopIceCreamJob()
			end
		end
	end
end)

function giveIceCreamToCustomer()
	if currentOrder.cone == selectedCone then
		if deepcompare(scoops, currentOrder.scoops) then
			selectedCone = nil
			scoopInHand = nil
			exports.sarp_hud:showInfobox("info", "Átadtad a fagyit! Kaptál " .. #currentOrder.scoops * 10 .. "$-t")
			exports.sarp_core:giveMoney(localPlayer, #currentOrder.scoops * 10)
			scoops = {}
			currentOrder = nil
			createOrder()
		else
			exports.sarp_hud:showInfobox("error", "A fagyi nem egyezik meg a vevő kérésével!")
		end
	else
		exports.sarp_hud:showInfobox("error", "A tölcsér nem egyezik a kért tölcsérrel!")
	end
end

addEventHandler("onClientMarkerHit", root, function(player)
	if player == localPlayer then
		if isPedInVehicle(localPlayer) then
			local playerVehicle = getPedOccupiedVehicle(localPlayer)
			if getElementModel(playerVehicle) == 423 then
				if source == fillMarker then
					for k, v in pairs(iceCreams) do
						v[4] = 100
					end

					for k, v in pairs(iceCreamCones) do
						v[4] = 10
					end

					exports.sarp_hud:showAlert("info", "Sikeresen feltöltötted a készleteket")
				elseif source == sellMarker then
				
						setPlayerMode("selling")
						createOrder()
						
					
				end
			end
		end
	end
end)

function generateFillPoint()
	if isElement(fillMarker) then
		destroyElement(fillMarker)
	end
	
	if isElement(fillBlip) then
		destroyElement(fillBlip)
	end

	fillMarker = createMarker(loadPoint[1], loadPoint[2], loadPoint[3], "checkpoint", 4)
	fillBlip = createBlip(loadPoint[1], loadPoint[2], loadPoint[3])
	setElementData(fillBlip, "blipIcon", "cp")
	setElementData(fillBlip, "blipSize", 10)
	setElementData(fillBlip, "blipTooltipText","Feltöltési pont")
	setElementData(fillBlip, "blipColor", tocolor(255, 0, 0))
end

function generateSellPoint()
	local rand = math.random(1, #sellPoints)
	if isElement(sellMarker) then
		destroyElement(sellMarker)
	end

	if isElement(sellBlip) then
		destroyElement(sellBlip)
	end
	

	local mX, mY, mZ = sellPoints[rand][1], sellPoints[rand][2], sellPoints[rand][3]
	sellMarker = createMarker(mX, mY, mZ, "checkpoint", 4, 50, 179, 239, 100)
	sellBlip = createBlip(mX, mY, mZ)
	setElementData(sellBlip, "blipIcon", "cp")
	setElementData(sellBlip, "blipSize", 10)
	setElementData(sellBlip, "blipTooltipText","Eladási pont")
	setElementData(sellBlip, "blipColor", tocolor(50, 179, 239))
end

function destroyFillPoint()
	if isElement(fillMarker) then
		destroyElement(fillMarker)
	end
end

function destroySellPoint()
	if isElement(sellMarker) then
		destroyElement(sellMarker)
	end
end

function destroyFillBlip()
	if isElement(fillBlip) then
		destroyElement(fillBlip)
	end
end

function destroySellBlip()
	if isElement(sellBlip) then
		destroyElement(sellBlip)
	end
end


function clearIceCream()
	scoops = {}
	selectedCone = nil
	clearHand()
end

function clearHand()
	scoopInHand = nil
end

function addScoope(scoop)
	table.insert(scoops, scoop)
	scoopInHand = nil
end

function showIceCreamPanel()
	local currentTick = getTickCount()
    alphaTable = {currentTick, currentTick + 500}

	local currentTick = getTickCount()
    local process = (currentTick - alphaTable[1]) / (alphaTable[2] - alphaTable[1])
    local alphaMultiplier = interpolateBetween(0, 0, 0, 1, 0, 0, process, "Linear")
end

function hasCustomer()
	if currentCustomer >= maxCustomers then
		-- Kidobjuk a belső nézetből	
		if isElement(pedElement) then
			destroyElement(pedElement)
			setPlayerMode("normal")
			generateSellPoint()
		end
		return false
	else
		return true
	end
end

function createNPC()
	if isElement(pedElement) then
		destroyElement(pedElement)
	end

	local occupiedVehicle = getPedOccupiedVehicle(localPlayer)
	local cameraX, cameraY, cameraZ = getPositionFromElementOffset(occupiedVehicle, -1, -1, 1)
	local pedX, pedY, pedZ = getPositionFromElementOffset(occupiedVehicle, 1, -1, 1)
	local pedRotation = math.deg(math.atan2(pedY - cameraY, pedX - cameraX)) + 180 - 90
	pedElement = createPed(100, pedX, pedY, pedZ, pedRotation)

	
	
	setElementRotation(pedElement, 0, 0, pedRotation)
	setPedCameraRotation(pedElement, pedRotation)
end

function createOrder(returning)
	if hasCustomer() then
		createNPC()

		local order = {}
		order.scoops = {}
		order.cone = math.random(1, #iceCreamCones)

		for i=1, math.random(1, 5) do
			table.insert(order.scoops, math.random(1, #iceCreams))
		end

		currentCustomer = currentCustomer + 1

		if returning then
			return order
		end

		currentOrder = order
	end
end

function deepcompare(t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
	local v2 = t2[k1]
	if v2 == nil or not deepcompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
	local v1 = t1[k2]
	if v1 == nil or not deepcompare(v1,v2) then return false end
	end
	return true
end