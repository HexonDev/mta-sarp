pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

local screenX, screenY = guiGetScreenSize()

local panelState = false

local panelWidth = (defaultSettings.slotBoxWidth + 5) * defaultSettings.width + 5 + 10
local panelHeight = (defaultSettings.slotBoxHeight + 5) * math.floor(defaultSettings.slotLimit / defaultSettings.width) + 5

local panelPosX = screenX / 2
local panelPosY = screenY / 2

local moveDifferenceX, moveDifferenceY = 0, 0
local panelIsMoving = false

local sizeForTabs = panelWidth / 3

local Roboto = dxCreateFont("files/fonts/Roboto.ttf", 22, false, "antialiased")
local RobotoL = dxCreateFont("files/fonts/RobotoL.ttf", 12, false, "antialiased")
local Roboto2 = dxCreateFont("files/fonts/Roboto.ttf", 18, false, "antialiased")

local stackAmount = 0

itemsTable = {}
itemsTable.player = {}
itemsTable.vehicle = {}
itemsTable.object = {}
itemsTableState = "player"
currentInventoryElement = localPlayer

local haveMoving = false

local movedslotId = false
local lastslotId = false

local currentCategory = "main"
local categoryHover = false
local tabLineInterpolation = false
local lastCategory = currentCategory

local absX = -1
local absY = -1

local lastWeightSize = 0
local gotWeightInterpolation = false

local itemPictures = {}
local grayItemPictures = {}
local perishableTimer = false

local itemListState = false
local itemListWidth = screenX / 2
local itemListHeight = 30 + defaultSettings.slotBoxHeight * 12 + 30 + 5
local itemListPosX = screenX / 2 - itemListWidth / 2
local itemListPosY = screenY / 2 - itemListHeight / 2
local itemListOffset = 0
local itemListItems = false

local friskPanelState = false
local friskPanelWidth = (defaultSettings.slotBoxWidth + 5) * defaultSettings.width + 5
local friskPanelHeight = (defaultSettings.slotBoxHeight + 5) * math.floor(defaultSettings.slotLimit / defaultSettings.width) + 5
local friskPanelPosX = screenX / 3
local friskPanelPosY = screenY / 3
local friskTableState = false

local friskCategory = "main"
local friskCategoryHover = false
local friskCatInterpolate = false
local friskLastCategory = friskCategory
local friskPanelIsMoving = false

local hoverShowItem = false
local lastShowItemTick = 0

local lastSpecialItemUsage = 0

local drunkenLevel = 0
local drunkHandled = false
local drunkenScreenSource = false
local fuckControlsDisabledControl = false
local fuckControlsChangeTick = 0
local drunkenScreenFlickeringState = false

local rottenEffect = false

local storedTrashes = {}

local vehicleTickets = {}
local hoverTicket = false

local myCharacterId = false

local itemsLoaded = false

addEventHandler("onClientClick", getRootElement(),
	function (button, state)
		if state == "up" and hoverTicket and itemsLoaded then
			if myCharacterId == hoverTicket[2].ownerId then
				triggerServerEvent("requestVehicleTicket", localPlayer, hoverTicket[1], hoverTicket[2].data)

				exports.sarp_chat:sendLocalMeAction(localPlayer, "elvesz egy bírságot a járműről.")
			else
				exports.sarp_hud:showAlert("error", "A jármű nem a Te tulajdonod ezért a csekket sem tudod elvenni!")
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local cameraPosX, cameraPosY, cameraPosZ = getCameraMatrix()
		local playerDimension = getElementDimension(localPlayer)
		local cursorX, cursorY = getCursorPosition()

		if cursorX then
			cursorX, cursorY = cursorX * screenX, cursorY * screenY
		else
			cursorX, cursorY = -1, -1
		end

		hoverTicket = false

		for k, v in pairs(vehicleTickets) do
			if isElement(k) and isElement(v.thePicture) then
				local vehicleDimension = getElementDimension(k)

				if vehicleDimension == playerDimension then
					local vehiclePosX, vehiclePosY, vehiclePosZ = getVehicleComponentPosition(k, "windscreen_dummy", "world")

					if not vehiclePosX then
						vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(k)
					end

					if isLineOfSightClear(cameraPosX, cameraPosY, cameraPosZ, vehiclePosX, vehiclePosY, vehiclePosZ, true, false, false, true, false, false) then
						local screenPosX, screenPosY = getScreenFromWorldPosition(vehiclePosX, vehiclePosY, vehiclePosZ)

						if screenPosX and screenPosY then
							local distance = getDistanceBetweenPoints3D(cameraPosX, cameraPosY, cameraPosZ, vehiclePosX, vehiclePosY, vehiclePosZ)

							if distance <= 8 then
								local scaleFactor = 1 - distance / 16

								local sx = 256 * 0.25 * scaleFactor
								local sy = 512 * 0.25 * scaleFactor

								local x = screenPosX - sx / 2
								local y = screenPosY - sy / 2

								if cursorX >= x and cursorX <= x + sx and cursorY >= y and cursorY <= y + sy then
									sx = 256 * scaleFactor
									sy = 512 * scaleFactor

									hoverTicket = {k, v}
								end

								dxDrawRectangle(x - 5, y - 5, sx + 10, sy + 10, tocolor(0, 0, 0, 160))
								dxDrawImage(x, y, sx, sy, v.thePicture)
							end
						end
					end
				end
			else
				vehicleTickets[k] = nil
			end
		end
	end
)

function render3DTicket(sourceVehicle, data)
	if vehicleTickets[sourceVehicle] and isElement(vehicleTickets[sourceVehicle].thePicture) then
		destroyElement(vehicleTickets[sourceVehicle].thePicture)
	end

	data = fromJSON(data)

	if not data or type(data) ~= "table" or data and not data.date or not data.fine or not data.numberplate or not data.type or not data.location or not data.reason or not data.agency then
		vehicleTickets[sourceVehicle] = nil
		setElementData(sourceVehicle, "vehicleTicket", false)
		return
	end

	vehicleTickets[sourceVehicle] = {}
	vehicleTickets[sourceVehicle].ownerId = getElementData(sourceVehicle, "vehicle.owner") or 0
	vehicleTickets[sourceVehicle].data = data

	local renderTarget = dxCreateRenderTarget(256, 512)
	local handFont = dxCreateFont(":sarp_assets/fonts/hand.otf", 24, false, "antialiased")
	local lunabar = dxCreateFont(":sarp_assets/fonts/lunabar.ttf", 16, false, "antialiased")
	local scaleFactor = 0.7

	dxSetRenderTarget(renderTarget)

	dxDrawImage(0, 0, 256, 512, ":sarp_ticket/files/parking.png")

	dxDrawText(data["date"], 16 * scaleFactor, 145 * scaleFactor, 170 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["fine"] .. "$", 186 * scaleFactor, 145 * scaleFactor, 167 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["numberplate"], 16 * scaleFactor, 195 * scaleFactor, 337 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["type"], 16 * scaleFactor, 249 * scaleFactor, 337 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["location"], 16 * scaleFactor, 303 * scaleFactor, 337 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["reason"], 16 * scaleFactor, 357 * scaleFactor, 337 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)
	dxDrawText(data["agency"], 16 * scaleFactor, 409 * scaleFactor, 337 * scaleFactor, 49 * scaleFactor, tocolor(0, 84, 166), 0.6, handFont)

	if data["officer"] then
		dxDrawText(data["officer"], 188 * scaleFactor, 512 - 49 * scaleFactor - 10 * scaleFactor, 188 * scaleFactor + 152 * scaleFactor, 512 - 49 * scaleFactor - 30 * scaleFactor + 49 * scaleFactor, tocolor(0, 84, 166), 1, lunabar, "center", "center")
	end

	dxSetRenderTarget()

	if isElement(handFont) then
		destroyElement(handFont)
	end

	if isElement(lunabar) then
		destroyElement(lunabar)
	end

	if isElement(renderTarget) then
		local pixels = dxGetTexturePixels(renderTarget)

		pixels = dxConvertPixels(pixels, "png")

		destroyElement(renderTarget)

		vehicleTickets[sourceVehicle].thePicture = dxCreateTexture(pixels, "dxt3")
	end

	return false
end

addEventHandler("onClientRestore", getRootElement(),
	function ()
		for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
			local theTicket = getElementData(v, "vehicleTicket")

			if theTicket then
				render3DTicket(v, theTicket)
			elseif vehicleTickets[v] then
				if isElement(vehicleTickets[v].thePicture) then
					destroyElement(vehicleTickets[v].thePicture)
				end

				vehicleTickets[v] = nil
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		setTimer(triggerServerEvent, 5000, 1, "requestTrashes", localPlayer)

		if getElementData(localPlayer, "loggedIn") then
			setTimer(triggerServerEvent, 5000, 1, "requestCache", localPlayer)

			if isTimer(perishableTimer) then
				killTimer(perishableTimer)
			end
			
			perishableTimer = setTimer(processPerishableItems, 60000, 0)
		end

		for k, v in pairs(availableItems) do
			if fileExists("files/items/" .. k .. ".png") then
				itemPictures[k] =  dxCreateTexture("files/items/" .. k .. ".png")
			else
				itemPictures[k] =  dxCreateTexture("files/noitempic.png")
			end
		end

		for k, v in pairs(perishableItems) do
			if itemPictures[k] then
				grayItemPictures[k] = dxCreateShader("files/blackwhite.fx")

				dxSetShaderValue(grayItemPictures[k], "screenSource", itemPictures[k])
			end
		end

		setElementData(localPlayer, "canUseMegaphone", false)

		setTimer(
			function()
				toggleControl("next_weapon", false)
				toggleControl("previous_weapon", false)
			end,
		1000, 0)

		bindKey("r", "down", "reloadmyweapon")

		for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
			local theTicket = getElementData(v, "vehicleTicket")

			if theTicket then
				render3DTicket(v, theTicket)
			end
		end

		myCharacterId = getElementData(localPlayer, "char.ID")
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" then
			local theTicket = getElementData(source, "vehicleTicket")

			if theTicket then
				render3DTicket(source, theTicket)
			end
		end
	end
)

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if vehicleTickets[source] then
			if isElement(vehicleTickets[source].thePicture) then
				destroyElement(vehicleTickets[source].thePicture)
			end

			vehicleTickets[source] = nil
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if source == localPlayer then
			if dataName == "loggedIn" and getElementData(source, dataName) then
				if isTimer(perishableTimer) then
					killTimer(perishableTimer)
				end

				perishableTimer = setTimer(processPerishableItems, 60000, 0)

				myCharacterId = getElementData(localPlayer, "char.ID")
			end
		elseif dataName == "vehicleTicket" then
			local theTicket = getElementData(source, "vehicleTicket")

			if theTicket then
				if isElementStreamedIn(source) then
					render3DTicket(source, theTicket)
				end
			elseif vehicleTickets[source] then
				if isElement(vehicleTickets[source].thePicture) then
					destroyElement(vehicleTickets[source].thePicture)
				end

				vehicleTickets[source] = nil
			end
		end
	end
)

addCommandHandler("reloadmyweapon",
	function (commandName)
		if not isPedDead(localPlayer) and getPedTask(localPlayer, "secondary", 0) ~= "TASK_SIMPLE_USE_GUN" then
			if getElementData(localPlayer, "tazerReloadNeeded") then
				setElementData(localPlayer, "tazerReloadNeeded", false)
				exports.sarp_controls:toggleControl({"fire", "vehicle_fire", "action"}, true)
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("nearbytrashes", 1, "Közelben lévő szemetesek")
addCommandHandler("nearbytrashes",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			outputChatBox(exports.sarp_core:getServerTag("admin") .. "A közeledben lévő szemetesek:", 255, 255, 255, true)

			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local playerInterior = getElementInterior(localPlayer)
			local playerDimension = getElementDimension(localPlayer)
			local nearbyTrashes = 0

			for k, v in pairs(storedTrashes) do
				if playerInterior == v.interior and playerDimension == v.dimension then
					local objectPosX, objectPosY, objectPosZ = getElementPosition(v.objectElement)
					local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, objectPosX, objectPosY, objectPosZ)

					if distance <= 15 then
						outputChatBox("#ff4646>> #FFFFFFAzonosító: #ff4646" .. v.trashId .. "#FFFFFF <> Távolság: #ff4646" .. math.floor(distance), 255, 255, 255, true)
						nearbyTrashes = nearbyTrashes + 1
					end
				end
			end

			if nearbyTrashes == 0 then
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "A közeledben nem található egyetlen szemetes sem.", 255, 255, 255, true)
			end
		end
	end
)

addEvent("receiveTrashes", true)
addEventHandler("receiveTrashes", getRootElement(),
	function (array)
		if array and type(array) == "table" then
			storedTrashes = array
		end
	end
)

addEvent("createTrash", true)
addEventHandler("createTrash", getRootElement(),
	function (trashId, array)
		if trashId then
			trashId = tonumber(trashId)

			if array and type(array) == "table" then
				storedTrashes[trashId] = array
			end
		end
	end
)

addEvent("destroyTrash", true)
addEventHandler("destroyTrash", getRootElement(),
	function (trashId)
		if trashId then
			trashId = tonumber(trashId)

			if storedTrashes[trashId] then
				storedTrashes[trashId] = nil
			end
		end
	end
)

function addDrunkenLevel(amount)
	drunkenLevel = drunkenLevel + amount

	processDrunkRender()

	setTimer(removeDrunkenLevel, 30000, 1, 2, 30000)
end

function removeDrunkenLevel(amount, renderTime)
	drunkenLevel = drunkenLevel - amount
	
	if drunkenLevel < 0 then
		drunkenLevel = 0
	end

	processDrunkRender()

	if renderTime and drunkenLevel > 0 then
		setTimer(removeDrunkenLevel, renderTime, 1, 2, renderTime)
	end
end

function processDrunkRender()
	if drunkenLevel > 0 then
		if not drunkHandled then
			drunkHandled = true
			addEventHandler("onClientRender", getRootElement(), drunkenRender, true, "low-999")

			drunkenScreenSource = dxCreateScreenSource(screenX, screenY)
		end
	else
		if drunkHandled then
			drunkHandled = false
			removeEventHandler("onClientRender", getRootElement(), drunkenRender)

			if isElement(drunkenScreenSource) then
				destroyElement(drunkenScreenSource)
			end
		end

		if fuckControlsDisabledControl then
			setAnalogControlState("vehicle_left", 0)
     		setAnalogControlState("vehicle_right", 0)
     		exports.sarp_controls:toggleControl({"vehicle_left", "vehicle_right"}, true)
     		fuckControlsDisabledControl = false
		end
	end
end

function drunkenRender()
	if isElement(drunkenScreenSource) then
		dxUpdateScreenSource(drunkenScreenSource)
	end

	local currentTick = getTickCount()
	local elapsedTime = currentTick - fuckControlsChangeTick

	if elapsedTime >= 3000 then
		fuckControlsChangeTick = currentTick
		elapsedTime = 0
		drunkenScreenFlickeringState = not drunkenScreenFlickeringState

		if fuckControlsDisabledControl then
			setAnalogControlState("vehicle_left", 0)
     		setAnalogControlState("vehicle_right", 0)
     		exports.sarp_controls:toggleControl({"vehicle_left", "vehicle_right"}, true)
     		fuckControlsDisabledControl = false
		end

		if math.random(5) <= 3 then
			exports.sarp_controls:toggleControl({"vehicle_left", "vehicle_right"}, false)
			fuckControlsDisabledControl = true

			if math.random(10) <= 5 then
				setAnalogControlState("vehicle_left", 1)
			else
				setAnalogControlState("vehicle_right", 1)
			end
		end
	end

	local progress = elapsedTime / 3000
	local flickerOffsetX = 0
	local flickerOffsetY = 0

	if drunkenScreenFlickeringState then
		flickerOffsetX, flickerOffsetY = interpolateBetween(0, 0, 0, -drunkenLevel * 5, -drunkenLevel * 5, 0, progress, "OutQuad")
	else
		flickerOffsetX, flickerOffsetY = interpolateBetween(-drunkenLevel * 5, -drunkenLevel * 5, 0, 0, 0, 0, progress, "OutQuad")
	end

	if isElement(drunkenScreenSource) then
		dxDrawImage(0 - flickerOffsetX, 0 - flickerOffsetY, screenX, screenY, drunkenScreenSource, 0, 0, 0, tocolor(255, 255, 255, 200))
		dxDrawImage(0 + flickerOffsetX, 0 + flickerOffsetY, screenX, screenY, drunkenScreenSource, 0, 0, 0, tocolor(255, 255, 255, 200))
	end
end

addEventHandler("onClientPlayerWeaponSwitch", getRootElement(),
	function (previousWeaponSlot, currentWeaponSlot)
		if getPedWeapon(localPlayer, currentWeaponSlot) == 0 then
			deactivateWeapon()
		end
	end
)

function deactivateWeapon()
	local weaponInUse = false
	local ammoInUse = false

	for k, v in pairs(itemsTable.player) do
		if v.inUse then
			if isWeaponItem(v.itemId) and not weaponInUse then
				weaponInUse = weaponInUse or v
			elseif isAmmoItem(v.itemId) and not ammoInUse then
				ammoInUse = v
			end
		end
	end

	if weaponInUse then
		local slotId = weaponInUse.slot
		local itemId = itemsTable.player[slotId].itemId

		itemsTable.player[slotId].inUse = false

		triggerServerEvent("takeWeapon", localPlayer)

		if availableItems[itemId] then
			if itemId == 28 then
				exports.sarp_chat:sendLocalMeAction(localPlayer, "elrakott egy fényképezőgépet.")
			elseif itemId == 110 then
				if getElementData(localPlayer, "tazerReloadNeeded") then
					exports.sarp_controls:toggleControl({"fire", "vehicle_fire", "action"}, true)
					setElementData(localPlayer, "tazerReloadNeeded", false)
				end

				exports.sarp_chat:sendLocalMeAction(localPlayer, "elrakott egy sokkoló pisztolyt.")

				setElementData(localPlayer, "tazerState", false)
			else
				exports.sarp_chat:sendLocalMeAction(localPlayer, "elrakott egy fegyvert. (" .. getItemName(itemId) .. ")")

				triggerEvent("movedItemInInventory", localPlayer)
			end
		else
			exports.sarp_chat:sendLocalMeAction(localPlayer, "elrakott egy fegyvert.")
		end

		togglePlayerWeaponFire(true)

		if ammoInUse then
			itemsTable.player[ammoInUse.slot].inUse = false
		end
	end
end

function unuseItem(dbID)
	if dbID then
		dbID = tonumber(dbID)

		for k, v in pairs(itemsTable.player) do
			if v.dbID == dbID then
				itemsTable.player[v.slot].inUse = false
				break
			end
		end
	end
end

local lastDrugTick = 0

function useItem(itemDbId)
	if itemDbId then
		if (getElementData(localPlayer, "acc.adminJail") or 0) ~= 0 then
			return
		end

		if getElementData(localPlayer, "player.Cuffed") then
			exports.sarp_hud:showInfobox("error", "Bilincsben nem tudod használni az itemeket!")
			return
		end

		local slotId = false
		itemDbId = tonumber(itemDbId)

		for k, v in pairs(itemsTable.player) do
			if v.dbID == itemDbId then
				slotId = k
				break
			end
		end

		if itemsTable.player[slotId] and itemsTable.player[slotId].amount > 0 and itemsTable.player[slotId].itemId then
			local itemData = itemsTable.player[slotId]
			local itemId = tonumber(itemData.itemId)

			if isWeaponItem(itemId) or isAmmoItem(itemId) then
				local weaponInUse = false
				local ammoInUse = false

				for k, v in pairs(itemsTable.player) do
					if v.inUse then
						if isWeaponItem(v.itemId) and not weaponInUse then
							weaponInUse = v
						elseif isAmmoItem(v.itemId) and not ammoInUse then
							ammoInUse = v
						end
					end
				end

				if isWeaponItem(itemId) then
					if not weaponInUse then
						if getPedControlState("fire") then
							exports.sarp_hud:showInfobox("warning", "Amíg nyomva tartod a lövés gombot, nem veheted elő a fegyvert.")
							return
						elseif getElementData(localPlayer, "canUseMegaphone") then
							exports.sarp_hud:showInfobox("warning", "Előbb rakd el a megafont!")
							return
						end

						itemsTable.player[slotId].inUse = true
						weaponInUse = itemsTable.player[slotId]

						local haveAmmo = false

						if getItemAmmoID(weaponInUse.itemId) > 0 then
							for k, v in pairs(itemsTable.player) do
								if isAmmoItem(v.itemId) and not v.inUse and getItemAmmoID(weaponInUse.itemId) == v.itemId then
									ammoInUse = v
									itemsTable.player[v.slot].inUse = true
									haveAmmo = true
									break
								end
							end
						end

						if (not haveAmmo and getItemAmmoID(weaponInUse.itemId) == weaponInUse.itemId) or getItemAmmoID(weaponInUse.itemId) == -1 then
							ammoInUse = weaponInUse
							haveAmmo = true
						end

						if haveAmmo then
							if weaponInUse.itemId == 110 then
								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), 99999)
							elseif weaponInUse.itemId == ammoInUse.itemId then
								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), ammoInUse.amount)
							elseif ammoInUse.itemId == 44 then
								if (tonumber(ammoInUse.data1) or 0) >= 100 then
									togglePlayerWeaponFire(false)
								end

								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), 99999)
							else
								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), ammoInUse.amount + 1)
							end
						else
							triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), 1)
							togglePlayerWeaponFire(false)
						end

						if availableItems[weaponInUse.itemId] then
							if weaponInUse.itemId == 28 then
								exports.sarp_chat:sendLocalMeAction(localPlayer, "elővett egy fényképezőgépet.")
							elseif weaponInUse.itemId == 110 then
								exports.sarp_chat:sendLocalMeAction(localPlayer, "elővett egy sokkoló pisztolyt.")
								setElementData(localPlayer, "tazerState", true)
							else
								local itemName = ""

								if availableItems[weaponInUse.itemId] then
									itemName = " (" .. getItemName(weaponInUse.itemId) .. ")"
								end

								exports.sarp_chat:sendLocalMeAction(localPlayer, "elővett egy fegyvert." .. itemName)

								setElementData(localPlayer, "tazerState", false)

								triggerEvent("movedItemInInventory", localPlayer)
							end
						end
					elseif weaponInUse.dbID == itemDbId then
						deactivateWeapon()
					end
				elseif isAmmoItem(itemId) and weaponInUse then
					if not ammoInUse then
						if getItemAmmoID(weaponInUse.itemId) == itemId then
							if itemsTable.player[slotId].itemId == 44 then
								if (tonumber(itemsTable.player[slotId].data1) or 0) >= 100 then
									togglePlayerWeaponFire(false)
								else
									togglePlayerWeaponFire(true)
								end

								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), 99999)
							else
								triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), itemsTable.player[slotId].amount + 1)

								togglePlayerWeaponFire(true)
							end

							itemsTable.player[slotId].inUse = true
						end
					elseif getItemWeaponID(weaponInUse.itemId) and ammoInUse.dbID == itemDbId then
						triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, getItemWeaponID(weaponInUse.itemId), 1)

						togglePlayerWeaponFire(false)

						itemsTable.player[slotId].inUse = false
					end
				end
			elseif isSpecialItem(itemId) then
				if getTickCount() >= lastSpecialItemUsage then
					if getElementData(localPlayer, "canUseMegaphone") then
						exports.sarp_hud:showInfobox("warning", "Előbb rakd el a megafont!")
						return
					end

					lastSpecialItemUsage = getTickCount() + 3000

					local currentAmount = tonumber(itemsTable.player[slotId].data2) or 0

					if itemId == 62 or itemId == 63 or (itemId >= 64 and itemId <= 69) then
						addDrunkenLevel(3)
					end

					if currentAmount + (specialItemUsage[itemId] or 20) >= 100 then
						triggerServerEvent("useItem", localPlayer, itemsTable.player[slotId].dbID)
						triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[slotId].dbID, 1)
						itemsTable.player[slotId] = nil
					else
						triggerEvent("updateItemData2", localPlayer, "player", itemsTable.player[slotId].dbID, currentAmount + (specialItemUsage[itemId] or 20), true)
						triggerServerEvent("useItem", localPlayer, itemsTable.player[slotId].dbID)
					end
				else
					exports.sarp_hud:showInfobox("error", "Ne kapkodj, még megfulladsz!")
				end
			elseif itemId == 123 then -- Feldolgozatlan marihuana
				if exports.sarp_groupscripting:isInDrugMakeZone(localPlayer	) then
					if not getElementData(localPlayer, "drugProcessing") then
						lastDrugTick = getTickCount() + 60000

						triggerServerEvent("useItem", localPlayer, itemDbId)
						triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[slotId].dbID, 1)
						triggerEvent("sarp_drugC:startDrugMaking", localPlayer, "marihuana")
						
						itemsTable.player[slotId] = nil
					else
						exports.sarp_hud:showInfobox("error", "Várj míg feldolgozod ezt az adagot!")
					end
				else
					exports.sarp_hud:showInfobox("error", "Nem vagy a feldolgozó helynél!")
				end
			elseif itemId == 111 or itemId == 112 then -- Jogsi/Személyi
				for k, v in pairs(itemsTable.player) do
					if (v.itemId == 111 or v.itemId == 112) and v.inUse then

						itemsTable.player[v.slot].inUse = false

						if v.itemId == 111 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy jogosítványt.")
							triggerEvent("sarp_licensesC:showDocument", localPlayer)
						elseif v.itemId == 112 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy személyigazolványt.")
							triggerEvent("sarp_licensesC:showDocument", localPlayer)
						end
					end
				end

				if not licenseState then
					itemsTable.player[slotId].inUse = true

					if itemsTable.player[slotId].itemId == 111 then
						--triggerEvent("sarp_licensesC:showDocument", localPlayer, "driver", fromJSON(itemsTable.player[slotId].data1))
						triggerEvent("sarp_licensesC:showDocument", localPlayer, "DriverLicense", fromJSON(itemsTable.player[slotId].data1))

						exports.sarp_chat:sendLocalMeAction(localPlayer, "megnéz egy jogosítványt.")
					elseif itemsTable.player[slotId].itemId == 112 then
						--triggerEvent("sarp_licensesC:showDocument", localPlayer, "identity", fromJSON(itemsTable.player[slotId].data1))
						triggerEvent("sarp_licensesC:showDocument", localPlayer, "Identity", fromJSON(itemsTable.player[slotId].data1))

						exports.sarp_chat:sendLocalMeAction(localPlayer, "megnéz egy személyigazolványt.")
					end

					licenseState = true
				else
					licenseState = false
				end
			elseif itemId == 119 or itemId == 118 then -- Bírság/Parkolási bírság
				for k, v in pairs(itemsTable.player) do
					if (v.itemId == 119 or v.itemId == 118) and v.inUse then

						itemsTable.player[v.slot].inUse = false

						if v.itemId == 119 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy bírságot.")
							triggerEvent("sarp_ticketC:showTicket", localPlayer)
						elseif v.itemId == 118 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy parkolási bírságot.")
							triggerEvent("sarp_ticketC:showTicket", localPlayer)
						end
					end
				end

				if not ticketState then
					

					local nearNPC = false
					for k, v in pairs(getElementsByType("ped", root, true)) do
						if getElementData(v, "ped.type") == "FINEPAY" then
							if exports.sarp_core:inDistance3D(v, localPlayer, 5) then
								nearNPC = true
								break
							end
						end
					end

					if nearNPC then
						local ticketData = fromJSON(itemsTable.player[slotId].data1)
						if exports.sarp_core:takeMoney(localPlayer, tonumber(ticketData["fine"])) then
							triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[slotId].dbID, 1)
							exports.sarp_hud:showAlert("info", "Sikeresen befizetted a bírságot")
						else
							exports.sarp_hud:showAlert("error", "Nincs elegendő pénzed befizetni a bírságot")
						end
					else
						itemsTable.player[slotId].inUse = true
						if itemsTable.player[slotId].itemId == 119 then
							triggerEvent("sarp_ticketC:showTicket", localPlayer, itemsTable.player[slotId].dbID, true, "Traffic", fromJSON(itemsTable.player[slotId].data1), false)

							exports.sarp_chat:sendLocalMeAction(localPlayer, "megnéz egy bírságot.")
						elseif itemsTable.player[slotId].itemId == 118 then
							triggerEvent("sarp_ticketC:showTicket", localPlayer, itemsTable.player[slotId].dbID, true, "Parking", fromJSON(itemsTable.player[slotId].data1), false)

							exports.sarp_chat:sendLocalMeAction(localPlayer, "megnéz egy parkolási bírságot.")
						end
						ticketState = true
					end

					
				else
					ticketState = false
				end
			elseif itemId == 120 or itemId == 121 then -- Bírság/Parkolási bírság tömb
				for k, v in pairs(itemsTable.player) do
					if (v.itemId == 120 or v.itemId == 121) and v.inUse then

						itemsTable.player[v.slot].inUse = false

						if v.itemId == 120 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy bírság tömböt.")
							triggerEvent("sarp_ticketC:showTicket", localPlayer)
						elseif v.itemId == 121 then
							exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy parkolási bírság tömböt.")
							triggerEvent("sarp_ticketC:showTicket", localPlayer)
						end
					end
				end

				if not ticketState then
					itemsTable.player[slotId].inUse = true

					if itemsTable.player[slotId].itemId == 120 then
						triggerEvent("sarp_ticketC:showTicket", localPlayer, itemsTable.player[slotId].dbID, true, "Traffic", nil, true)

						exports.sarp_chat:sendLocalMeAction(localPlayer, "elővesz egy bírság tömböt.")
					elseif itemsTable.player[slotId].itemId == 121 then
						triggerEvent("sarp_ticketC:showTicket", localPlayer, itemsTable.player[slotId].dbID, true, "Parking", nil, true)

						exports.sarp_chat:sendLocalMeAction(localPlayer, "elővesz egy parkolási bírság tömböt.")
					end

					ticketState = true
				else
					ticketState = false
				end
			elseif itemId == 79 then -- Walkie Talkie
				local itemFound = false

				for k, v in pairs(itemsTable.player) do
					if v.itemId == 79 and v.inUse then
						exports.sarp_hud:showWalkieTalkie(false)
						itemsTable.player[v.slot].inUse = false
						exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy rádiót.")
						itemFound = true
					end
				end

				if not itemFound then
					itemsTable.player[slotId].inUse = true
					exports.sarp_hud:showWalkieTalkie(true, itemsTable.player[slotId])
					exports.sarp_chat:sendLocalMeAction(localPlayer, "elővesz egy rádiót.")
				end
			elseif itemId == 114 then -- Megaphone
				local itemFound = false

				for k, v in pairs(itemsTable.player) do
					if v.itemId == 114 and v.inUse then
						setElementData(localPlayer, "canUseMegaphone", false)
						itemsTable.player[v.slot].inUse = false
						exports.sarp_chat:sendLocalMeAction(localPlayer, "elrak egy megafont.")
						itemFound = true
					end
				end

				if getPedWeapon(localPlayer) > 0 then
					exports.sarp_hud:showInfobox("error", "Előbb rakd el a fegyvert!")
				elseif not itemFound then
					itemsTable.player[slotId].inUse = true
					setElementData(localPlayer, "canUseMegaphone", true)
					exports.sarp_chat:sendLocalMeAction(localPlayer, "elővesz egy megafont.")
				end
			elseif itemId == 105 then -- Gyógyszer
				if getTickCount() >= lastDrugTick then
					lastDrugTick = getTickCount() + 60000

					triggerServerEvent("useItem", localPlayer, itemDbId)
					triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[slotId].dbID, 1)
					
					itemsTable.player[slotId] = nil
				else
					exports.sarp_hud:showInfobox("error", "Csak percenként vehetsz be gyógyszert!")
				end
			elseif itemId == 106 then -- Vitamin
				if getTickCount() >= lastDrugTick then
					lastDrugTick = getTickCount() + 60000

					triggerServerEvent("useItem", localPlayer, itemDbId)
					triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[slotId].dbID, 1)
					
					itemsTable.player[slotId] = nil
				else
					exports.sarp_hud:showInfobox("error", "Csak percenként vehetsz be gyógyszert!")
				end
			elseif itemId == 86 or itemId == 71 then -- Jelvény / Telefon
				if itemsTable.player[slotId].inUse then
					itemsTable.player[slotId].inUse = false
					triggerServerEvent("useItem", localPlayer, itemDbId, false)
				else
					local itemFound = false

					for k, v in pairs(itemsTable.player) do
						if (v.itemId == 86 or v.itemId == 71) and v.inUse then
							itemsTable.player[v.slot].inUse = false
							itemFound = true
						end
					end
				
					if not itemFound then
						itemsTable.player[slotId].inUse = true
						triggerServerEvent("useItem", localPlayer, itemDbId, true)
					else
						triggerServerEvent("useItem", localPlayer, itemDbId, false)
					end
				end
			else
				triggerServerEvent("useItem", localPlayer, itemDbId)
			end
		end
	end
end

local weaponFireCount = 0

addEventHandler("onClientPlayerWeaponFire", getLocalPlayer(),
	function (weaponId)
		local weaponInUse = false
		local ammoInUse = false

		for k, v in pairs(itemsTable.player) do
			if v.inUse then
				if isWeaponItem(v.itemId) then
					weaponInUse = v
				elseif isAmmoItem(v.itemId) then
					ammoInUse = v
				end
			end
		end

		local itemAmmoId = getItemAmmoID(weaponInUse.itemId)

		if weaponInUse and not ammoInUse and itemAmmoId and (itemAmmoId <= 0 or itemAmmoId == weaponInUse.itemId) then
			ammoInUse = weaponInUse
		end

		if weaponInUse and ammoInUse and ammoInUse.amount and weaponInUse.itemId ~= 110 then
			if weaponId == 43 then
				exports.sarp_chat:sendLocalMeAction(localPlayer, "készít egy képet a kamerával.")
				
				if (tonumber(ammoInUse.data1) or 0) + 5 >= 100 then
					triggerEvent("updateItemData1", localPlayer, "player", ammoInUse.dbID, 100, true)

					if getItemAmmoID(itemsTable.player[weaponInUse.slot].itemId) ~= weaponInUse.itemId then
						triggerServerEvent("giveWeapon", localPlayer, weaponInUse.itemId, weaponId, 1)
						togglePlayerWeaponFire(false)
					end

					exports.sarp_hud:showInfobox("warning", "Betelt a kamera SD kártyája!")
				else
					triggerEvent("updateItemData1", localPlayer, "player", ammoInUse.dbID, (tonumber(itemsTable.player[ammoInUse.slot].data1) or 0) + 5, true)
				end
			else
				if weaponInUse.itemId ~= ammoInUse.itemId and getPedTotalAmmo(localPlayer) > ammoInUse.amount - 1 and ammoInUse.amount - 1 == 0 then
					togglePlayerWeaponFire(false)
				end

				if ammoInUse.amount - 1 > 0 then
					if itemsTable.player[ammoInUse.slot].amount then
						weaponFireCount = weaponFireCount + 1

						itemsTable.player[ammoInUse.slot].amount = itemsTable.player[ammoInUse.slot].amount - 1

						if weaponId == 24 or weaponId == 25 or weaponId == 33 or weaponId == 34 or (weaponId >= 16 and weaponId <= 18) then
							triggerServerEvent("updateItemAmount", localPlayer, localPlayer, ammoInUse.dbID, itemsTable.player[ammoInUse.slot].amount)
							weaponFireCount = 0
						elseif weaponFireCount == 4 then
							triggerServerEvent("updateItemAmount", localPlayer, localPlayer, ammoInUse.dbID, itemsTable.player[ammoInUse.slot].amount)
							weaponFireCount = 0
						end

						triggerEvent("movedItemInInventory", localPlayer, true)
					end
				else
					triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", itemsTable.player[ammoInUse.slot].dbID)
					itemsTable.player[ammoInUse.slot] = nil
				end
			end
		end
	end
)

function togglePlayerWeaponFire(state)
	if state then
		if getElementData(localPlayer, "playerNoAmmo") then
			exports.sarp_controls:toggleControl({"fire", "vehicle_fire", "action"}, true)
			setElementData(localPlayer, "playerNoAmmo", false)
		end
	else
		if not getElementData(localPlayer, "playerNoAmmo") then
			exports.sarp_controls:toggleControl({"fire", "vehicle_fire", "action"}, false)
			setElementData(localPlayer, "playerNoAmmo", true)
		end
	end
end

function processPerishableItems()
	for k, v in pairs(itemsTable.player) do
		if perishableItems[v.itemId] then
			local perishableAmount = (tonumber(v.data3) or 0) + 1

			if perishableAmount - 1 > perishableItems[v.itemId] then
				triggerEvent("updateItemData3", localPlayer, "player", v.dbID, perishableItems[v.itemId], true)
			end

			if perishableAmount <= perishableItems[v.itemId] then
				triggerEvent("updateItemData3", localPlayer, "player", v.dbID, perishableAmount, true)
			elseif perishableEvent[v.itemId] then
				triggerServerEvent(perishableEvent[v.itemId], localPlayer, v.dbID)
			end
		end
	end
end

function getLocalPlayerItems()
	return itemsTable.player
end

function countEmptySlots(category)
	local x = 0

	if not category then
		for i = 0, defaultSettings.slotLimit - 1 do
			if not itemsTable.player[i] then
				x = x + 1
			end
		end
	elseif category == "keys" then
		for i = defaultSettings.slotLimit, defaultSettings.slotLimit * 2 - 1 do
			if not itemsTable.player[i] then
				x = x + 1
			end
		end
	elseif category == "papers" then
		for i = defaultSettings.slotLimit * 2, defaultSettings.slotLimit * 3 - 1 do
			if not itemsTable.player[i] then
				x = x + 1
			end
		end
	end

	return x
end

function countItemsByItemID(itemId, countAmount)
	local x = 0

	for i = 0, defaultSettings.slotLimit * 3 - 1 do
		if itemsTable.player[i] and itemsTable.player[i].itemId == itemId then
			if countAmount then
				x = x + itemsTable.player[i].amount
			else
				x = x + 1
			end
		end
	end

	return x
end

function hasItem(itemId)
	for k, v in pairs(itemsTable.player) do
		if v.itemId == itemId then
			return v
		end
	end

	return false
end

function hasItemWithData(itemId, dataType, data)
	data = tonumber(data) or data

	for k, v in pairs(itemsTable.player) do
		if v.itemId == itemId and (tonumber(v[dataType]) or v[dataType]) == data then
			return v
		end
	end
	
	return false
end

function getItemsWeight(elementType)
	local weight = 0
	
	if itemsTable[elementType] then
		for k, v in pairs(itemsTable[elementType]) do
			if availableItems[v.itemId] then
				weight = weight + getItemWeight(v.itemId) * v.amount
			end
		end
	end
	
	return weight
end

function getCurrentWeight()
	local weight = 0
	
	for k, v in pairs(itemsTable.player) do
		if availableItems[v.itemId] then
			weight = weight + getItemWeight(v.itemId) * v.amount
		end
	end
	
	return weight
end

addEvent("updateInUse", true)
addEventHandler("updateInUse", getRootElement(),
	function (ownerType, itemDbId, newState)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)

			if itemDbId then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].inUse = newState
						break
					end
				end
			end
		end
	end
)

addEvent("updateItemID", true)
addEventHandler("updateItemID", getRootElement(),
	function (ownerType, itemDbId, newId)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)
			newId = tonumber(newId)

			if itemDbId and newId then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].itemId = newId
						break
					end
				end
			end
		end
	end
)

addEvent("updateItemData3", true)
addEventHandler("updateItemData3", getRootElement(),
	function (ownerType, itemDbId, newData, sync)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)

			if itemDbId and newData then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].data3 = newData

						if sync then
							triggerServerEvent("updateItemData3", localPlayer, localPlayer, itemDbId, newData)
						end

						break
					end
				end
			end
		end
	end
)

addEvent("updateItemData2", true)
addEventHandler("updateItemData2", getRootElement(),
	function (ownerType, itemDbId, newData, sync)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)

			if itemDbId and newData then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].data2 = newData

						if sync then
							triggerServerEvent("updateItemData2", localPlayer, localPlayer, itemDbId, newData)
						end

						break
					end
				end
			end
		end
	end
)

addEvent("updateItemData1", true)
addEventHandler("updateItemData1", getRootElement(),
	function (ownerType, itemDbId, newData, sync)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)
			newData = tonumber(newData) or newData

			if itemDbId and newData then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].data1 = newData

						if sync then
							triggerServerEvent("updateItemData1", localPlayer, localPlayer, itemDbId, newData)
						end

						break
					end
				end
			end
		end
	end
)

addEvent("updateItemAmount", true)
addEventHandler("updateItemAmount", getRootElement(),
	function (ownerType, itemDbId, newAmount)
		if itemsTable[ownerType] then
			itemDbId = tonumber(itemDbId)
			newAmount = tonumber(newAmount)
			
			if itemDbId and newAmount then
				for k, v in pairs(itemsTable[ownerType]) do
					if v.dbID == itemDbId then
						itemsTable[ownerType][v.slot].amount = newAmount
						break
					end
				end
			end
		end
	end
)

addEvent("unLockItem", true)
addEventHandler("unLockItem", getRootElement(),
	function (ownerType, slot)
		if itemsTable[ownerType] and itemsTable[ownerType][slot] and itemsTable[ownerType][slot].locked then
			itemsTable[ownerType][slot].locked = false
		end
	end
)

addEvent("deleteItem", true)
addEventHandler("deleteItem", getRootElement(),
	function (ownerType, items)
		if itemsTable[ownerType] and items and type(items) == "table" then
			for k, v in pairs(items) do
				for i = 0, defaultSettings.slotLimit * 3 - 1 do
					if itemsTable[ownerType][i] and itemsTable[ownerType][i].dbID == v then
						itemsTable[ownerType][i] = nil
						
						if movedslotId == i then
							movedslotId = false
						end
					end
				end
			end
		end
	end
)

function addItem(ownerType, dbID, slot, itemId, amount, data1, data2, data3)
	if dbID and slot and itemId and amount and not itemsTable[ownerType][slot] then
		itemsTable[ownerType][slot] = {}
		itemsTable[ownerType][slot].dbID = dbID
		itemsTable[ownerType][slot].slot = slot
		itemsTable[ownerType][slot].itemId = itemId
		itemsTable[ownerType][slot].amount = amount
		itemsTable[ownerType][slot].data1 = data1
		itemsTable[ownerType][slot].data2 = data2
		itemsTable[ownerType][slot].data3 = data3
		itemsTable[ownerType][slot].inUse = false
		itemsTable[ownerType][slot].locked = false
	end
end

addEvent("addItem", true)
addEventHandler("addItem", getRootElement(),
	function (ownerType, item)
		if itemsTable[ownerType] and item and type(item) == "table" then
			addItem(ownerType, item.dbID, item.slot, item.itemId, item.amount, item.data1, item.data2, item.data3)
		end
	end
)

addEvent("loadItems", true)
addEventHandler("loadItems", getRootElement(),
	function (items, ownerType, inventoryElement, otherType)
		if items and type(items) == "table" then
			itemsTable[ownerType] = {}

			for k, v in pairs(items) do
				addItem(tostring(ownerType), v.dbID, v.slot, v.itemId, v.amount, v.data1, v.data2, v.data3)
			end

			if otherType then
				toggleInventory(false)
				currentInventoryElement = inventoryElement
				itemsTableState = ownerType
				toggleInventory(true)
			else
				itemsLoaded = true
			end

			triggerEvent("movedItemInInventory", localPlayer)
		end
	end
)

function isPointOnInventory(x, y)
	if panelState then
		if x >= panelPosX and x <= panelPosX + panelWidth and y >= panelPosY and y <= panelPosY + panelHeight then
			return true
		else
			return false
		end
	else
		return false
	end
end

function findSlot(x, y)
	if panelState then
		local slotId = false
		local slotPosX, slotPosY = false, false

		for i = 0, defaultSettings.slotLimit - 1 do
			local x2 = panelPosX + (defaultSettings.slotBoxWidth + 5) * (i % defaultSettings.width)
			local y2 = panelPosY + (defaultSettings.slotBoxHeight + 5) * math.floor(i / defaultSettings.width)

			if x >= x2 and x <= x2 + defaultSettings.slotBoxWidth and y >= y2 and y <= y2 + defaultSettings.slotBoxHeight then
				slotId = tonumber(i)
				slotPosX, slotPosY = x2, y2
				break
			end
		end

		if slotId then
			if itemsTableState == "player" and currentCategory == "keys" then
				slotId = slotId + defaultSettings.slotLimit
			elseif itemsTableState == "player" and currentCategory == "papers" then
				slotId = slotId + defaultSettings.slotLimit * 2
			end

			return slotId, slotPosX, slotPosY
		else
			return false
		end
	else
		return false
	end
end

function findEmptySlot(ownerType)
	local emptySlot = false
	
	for i = 0, defaultSettings.slotLimit - 1 do
		if not itemsTable[ownerType][i] then
			emptySlot = i
			break
		end
	end
	
	return emptySlot
end

function findEmptySlotOfKeys(ownerType)
	local emptySlot = false
	
	for i = defaultSettings.slotLimit, defaultSettings.slotLimit * 2 - 1 do
		if not itemsTable[ownerType][i] then
			emptySlot = i
			break
		end
	end
	
	return emptySlot
end

function findEmptySlotOfPapers(ownerType)
	local emptySlot = false
	
	for i = defaultSettings.slotLimit * 2, defaultSettings.slotLimit * 3 - 1 do
		if not itemsTable[ownerType][i] then
			emptySlot = i
			break
		end
	end
	
	return emptySlot
end

function bootCheck(vehicle)
	local componentPosX, componentPosY, componentPosZ = getVehicleComponentPosition(vehicle, "boot_dummy", "world")

	if not componentPosX or not componentPosY or getVehicleType(vehicle) ~= "Automobile" then
		return true
	end

	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
	local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(vehicle)
	local vehicleRotX, vehicleRotY, vehicleRotZ = getElementRotation(vehicle)

	if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, componentPosX, componentPosY, componentPosZ) < 1.75 then
		local angle = math.deg(math.atan2(vehiclePosY - playerPosY, vehiclePosX - playerPosX)) + 180 - vehicleRotZ

		if angle < 0 then
			angle = angle + 360
		end

		if angle > 250 and angle <= 285 then
			return true
		end
	end

	return false
end

addEvent("failedToMoveItem", true)
addEventHandler("failedToMoveItem", getRootElement(),
	function (failSlot, originalSlot, amount)
		if originalSlot then
			itemsTable[itemsTableState][originalSlot] = itemsTable[itemsTableState][failSlot]
			itemsTable[itemsTableState][originalSlot].slot = originalSlot
			itemsTable[itemsTableState][failSlot] = nil
		elseif stackAmount > 0 then
			itemsTable[itemsTableState][originalSlot].amount = amount
		end
	end
)

addEventHandler("onClientClick", getRootElement(),
	function (button, state, absX, absY, worldX, worldY, worldZ, clickedWorld)
		if button == "left" then
			if state == "up" then
				selectedInput = false

				if activeButton and string.find(activeButton, "input:") then
					selectedInput = string.gsub(activeButton, "input:", "")
					inputCursorState = true
					lastChangeCursorState = getTickCount()
				end
			end

			if friskTableState then
				if not friskPanelIsMoving then
					if state == "down" then
						if absX >= friskPanelPosX and absX <= friskPanelPosX + panelWidth - 50 - 15 and absY >= friskPanelPosY - 30 and absY <= friskPanelPosY then
							moveDifferenceX = absX - friskPanelPosX
							moveDifferenceY = absY - friskPanelPosY
							friskPanelIsMoving = true
							return
						end

						if friskCategoryHover and friskCategoryHover ~= friskCategory then
							friskCatInterpolate = getTickCount()

							friskLastCategory = friskCategory
							friskCategory = friskCategoryHover

							playSound(":sarp_assets/audio/interface/3.ogg")
						end
					end
				elseif state == "up" and friskTableState then
					friskPanelIsMoving = false
					moveDifferenceX, moveDifferenceY = 0, 0
				end
			end

			if panelState then
				if not panelIsMoving then
					if state == "down" then
						if absX >= panelPosX and absX <= panelPosX + panelWidth - 50 - 15 and absY >= panelPosY - 30 and absY <= panelPosY then
							moveDifferenceX = absX - panelPosX
							moveDifferenceY = absY - panelPosY
							panelIsMoving = true
							return
						end

						if itemsTableState == "player" then
							if categoryHover and categoryHover ~= currentCategory then
								tabLineInterpolation = getTickCount()

								lastCategory = currentCategory
								currentCategory = categoryHover

								playSound(":sarp_assets/audio/interface/3.ogg")
							end
						end

						local hoveredSlot, slotPosX, slotPosY = findSlot(absX, absY)

						if hoveredSlot and itemsTable[itemsTableState][hoveredSlot] then
							if not itemsTable[itemsTableState][hoveredSlot].inUse then
								haveMoving = true
								movedslotId = hoveredSlot
								moveDifferenceX = absX - slotPosX
								moveDifferenceY = absY - slotPosY
							else
								exports.sarp_hud:showInfobox("error", "Használatban lévő itemet nem mozgathatsz!")
							end
						end
					elseif state == "up" then
						if movedslotId then
							local hoveredSlot = findSlot(absX, absY)
							local movedItem = itemsTable[itemsTableState][movedslotId]

							if hoverShowItem then
								if getTickCount() - lastShowItemTick >= 5500 then
									lastShowItemTick = getTickCount()

									if availableItems[movedItem.itemId] then
										exports.sarp_chat:sendLocalMeAction(localPlayer, "felmutat egy tárgyat: " .. getItemName(movedItem.itemId))
									else
										exports.sarp_chat:sendLocalMeAction(localPlayer, "felmutat egy tárgyat.")
									end

									triggerServerEvent("showTheItem", localPlayer, movedItem, getElementsByType("player", getRootElement(), true))
								end
							elseif hoveredSlot then
								if itemsTableState == "player" and isKeyItem(movedItem.itemId) and hoveredSlot < defaultSettings.slotLimit then
									hoveredSlot = findEmptySlotOfKeys("player")

									if not hoveredSlot then
										return
									end

									exports.sarp_hud:showInfobox("warning", "Ez az item átkerült a kulcsokhoz!")
								end

								if itemsTableState == "player" and isPaperItem(movedItem.itemId) and hoveredSlot < defaultSettings.slotLimit then
									hoveredSlot = findEmptySlotOfPapers("player")

									if not hoveredSlot then
										return
									end

									exports.sarp_hud:showInfobox("warning", "Ez az item átkerült a iratokhoz!")
								end

								if movedslotId ~= hoveredSlot and movedItem then
									if hoveredSlot >= defaultSettings.slotLimit * 2 and not isPaperItem(movedItem.itemId) then
										if isKeyItem(movedItem.itemId) then
											hoveredSlot = findEmptySlotOfKeys("player")
											exports.sarp_hud:showInfobox("warning", "Ez az item átkerült a kulcsokhoz!")
										else
											hoveredSlot = findEmptySlot("player")
											exports.sarp_hud:showInfobox("warning", "Ez nem irat!")
										end
									elseif hoveredSlot >= defaultSettings.slotLimit and hoveredSlot < defaultSettings.slotLimit * 2 and not isKeyItem(movedItem.itemId) then
										if isPaperItem(movedItem.itemId) then
											hoveredSlot = findEmptySlotOfPapers("player")
											exports.sarp_hud:showInfobox("warning", "Ez az item átkerült az iratokhoz!")
										else
											hoveredSlot = findEmptySlot("player")
											exports.sarp_hud:showInfobox("warning", "Ez nem kulcs item!")
										end
									end

									if not movedItem.inUse and not movedItem.locked then
										local hoveredItem = itemsTable[itemsTableState][hoveredSlot]

										if not hoveredItem then
											triggerServerEvent("moveItem", localPlayer, movedItem.dbID, movedItem.itemId, movedslotId, hoveredSlot, stackAmount, currentInventoryElement, currentInventoryElement)

											playSound(":sarp_assets/audio/interface/6.ogg")

											if stackAmount >= 0 then
												if stackAmount >= movedItem.amount or stackAmount <= 0 then
													itemsTable[itemsTableState][hoveredSlot] = itemsTable[itemsTableState][movedslotId]
													itemsTable[itemsTableState][hoveredSlot].slot = hoveredSlot
													itemsTable[itemsTableState][movedslotId] = nil
												elseif stackAmount > 0 then
													itemsTable[itemsTableState][movedslotId].amount = itemsTable[itemsTableState][movedslotId].amount - stackAmount
												end
											end
										elseif movedItem.itemId == hoveredItem.itemId and isItemStackable(hoveredItem.itemId) then
											if stackAmount >= 0 then
												if (movedItem.data3 == "duty" or hoveredItem.data3 == "duty") and (movedItem.data3 ~= "duty" or hoveredItem.data3 ~= "duty") then
													exports.sarp_hud:showInfobox("error", "Szolgálati eszközzel ezt nem teheted meg!")
												else
													local amount = stackAmount

													if amount <= 0 or amount >= movedItem.amount then
														amount = movedItem.amount
													end

													playSound(":sarp_assets/audio/interface/6.ogg")

													if movedItem.amount - amount > 0 then
														triggerServerEvent("updateItemAmount", localPlayer, currentInventoryElement, hoveredItem.dbID, hoveredItem.amount + amount)
														itemsTable[itemsTableState][hoveredSlot].amount = itemsTable[itemsTableState][hoveredSlot].amount + amount

														triggerServerEvent("updateItemAmount", localPlayer, currentInventoryElement, movedItem.dbID, movedItem.amount - amount)
														itemsTable[itemsTableState][movedslotId].amount = itemsTable[itemsTableState][movedslotId].amount - amount
													else
														triggerServerEvent("updateItemAmount", localPlayer, currentInventoryElement, hoveredItem.dbID, hoveredItem.amount + movedItem.amount)
														itemsTable[itemsTableState][hoveredSlot].amount = itemsTable[itemsTableState][hoveredSlot].amount + movedItem.amount

														triggerServerEvent("takeItem", localPlayer, currentInventoryElement, "dbID", movedItem.dbID)
														itemsTable[itemsTableState][movedslotId] = nil
													end

													triggerEvent("movedItemInInventory", localPlayer, true)
												end
											end
										end
									end
								end
							elseif isPointOnActionBar(absX, absY) then
								if itemsTableState == "player" then
									hoveredSlot = findActionBarSlot(absX, absY)

									if hoveredSlot then
										putOnActionBar(hoveredSlot, itemsTable[itemsTableState][movedslotId])
										playSound(":sarp_assets/audio/interface/6.ogg")
									end
								end
							elseif not movedItem.locked and not movedItem.inUse and not isPointOnInventory(absX, absY) then
								if isElement(clickedWorld) then
									local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
									local targetPosX, targetPosY, targetPosZ = getElementPosition(clickedWorld)
									local clickedElementType = getElementType(clickedWorld)

									if movedItem.itemId == 118 or movedItem.itemId == 119 then
										exports.sarp_hud:showInfobox("error", "Ezt az itemet nem dobhatod ki és nem adhatod át másnak!")
										movedslotId = false
										haveMoving = false
										return
									end

									if clickedElementType == "object" and isTrashModel(getElementModel(clickedWorld)) and not getElementAttachedTo(clickedWorld) and itemsTableState == "player" then
										if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ) <= 4 then
											if availableItems[movedItem.itemId] then
												exports.sarp_chat:sendLocalMeAction(localPlayer, "kidobott egy tárgyat a szemetesbe. (" .. getItemName(movedItem.itemId) .. ")")
											else
												exports.sarp_chat:sendLocalMeAction(localPlayer, "kidobott egy tárgyat a szemetesbe.")
											end

											if stackAmount > 0 and stackAmount < movedItem.amount then
												triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", movedItem.dbID, stackAmount)
											else
												triggerServerEvent("takeItem", localPlayer, localPlayer, "dbID", movedItem.dbID)
											end
										end
									else
										if movedItem.data3 == "duty" then
											exports.sarp_hud:showInfobox("error", "Szolgálati eszközzel ezt nem teheted meg!")
										else
											if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ) <= 8 then
												if not (clickedElementType == "player" and clickedWorld == localPlayer and itemsTableState == "player") then
													if (itemsTableState == "vehicle" or itemsTableState == "object") and (clickedElementType ~= "player" or clickedWorld ~= localPlayer) then
														exports.sarp_hud:showInfobox("error", "Járműből / széfből csak a saját inventorydba pakolhatsz!")
													else
														local hitDatabaseId = getElementDatabaseId(clickedWorld)

														if tonumber(hitDatabaseId) then
															if clickedElementType == "vehicle" then
																if not bootCheck(clickedWorld) then
																	exports.sarp_hud:showInfobox("error", "Csak a jármű csomagtartójánál állva rakhatsz tárgyat a csomagtérbe!")
																	movedslotId = false
																	haveMoving = false
																	return
																end
															end

															itemsTable[itemsTableState][movedslotId].locked = true

															triggerServerEvent("moveItem", localPlayer, movedItem.dbID, movedItem.itemId, movedslotId, false, stackAmount, currentInventoryElement, clickedWorld)
														else
															exports.sarp_hud:showInfobox("error", "A kiválasztott elem nem rendelkezik önálló tárterülettel!")
														end
													end
												end
											end
										end
									end
								end
							end

							movedslotId = false
							haveMoving = false
						end
					end
				elseif state == "up" and panelState then
					panelIsMoving = false
					moveDifferenceX, moveDifferenceY = 0, 0
				end
			end
		elseif button == "right" and state == "up" then
			local hoveredSlot = findSlot(absX, absY)

			if panelState then
				if hoveredSlot then
					if itemsTable[itemsTableState][hoveredSlot] then
						useItem(itemsTable[itemsTableState][hoveredSlot].dbID)
						movedslotId = false
					end
				end
			end
		end
	end
)

addEvent("rottenEffect", true)
addEventHandler("rottenEffect", getRootElement(),
	function (amount)
		rottenEffect = {getTickCount(), amount}
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		if rottenEffect then
			local currentTick = getTickCount()
			local elapsedTime = currentTick - rottenEffect[1]
			local progress = elapsedTime / 750
			
			local alpha = interpolateBetween(0, 0, 0, 150 * rottenEffect[2] + 55, 0, 0, progress, "InQuad")

			if progress - 1 > 0 then
				alpha = interpolateBetween(150 * rottenEffect[2] + 55, 0, 0, 0, 0, 0, progress - 1, "OutQuad")
			end

			if progress > 2 then
				rottenEffect = false
			end

			dxDrawImage(0, 0, screenX, screenY, "files/vin.png", 0, 0, 0, tocolor(20, 100, 40, alpha))
		end
	end
)

local showedItems = {}
local showItemsHandled = false

addEvent("showTheItem", true)
addEventHandler("showTheItem", getRootElement(),
	function (item)
		local sx, sy = processTooltip(0, 0, getItemName(item.itemId), item.itemId, item, true)

		sy = sy + 8

		table.insert(showedItems, {source, getTickCount(), item, dxCreateRenderTarget(sx, sy, true), sx, sy})

		processShowItem()
	end
)

function processShowItem(hide)
	if #showedItems > 0 then
		if not showItemsHandled then
			addEventHandler("onClientRender", getRootElement(), renderShowItem)
			addEventHandler("onClientRestore", getRootElement(), processShowItem)
			showItemsHandled = true
		end

		if not hide and showedItems then
			for i = 1, #showedItems do
				if showedItems[i] then
					local item = showedItems[i][3]

					dxSetRenderTarget(showedItems[i][4], true)

					dxSetBlendMode("modulate_add")

					processTooltip(0, 0, getItemName(item.itemId), item.itemId, item, false, showedItems[i][5])
				end
			end

			dxSetBlendMode("blend")

			dxSetRenderTarget()
		end
	elseif showItemsHandled then
		removeEventHandler("onClientRender", getRootElement(), renderShowItem)
		removeEventHandler("onClientRestore", getRootElement(), processShowItem)
		showItemsHandled = false
	end
end

function renderShowItem()
	local currentTick = getTickCount()
	local cameraPosX, cameraPosY, cameraPosZ = getCameraMatrix()
	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

	if showedItems then
		for i = 1, #showedItems do
			if showedItems[i] then
				local elapsedTime = currentTick - showedItems[i][2]
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
						showedItems[i] = nil
						processShowItem(true)
					end
				end

				if showedItems[i] then
					local sourcePlayer = showedItems[i][1]

					if isElement(sourcePlayer) then
						local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(sourcePlayer)
						local distance = getDistanceBetweenPoints3D(sourcePosX, sourcePosY, sourcePosZ, playerPosX, playerPosY, playerPosZ)
						
						if distance < 10 then
							if isLineOfSightClear(cameraPosX, cameraPosY, cameraPosZ, sourcePosX, sourcePosY, sourcePosZ, true, false, false, true, false, true, false) then
								local multipler = 1

								if distance > 7.5 then
									multipler = 1 - (distance - 7.5) / 2.5
								end

								local x, y, z = getPedBonePosition(sourcePlayer, 5)
								x, y = getScreenFromWorldPosition(x, y, z + 0.55)

								if x and y then
									dxDrawImage(math.floor(x - showedItems[i][5] / 2), math.floor(y - showedItems[i][6] / 2) + (255 - progress) / 4, showedItems[i][5], showedItems[i][6], showedItems[i][4], 0, 0, 0, tocolor(255, 255, 255, progress * 0.9 * multipler))
								end
							end
						end
					end
				end
			end
		end
	end
end

function drawCategoryTab(x, y, k, picture, name, bodySearch)
	local colorOfTab = tocolor(145, 145, 145)
	local textWidth = dxGetTextWidth(name, 0.55, Roboto)
	local x2 = x + (sizeForTabs - textWidth) / 2

	if not bodySearch then
		if itemsTableState ~= "player" then
			x2 = x + (panelWidth - textWidth) / 2
			colorOfTab = tocolor(255, 255, 255)
		elseif currentCategory == k or absX >= x2 - 14.5 and absX <= x2 + 14.5 + textWidth and absY >= y and absY <= y + 24 then
			colorOfTab = tocolor(255, 255, 255)

			if currentCategory ~= k then
				categoryHover = k
			end
		end
	elseif friskCategory == k or absX >= x2 - 14.5 and absX <= x2 + 14.5 + textWidth and absY >= y and absY <= y + 24 then
		colorOfTab = tocolor(255, 255, 255)

		if friskCategory ~= k then
			friskCategoryHover = k
		end
	end

	dxDrawImage(x2 - 14.5, y, 24, 24, "files/categories/" .. picture ..".png", 0, 0, 0, colorOfTab)
	dxDrawText(name, x2 + 14.5, y, 0, y + 24, colorOfTab, 0.55, Roboto, "left", "center")

	return x
end

addEvent("bodySearchGetDatas", true)
addEventHandler("bodySearchGetDatas", getRootElement(),
	function (items, playerName, charMoney)
		friskTableState = {}
		friskTableState.items = {}
		friskTableState.name = playerName
		friskTableState.money = charMoney

		for k, v in pairs(items) do
			friskTableState.items[v.slot] = {
				itemId = v.itemId,
				amount = v.amount,
				data1 = v.data1,
				data2 = v.data2,
				data3 = v.data3
			}
		end

		addEventHandler("onClientRender", getRootElement(), renderBodySearch)
	end
)

function renderBodySearch()
	absX, absY = 0, 0

	buttons = {}

	if isCursorShowing() then
		local relX, relY = getCursorPosition()

		absX = screenX * relX
		absY = screenY * relY
	end

	if isCursorShowing() and friskPanelIsMoving then
		friskPanelPosX = absX - moveDifferenceX
		friskPanelPosY = absY - moveDifferenceY
	end

	-- ** Háttér
	local x = friskPanelPosX - 5
	local y = friskPanelPosY - 5

	dxDrawRectangle(x, y, friskPanelWidth, friskPanelHeight, tocolor(31, 31, 31, 240))

	-- ** Cím
	dxDrawRectangle(x, y - 30, friskPanelWidth, 30, tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(x + 3), math.floor(y - 25), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
	dxDrawText("Motozás: ", x + 30, y - 25, 0, y, tocolor(255, 255, 255), 1, RobotoL, "left", "center")
	dxDrawText(friskTableState.name, x + 30 + dxGetTextWidth("Motozás: ", 1, RobotoL), y - 25, 0, y, tocolor(50, 179, 239), 0.5, Roboto, "left", "center")

	-- ** Kilépés
	local closeTextWidth = dxGetTextWidth("X", 1, RobotoL)
	local closeTextPosX = x + friskPanelWidth - closeTextWidth - 5
	local closeColor = tocolor(255, 255, 255)

	if absX >= closeTextPosX and absY >= y - 30 and absX <= closeTextPosX + closeTextWidth and absY <= y then
		closeColor = tocolor(215, 89, 89)

		if getKeyState("mouse1") then
			removeEventHandler("onClientRender", getRootElement(), renderBodySearch)
			friskTableState = false
			return
		end
	end

	dxDrawText("X", closeTextPosX, y - 25, 0, y, closeColor, 1, RobotoL, "left", "center")

	-- ** Kategóriák
	dxDrawRectangle(x, y + friskPanelHeight, friskPanelWidth, 30, tocolor(31, 31, 31, 240))

	local tabStartX = math.floor(x)
	local tabStartY = math.floor(y + friskPanelHeight)
	local sizeForTabs = friskPanelWidth / 3

	friskCategoryHover = false

	local currentCategoryId = 0
	local lastCategoryId = currentCategoryId

	if friskCategory == "keys" then
		currentCategoryId = 1
	elseif friskCategory == "papers" then
		currentCategoryId = 2
	end

	if friskLastCategory == "keys" then
		lastCategoryId = 1
	elseif friskLastCategory == "papers" then
		lastCategoryId = 2
	end

	if friskCatInterpolate and friskCategory ~= friskLastCategory then
		local elapsedTime = getTickCount() - friskCatInterpolate
		local duration = 250
		local progress = elapsedTime / duration

		local x = interpolateBetween(
			tabStartX + sizeForTabs * lastCategoryId, 0, 0,
			tabStartX + sizeForTabs * currentCategoryId, 0, 0,
			progress, "InOutQuad")

		dxDrawRectangle(x, tabStartY + 28, sizeForTabs, 2, tocolor(50, 179, 239))

		if progress >= 1 then
			friskCatInterpolate = false
		end
	else
		dxDrawRectangle(tabStartX + sizeForTabs * currentCategoryId, tabStartY + 28, sizeForTabs, 2, tocolor(50, 179, 239))
	end

	tabStartX = drawCategoryTab(tabStartX, tabStartY, "main", "bag", "Tárgyak", true)
	tabStartX = drawCategoryTab(tabStartX + sizeForTabs, tabStartY, "keys", "key", "Kulcsok", true)
	tabStartX = drawCategoryTab(tabStartX + sizeForTabs, tabStartY, "papers", "wallet", "Iratok", true)

	-- ** Itemek
	local hoveredItemSlot = false

	for i = 0, defaultSettings.slotLimit - 1 do
		local slot = i

		x = friskPanelPosX + (defaultSettings.slotBoxWidth + 5) * (slot % defaultSettings.width)
		y = friskPanelPosY + (defaultSettings.slotBoxHeight + 5) * math.floor(slot / defaultSettings.width)

		if friskCategory == "keys" then
			i = i + defaultSettings.slotLimit
		elseif friskCategory == "papers" then
			i = i + defaultSettings.slotLimit * 2
		end

		local item = friskTableState.items

		if item then
			item = friskTableState.items[i]

			if item and not availableItems[item.itemId] then
				item = false
			end
		end

		dxDrawRectangle(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, tocolor(53, 53, 53, 200))

		if item then
			if absX >= x and absX <= x + defaultSettings.slotBoxWidth and absY >= y and absY <= y + defaultSettings.slotBoxHeight then
				hoveredItemSlot = item
			end

			drawItemPicture(item, x, y)
			dxDrawText(item.amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
		end
	end

	if hoveredItemSlot then
		processTooltip(absX, absY, getItemName(hoveredItemSlot.itemId), hoveredItemSlot.itemId, hoveredItemSlot, false)
	end

	activeButton = false

	if absX and absY then
		for k, v in pairs(buttons) do
			if absX >= v[1] and absY >= v[2] and absX <= v[1] + v[3] and absY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function onRender()
	absX, absY = 0, 0

	buttons = {}

	if isCursorShowing() then
		local relX, relY = getCursorPosition()

		absX = screenX * relX
		absY = screenY * relY
	end

	if isCursorShowing() and panelIsMoving then
		panelPosX = absX - moveDifferenceX
		panelPosY = absY - moveDifferenceY
	end

	if currentInventoryElement ~= localPlayer and isElement(currentInventoryElement) then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
		local targetPosX, targetPosY, targetPosZ = getElementPosition(currentInventoryElement)

		if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ) >= 5 then
			toggleInventory(false)
			return
		end
	end

	-- ** Háttér
	local x = panelPosX - 5
	local y = panelPosY - 5

	dxDrawRectangle(x, y, panelWidth, panelHeight, tocolor(31, 31, 31, 240))

	-- ** Cím
	dxDrawRectangle(x, y - 30, panelWidth, 30, tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(x + 3), math.floor(y - 25), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
	dxDrawText("Inventory", x + 30, y - 25, 0, y, tocolor(255, 255, 255), 1, RobotoL, "left", "center")

	drawInput("stack|4|num-only", "Stack", panelPosX + panelWidth - 50 - 10, panelPosY - 30, 50, 25, Roboto, 0.45)

	local drawShowItemTooltip = false
	hoverShowItem = false

	if movedslotId and itemsTableState == "player" and currentInventoryElement == localPlayer then
		local textWidth = dxGetTextWidth("Tárgy felmutatása", 0.5, Roboto)
		local x2 = x + (panelWidth - textWidth) / 2

		if absX >= x2 and absY >= y - 25 and absX <= x2 + textWidth and absY <= y then
			local elapsedTime = getTickCount() - lastShowItemTick

			if elapsedTime >= 5500 then
				hoverShowItem = true
			else
				drawShowItemTooltip = elapsedTime
			end

			dxDrawText("Tárgy felmutatása", x2, y - 25, 0, y, tocolor(225, 225, 225), 0.5, Roboto, "left", "center")
		else
			dxDrawText("Tárgy felmutatása", x2, y - 25, 0, y, tocolor(154, 154, 154), 0.5, Roboto, "left", "center")
		end
	end

	-- ** Súly
	local weightLimit = getWeightLimit(itemsTableState, currentInventoryElement)
	local weight = 0

	for k, v in pairs(itemsTable[itemsTableState]) do
		if availableItems[v.itemId] then
			weight = weight + getItemWeight(v.itemId) * v.amount
		end
	end

	if weight > weightLimit then
		weight = weightLimit
	end

	local sizeOfWeight = (panelHeight - 10) * weight / weightLimit
	local weightSize = lastWeightSize

	if lastWeightSize ~= sizeOfWeight then
		if not gotWeightInterpolation then
			gotWeightInterpolation = getTickCount()
		else
			local elapsedTime =  getTickCount() - gotWeightInterpolation
			local progress = elapsedTime / 250

			weightSize = interpolateBetween(
				lastWeightSize, 0, 0,
				sizeOfWeight, 0, 0,
				progress, "OutQuad")

			if progress >= 1 then
				lastWeightSize = sizeOfWeight
				gotWeightInterpolation = false
			end
		end
	end

	dxDrawRectangle(panelPosX + panelWidth - 15, panelPosY, 5, panelHeight - 10, tocolor(53, 53, 53, 200))
	dxDrawRectangle(panelPosX + panelWidth - 15, panelPosY + panelHeight - 10 - weightSize, 5, weightSize, tocolor(50, 179, 239))
	dxDrawText(math.ceil(weight) .. "/" .. weightLimit .. "kg", 0, y - 25, panelPosX + panelWidth - 50 - 15 - 5, y, tocolor(194, 194, 194), 0.45, Roboto, "right", "center")

	-- ** Kategóriák
	dxDrawRectangle(x, y + panelHeight, panelWidth, 30, tocolor(31, 31, 31, 240))

	local tabStartX = math.floor(x)
	local tabStartY = math.floor(y + panelHeight)

	categoryHover = false

	local currentCategoryId = 0
	local lastCategoryId = currentCategoryId

	if itemsTableState == "player" then
		if currentCategory == "keys" then
			currentCategoryId = 1
		elseif currentCategory == "papers" then
			currentCategoryId = 2
		end

		if lastCategory == "keys" then
			lastCategoryId = 1
		elseif lastCategory == "papers" then
			lastCategoryId = 2
		end
	else
		currentCategoryId = 0
		lastCategoryId = currentCategoryId
	end

	if tabLineInterpolation and currentCategory ~= lastCategory then
		local elapsedTime = getTickCount() - tabLineInterpolation
		local duration = 250
		local progress = elapsedTime / duration

		local x = interpolateBetween(
			tabStartX + sizeForTabs * lastCategoryId, 0, 0,
			tabStartX + sizeForTabs * currentCategoryId, 0, 0,
			progress, "InOutQuad")

		dxDrawRectangle(x, tabStartY + 28, sizeForTabs, 2, tocolor(50, 179, 239))

		if progress >= 1 then
			tabLineInterpolation = false
		end
	else
		if itemsTableState ~= "player" then
			dxDrawRectangle(tabStartX, tabStartY + 28, panelWidth, 2, tocolor(50, 179, 239))
		else
			dxDrawRectangle(tabStartX + sizeForTabs * currentCategoryId, tabStartY + 28, sizeForTabs, 2, tocolor(50, 179, 239))
		end
	end

	if itemsTableState == "player" then
		tabStartX = drawCategoryTab(tabStartX, tabStartY, "main", "bag", "Tárgyak")
		tabStartX = drawCategoryTab(tabStartX + sizeForTabs, tabStartY, "keys", "key", "Kulcsok")
		tabStartX = drawCategoryTab(tabStartX + sizeForTabs, tabStartY, "papers", "wallet", "Iratok")
	elseif itemsTableState == "vehicle" then
		tabStartX = drawCategoryTab(tabStartX, tabStartY, "main", "vehicle", "Csomagtartó")
	elseif itemsTableState == "object" then
		tabStartX = drawCategoryTab(tabStartX, tabStartY, "main", "safe", "Széf")
	end

	-- ** Slotok @ Itemek
	local hoveredItemSlot = false

	for i = 0, defaultSettings.slotLimit - 1 do
		local slot = i

		x = panelPosX + (defaultSettings.slotBoxWidth + 5) * (slot % defaultSettings.width)
		y = panelPosY + (defaultSettings.slotBoxHeight + 5) * math.floor(slot / defaultSettings.width)

		if itemsTableState == "player" and currentCategory == "keys" then
			i = i + defaultSettings.slotLimit
		elseif itemsTableState == "player" and currentCategory == "papers" then
			i = i + defaultSettings.slotLimit * 2
		end

		local item = itemsTable[itemsTableState]

		if item then
			item = itemsTable[itemsTableState][i]

			if item and not availableItems[item.itemId] then
				item = false
			end
		end

		local slotColor = tocolor(53, 53, 53, 200)

		if item and item.inUse then
			slotColor = tocolor(50, 200, 50, 200)
		end

		if absX >= x and absX <= x + defaultSettings.slotBoxWidth and absY >= y and absY <= y + defaultSettings.slotBoxHeight then
			slotColor = tocolor(50, 179, 239, 200)

			if item and not movedslotId then
				hoveredItemSlot = item

				if lastslotId ~= i then
					lastslotId = i
					playSound(":sarp_assets/audio/interface/9.ogg")
				end
			end
		elseif lastslotId == i then
			lastslotId = false
		end

		dxDrawRectangle(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, slotColor)

		if item and (movedslotId ~= i or movedslotId == i and stackAmount > 0 and stackAmount < item.amount) then
			drawItemPicture(item, x, y)
			dxDrawText(item.amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
		end
	end

	if hoveredItemSlot then
		processTooltip(absX, absY, getItemName(hoveredItemSlot.itemId), hoveredItemSlot.itemId, hoveredItemSlot)
	end

	-- ** Mozgatott item
	if movedslotId then
		local x = absX - moveDifferenceX
		local y = absY - moveDifferenceY

		drawItemPicture(itemsTable[itemsTableState][movedslotId], x, y)

		if stackAmount < itemsTable[itemsTableState][movedslotId].amount then
			if stackAmount > 0 then
				dxDrawText(stackAmount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
			else
				dxDrawText(itemsTable[itemsTableState][movedslotId].amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
			end
		else
			dxDrawText(itemsTable[itemsTableState][movedslotId].amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
		end
	end

	if drawShowItemTooltip then
		local tooltipText = "Várj #d75959" .. math.floor(6.5 - drawShowItemTooltip / 1000) .. "#ffffff másodpercet."
		local tooltipWidth, tooltipHeight = getTooltipBestSize(tooltipText)

		showTooltip(panelPosX + (panelWidth - tooltipWidth) / 2, panelPosY - 30 - tooltipHeight, tooltipText)
	end

	-- ** Gombok
	activeButton = false

	if absX and absY then
		for k, v in pairs(buttons) do
			if absX >= v[1] and absY >= v[2] and absX <= v[1] + v[3] and absY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function processTooltip(x, y, text, itemId, item, getSize, showItem)
	local text2 = ""

	if itemId == 71 and tonumber(item.data1) then
		text2 = "Telefonszám: #7cc576" .. item.data1
	elseif itemId == 86 then
		if item.data1 and item.data2 then
			text2 = "#DCA300# " .. tostring(item.data1) .. " - " .. item.data2 .. " #"
		end
	elseif itemId == 118 or itemId == 119 then
		if item.data1 then
			local remainMinute = perishableItems[itemId] - (item.data3 or 0)
			local totalSecond = remainMinute * 60
			local remainHour = math.floor(totalSecond / 3600)

			if remainHour >= 1 then
				text2 = "Hátralévő idő a befizetésig: #d75959" .. remainHour .. " óra és " .. ((totalSecond % 3600) / 60) .. " perc"
			else
				text2 = "Hátralévő idő a befizetésig: #d75959" .. remainMinute .. " perc"
			end
		end
	elseif isKeyItem(itemId) then
		if item.data1 then
			text2 = "Azonosító: " .. item.data1
		else
			text2 = "#d75959** HIBÁS KULCS **"
		end
	elseif itemId == 79 then
		if item.data1 and tonumber(item.data1) > 0 then
			text2 = "Frekvencia: #6fcc9fCH-" .. item.data1
		else
			text2 = "#d75959Nincs beállítva frekvencia."
		end
	elseif perishableItems[itemId] or isSpecialItem(itemId) then
		local health = 0
		local color = ""

		if perishableItems[itemId] then
			health = math.floor(100 - (item.data3 or 0) / perishableItems[itemId] * 100)
			color = "#6fcc9f"

			if health > 30 and health <= 65 then
				color = "#FF9600"
			elseif health <= 30 then
				color = "#d75959"
			end

			text2 = "Állapot: " .. color .. health .. "%"

			if isSpecialItem(itemId) then
				text2 = text2 .. "\n"
			end
		end

		if isSpecialItem(itemId) then
			health = tonumber(item.data2) or 0
			color = "#d75959"
			
			if health > 45 and health <= 75 then
				color = "#FF9600"
			elseif health <= 45 then
				color = "#6fcc9f"
			end
			
			text2 = text2 .. "#ffffffElfogyasztva: " .. color .. health .. "%"
		end
	elseif itemId == 44 then -- SD Kártya
		local health = tonumber(item.data1) or 0
		local color = "#d75959"
		
		if health > 30 and health <= 65 then
			color = "#FF9600"
		elseif health <= 30 then
			color = "#6fcc9f"
		end
		
		text2 = "Telítettség: " .. color .. health .. "%"
	elseif itemId == 111 then -- Jogosítvány
		local data = fromJSON(item.data1)

		text2 = "Aláírás: #4283de" .. data.name .. "\n#ffffffKategória: #6fcc9f" .. data.category
	elseif itemId == 112 then -- Személyigazolvány
		local data = fromJSON(item.data1)

		text2 = "Aláírás: #4283de" .. data.name
	elseif itemId == 113 then -- Vizsga záradék
		local result = "#d75959Sikertelen"

		if tonumber(item.data1) == 1 then
			result = "#6fcc9fSikeres"
		end

		text2 = "Vizsga megnevezése: #8e8e8e" .. item.data2 .. "\n#ffffffVizsga eredménye: " .. result
	elseif availableItems[itemId][2] then
		text2 = availableItems[itemId][2]
	else
		text2 = "#ffffffSúly: #8e8e8e" .. getItemWeight(itemId) * item.amount .. " kg"
	end

	if not getSize then
		if showItem then
			showTooltip(showItem / 2, 0, text, text2, item)
		else
			showTooltip(x, y, text, text2)
		end
	else
		return getTooltipBestSize(text, text2, true)
	end
end

function drawItemPicture(item, x, y)
	if not item then
		dxDrawImage(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, "files/noitem.png")
	else
		local picture = ""

		if itemPictures[item.itemId] then
			picture = itemPictures[item.itemId]
		else
			picture = "files/items/" .. item.itemId .. ".png"
		end

		local perishableItem = false
		local pictureAlpha = 255

		if item.itemId and grayItemPictures[item.itemId] then
			pictureAlpha = 255 * (1 - (item.data3 or 0) / perishableItems[item.itemId])
			perishableItem = grayItemPictures[item.itemId]
		end

		if perishableItem then
			dxDrawImage(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, perishableItem)
		end

		dxDrawImage(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, picture, 0, 0, 0, tocolor(255, 255, 255, pictureAlpha))

		local k = 1

		if perishableItem then
			k = drawItemStatusBar(x, y, item, "perishable", k)
		end

		if isSpecialItem(item.itemId) then
			k = drawItemStatusBar(x, y, item, "usage", k)
		end

		if item.itemId == 44 then
			k = drawItemStatusBar(x, y, item, "sdcard", k)
		end
	end
end

function drawItemStatusBar(x, y, item, stat, k)
	local health = 0
	local color = 0

	if stat == "perishable" then
		health = math.floor(100 - (item.data3 or 0) / perishableItems[item.itemId] * 100)
		color = tocolor(20, 165, 20)

		if health > 30 and health <= 65 then
			color =  tocolor(255, 128, 0)
		elseif health <= 30 then
			color = tocolor(180, 40, 40)
		end
	elseif stat == "usage" then
		health = 100 - (item.data2 or 0)
		color = tocolor(20, 140, 250)
	elseif stat == "sdcard" then
		health = tonumber(item.data1) or 0
		color = tocolor(180, 40, 40)

		if health > 45 and health <= 75 then
			color = tocolor(255, 128, 0)
		elseif health <= 45 then
			color = tocolor(20, 165, 20)
		end
	end

	health = health / 100

	dxDrawRectangle(x + 2, y + defaultSettings.slotBoxHeight - 3 * k - 2 - (k - 1), defaultSettings.slotBoxWidth - 4, 3, tocolor(0, 0, 0, 175))
	dxDrawRectangle(x + 2, y + defaultSettings.slotBoxHeight - 3 * k - 2 - (k - 1), (defaultSettings.slotBoxWidth - 4) * health, 3, color)

	if health > 0 then
		return k + 1
	end

	return k
end

function getTooltipBestSize(text, subText, showItem)
	text = tostring(text)
	subText = subText and tostring(subText)

	if text == subText then
		subText = nil
	end

	local sx = dxGetTextWidth(text, 0.5, Roboto2, true) + 20

	if subText then
		sx = math.max(sx, dxGetTextWidth(subText, 0.5, Roboto2, true) + 20)
		text = "#32b3ef" .. text .. "\n#ffffff" .. subText
	end

	local _, newLines = string.gsub(subText or "", "\n", "")
	local sy = 10 * (newLines + 4)

	if not subText then
		sy = 30
	end

	if showItem then
		sx = sx + defaultSettings.slotBoxWidth - 10
	end

	return sx, sy, text
end

function showTooltip(x, y, text, subText, showItem)
	local sx, sy, text = getTooltipBestSize(text, subText, showItem)

	if showItem then
		x = math.floor(x - sx / 2)

		dxDrawImage(x, y, sx, sy, "files/tooltip_bg.png", 0, 0, 0, tocolor(0, 0, 0, 190))
		dxDrawImage(x + (sx - 16) / 2, y + sy, 16, 8, "files/tooltip_arrow.png", 0, 0, 0, tocolor(0, 0, 0, 190))

		drawItemPicture(showItem, math.floor(x), math.floor(y + (sy - defaultSettings.slotBoxHeight) / 2))

		dxDrawText(showItem.amount, x, y + (sy - defaultSettings.slotBoxHeight) / 2, x + defaultSettings.slotBoxWidth - 3, y + (sy + defaultSettings.slotBoxHeight) / 2 - 3, tocolor(255, 255, 255), 0.5, Roboto2, "right", "bottom")

		dxDrawText(text, x + defaultSettings.slotBoxWidth + 5, y, x + sx, y + sy, tocolor(255, 255, 255), 0.5, Roboto2, "left", "center", false, false, false, true)
	else
		x = math.max(0, math.min(screenX - sx, x))
		y = math.max(0, math.min(screenY - sy, y))

		dxDrawImage(x, y, sx, sy, "files/tooltip_bg.png", 0, 0, 0, tocolor(0, 0, 0, 190))
		dxDrawText(text, x, y, x + sx, y + sy, tocolor(255, 255, 255, 255), 0.5, Roboto2, "center", "center", false, false, false, true)
	end
end

function toggleInventory(state)
	if panelState ~= state then
		if state then
			stackAmount = 0

			addEventHandler("onClientRender", getRootElement(), onRender, true, "low-999")

			panelState = true
		else
			if itemsTableState == "vehicle" or itemsTableState == "object" then
				local nearbyPlayers = getElementsByType("player", getRootElement(), true)
				
				triggerServerEvent("closeInventory", localPlayer, currentInventoryElement, nearbyPlayers)
			end

			removeEventHandler("onClientRender", getRootElement(), onRender)

			panelState = false

			stackAmount = 0
			fakeInputs = {}
			selectedInput = false
		end
	end
end

bindKey("i", "down",
	function (key, keyState)
		if getElementData(localPlayer, "loggedIn") then
			toggleInventory(not panelState)

			itemsTableState = "player"
			currentInventoryElement = localPlayer

			panelIsMoving = false
			selectedInput = false
		end
	end
)

exports.sarp_admin:addAdminCommand("itemlist", 7, "Item lista")
addCommandHandler("itemlist",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 7 then
			itemListState = not itemListState
			
			if itemListState then
				if not itemListItems then
					itemListItems = {}
					
					for i = 1, #availableItems do
						table.insert(itemListItems, i)
					end
				end
				
				addEventHandler("onClientRender", getRootElement(), onItemListRender, true, "low-1000")
				showCursor(true)
			else
				removeEventHandler("onClientRender", getRootElement(), onItemListRender)
				showCursor(false)
			end
		end
	end
)

function onItemListRender()
	absX, absY = 0, 0

	buttons = {}

	if isCursorShowing() then
		local relX, relY = getCursorPosition()

		absX = screenX * relX
		absY = screenY * relY
	end

	-- ** Háttér
	dxDrawRectangle(itemListPosX, itemListPosY, itemListWidth, itemListHeight, tocolor(31, 31, 31, 240))

	-- ** Cím
	dxDrawRectangle(itemListPosX, itemListPosY, itemListWidth, 30, tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(itemListPosX + 3), math.floor(itemListPosY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
	dxDrawText("Tárgy lista", itemListPosX + 30, itemListPosY, 0, itemListPosY + 30, tocolor(255, 255, 255), 1, RobotoL, "left", "center")

	-- ** Kilépés
	local closeTextWidth = dxGetTextWidth("X", 1, RobotoL)
	local closeTextPosX = itemListPosX + itemListWidth - closeTextWidth - 5
	local closeColor = tocolor(255, 255, 255)

	if absX >= closeTextPosX and absY >= itemListPosY and absX <= closeTextPosX + closeTextWidth and absY <= itemListPosY + 30 then
		closeColor = tocolor(215, 89, 89)

		if getKeyState("mouse1") then
			selectedInput = false
			itemListState = false
			removeEventHandler("onClientRender", getRootElement(), onItemListRender)
			showCursor(false)
			return
		end
	end

	dxDrawText("X", closeTextPosX, itemListPosY, 0, itemListPosY + 30, closeColor, 1, RobotoL, "left", "center")

	-- ** Content
	local x = itemListPosX + 5
	local y = itemListPosY + 30

	for i = 1, 12 do
		local colorOfRow = tocolor(10, 10, 10, 125)

		if i % 2 == 0 then
			colorOfRow = tocolor(10, 10, 10, 75)
		end

		dxDrawRectangle(x, y, itemListWidth - 10, defaultSettings.slotBoxHeight, colorOfRow)

		local itemId = itemListItems[i + itemListOffset]

		if itemId then
			if itemPictures[itemId] then
				dxDrawImage(math.floor(x), math.floor(y), defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, itemPictures[itemId])
			end

			local itemName = getItemName(itemId)
			local itemDesc = getItemDescription(itemId)

			if itemDesc then
				dxDrawText("#32b3ef[" .. itemId .. "] #ffffff" .. itemName, x + defaultSettings.slotBoxWidth + 5, y, 0, y + defaultSettings.slotBoxHeight / 2 + 3, tocolor(255, 255, 255), 0.45, Roboto, "left", "center", false, false, false, true)
				dxDrawText(itemDesc, x + defaultSettings.slotBoxWidth + 5, y + defaultSettings.slotBoxHeight / 2 - 3, 0, y + defaultSettings.slotBoxHeight, tocolor(200, 200, 200), 0.4, Roboto, "left", "center")
			else
				dxDrawText("#32b3ef[" .. itemId .. "] #ffffff" .. itemName, x + defaultSettings.slotBoxWidth + 5, y, 0, y + defaultSettings.slotBoxHeight, tocolor(255, 255, 255), 0.45, Roboto, "left", "center", false, false, false, true)
			end
		end

		y = y + defaultSettings.slotBoxHeight
	end

	-- ** Scrollbar
	if #itemListItems > 12 then
		local listSize = defaultSettings.slotBoxHeight * 12

		dxDrawRectangle(itemListPosX + itemListWidth - 10, itemListPosY + 30, 5, listSize, tocolor(0, 0, 0, 100))
		dxDrawRectangle(itemListPosX + itemListWidth - 10, itemListPosY + 30 + (listSize / #itemListItems) * math.min(itemListOffset, #itemListItems - 12), 5, (listSize / #itemListItems) * 12, tocolor(50, 179, 239))
	end

	-- ** Kereső mező
	drawInput("searchitem|50", "Keresés...", itemListPosX + 5, itemListPosY + itemListHeight - 30, itemListWidth - 10, 25, Roboto, 0.5)

	activeButton = false

	if absX and absY then
		for k, v in pairs(buttons) do
			if absX >= v[1] and absY >= v[2] and absX <= v[1] + v[3] and absY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function searchItems()
	itemListItems = {}
	
	local searchText = fakeInputs["searchitem|50"] or ""

	if utf8.len(searchText) < 1 then
		for i = 1, #availableItems do
			table.insert(itemListItems, i)
		end
	elseif tonumber(searchText) then
		searchText = tonumber(searchText)

		if availableItems[searchText] then
			table.insert(itemListItems, searchText)
		end
	else
		for i = 1, #availableItems do
			if utf8.find(utf8.lower(availableItems[i][1]), utf8.lower(searchText)) then
				table.insert(itemListItems, i)
			end
		end
	end
	
	itemListOffset = 0
end

addEventHandler("onClientCharacter", getRootElement(),
	function (character)
		if selectedInput and character ~= "\\" and fakeInputs[selectedInput] then
			local selected = split(selectedInput, "|")

			if panelState and character == "i" then
				toggleInventory(false)
				return
			end

			if utf8.len(fakeInputs[selectedInput]) < tonumber(selected[2]) then
				if selected[3] == "num-only" and not tonumber(character) then
					return
				end

				if not string.find(character, "[a-zA-Z0-9#@._öüóőúűéáÖÜÓŐÚŰÉÁ]") then
					return
				end

				fakeInputs[selectedInput] = fakeInputs[selectedInput] .. character

				if selected[1] == "stack" then
					local stack = tonumber(fakeInputs[selectedInput])

					if stack then
						if stack >= 0 then
							stackAmount = tonumber(string.format("%.0f", stack))
						else
							stackAmount = 0
						end
					else
						stackAmount = 0
					end
				elseif selected[1] == "searchitem" then
					searchItems()
				end
			end
		end
	end
)

addEventHandler("onClientKey", getRootElement(),
	function (key, state)
		if itemListState and isCursorShowing() then
			if #itemListItems > 12 then
				if key == "mouse_wheel_down" and itemListOffset < #itemListItems - 12 then
					itemListOffset = itemListOffset + 12
				elseif key == "mouse_wheel_up" and itemListOffset > 0 then
					itemListOffset = itemListOffset - 12
				end
			end
		end

		if itemListState and selectedInput and state then
			cancelEvent()

			if key == "backspace" then
				removeCharacterFromInput(selectedInput)

				if getKeyState(key) then
					repeatStartTimer = setTimer(removeCharacterFromInput, 500, 1, selectedInput, true)
				end
			end
		else
			if isTimer(repeatStartTimer) then
				killTimer(repeatStartTimer)
			end

			if isTimer(repeatTimer) then
				killTimer(repeatTimer)
			end

			repeatStartTimer = nil
			repeatTimer = nil
		end
	end
)

function removeCharacterFromInput(input, repeatTheTimer)
	if utf8.len(fakeInputs[input]) >= 1 then
		fakeInputs[input] = utf8.sub(fakeInputs[input], 1, -2)

		if string.find(input, "stack") then
			local stack = tonumber(fakeInputs[input])

			if stack then
				if stack >= 0 then
					stackAmount = tonumber(string.format("%.0f", stack))
				else
					stackAmount = 0
				end
			else
				stackAmount = 0
			end
		elseif string.find(input, "searchitem") then
			searchItems()
		end
	end

	if repeatTheTimer then
		repeatTimer = setTimer(removeCharacterFromInput, 50, 1, selectedInput, repeatTheTimer)
	end
end