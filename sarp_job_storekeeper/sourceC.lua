local JOB_ID = 1

local screenX, screenY = guiGetScreenSize()
local responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

local function resp(value)
	return value * responsiveMultipler
end

local function respc(value)
	return math.ceil(value * responsiveMultipler)
end

local function loadFonts()
	local fonts = {
		ocr10bold = exports.sarp_assets:loadFont("ocr.ttf", 10, false, "cleartype"),
		ocr25bold = exports.sarp_assets:loadFont("ocr.ttf", 25, false, "cleartype"),
		RobotoLabel = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
		RobotoBold = exports.sarp_assets:loadFont("Roboto-Bold.ttf", 24, false, "antialiased"),
		handFont = exports.sarp_assets:loadFont("hand.otf", respc(24), false, "antialiased"),
		barCode = exports.sarp_assets:loadFont("VT323.ttf", respc(10), false, "cleartype"),
		CourierNew = exports.sarp_assets:loadFont("CourierNew.ttf", respc(18), false, "antialiased"),
		RobotoBoldR = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(24), false, "cleartype"),
		lunabar = exports.sarp_assets:loadFont("lunabar.ttf", respc(26), false, "antialiased"),
	}

	for k,v in pairs(fonts) do
		_G[k] = v
		_G[k .. "H"] = dxGetFontHeight(1, _G[k])
	end
end

local scriptMode = true

local jobPed = false
local jobStarted = false
local jobData = false

local sign1 = dxCreateTexture("files/sign1.png")
local sign2 = dxCreateTexture("files/sign2.png")
local sign3 = dxCreateTexture("files/sign3.png")
local stripe = dxCreateTexture("files/stripe.png")

local selection = dxCreateTexture("files/selection.png")
local selectionSize = 16 * (1 / 75)

local shelfPositions = {
	{2783.75, -2448, 14.63482093811, 90},
	{2791.75, -2448, 14.63482093811, 90},
	{2783.75, -2464, 14.63482093811, 90},
	{2791.75, -2464, 14.63482093811, 90},
}

local randomShelfBoxModels = {2968, 1271}
local shelfBoxPoses = {}
local disallowedShelfCratePoses = {}
local jobCreatedObjects = {}

local carrierModel = 8287
local mainCarrierObject = false

local currentInteractions = {
	carrier = {},
	crate = {}
}

local jobColshape = createColCuboid(2720.5751953125, -2565.7885742188, 12.627555847168, 90.148193359375, 181.91625976563, 10)
local factoryColshape = createColCuboid(2775.4482421875, -2468.0024414063, 12.631188392639, 26.27490234375, 23.430419921875, 10)
local labelingColshape = createColCuboid(2764.7951660156, -2538.3078613281, 12.631188392639, 22.5966796875, 25.46875, 10)

local inTheJobColShape = false

local quantityRT = false
local clockRT = false
local clockRefreshTimer = false

local syncableCarriers = {}
local syncableCrates = {}
local syncableCarryingCrates = {}

local workbenchPositions = {
	{2780.2309570313, -2520.0639648438, 12.631794929504, 4.75, 1.75, 2.75},
	{2780.2309570313, -2524.3, 12.627556800842, 4.75, 1.75, 2.75},

	{2765.95, -2522.4729003906, 12.641052246094, 4.75, 1.75, 2.75},
	{2765.95, -2526.7089355468, 12.641052246094, 4.75, 1.75, 2.75},

	{2769.7543945313, -2517.7, 12.627555847168, 1.75, 2.375, 2.75},
	{2765.5183593751, -2517.7, 12.627555847168, 1.75, 2.375, 2.75},

	{2784.45, -2531.2, 12.627555847168, 1.75, 2.375, 2.75},
	{2780.2139648437997, -2531.2, 12.627555847168, 1.75, 2.375, 2.75},
}

local crateFinalPosition = {2771.0791015625, -2538.3232421875, 12.637613296509, 10.032958984375, 3.630859375, 2.75}

local showSticker = false

local lastNames = {
	"Bell",
	"Walsh",
	"Black",
	"Butler",
	"Thompson",
	"O'connor",
	"Marquez",
	"Morales",
	"Douglas",
	"Hendrix",
	"Chapman",
	"Adams",
	"Harper",
	"Saunders",
	"Reynolds",
	"Lara",
	"Wong",
	"Leon",
	"Mayo",
	"Donaldson",
	"Stewart",
	"Wallace",
	"Sutton",
	"Donovan",
	"Carson",
	"Ferrell",
	"Mathis",
	"Riley",
	"West",
	"Stone",
	"Hughes",
	"Lawson",
	"Zamora",
	"Cotton",
	"Silva"
}

local firstNames = {
	"Jess",
	"Leigh",
	"Elliot",
	"Rory",
	"Silver",
	"Emerson",
	"Kris",
	"Tyler",
	"Casey",
	"Ashton",
	"Sam",
	"Taylor",
	"Ollie",
	"Christoph",
	"Brennen",
	"Cedric",
	"Otto",
	"Colten",
	"Jameson",
	"Morgan",
	"Bobby",
	"Anthony",
	"Arthur",
	"Leo",
	"Gilbert",
	"Jaycob",
	"Wade",
	"Louis",
	"Jake",
	"Declan",
	"Kian",
	"Charles",
	"Kayson",
	"Bryan",
	"Caiden"
}

function swap(array, a, b)
	array[a], array[b] = array[b], array[a]
end

function shuffleTable(array)
	local count = #array

	while count > 1 do
		swap(array, math.random(#array), count)
		count = count - 1
	end
end

local activeFakeInput = false
local fakeInputs = {
	customerName = "",
	deliveryAddress = "",
	zipCode = ""
}

local getElementBoundingBox_ = getElementBoundingBox
function getElementBoundingBox(element)
	if getElementModel(element) == carrierModel then
		return -0.265625, -0.25, 0, 0.265625, 1.325, 1.5
	end

	return getElementBoundingBox_(element)
end

local texturedElements = {}

function removeTextureFromElement(element)
	if texturedElements[element] then
		if isElement(texturedElements[element][1]) then
			destroyElement(texturedElements[element][1])
		end

		if isElement(texturedElements[element][2]) then
			destroyElement(texturedElements[element][2])
		end

		texturedElements[element] = nil
	end
end

function applyTextureToElement(element, texture, applyTo)
	if isElement(element) and isElement(texture) then
		removeTextureFromElement(element)

		texturedElements[element] = {}
		texturedElements[element][1] = dxCreateShader("files/texturechanger.fx")

		if isElement(texturedElements[element][1]) and applyTo then
			texturedElements[element][2] = texture

			dxSetShaderValue(texturedElements[element][1], "gTexture", texturedElements[element][2])
			engineApplyShaderToWorldTexture(texturedElements[element][1], applyTo, element)
		else
			texturedElements[element] = nil
		end
	end
end

function applyStorageNumberToCrate(crateElement, storageNumber, stickered)
	if isElement(crateElement) and storageNumber then
		local rt = dxCreateRenderTarget(128, 128)
		
		if isElement(rt) then
			dxSetRenderTarget(rt)

			dxDrawImage(0, 0, 128, 128, "files/cheerybox01.png")
			dxDrawText(storageNumber, 0, 0, 128, 128, tocolor(0, 0, 0, 175), 1, RobotoBold, "center", "center", false, false, false, false, false, 180)

			if stickered then
				dxDrawImage(15, 75, 41, -62, "files/vignette.png")
			end

			dxSetRenderTarget()

			local pixels = dxConvertPixels(dxGetTexturePixels(rt), "png")
			applyTextureToElement(crateElement, dxCreateTexture(pixels, "dxt1"), "cheerybox01")

			destroyElement(rt)
			rt = nil
		end
	end
end

function startTheJob()
	if jobStarted then
		return
	end

	jobStarted = true

	math.randomseed(getTickCount())

	jobData = {}
	jobData.shelfPlacedItems = math.random(2, 4)--math.random(8, 15)
	jobData.cratesPlaced = {}
	jobData.cratesOnShelf = {}
	jobData.crateDatas = {}
	jobData.cratesDone = {}

	for i = 1, jobData.shelfPlacedItems do
		local positionId = false

		while true do
			positionId = math.random(1, #shelfBoxPoses)

			if not disallowedShelfCratePoses[positionId] then
				disallowedShelfCratePoses[positionId] = true
				break
			end
		end

		local position = shelfBoxPoses[positionId]

		local boxObject = createObject(2912, position[1], position[2], position[3])
		setElementFrozen(boxObject, true)
		setObjectBreakable(boxObject, false)

		table.insert(jobData.cratesPlaced, boxObject)

		local zoneX, zoneY, zoneZ = math.random(-2500, 2500), math.random(-2500, 580), math.random(0, 50)
		local cityName = getZoneName(zoneX, zoneY, zoneZ, true)
		local zoneName = getZoneName(zoneX, zoneY, zoneZ)
		local rawZoneName = zoneName

		if cityName ~= zoneName then
			zoneName = cityName .. ", " .. zoneName
		else
			zoneName = zoneName .. ","
		end

		local houseID = math.random(10, 99)

		shuffleTable(lastNames)
		shuffleTable(firstNames)

		jobData.cratesOnShelf[boxObject] = {
			objectID = #jobData.cratesPlaced,
			storageNumber = math.random(100, 999) .. string.char(math.random(65, 90)),
			zipCode = math.random(10000, 99999),
			address = zoneName .. " " .. houseID,
			barCode = tonumber(math.random(10000, 99999) .. math.random(10000, 99999)),
			deliveryBarCode = cityName:gsub("%l", ""):gsub(" ", "") .. "~" .. rawZoneName:gsub("%l", ""):gsub(" ", "") .. "~" .. houseID,
			customerName = lastNames[i] .. " " .. firstNames[i]
		}

		table.insert(jobData.crateDatas, jobData.cratesOnShelf[boxObject])

		applyStorageNumberToCrate(boxObject, jobData.cratesOnShelf[boxObject].storageNumber)

		setElementData(boxObject, "isInteractable", true)
		setElementData(boxObject, "object.name", "Csomag")
		setElementData(boxObject, "isFactoryObject", true)
	end

	mainCarrierObject = createObject(carrierModel, 2773.2155761719, -2449.8220214844, 12.637222290039)
	setElementData(mainCarrierObject, "isInteractable", true)
	setElementData(mainCarrierObject, "object.name", "Kézi raklapemelő")
	setElementData(mainCarrierObject, "isFactoryObject", true)

	currentInteractions.carrier = {}
	currentInteractions.crate = {}

	table.insert(currentInteractions.carrier, {"Eszköz felvétele", ":sarp_job_storekeeper/files/pickUpCarrier.png", "onClientPlayerPickUpCarrier"})

	table.insert(currentInteractions.crate, {"Átrakás a raklapemelőre", ":sarp_job_storekeeper/files/moveCrate.png", "onClientPlayerPickUpCrate"})
end

function endJob(finish)
	local crateCount = 0

	if jobData then
		if jobData.cratesPlaced then
			for k,v in pairs(jobData.cratesPlaced) do
				if isElement(v) then
					removeTextureFromElement(v)
					destroyElement(v)
				end
			end
		end

		if jobData.cratesDone then
			for k,v in pairs(jobData.cratesDone) do
				if isElement(v) then
					crateCount = crateCount + 1

					removeTextureFromElement(v)
					destroyElement(v)
				end
			end
		end
	end

	if texturedElements then
		for k,v in pairs(texturedElements) do
			if isElement(v[1]) then
				destroyElement(v[1])
			end

			if isElement(v[2]) then
				destroyElement(v[2])
			end

			texturedElements[k] = nil
		end
	end

	texturedElements = {}

	jobData = nil
	currentInteractions.carrier = {}
	currentInteractions.crate = {}
	disallowedShelfCratePoses = {}

	if isElement(mainCarrierObject) then
		destroyElement(mainCarrierObject)
	end
	mainCarrierObject = nil

	setElementData(localPlayer, "carrierActive", false)
	setElementData(localPlayer, "carrierPlacedObjects", false)
	setElementData(localPlayer, "carrierPlacedOnFactory", false)
	setElementData(localPlayer, "carryingCrate", false)

	if finish then
		local payment = crateCount * 250

		exports.sarp_hud:showAlert("success", "Sikeresen végeztél a munkával!", "Fizetés: " .. payment .. " $")
		outputChatBox(exports.sarp_core:getServerTag("info") .. "Elvégezted a munkád, a fizetésed: #acd373" .. payment .. " $", 50, 179, 239, true)

		triggerServerEvent("giveStorekeeperJobCash", localPlayer, payment)
	end

	jobStarted = false
end

addEventHandler("onAssetsLoaded", getRootElement(),
	function ()
		loadFonts()
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		removeGTAObjects()
		loadFonts()

		jobPed = createPed(16, 2743.6000976563, -2454.7802734375, 13.86225605011, 270)
		setElementFrozen(jobPed, true)
		setElementData(jobPed, "invulnerable", true)
		setElementData(jobPed, "visibleName", "Műszakvezető")
		setElementData(jobPed, "pedNameType", "Munka")
		setPedAnimation(jobPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)

		local desk = createObject(2008, 2744.3068847656, -2453.8518066406, 12.86225605011)
		setElementRotation(desk, 0, 0, 270)

		local chair = createObject(1810, 2743.25, -2454.4802734375, 12.86225605011)
		setElementRotation(chair, 0, 0, 90)

		generateFactoryShelfs()
		updateDynamicDatas()

		for _, player in ipairs(getElementsByType("player", root, true)) do
			if getElementData(player, "loggedIn") then
				syncPlayerElements(player)
			end
		end

		jobStarted = false
		inTheJobColShape = false
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		endJob()
	end
)

addEventHandler("onClientClick", getRootElement(),
	function (button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
		if state == "up" and clickedWorld == jobPed and getElementData(localPlayer, "char.Job") == JOB_ID then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local pedPosX, pedPosY, pedPosZ = getElementPosition(jobPed)

			if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 5 then
				if jobStarted then
					exports.sarp_hud:showAlert("error", "Már dolgozol!")
				else
					startTheJob()

					outputChatBox(exports.sarp_core:getServerTag("info") .. "Elkezdted a munkát. A kézi raklapemelőt a raktár bejáratánál találod.", 255, 150, 0, true)
					outputChatBox(exports.sarp_core:getServerTag("info") .. "Jelenleg #32b3ef" .. jobData.shelfPlacedItems .. " db#ffffff csomagot kell átszállítanod és címkézned.", 255, 150, 0, true)

					exports.sarp_hud:showAlert("info", "Elkezdted a munkát.")
				end
			end
		end
	end
)

addEvent("onClientPlayerPickUpCarrier", true)
addEventHandler("onClientPlayerPickUpCarrier", getRootElement(),
	function (sourceElement)
		setElementData(localPlayer, "carrierActive", true)
		exports.sarp_controls:toggleControl({"jump", "aim_weapon", "fire", "enter_exit", "crouch", "sprint"}, false)
	end
)

addEvent("onClientPlayerPickUpCrate", true)
addEventHandler("onClientPlayerPickUpCrate", getRootElement(),
	function (sourceElement)
		if not getElementData(localPlayer, "carrierActive") then
			exports.sarp_hud:showAlert("error", "Előbb vedd fel a raktár bejáratától a raklapemelőt!")
		else
			local cratesOnCarrier = getElementData(localPlayer, "carrierPlacedObjects") or {}

			if #cratesOnCarrier + 1 > 4 then
				exports.sarp_hud:showAlert("error", "Nem fér több láda az emelőre!")
			else
				table.insert(cratesOnCarrier, jobData.cratesOnShelf[sourceElement])

				removeTextureFromElement(sourceElement)
				jobData.cratesOnShelf[sourceElement] = nil

				for k,v in pairs(jobData.cratesPlaced) do
					if isElement(v) and v == sourceElement then
						destroyElement(v)
					end
				end

				setElementData(localPlayer, "carrierPlacedObjects", cratesOnCarrier)
			end
		end
	end
)

addEvent("onClientPlayerPickUpCarrierAfterDropped", true)
addEventHandler("onClientPlayerPickUpCarrierAfterDropped", getRootElement(),
	function (sourceElement)
		if jobData.carryingCrate then
			exports.sarp_hud:showAlert("error", "Előbb címkézd fel a kezedben lévő ládát!")
		else
			setElementData(sourceElement, "isInteractable", false)
			setElementData(localPlayer, "carrierPlacedOnFactory", false)
			setElementData(localPlayer, "carrierActive", true)
			exports.sarp_controls:toggleControl({"jump", "aim_weapon", "fire", "enter_exit", "crouch", "sprint"}, false)
		end
	end
)

addEvent("onClientPlayerPickUpCrateFromCarrier", true)
addEventHandler("onClientPlayerPickUpCrateFromCarrier", getRootElement(),
	function (sourceElement)
		if getElementData(localPlayer, "carryingCrate") then
			exports.sarp_hud:showAlert("error", "Már van a kezedben egy láda!")
		else
			setElementData(sourceElement, "isInteractable", false)

			local carrierPlacedObjects = getElementData(localPlayer, "carrierPlacedObjects") or {}
			if #carrierPlacedObjects > 0 then
				removeTextureFromElement(sourceElement)

				jobData.carryingCrate = carrierPlacedObjects[#carrierPlacedObjects]
				table.remove(carrierPlacedObjects, #carrierPlacedObjects)

				setElementData(localPlayer, "carrierPlacedObjects", carrierPlacedObjects)
				setElementData(localPlayer, "carryingCrate", jobData.carryingCrate.storageNumber)

				triggerServerEvent("crateCarryAnimation", localPlayer)
				exports.sarp_controls:toggleControl({"jump", "aim_weapon", "fire", "enter_exit", "crouch", "sprint"}, false)
			end
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if dataName == "carrierActive" then
			syncPlayerElements(source)
		elseif dataName == "carrierPlacedObjects" then
			syncPlayerElements(source)
		elseif dataName == "carrierPlacedOnFactory" then
			syncPlayerElements(source)
		elseif dataName == "carryingCrate" then
			syncPlayerElements(source)
		elseif dataName == "donePackages" then
			updateQuantity()
		elseif dataName == "char.Job" and source == localPlayer then
			endJob()
		end
	end
)

addEventHandler("onClientPlayerQuit", getRootElement(),
	function ()
		unloadPlayerElements(source)
	end
)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if getElementType(source) == "player" then
			unloadPlayerElements(source)
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "player" then
			syncPlayerElements(source)
		end
	end
)

function unloadPlayerElements(player)
	if syncableCrates[player] then
		for k, v in pairs(syncableCrates[player]) do
			if isElement(v) then
				removeTextureFromElement(v)
				destroyElement(v)
			end
		end

		syncableCrates[player] = nil
	end

	if isElement(syncableCarriers[player]) then
		destroyElement(syncableCarriers[player])
	end
	syncableCarriers[player] = nil

	if isElement(syncableCarryingCrates[player]) then
		destroyElement(syncableCarryingCrates[player])
	end
	syncableCarryingCrates[player] = nil
end

function syncPlayerElements(player)
	if syncableCrates[player] then
		for k, v in pairs(syncableCrates[player]) do
			if isElement(v) then
				removeTextureFromElement(v)
				destroyElement(v)
			end
		end

		syncableCrates[player] = nil
	end

	if getElementData(player, "carrierActive") then
		if not syncableCarriers[player] then
			if player == localPlayer then
				if isElement(mainCarrierObject) then
					destroyElement(mainCarrierObject)
				end
				mainCarrierObject = nil
			end

			syncableCarriers[player] = createObject(carrierModel, getElementPosition(player))
		end

		setElementCollisionsEnabled(syncableCarriers[player], false)
		attachElements(syncableCarriers[player], player, 0, 0.6, -0.99)

		local enableCrateCollisions = false

		if getElementData(player, "carrierPlacedOnFactory") and syncableCarriers[player] then
			local pos = getElementData(player, "carrierPlacedOnFactory")

			detachElements(syncableCarriers[player], player)

			setElementPosition(syncableCarriers[player], pos[1], pos[2], pos[3])
			setElementRotation(syncableCarriers[player], 0, 0, pos[4])
			setElementCollisionsEnabled(syncableCarriers[player], true)

			if player == localPlayer then
				setElementData(syncableCarriers[player], "isInteractable", true)
				setElementData(syncableCarriers[player], "object.name", "Kézi raklapemelő")
				setElementData(syncableCarriers[player], "isFactoryObject", true)

				currentInteractions.carrier = {}
				table.insert(currentInteractions.carrier, {"Eszköz felvétele", ":sarp_job_storekeeper/files/pickUpCarrier.png", "onClientPlayerPickUpCarrierAfterDropped"})
			end

			if getElementData(player, "carryingCrate") and not syncableCarryingCrates[player] then
				local crateObject = createObject(2912, 0, 0, 0)

				setElementCollisionsEnabled(crateObject, false)
				setObjectScale(crateObject, 0.9)

				exports.sarp_boneattach:attachElementToBone(crateObject, player, 12, 0.25, 0, 0.15, -100, 0, -20)

				syncableCarryingCrates[player] = crateObject

				if player == localPlayer then
					applyStorageNumberToCrate(crateObject, getElementData(player, "carryingCrate"))
				end
			elseif syncableCarryingCrates[player] then
				if isElement(syncableCarryingCrates[player]) then
					destroyElement(syncableCarryingCrates[player])
				end

				syncableCarryingCrates[player] = nil
			end

			enableCrateCollisions = true
		end

		local carrierPlacedObjects = getElementData(player, "carrierPlacedObjects") or {}
		if #carrierPlacedObjects > 0 then
			syncableCrates[player] = {}

			for i = 1, #carrierPlacedObjects do
				local y = i % 2 ~= 0 and 0.45 or 1.1
				local z = i <= 2 and 0.07 or 0.7

				local crateObject = createObject(2912, getElementPosition(player))
				
				setObjectBreakable(crateObject, false)
				setElementCollisionsEnabled(crateObject, enableCrateCollisions)
				setObjectScale(crateObject, 0.9)
				setElementParent(crateObject, player)
				
				attachElements(crateObject, syncableCarriers[player], 0, y, z)

				table.insert(syncableCrates[player], crateObject)

				if player == localPlayer then
					applyStorageNumberToCrate(crateObject, carrierPlacedObjects[i].storageNumber)

					if enableCrateCollisions then
						currentInteractions.carrier = {}
						table.insert(currentInteractions.carrier, {"Eszköz felvétele", ":sarp_job_storekeeper/files/pickUpCarrier.png", "onClientPlayerPickUpCarrierAfterDropped"})
						table.insert(currentInteractions.carrier, {"Doboz felvétele", ":sarp_job_storekeeper/files/pickUpCrate.png", "onClientPlayerPickUpCrateFromCarrier"})
					end
				end
			end
		end
	elseif syncableCarriers[player] then
		if isElement(syncableCarriers[player]) then
			destroyElement(syncableCarriers[player])
		end
		syncableCarriers[player] = nil
	end
end

function loadJob()
	if not inTheJobColShape then
		inTheJobColShape = true

		clockRT = dxCreateRenderTarget(180, 90)
		clockRefreshTimer = setTimer(refreshClockRT, 10000, 0)

		quantityRT = dxCreateRenderTarget(250, 90, true)

		generateFactoryShelfs()
		updateDynamicDatas()

		addEventHandler("onClientRender", getRootElement(), renderInsideFactory)
	end
end

addEventHandler("onClientPlayerSpawn", localPlayer,
	function ()
		if isElementWithinColShape(localPlayer, jobColshape) then
			loadJob()
		end
	end
)

addEventHandler("onClientDimensionChange", getRootElement(),
	function ()
		if getElementDimension(localPlayer) == 0 then
			if isElementWithinColShape(localPlayer, jobColshape) then
				loadJob()
			end
		end
	end
)

addEventHandler("onClientColShapeHit", jobColshape,
	function (hitElement, matchDimension)
		if hitElement == localPlayer and matchDimension then
			loadJob()
		end
	end
)

addEventHandler("onClientColShapeLeave", jobColshape,
	function (hitElement, matchDimension)
		if hitElement == localPlayer and matchDimension then
			removeEventHandler("onClientRender", getRootElement(), renderInsideFactory)

			if isTimer(clockRefreshTimer) then
				killTimer(clockRefreshTimer)
			end
			clockRefreshTimer = nil

			if isElement(clockRT) then
				destroyElement(clockRT)
			end
			clockRT = nil

			if isElement(quantityRT) then
				destroyElement(quantityRT)
			end
			quantityRT = nil

			endJob()
			unloadFactoryShelfs()

			inTheJobColShape = false
		end
	end
)

function refreshClockRT()
	if isElement(clockRT) then
		local realTime = getRealTime()

		dxSetRenderTarget(clockRT)

		dxDrawRectangle(0, 0, 180, 90, tocolor(40, 40, 40))
		dxDrawRectangle(10, 10, 160, 70, tocolor(0, 0, 0))

		dxDrawText(string.format("%02d:%02d", realTime.hour, realTime.minute), 0, 0, 180, 90, tocolor(245, 10, 10), 1, ocr25bold, "center", "center")

		dxSetRenderTarget()
	end
end

function updateQuantity()
	if isElementWithinColShape(localPlayer, jobColshape) then
		if isElement(quantityRT) then
			dxSetRenderTarget(quantityRT, true)

			dxDrawRectangle(0, 0, 250, 90, tocolor(20, 20, 20))
			dxDrawRectangle(5, 5, 240, 80, tocolor(95, 120, 80))

			dxDrawText("Címkézett csomagok\n" .. getElementData(resourceRoot, "donePackages") .. " db", 0, 0, 250, 90, tocolor(37, 40, 12), 1, ocr10bold, "center", "center")
			dxDrawRectangle(10, 28, 230, 2, tocolor(37, 40, 12))
			dxDrawRectangle(10, 62, 230, 2, tocolor(37, 40, 12))

			dxSetRenderTarget()
		end
	end
end

function updateDynamicDatas()
	if isElementWithinColShape(localPlayer, jobColshape) then
		refreshClockRT()
		updateQuantity()
		createCrateLabelingShapes()
	end
end
addEventHandler("onClientRestore", getRootElement(), updateDynamicDatas)

function renderInsideFactory()
	if isElement(clockRT) then
		dxDrawMaterialLine3D(2801.5708203125, -2455.7221679688, 18.857726669312, 2801.5708203125, -2455.7221679688, 17.657726669312, clockRT, 2.4, -1, 2800.5708203125, -2455.7221679688, 18.857726669312)
	end

	if isElement(quantityRT) then
		dxDrawMaterialLine3D(2767.2199707026, -2511.5356835938, 16.78900680542, 2767.2199707026, -2511.5356835938, 15.58900680542, quantityRT, 3.3333333333333, -1, 2767.2199706907, -2510.5356835938, 16.78900680542)
	end

	if isElementWithinColShape(localPlayer, factoryColshape) then
		if jobStarted then
			local currentTick = getTickCount()
			local animationOffset = getEasingValue(currentTick * 0.001, "SineCurve") * 0.0235

			for _, objectElement in pairs(jobData.cratesPlaced) do
				if jobData.cratesOnShelf[objectElement] then
					local objectX, objectY, objectZ = getElementPosition(objectElement)
					objectZ = objectZ + 0.85
				
					dxDrawMaterialLine3D(objectX, objectY, objectZ + selectionSize / 2 + animationOffset, objectX, objectY, objectZ - selectionSize / 2 + animationOffset, selection, selectionSize, tocolor(115, 200, 85))
				end
			end
		end
	end

	for i = 1, #workbenchPositions do
		local position = workbenchPositions[i]

		if position and isElement(position[8]) then
			dxDrawMaterialLine3D(position[1] + position[4] / 2, position[2], position[3] + 0.0375, position[1] + position[4] / 2, position[2] + position[5], position[3] + 0.0375, position[8], position[4], position[9], position[1] + position[4] / 2, position[2] + position[5] / 2, position[3] + 10)
		end
	end

	if isElement(crateFinalPosition[8]) then
		dxDrawMaterialLine3D(crateFinalPosition[1] + crateFinalPosition[4] / 2, crateFinalPosition[2], crateFinalPosition[3] + 0.0375, crateFinalPosition[1] + crateFinalPosition[4] / 2, crateFinalPosition[2] + crateFinalPosition[5], crateFinalPosition[3] + 0.0375, crateFinalPosition[8], crateFinalPosition[4], crateFinalPosition[9], crateFinalPosition[1] + crateFinalPosition[4] / 2, crateFinalPosition[2] + crateFinalPosition[5] / 2, crateFinalPosition[3] + 10)
	end

	if jobStarted and isElementWithinColShape(localPlayer, labelingColshape) then
		local sx = respc(512)
		local sy = respc(512)
		local x = screenX - respc(447)
		local y = (screenY - sy) / 2

		dxDrawImage(x, y, sx, sy, "files/notes.png")

		sx = respc(277)
		sy = resp(21)
		x = x + respc(128)
		y = y + resp(70)

		if jobData and jobData.crateDatas then
			for i = 1, #jobData.crateDatas do
				local y2 = y + sy * (i - 1)
				
				dxDrawText(jobData.crateDatas[i].storageNumber .. " - " .. jobData.crateDatas[i].customerName, x, y2, 0, y2 + sy, tocolor(0, 84, 166), 0.5, handFont, "left", "center")
			
				if jobData.crateDatas[i].startErase then
					local progress = (getTickCount() - jobData.crateDatas[i].startErase) / 750

					dxDrawLine(x - 2, y2 + respc(9.25), x + interpolateBetween(0, 0, 0, dxGetTextWidth(jobData.crateDatas[i].storageNumber .. " - " .. jobData.crateDatas[i].customerName, 0.5, handFont), 0, 0, progress, "Linear") + 2, y2 + respc(9.25), tocolor(0, 84, 166), 2.5)
				
					if progress >= 1 then
						jobData.crateDatas[i].done = true
						jobData.crateDatas[i].startErase = nil
					end
				end

				if jobData.crateDatas[i].done then
					dxDrawLine(x - 2, y2 + respc(9.25), x + dxGetTextWidth(jobData.crateDatas[i].storageNumber .. " - " .. jobData.crateDatas[i].customerName, 0.5, handFont) + 2, y2 + respc(9.25), tocolor(0, 84, 166), 2.5)
				end
			end
		end

		if jobData.carryingCrate then
			if jobData.carryingCrate.canPlace then
				dxDrawText("A tárgy lerakásához nyomd meg az [E] gombot.", 1, screenY - respc(256) + 1, screenX + 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy lerakásához nyomd meg az [E] gombot.", -1, screenY - respc(256) - 1, screenX - 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy lerakásához nyomd meg az [E] gombot.", -1, screenY - respc(256) + 1, screenX - 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy lerakásához nyomd meg az [E] gombot.", 1, screenY - respc(256) - 1, screenX + 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy lerakásához nyomd meg az #32b3ef[E]#ffffff gombot.", 0, screenY - respc(256), screenX, screenY - respc(224), tocolor(255, 255, 255), 1, RobotoLabel, "center", "center", false, false, false, true)
			elseif not showSticker then
				dxDrawText("A tárgy felcímkézéséhez nyomd meg az [E] gombot.", 1, screenY - respc(256) + 1, screenX + 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy felcímkézéséhez nyomd meg az [E] gombot.", -1, screenY - respc(256) - 1, screenX - 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy felcímkézéséhez nyomd meg az [E] gombot.", -1, screenY - respc(256) + 1, screenX - 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy felcímkézéséhez nyomd meg az [E] gombot.", 1, screenY - respc(256) - 1, screenX + 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
				dxDrawText("A tárgy felcímkézéséhez nyomd meg az #32b3ef[E]#ffffff gombot.", 0, screenY - respc(256), screenX, screenY - respc(224), tocolor(255, 255, 255), 1, RobotoLabel, "center", "center", false, false, false, true)
			else
				sx = respc(822)
				sy = respc(417)
				x = (screenX - sx) / 2
				y = (screenY - sy) / 2

				dxDrawImage(x, y, sx, sy, "files/sticker.png")

				local info = jobData.carryingCrate

				dxDrawText(info.barCode, x + respc(41), y + respc(50), x + respc(221), y + respc(66), tocolor(0, 0, 0), 1, barCode, "center", "center")
				
				local textWidth = respc(521) / dxGetTextWidth(info.zipCode .. ", " .. info.address, 0.75, CourierNew)
				local textScale = 0.75

				if 1 - textWidth > 0 then
					textScale = 0.75 - textWidth * (0.75 - 0.6)
				end

				dxDrawText(info.zipCode .. ", " .. info.address, x + respc(41), y + respc(86), x + respc(562), y + respc(140), tocolor(0, 0, 0), textScale, 0.75, CourierNew, "center", "center")
			
				dxDrawText("\"HOME\" TÁROLÓDOBOZ | 1 DARAB", x + respc(41), y + respc(171), x + respc(562), y + respc(210), tocolor(0, 0, 0), 0.75, CourierNew, "center", "center")

				dxDrawText(info.storageNumber, x + respc(486), y + respc(144), x + respc(608), y + respc(225), tocolor(0, 0, 0), 1, RobotoBoldR, "center", "center", false, false, false, false, false, 9)
			
				dxDrawText(info.deliveryBarCode, x + respc(623), y + respc(377), x + respc(792), y + respc(393), tocolor(0, 0, 0), 1, barCode, "center", "center")

				dxDrawText(fakeInputs["customerName"], x + respc(74), y + respc(276), x + respc(589), y + respc(301), tocolor(0, 84, 166), 0.75, handFont, "left", "center", true)
				dxDrawText(fakeInputs["deliveryAddress"], x + respc(74), y + respc(311), x + respc(589), y + respc(336), tocolor(0, 84, 166), 0.75, handFont, "left", "center", true)
				dxDrawText(fakeInputs["zipCode"], x + respc(154), y + respc(345), x + respc(590), y + respc(370), tocolor(0, 84, 166), 0.75, handFont, "left", "center", true)

				local cx, cy = getCursorPosition()
				if tonumber(cx) and tonumber(cy) then
					cx, cy = cx * screenX, cy * screenY

					if getKeyState("mouse1") then
						activeFakeInput = false

						if cx >= x + respc(74) and cy >= y + respc(276) and cx <= x + respc(589) and cy <= y + respc(301) then
							activeFakeInput = "customerName"
						elseif cx >= x + respc(74) and cy >= y + respc(311) and cx <= x + respc(589) and cy <= y + respc(336) then
							activeFakeInput = "deliveryAddress"
						elseif cx >= x + respc(154) and cy >= y + respc(345) and cx <= x + respc(590) and cy <= y + respc(370) then
							activeFakeInput = "zipCode"
						end
					end
				else
					activeFakeInput = false
				end

				if signStart then
					local progress = (getTickCount() - signStart) / 3579
					local playerName = getElementData(localPlayer, "visibleName"):gsub("_", " ")

					dxDrawText(playerName, x + respc(594.95), y + respc(27.55), x + respc(594.95) + interpolateBetween(0, 0, 0, dxGetTextWidth(playerName, 1, lunabar), 0, 0, progress, "Linear"), y + respc(86.49), tocolor(22, 53, 98), 1, lunabar, "left", "center", true)
				
					if progress > 1.25 then
						removeEventHandler("onClientCharacter", getRootElement(), onClientCharacter)
						removeEventHandler("onClientKey", getRootElement(), onClientKey)

						showCursor(false)
						showSticker = false
						activeFakeInput = false
						jobData.carryingCrate.canPlace = true

						setElementFrozen(localPlayer, false)

						for i = 1, #jobData.crateDatas do
							if jobData.crateDatas[i].storageNumber == info.storageNumber then
								applyStorageNumberToCrate(syncableCarryingCrates[localPlayer], info.storageNumber, true)
								jobData.crateDatas[i].startErase = getTickCount()
								break
							end
						end

						fakeInputs.customerName = ""
						fakeInputs.deliveryAddress = ""
						fakeInputs.zipCode = ""

						signStart = false

						exports.sarp_hud:showAlert("info", "Címkézés kész!", "Vidd a ládát a sárgán jelölt helyre.")
					end
				end
			end
		elseif syncableCarriers[localPlayer] and isElementAttached(syncableCarriers[localPlayer]) then
			dxDrawText("Az emelő lerakásához nyomd meg az [E] gombot.", 1, screenY - respc(256) + 1, screenX + 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
			dxDrawText("Az emelő lerakásához nyomd meg az [E] gombot.", -1, screenY - respc(256) - 1, screenX - 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
			dxDrawText("Az emelő lerakásához nyomd meg az [E] gombot.", -1, screenY - respc(256) + 1, screenX - 1, screenY - respc(224) + 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
			dxDrawText("Az emelő lerakásához nyomd meg az [E] gombot.", 1, screenY - respc(256) - 1, screenX + 1, screenY - respc(224) - 1, tocolor(0, 0, 0), 1, RobotoLabel, "center", "center")
			dxDrawText("Az emelő lerakásához nyomd meg az #32b3ef[E]#ffffff gombot.", 0, screenY - respc(256), screenX, screenY - respc(224), tocolor(255, 255, 255), 1, RobotoLabel, "center", "center", false, false, false, true)
		end
	end
end

addEventHandler("onClientRender", getRootElement(),
	function ()
		dxDrawMaterialLine3D(2745.4055175811, -2451.8471875, 15, 2745.4055175811, -2451.8471875, 14.5, sign1, 2, -1, 2745.4055177321, -2450.8471875, 15)
		dxDrawMaterialLine3D(2773.911640625, -2455.72265625, 18.609192301432, 2773.911640625, -2455.72265625, 17.755858968099, sign2, 3.4133333333333, -1, 2772.911640625, -2455.72265625, 18.609192301432)
		dxDrawMaterialLine3D(2776.2202148433, -2511.2820214844, 18.725061823527, 2776.2202148433, -2511.2820214844, 17.871728490194, sign3, 3.4133333333333, -1, 2776.2202148313, -2510.2820214844, 18.725061823527)
	end
)

bindKey("e", "down",
	function ()
		if jobStarted and not showSticker then
			if isElementWithinColShape(localPlayer, labelingColshape) then
				if syncableCarriers[localPlayer] and isElementAttached(syncableCarriers[localPlayer]) and canPlaceObject(syncableCarriers[localPlayer]) then
					local carrierX, carrierY, carrierZ = getElementPosition(syncableCarriers[localPlayer])
					local _, _, carrierRotation = getElementRotation(syncableCarriers[localPlayer])

					setElementData(localPlayer, "carrierPlacedOnFactory", {carrierX, carrierY, carrierZ, carrierRotation})

					exports.sarp_controls:toggleControl({"jump", "aim_weapon", "fire", "enter_exit", "crouch", "sprint"}, true)
				elseif jobData.carryingCrate then
					if jobData.carryingCrate.canPlace then
						if isElementWithinColShape(localPlayer, crateFinalPosition[7]) then
							local storageNumber = jobData.carryingCrate.storageNumber
							jobData.carryingCrate = false

							triggerServerEvent("cratePutDownAnimation", localPlayer, true)
							exports.sarp_controls:toggleControl({"jump", "aim_weapon", "fire", "enter_exit", "crouch", "sprint"}, true)

							setTimer(
								function ()
									local playerX, playerY, playerZ = getElementPosition(localPlayer)
									local _, _, playerRotation = getElementRotation(localPlayer)

									playerX = playerX + math.cos(math.rad(playerRotation + 90)) * 0.75
									playerY = playerY + math.sin(math.rad(playerRotation + 90)) * 0.75

									local groundLevel = getGroundPosition(playerX, playerY, playerZ)

									local crateObject = createObject(2912, playerX, playerY, groundLevel, 0, 0, playerRotation + 180)

									setElementFrozen(crateObject, true)
									setObjectBreakable(crateObject, false)

									table.insert(jobData.cratesDone, crateObject)

									applyStorageNumberToCrate(crateObject, storageNumber, true)

									setElementData(localPlayer, "carryingCrate", false)

									if #jobData.cratesDone == #jobData.crateDatas then
										endJob(true)
									end
								end,
							750, 1)
						else
							exports.sarp_hud:showAlert("error", "Itt nem rakhatod le, menj a sárgával kijelölt helyre!")
						end
					else
						local workbench = false

						for i = 1, #workbenchPositions do
							if isElement(workbenchPositions[i][7]) and isElementWithinColShape(localPlayer, workbenchPositions[i][7]) then
								workbench = i
								break
							end
						end

						if not workbench then
							exports.sarp_hud:showAlert("error", "Itt nem címkézheted fel, menj egy asztalhoz!")
						else
							local playerX, playerY, playerZ = getElementPosition(localPlayer)
							local offsetX, offsetY, offsetZ = getPositionFromElementOffset(getElementMatrix(localPlayer), 0, 1.5, -0.25)

							local hit, _, _, _, hitElement = processLineOfSight(playerX, playerY, playerZ, offsetX, offsetY, offsetZ, false, false, false, true, false)
							if hit and hitElement and getElementModel(hitElement) == 941 then
								setElementFrozen(localPlayer, true)
								showCursor(true)
								showSticker = true

								addEventHandler("onClientCharacter", getRootElement(), onClientCharacter, true, "low-99999")
								addEventHandler("onClientKey", getRootElement(), onClientKey, true, "low-99999")
							else
								exports.sarp_hud:showAlert("error", "Fordulj szembe az asztallal, vagy állj közelebb!")
							end
						end
					end
				end
			end
		end
	end
)

function onClientCharacter(character)
	if activeFakeInput and not signStart then
		if utfLen(fakeInputs[activeFakeInput]) <= 40 then
			local onlyNumber = false

			if activeFakeInput == "zipCode" then
				onlyNumber = true
			end

			if (onlyNumber and tonumber(character)) or not onlyNumber then
				fakeInputs[activeFakeInput] = fakeInputs[activeFakeInput] .. character
			end
		end
	end
end

function onClientKey(key, press)
	if not signStart then
		cancelEvent()

		if key == "enter" and press then
			if fakeInputs["customerName"] == jobData.carryingCrate.customerName then
				if fakeInputs["deliveryAddress"] == jobData.carryingCrate.address then
					if tonumber(fakeInputs["zipCode"]) == jobData.carryingCrate.zipCode then
						signStart = getTickCount()
						playSound("files/sign.mp3")
					else
						exports.sarp_hud:showAlert("error", "Az irányítószám nem megfelelő!")
					end
				else
					exports.sarp_hud:showAlert("error", "A megrendelő címe nem megfelelő!")
				end
			else
				exports.sarp_hud:showAlert("error", "A megrendelő név nem megfelelő!")
			end
		elseif key == "backspace" and press and activeFakeInput then
			fakeInputs[activeFakeInput] = fakeInputs[activeFakeInput]:sub(1, -2)
		end
	end
end

function unloadFactoryShelfs()
	for k,v in pairs(jobCreatedObjects) do
		if isElement(v) then
			destroyElement(v)
		end
	end

	jobCreatedObjects = {}
	shelfBoxPoses = {}

	for i = 1, #workbenchPositions do
		local position = workbenchPositions[i]

		if isElement(position[7]) then
			destroyElement(position[7])
		end

		if isElement(position[8]) then
			destroyElement(position[8])
		end

		workbenchPositions[i][7] = nil
		workbenchPositions[i][8] = nil
	end

	if isElement(crateFinalPosition[7]) then
		destroyElement(crateFinalPosition[7])
	end

	if isElement(crateFinalPosition[8]) then
		destroyElement(crateFinalPosition[8])
	end

	crateFinalPosition[7] = nil
	crateFinalPosition[8] = nil
end

function generateFactoryShelfs()
	unloadFactoryShelfs()

	if isElementWithinColShape(localPlayer, jobColshape) then
		for i = 1, #shelfPositions do
			local shelf = shelfPositions[i]

			local shelfObject = createObject(3761, shelf[1], shelf[2], shelf[3], 0, 0, shelf[4])

			for j = 1, 15 do
				local x, y = rotateAround(shelfPositions[i][4], j % 5, 0)
				local z = j > 10 and 2.2 or j > 5 and 1.01 or 0

				x, y, z = shelf[1] + x, shelf[2] - 1.85 + y, shelf[3] - 1.575 + z

				if math.random(100) <= 50 then
					local randomModel = randomShelfBoxModels[math.random(1, #randomShelfBoxModels)]

					if randomModel == 2968 then
						z = z - 0.025
					end

					local boxObject = createObject(randomModel, x, y, z + 0.325, 0, 0, math.random(0, 360))
					setElementFrozen(boxObject, true)
					setObjectBreakable(boxObject, false)

					table.insert(jobCreatedObjects, boxObject)
				else
					table.insert(shelfBoxPoses, {x, y, z})
				end
			end

			table.insert(jobCreatedObjects, shelfObject)
		end

		createCrateLabelingShapes()
	end
end

function createCrateLabelingShapes()
	for i = 1, #workbenchPositions do
		local position = workbenchPositions[i]

		if isElement(position[7]) then
			destroyElement(position[7])
		end

		if isElement(position[8]) then
			destroyElement(position[8])
		end

		workbenchPositions[i][7] = nil
		workbenchPositions[i][8] = nil
	end

	if isElement(crateFinalPosition[7]) then
		destroyElement(crateFinalPosition[7])
	end

	if isElement(crateFinalPosition[8]) then
		destroyElement(crateFinalPosition[8])
	end

	crateFinalPosition[7] = nil
	crateFinalPosition[8] = nil

	for i = 1, #workbenchPositions do
		local position = workbenchPositions[i]

		local tempRT = dxCreateRenderTarget(position[4] * 48, position[5] * 48, true)
		if isElement(tempRT) then
			workbenchPositions[i][8] = tempRT
			workbenchPositions[i][9] = tocolor(255, 255, 255)

			dxSetRenderTarget(tempRT)

			for x = 0, position[4] * 2 do
				for y = 0, position[5] * 2 do
					dxDrawImage(x * 24, y * 24, 24, 24, "files/stripe.png")
				end
			end

			dxDrawRectangle(0, 0, 8, position[5] * 48, tocolor(255, 255, 255))
			dxDrawRectangle(position[4] * 48 - 8, 0, 8, position[5] * 48, tocolor(255, 255, 255))
			dxDrawRectangle(0, 0, position[4] * 48, 8, tocolor(255, 255, 255))
			dxDrawRectangle(0, position[5] * 48 - 8, position[4] * 48, 8, tocolor(255, 255, 255))

			dxSetRenderTarget()
		end

		workbenchPositions[i][7] = createColCuboid(unpack(position))
	end

	local tempRT = dxCreateRenderTarget(crateFinalPosition[4] * 48, crateFinalPosition[5] * 48, true)
	if isElement(tempRT) then
		crateFinalPosition[8] = tempRT
		crateFinalPosition[9] = tocolor(215, 175, 89)

		dxSetRenderTarget(tempRT)

		for x = 0, crateFinalPosition[4] * 2 do
			for y = 0, crateFinalPosition[5] * 2 do
				dxDrawImage(x * 24, y * 24, 24, 24, "files/stripe.png")
			end
		end

		dxDrawRectangle(0, 0, 8, crateFinalPosition[5] * 48, tocolor(255, 255, 255))
		dxDrawRectangle(crateFinalPosition[4] * 48 - 8, 0, 8, crateFinalPosition[5] * 48, tocolor(255, 255, 255))
		dxDrawRectangle(0, 0, crateFinalPosition[4] * 48, 8, tocolor(255, 255, 255))
		dxDrawRectangle(0, crateFinalPosition[5] * 48 - 8, crateFinalPosition[4] * 48, 8, tocolor(255, 255, 255))

		dxSetRenderTarget()
	end

	crateFinalPosition[7] = createColCuboid(unpack(crateFinalPosition))
end

function canPlaceObject(objectElement)
	if isElement(objectElement) then
		local objectX, objectY, objectZ = getElementPosition(objectElement)
		local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(objectElement)
		local objectMatrix = getElementMatrix(objectElement)

		for i = 0, 1 do
			local z = minZ + maxZ * i

			local offX, offY, offZ = getPositionFromElementOffset(objectMatrix, minX, minY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end

			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, maxX, minY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end

			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, minX, maxY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end
			
			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, maxX, maxY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end

			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, minX, 0, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end
			
			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, maxX, 0, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end

			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, 0, minY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end
			
			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, 0, maxY, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end
			
			offX, offY, offZ = getPositionFromElementOffset(objectMatrix, 0, 0, z)
			if not isLineOfSightClear(objectX, objectY, objectZ, offX, offY, offZ, true, true, false, true, true, false, false, localPlayer) then
				exports.sarp_hud:showAlert("error", "Ide nem rakhatod le, mert valamivel ütközik a tárgy!")
				return
			end
		end

		return true
	end

	return false
end

function getCurrentInteractionList(model)
	if model == carrierModel then
		return currentInteractions.carrier
	else
		return currentInteractions.crate
	end
end

function rotateAround(angle, x, y)
	angle = math.rad(angle)

	local cosX = math.cos(angle)
	local sinY = math.sin(angle)

	return x * cosX - y * sinY, x * sinY + y * cosX
end

function getPositionFromElementOffset(matrix, x, y, z)
	local offsetX = x * matrix[1][1] + y * matrix[2][1] + z * matrix[3][1] + matrix[4][1]
	local offsetY = x * matrix[1][2] + y * matrix[2][2] + z * matrix[3][2] + matrix[4][2]
	local offsetZ = x * matrix[1][3] + y * matrix[2][3] + z * matrix[3][3] + matrix[4][3]
	
	return offsetX, offsetY, offsetZ
end

function removeGTAObjects()
	-- ** Első raktár
	removeWorldModel(3624, 2.5, 2788.15625, -2417.7890625, 16.7265625)
	removeWorldModel(3710, 2.5, 2788.15625, -2417.7890625, 16.7265625)
	removeWorldModel(3761, 75, 2783.78125, -2410.2109375, 14.671875) -- polcok

	-- ** Második raktár
	--removeWorldModel(3624, 2.5, 2788.15625, -2455.8828125, 16.7265625)
	--removeWorldModel(3710, 2.5, 2788.15625, -2455.8828125, 16.7265625)

	-- ** Harmadik raktár
	removeWorldModel(3624, 2.5, 2788.15625, -2493.984375, 16.7265625)
	removeWorldModel(3710, 2.5, 2788.15625, -2493.984375, 16.7265625)
	removeWorldModel(3761, 75, 2783.78125, -2486.9609375, 14.65625) -- polcok

	removeWorldModel(3577, 15, 2744.5703125, -2436.1875, 13.34375)

	-- ** Konténerek
	removeWorldModel(3574, 20, 2771.0703125, -2520.546875, 15.21875)
	removeWorldModel(3744, 20, 2771.0703125, -2520.546875, 15.21875)

	createObject(3624, 2776.0703125, -2525.546875, 16.7265625, 0, 0, 270) -- Címkéző részleg

	createObject(941, 2783.5412597656, -2520.7065429688, 13.106855392456, 0, 0, 0)
	createObject(941, 2781.1291503906, -2520.7021484375, 13.107444763184, 0, 0, 0)
	createObject(941, 2783.5454101563, -2521.9431152344, 13.106854438782, 0, 0, 0)
	createObject(941, 2781.1257324219, -2521.9345703125, 13.107445716858, 0, 0, 0)

	createObject(941, 2766.8732910156, -2523.0856933594, 13.115160942078, 0, 0, 0)
	createObject(941, 2769.2653808594, -2523.09375, 13.115159034729, 0, 0, 0)
	createObject(941, 2766.8823242188, -2524.3215332031, 13.114859580994, 0, 0, 0)
	createObject(941, 2769.2561035156, -2524.3166503906, 13.114859580994, 0, 0, 0)

	createObject(941, 2769.1206054688, -2516.7416992188, 13.116709709167, 0, 0, 90)
	createObject(941, 2767.8991699219, -2516.7475585938, 13.116708755493, 0, 0, 90)

	createObject(941, 2783.8037109375, -2529.7575683594, 13.102269172668, 0, 0, 270)
	createObject(941, 2782.5778808594, -2529.7541503906, 13.102270126343, 0, 0, 270)
end