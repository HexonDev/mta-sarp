local screenX, screenY = guiGetScreenSize()

local slotLimit = 6

local panelState = false
local panelWidth = (defaultSettings.slotBoxWidth + 5) * slotLimit + 5
local panelHeight = defaultSettings.slotBoxHeight + 5 * 2
local panelPosX = screenX  / 2 - panelWidth / 2
local panelPosY = screenY - panelHeight - 5

local actionBarItems = {}
local actionBarSlots = {}
local slotPositions = false

local Roboto = dxCreateFont("files/fonts/Roboto.ttf", 22, false, "antialiased")

local loggedIn = false
local editHud = false
local bigMapState = false

local moveDifferenceX = 0
local moveDifferenceY = 0

local movedItemSlot = false
local lastItemSlot = false

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		if getElementData(localPlayer, "loggedIn") then
			loggedIn = true
			panelState = true

			loadActionBarItems()

			triggerEvent("requestChangeItemStartPos", getRootElement())

			triggerEvent("movedItemInInventory", localPlayer, true)
		end
	end
)

function loadActionBarItems()
	actionBarSlots = {}
	
	for i = 0, slotLimit - 1 do
		actionBarSlots[i] = getElementData(localPlayer, "actionBarSlot_" .. tostring(i)) or nil
	end
end

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if source == localPlayer then
			if dataName == "loggedIn" then
				if getElementData(localPlayer, "loggedIn") then
					loggedIn = true
					panelState = true

					loadActionBarItems()
				end
			elseif string.find(dataName, "actionBarSlot_") then
				triggerEvent("movedItemInInventory", localPlayer)
			elseif dataName == "isEditingHUD" then
				editHud = getElementData(source, "isEditingHUD")
			elseif dataName == "bigmapIsVisible" then
				bigMapState = getElementData(source, "bigmapIsVisible")
			end
		end
	end
)

addEventHandler("onClientClick", getRootElement(),
	function (button, state, absX, absY, worldX, worldY, worldZ, clickedWorld)
		if loggedIn and not editHud and not bigMapState then
			if button == "left" then
				if state == "down" then
					local hoveredSlot, slotPosX, slotPosY = findActionBarSlot(absX, absY)

					if hoveredSlot and actionBarSlots[hoveredSlot] then
						movedItemSlot = hoveredSlot
						moveDifferenceX = absX - slotPosX
						moveDifferenceY = absY - slotPosY
					end
				elseif state == "up" then
					if movedItemSlot then
						local hoveredSlot = findActionBarSlot(absX, absY)

						if hoveredSlot then
							if not actionBarSlots[hoveredSlot] then
								actionBarSlots[hoveredSlot] = actionBarSlots[movedItemSlot]

								setElementData(localPlayer, "actionBarSlot_" .. tostring(hoveredSlot), actionBarSlots[hoveredSlot])
								setElementData(localPlayer, "actionBarSlot_" .. tostring(movedItemSlot), false)

								actionBarSlots[movedItemSlot] = nil

								playSound(":sarp_assets/audio/interface/6.ogg")
							end
						else
							actionBarSlots[movedItemSlot] = nil
							setElementData(localPlayer, "actionBarSlot_" .. tostring(movedItemSlot), false)
						end

						movedItemSlot = false
					end
				end
			end
		end
	end
)

function putOnActionBar(slot, item)
	if slot then
		if not actionBarSlots[slot] then
			actionBarSlots[slot] = item.dbID

			setElementData(localPlayer, "actionBarSlot_" .. tostring(slot), item.dbID)

			triggerEvent("movedItemInInventory", localPlayer)

			return true
		else
			return false
		end
	else
		return false
	end
end

function findActionBarSlot(x, y)
	if panelState then
		local slot = false
		local slotPosX, slotPosY = false, false

		for i = 0, slotLimit - 1 do
			if not slotPositions or not slotPositions[i] then
				return
			end

			local x2 = slotPositions[i][1]
			local y2 = slotPositions[i][2]

			if x >= x2 and x <= x2 + defaultSettings.slotBoxWidth and y >= y2 and y <= y2 + defaultSettings.slotBoxHeight then
				slot = tonumber(i)
				slotPosX, slotPosY = x2, y2
				break
			end
		end

		if slot then
			return slot, slotPosX, slotPosY
		else
			return false
		end
	else
		return false
	end
end

for i = 1, slotLimit do
	bindKey(tostring(i), "down",
		function ()
			useActionSlot(i)
		end
	)
end

function useActionSlot(slot)
	if not haveMoving and slot then
		slot = tonumber(slot - 1)

		if not guiGetInputEnabled() then
			local item = tonumber(actionBarSlots[slot])

			if item then
				useItem(item)
			end
		end
	end
end

addEvent("updateItemID", true)
addEventHandler("updateItemID", getRootElement(),
	function (container, itemDbId, newId)
		if itemsTable[container] then
			itemDbId = tonumber(itemDbId)
			newId = tonumber(newId)
			
			if itemDbId and newId then
				for i = 0, slotLimit - 1 do
					if tonumber(actionBarSlots[i]) == itemDbId then
						actionBarItems[i].itemId = newId
					end
				end
			end
		end
	end
)

addEvent("updateItemData1", true)
addEventHandler("updateItemData1", getRootElement(),
	function (container, itemDbId, newData)
		if itemsTable[container] then
			itemDbId = tonumber(itemDbId)
			
			if itemDbId and newData then
				for i = 0, slotLimit - 1 do
					if tonumber(actionBarSlots[i]) == itemDbId then
						actionBarItems[i].data1 = newData
					end
				end
			end
		end
	end
)

addEvent("updateItemData2", true)
addEventHandler("updateItemData2", getRootElement(),
	function (container, itemDbId, newData)
		if itemsTable[container] then
			itemDbId = tonumber(itemDbId)
			
			if itemDbId and newData then
				for i = 0, slotLimit - 1 do
					if tonumber(actionBarSlots[i]) == itemDbId then
						actionBarItems[i].data2 = newData
					end
				end
			end
		end
	end
)

addEvent("updateItemData3", true)
addEventHandler("updateItemData3", getRootElement(),
	function (container, itemDbId, newData)
		if itemsTable[container] then
			itemDbId = tonumber(itemDbId)
			
			if itemDbId and newData then
				for i = 0, slotLimit - 1 do
					if tonumber(actionBarSlots[i]) == itemDbId then
						actionBarItems[i].data3 = newData
					end
				end
			end
		end
	end
)

function isPointOnActionBar(x, y)
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

function changeItemStartPos(x, y)
	panelPosX = x
	panelPosY = y
	slotPositions = {}

	for i = 0, slotLimit - 1 do
		slotPositions[i] = {math.floor(x + i * (defaultSettings.slotBoxWidth + 5) + 5), y + 5}
	end
end

function processActionBarShowHide(state)
	panelState = state
end

addEventHandler("onClientRender", getRootElement(),
	function ()
		if panelState and slotPositions then
			local cx, cy = getCursorPosition()

			if cx and cy then
				cx = cx * screenX
				cy = cy * screenY
			else
				cx, cy = -1, -1
			end

			for i = 0, slotLimit - 1 do
				if slotPositions[i] then
					renderActionBarItem(i, slotPositions[i][1], slotPositions[i][2], cx, cy)
				end
			end

			if movedItemSlot then
				local x = cx - moveDifferenceX
				local y = cy - moveDifferenceY
				local item = false

				for k, v in pairs(itemsTable.player) do
					if actionBarSlots[movedItemSlot] == v.dbID then
						item = v
						break
					end
				end

				if item and tonumber(item.itemId) and tonumber(item.amount) then
					drawItemPicture(item, x, y)
					dxDrawText(item.amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
				else
					dxDrawImage(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, "files/noitem.png")
				end
			end
		end
	end, true, "low"
)

function renderActionBarItem(slot, x, y, cx, cy)
	if actionBarItems[slot] and actionBarSlots[slot] and slot ~= movedItemSlot then
		local item = actionBarItems[slot].slot
		local slotColor = tocolor(53, 563, 53, 200)
		local itemInUse = false

		if item and itemsTable.player[item] and itemsTable.player[item].inUse then
			slotColor = tocolor(60, 184, 120, 200)
			itemInUse = true
		end

		if (getKeyState(slot + 1) or cx >= x and cx <= x + defaultSettings.slotBoxWidth and cy >= y and cy <= y + defaultSettings.slotBoxHeight) and not editHud then
			if not itemInUse then
				slotColor = tocolor(50, 179, 239, 200)
			end
			
			if lastItemSlot ~= slot then
				lastItemSlot = slot

				if not movedItemSlot then
					playSound(":sarp_assets/audio/interface/" .. math.random(9, 12) .. ".ogg")
				end
			end
		elseif lastItemSlot == slot then
			lastItemSlot = false
		end

		dxDrawRectangle(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, slotColor)

		if actionBarItems[slot].itemId and actionBarItems[slot].amount then
			drawItemPicture(actionBarItems[slot], x, y)
			dxDrawText(actionBarItems[slot].amount, x + defaultSettings.slotBoxWidth - 6, y + defaultSettings.slotBoxHeight - 15, x + defaultSettings.slotBoxWidth, y + defaultSettings.slotBoxHeight - 15 + 5, tocolor(255, 255, 255), 0.375, Roboto, "right")
		else
			dxDrawImage(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, "files/noitem.png")
		end
	else
		local slotColor = tocolor(53, 53, 53, 200)

		if getKeyState(slot + 1) or cx >= x and cx <= x + defaultSettings.slotBoxWidth and cy >= y and cy <= y + defaultSettings.slotBoxHeight then
			if not editHud then
				slotColor = tocolor(50, 179, 239, 200)
			end
		end

		dxDrawRectangle(x, y, defaultSettings.slotBoxWidth, defaultSettings.slotBoxHeight, slotColor)
	end
end

addEvent("movedItemInInventory", true)
addEventHandler("movedItemInInventory", getRootElement(),
	function ()
		for i = 0, slotLimit - 1 do
			actionBarItems[i] = {}

			for k, v in pairs(itemsTable.player) do
				if actionBarSlots[i] == v.dbID then
					actionBarItems[i].slot = tonumber(v.slot)
					actionBarItems[i].itemId = tonumber(v.itemId)
					actionBarItems[i].amount = tonumber(v.amount)
					actionBarItems[i].data1 = tonumber(v.data1)
					actionBarItems[i].data2 = tonumber(v.data2)
					actionBarItems[i].data3 = tonumber(v.data3)
					break
				end
			end
		end
	end
)