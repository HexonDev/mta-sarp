local JOB_ID = 4

local createdObject = {}
createdPeds = {}
createdOrders = {}
createdMeals = {}
createdDishes = {}

local oldCloth = 0
local clothChangeMarker = nil
pickupColshape = nil
jobPed = nil
jobActive = false
local orderTimer = nil

addEventHandler("onClientInteriorChange", root, function(currentInterior, oldInterior)
	if currentInterior == 0 then
		destroyManagerPed()
		destroyInteriorObjects()
		destroyClothChangeMarker()
		
		if getElementModel(localPlayer) == restaurants[oldInterior]["skin"] then
			setElementModel(localPlayer, oldCloth)
		end
	end

	if restaurants[currentInterior] then
		local playerDim = getElementDimension(localPlayer)
		if isValidInterior(currentInterior, playerDim) and getElementData(localPlayer, "char.Job") == JOB_ID then
			createManagerPed(currentInterior)
			createClothChangeMarker(currentInterior)
			createPickupColshape(currentInterior)
		end

		createInteriorObjects(currentInterior)
	end
end)

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

function startJob()
	local restaurant = restaurants[getElementInterior(localPlayer)]
	if getElementModel(localPlayer) ~= restaurant["skin"] then		
		exports.sarp_hud:showAlert("error", "Nem vagy munkaruhában", "Menj a kijelölt helyre, és öltözz át!")
		return
	end

	if isTimer(orderTimer) then
		killTimer(orderTimer) 
	end

	orderTimer = setTimer(function()
		createOrderPed(getElementInterior(localPlayer))
	end, math.random(30, 90) * 1000, 0)

    exports.sarp_hud:showAlert("info", "Sikeresen elkezdted a felszolgálást!", "Várj a vevőkre, majd kérdezd meg tőlük, hogy mit rendelnek")
	jobActive = true
	createOrderPed(getElementInterior(localPlayer))
end

function stopJob()
	if createdDishes[localPlayer] and isElement(createdDishes[localPlayer]) then
		triggerServerEvent("sarp_serverS:dettachDish", localPlayer)
	end	

	exports.sarp_hud:showAlert("info", "Befejezted a felszolgálást!", "Most már visszaöltözhetsz a hétköznapi ruhádba")
	jobActive = false
	for k, v in pairs(createdPeds) do
		deleteOrderPed(k)
	end
	if isTimer(orderTimer) then
		killTimer(orderTimer) 
	end
	createdOrders = {}
	
end


function createManagerPed(currentInterior)
	if restaurants[currentInterior] then
		if isElement(jobPed) then
			destroyElement(jobPed)
		end
		jobPed = createPed(restaurants[currentInterior]["managerPed"][1], restaurants[currentInterior]["managerPed"][2], restaurants[currentInterior]["managerPed"][3], restaurants[currentInterior]["managerPed"][4], restaurants[currentInterior]["managerPed"][5])
		setElementInterior(jobPed, currentInterior)
		local playerDim = getElementDimension(localPlayer)
		setElementDimension(jobPed, playerDim)
		setElementFrozen(jobPed, true)
		setElementData(jobPed, "invulnerable", true)
		setElementData(jobPed, "visibleName", "Műszakvezető")
		setElementData(jobPed, "pedNameType", "Felszolgáló Munka")
		setPedAnimation(jobPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
	end
end

function destroyManagerPed()
	if isElement(jobPed) then
		destroyElement(jobPed)
	end 
end

function createInteriorObjects(currentInterior)
	if restaurants[currentInterior] then
		local v = restaurants[currentInterior]
		local playerDim = getElementDimension(localPlayer)
		if v["ID"][playerDim] then		
			if v["objects"] then
				for objectID, objectData in pairs(v["objects"]) do
					local ID = #createdObject + 1
					createdObject[ID] = createObject(objectID, objectData[1], objectData[2], objectData[3], objectData[4], objectData[5], objectData[6])
					setElementInterior(createdObject[ID], currentInterior)
					setElementDimension(createdObject[ID], playerDim)
				end
			end
		end
	end
end

function destroyInteriorObjects()
	for k, v in pairs(createdObject) do
		if isElement(v) then
			destroyElement(v)
		end
	end
end

function createClothChangeMarker(currentInterior)
	if isElement(clothChangeMarker) then
		destroyElement(clothChangeMarker)
	end
	clothChangeMarker = createMarker(restaurants[currentInterior]["clothChange"][1], restaurants[currentInterior]["clothChange"][2], restaurants[currentInterior]["clothChange"][3], "cylinder", 1, 50, 179, 239, 100)
	setElementInterior(clothChangeMarker, currentInterior)
	local playerDim = getElementDimension(localPlayer)
	setElementDimension(clothChangeMarker, playerDim)
end

function destroyClothChangeMarker()
	if isElement(clothChangeMarker) then
		destroyElement(clothChangeMarker)
	end
end

function createPickupColshape(currentInterior)
	if isElement(pickupColshape) then
		destroyElement(pickupColshape)
	end
	pickupColshape = createColSphere(restaurants[currentInterior]["pickupPoint"][1], restaurants[currentInterior]["pickupPoint"][2], restaurants[currentInterior]["pickupPoint"][3], 1)
end

function destroyPickupColshape()
	if isElement(pickupColshape) then
		destroyElement(pickupColshape)
	end
end

function createOrderPed(currentInterior)
	local pedTable = restaurants[currentInterior]["peds"]
	local randomNumber = math.random(1, #pedTable)
	local pedID = randomNumber

	if table.size(createdPeds) == #pedTable then
		--print("Az étterem megtelt " .. table.size(createdPeds))
		return
	end

	if createdPeds[pedID] then
		createOrderPed(currentInterior)
		return
	end
	
	createdPeds[pedID] = createPed(math.random(179, 196), pedTable[randomNumber][1], pedTable[randomNumber][2], pedTable[randomNumber][3], pedTable[randomNumber][4])
	setElementInterior(createdPeds[pedID], currentInterior)
	local playerDim = getElementDimension(localPlayer)
	setElementDimension(createdPeds[pedID], playerDim)
	setElementFrozen(createdPeds[pedID], true)
	setElementData(createdPeds[pedID], "invulnerable", true)
	setElementData(createdPeds[pedID], "visibleName", "Vevő")
	setPedAnimation(createdPeds[pedID], pedTable[randomNumber][5], pedTable[randomNumber][6], -1, true, false)
	setElementData(createdPeds[pedID], "pedNameType", pedID)

	createOrder(currentInterior, pedID)

	exports.sarp_hud:showAlert("warning", "Új vevő érkezett!")
	--setTimer(function()
	--	deleteOrderPed(pedID)
	--end, 5000, 1)
end

function startOrderTimer()
	if isTimer(orderTimer) then
		killTimer(orderTimer) 
	end

	orderTimer = setTimer(function()
		createOrderPed(getElementInterior(localPlayer))
	end, math.random(30, 90) * 1000, 0)
end

function stopOrderTimer()
	if isTimer(orderTimer) then
		killTimer(orderTimer) 
		orderTimer = nil
	end
end

function deleteOrderPed(pedID)
	if createdPeds[pedID] then
		destroyElement(createdPeds[pedID])
		createdPeds[pedID] = nil
	end
end

function createOrder(currentInterior, pedID)
	if createdPeds[pedID] then
		createdOrders[pedID] = {}
		local order = createdOrders[pedID]
		local restaurant = restaurants[currentInterior]
		if order then
			for i = 1, math.random(2, 3) do
				local randomMeal = math.random(1, #restaurant["meals"])
				order[i] = {randomMeal, false}
				--print(i .. " || Rendelés létrehozva: " .. randomMeal .. " = " .. restaurant["meals"][randomMeal][2] .. " (" .. restaurant["meals"][randomMeal][1] .. ")")
			end
		end

		--outputConsole(inspect(createdOrders))
	end
end


function isOrderCompleted(pedID)
	if createdPeds[pedID] then
		local order = createdOrders[pedID]
		if order then
			local completed = false
			for k, v in pairs(order) do
				if v[2] then
					completed = true
					--print("Teljesítve")
				end
			end
			return completed
		end
	end
end

function calculateOrderPrice(pedID)
	if createdPeds[pedID] then
		local order = createdOrders[pedID]
		if order then
			local restaurant = restaurants[getElementInterior(localPlayer)]
			local price = 0
			for k, v in pairs(order) do
				local mealID = v[1]
				price = price + restaurant["meals"][mealID][3]
				--print(mealID .. " " .. price)
			end
			local tip = math.random(5, price)
			return price, tip
		end
	end
end

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedWorld)
	if getElementData(localPlayer, "char.Job") == JOB_ID then
        if button == "left" and state == "down" then
			if clickedWorld == jobPed then
				--print("asd")
				local restaurant = restaurants[getElementInterior(localPlayer)]

                local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local pedPosX, pedPosY, pedPosZ = getElementPosition(jobPed)

				local playerInt, playerDim = getElementInterior(localPlayer), getElementDimension(localPlayer)

				if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 3 then
					if jobActive then
                        stopJob()
                    else
                        startJob()
                    end
				end
			end

			for k, v in pairs(createdPeds) do
				if clickedWorld == v then
					if jobActive then
						local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
						local pedPosX, pedPosY, pedPosZ = getElementPosition(clickedWorld)

						local playerInt, playerDim = getElementInterior(localPlayer), getElementDimension(localPlayer)

						if getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ) <= 3 then
							showOrderPanel(k)
							break
						end
					else
						exports.sarp_hud:showAlert("error", "Éppen nem dolgozol", "Menj a műszakvezetőhöz és jelentkezz munkára")
					end
				end
			end
		end
	end
end)

addEventHandler("onClientColShapeHit", root, function(element)
    if element == localPlayer then
        if source == pickupColshape and jobActive then
            panelState = "meals"
        end
    end
end)

addEventHandler("onClientColShapeLeave", root, function(element)
    if element == localPlayer then
        if source == pickupColshape and jobActive then
            panelState = nil
        end
    end
end)

addEventHandler("onClientColShapeLeave", root, function(element)
    if element == localPlayer then
        if source == pickupColshape and jobActive then
            panelState = nil
        end
    end
end)

addEventHandler("onClientElementDataChange", getRootElement(), function(dataName, oldValue)
	if source == localPlayer then
		if dataName == "char.Job" then
			if oldValue == JOB_ID then
				if createdDishes[localPlayer] and isElement(createdDishes[localPlayer]) then
					triggerServerEvent("sarp_serverS:dettachDish", localPlayer)
				end	
				
				jobActive = false
				for k, v in pairs(createdPeds) do
					deleteOrderPed(k)
				end
				if isTimer(orderTimer) then
					killTimer(orderTimer) 
				end
				createdOrders = {}

				destroyManagerPed()
				destroyClothChangeMarker()
			end
		end
		
	end
end)

local changeTick = getTickCount()
local cooldownTick = 3000

addEventHandler("onClientKey", root, function(key, press)
	if getElementData(localPlayer, "char.Job") == JOB_ID then
		if isElement(clothChangeMarker) then
			if isElementWithinMarker(localPlayer, clothChangeMarker) then
				if key == "e" and press then
					if changeTick + cooldownTick <= getTickCount() then
						if not jobActive then
							local restaurant = restaurants[getElementInterior(localPlayer)]
							if getElementModel(localPlayer) == restaurant["skin"] then
								triggerServerEvent("sarp_serverS:changeModel", localPlayer, oldCloth)
								--print("asd2")
							else
								oldCloth = getElementModel(localPlayer)
								--print("asd")
								triggerServerEvent("sarp_serverS:changeModel", localPlayer, restaurant["skin"])
							end
							changeTick = getTickCount()
						else
							exports.sarp_hud:showAlert("error", "Munka közben nem öltözhetsz át")
						end
					else
						exports.sarp_hud:showAlert("error", "Várj 3 másodpercet mielőtt újra átöltözöl")
					end
				end
			end
		end
	end
end)

registerEvent("sarp_serverC:attachDish", root, function(objID)
	createdDishes[source] = createObject(objID, 0, 0, 0)
	setElementInterior(createdDishes[source], getElementInterior(source))
	setElementDimension(createdDishes[source], getElementDimension(source))

	exports.sarp_boneattach:attachElementToBone(createdDishes[source],source, 12, 0.45, -0.03, 0.15, 334, 22 + 100, -19 + 90 + 30)

	exports.sarp_controls:toggleControl({"jump", "sprint", "fire"}, false) 
end)

registerEvent("sarp_serverC:dettachDish", root, function()
	if isElement(createdDishes[source]) then
		destroyElement(createdDishes[source])
		createdDishes[source] = nil

		exports.sarp_controls:toggleControl({"jump", "sprint", "fire"}, true) 
	end
end)