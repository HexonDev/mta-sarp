pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

exports.sarp_admin:addAdminCommand("nearbyshoppeds", 6, "Közelben lévő Bolt NPC-k")
addCommandHandler("nearbyshoppeds",
	function(commandName, maxdist)
		if getElementData(localPlayer, "acc.adminLevel") >= 6 then
			maxdist = tonumber(maxdist) or 15

			if not maxdist then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [ < távolság > ]", 0, 0, 0, true)
			else
				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local peds = {}

				for k, v in pairs(getElementsByType("ped", getRootElement(), true)) do
					if getElementData(v, "pedId") then
						local pedPosX, pedPosY, pedPosZ = getElementPosition(v)
						local dist = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, pedPosX, pedPosY, pedPosZ)

						if dist <= maxdist then
							table.insert(peds, {getElementData(v, "pedId"), getElementData(v, "visibleName"), math.floor(dist * 1000) / 1000})
						end
					end
				end

				if #peds > 0 then
					outputChatBox(exports.sarp_core:getServerTag("admin") .. "Közeledben lévő pedek (" .. maxdist .. " yard):", 0, 0, 0, true)

					for k, v in ipairs(peds) do
						outputChatBox("    * #32b3efAzonosító: #ffffff" .. v[1] .. " | #32b3efNév: #ffffff" .. utf8.gsub(v[2], "_", " ") .. " | #32b3efTávolság: #ffffff" .. v[3] .. " yard", 255, 255, 255, true)
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("admin") .. "Nincs egyetlen ped sem a közeledben.", 0, 0, 0, true)
				end
			end
		end
	end)

local screenX, screenY = guiGetScreenSize()

local responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

local function respc(x)
	return math.ceil(x * responsiveMultipler)
end

local itemNames = {}
local nonStackableItems = {}

local currentPedId = false
local currentColShape = false
local currentPedInterior = false
local currentBalance = 0
local currentCategories = {}
local currentItems = {}
local currentItemsEx = {}

local RobotoFont = false
local RobotoLighter = false
local IconsFont = false

local isOwner = false
local panelState = false

local maxVisible = 10
local currentOffset = 0

local originalData = false
local haveChanges = false

local itemsCopy = {}
local menuContainer = {}
local collapsedCategories = {}
local visibleCount = 0

local selectedItemAction = false
local selectedActionItem = false

local cartOffset = 0
local cartItems = {}

local promptDatas = false

addEventHandler("onClientResourceStart", getRootElement(),
	function(res)
		if getResourceName(res) == "sarp_inventory" then
			itemNames = exports.sarp_inventory:getItemNameList()
			nonStackableItems = exports.sarp_inventory:getNonStackableItems()
		elseif source == getResourceRootElement() then
			local inventory = getResourceFromName("sarp_inventory")

			if getResourceState(inventory) == "running" then
				itemNames = exports.sarp_inventory:getItemNameList()
				nonStackableItems = exports.sarp_inventory:getNonStackableItems()
			end
		end
	end)

addEventHandler("onClientClick", getRootElement(),
	function(button, state, cx, cy, wx, wy, wz, element)
		if isElement(element) and not currentPedId and button == "right" and state == "up" then
			local pedId = getElementData(element, "pedId")

			if pedId then
				local colshape = getElementData(element, "pedColShape")

				if isElementWithinColShape(localPlayer, colshape) then
					currentPedId = pedId
					currentColShape = colshape
					currentPedInterior = false

					triggerServerEvent("requestPedItemList", localPlayer, pedId)

					RobotoFont = dxCreateFont(":sarp_assets/fonts/Roboto-Regular.ttf", respc(15), false, "antialiased")
					RobotoLighter = dxCreateFont(":sarp_assets/fonts/Roboto-Light.ttf", respc(15), false, "antialiased")
					IconsFont = dxCreateFont("files/Icons.otf", respc(13), false, "antialiased")

					showCursor(true)

					isOwner = false
					currentBalance = 0
					currentCategories = {}
					currentItems = {}
					currentItemsEx = {}
					panelState = true
					currentOffset = 0
					haveChanges = false
					originalData = false
					itemsCopy = {}
					menuContainer = {}
					collapsedCategories = {}
					visibleCount = 0
					selectedItemAction = false
					selectedActionItem = false
					fakeInputs = {}
					selectedInput = false
					cartItems = {}
					cartOffset = 0
					promptDatas = false

					addEventHandler("onClientRender", getRootElement(), renderTheShop)
					addEventHandler("onClientClick", getRootElement(), shopClickHandler)
					addEventHandler("onClientKey", getRootElement(), shopKeyHandler)
					addEventHandler("onClientCharacter", getRootElement(), shopCharacterHandler)
				end
			end
		end
	end)

addEventHandler("onClientColShapeLeave", getRootElement(),
	function(element)
		if element == localPlayer and currentPedId and currentColShape == source then
			unloadShop()
		end
	end)

function unloadShop()
	removeEventHandler("onClientRender", getRootElement(), renderTheShop)
	removeEventHandler("onClientClick", getRootElement(), shopClickHandler)
	removeEventHandler("onClientKey", getRootElement(), shopKeyHandler)
	removeEventHandler("onClientCharacter", getRootElement(), shopCharacterHandler)

	if isElement(RobotoFont) then
		destroyElement(RobotoFont)
		RobotoFont = nil
	end

	if isElement(RobotoLighter) then
		destroyElement(RobotoLighter)
		RobotoLighter = nil
	end

	if isElement(IconsFont) then
		destroyElement(IconsFont)
		IconsFont = nil
	end

	currentPedId = false
	currentColShape = false
	currentPedInterior = false
	isOwner = false
	currentBalance = 0
	currentCategories = {}
	currentItems = {}
	currentItemsEx = {}
	panelState = false
	currentOffset = 0
	haveChanges = false
	originalData = false
	itemsCopy = {}
	menuContainer = {}
	collapsedCategories = {}
	visibleCount = 0
	selectedItemAction = false
	selectedActionItem = false
	selectedInput = false
	cartItems = {}
	cartOffset = 0
	promptDatas = false

	showCursor(false)
end

function checkOwnership()
	isOwner = false

	if tonumber(currentPedInterior) then
		if exports.sarp_interiors:getInteriorOwner(currentPedInterior) == getElementData(localPlayer, "char.ID") or (getElementData(localPlayer, "acc.adminLevel") >= 6 and getElementData(localPlayer, "adminDuty")) then
			isOwner = true
		end
	end

	return isOwner
end

addEvent("gotPedItems", true)
addEventHandler("gotPedItems", getRootElement(),
	function(pedId, balance, cats, items, interiorId)
		currentPedId = pedId
		currentBalance = balance
		currentCategories = cats
		currentItems = items
		currentPedInterior = interiorId

		for k, v in pairs(items) do
			-- ha megszűnne az az item ami a készleten volt
			if not itemNames[k] or not availableItems[k] then
				currentItems[k] = nil
			end
			-- ha a kategória kikerülne vagy az admin elvenné az adott kategóriát a pedtől
			if not itemCategories[k] or not currentCategories[itemCategories[k]] then
				currentItems[k] = nil
			end
		end

		for k, v in pairs(currentItems) do
			table.insert(currentItemsEx, {k, v})
		end

		for k, v in pairs(availableItems) do
			table.insert(itemsCopy, {k, itemCategories[k], mainCategories[itemCategories[k]]})
		end

		table.sort(itemsCopy,
			function(a, b)
				return a[3] < b[3] or a[3] == b[3] and itemNames[a[1]] < itemNames[b[1]]
			end)

		collapseCategories()

		checkOwnership()
	end)

addEvent("refreshPedItemStock", true)
addEventHandler("refreshPedItemStock", getRootElement(),
	function(itemId, newAmount, newBalance)
		if currentItems[itemId] then
			currentItems[itemId][2] = newAmount

			currentItemsEx = {}

			for k, v in pairs(currentItems) do
				table.insert(currentItemsEx, {k, v})
			end
		end

		currentBalance = newBalance
	end)

addEvent("refreshPedItemPrice", true)
addEventHandler("refreshPedItemPrice", getRootElement(),
	function(itemId, newAmount)
		if currentItems[itemId] then
			currentItems[itemId][1] = newAmount

			currentItemsEx = {}

			for k, v in pairs(currentItems) do
				table.insert(currentItemsEx, {k, v})
			end
		end
	end)

addEvent("setPedBalance", true)
addEventHandler("setPedBalance", getRootElement(),
	function(newAmount)
		currentBalance = newAmount
	end)

function formatNumber(amount, stepper)
	local left, center, right = string.match(math.floor(amount), "^([^%d]*%d)(%d*)(.-)$")
	return left .. string.reverse(string.gsub(string.reverse(center), "(%d%d%d)", "%1" .. (stepper or " "))) .. right
end

function collapseCategories()
	local categories = {}
	local lastCategoryId = 0

	menuContainer = {}
	visibleCount = 0
	selectedItemAction = false
	selectedActionItem = false

	for k = 1, #itemsCopy do
		local v = itemsCopy[k]

		if v then
			local categoryId = v[2]
			local categoryName = v[3]

			if currentCategories[categoryId] then
				if not categories[categoryName] then
					categories[categoryName] = true

					table.insert(menuContainer, {"category", categoryName, collapsedCategories[categoryName]})

					lastCategoryId = #menuContainer
					visibleCount = visibleCount + 1
				end

				if menuContainer[lastCategoryId][3] then
					local itemId = v[1]

					if currentItems[itemId] then
						table.insert(menuContainer, {"haveitem", itemId})
					else
						table.insert(menuContainer, {"noitem", itemId})
					end

					visibleCount = visibleCount + 1
				end
			end
		end
	end

	if visibleCount == 0 then
		table.insert(menuContainer, {"Nincsenek kategóriák."})
		visibleCount = 1
	end

	if visibleCount > maxVisible then
		if currentOffset > visibleCount - maxVisible then
			currentOffset = visibleCount - maxVisible
		end
	else
		currentOffset = 0
	end
end

function renderTheShop()
	buttons = {}

	-- megerősítő ablak
	if promptDatas then
		local _, newlines = utf8.gsub(promptDatas["theQuestion"], "\n", "")
		local sx = dxGetTextWidth(promptDatas["theQuestion"], 1, RobotoLighter, true) + respc(40)
		local sy = respc(120) + newlines * dxGetFontHeight(1, RobotoLighter)
		local x, y = screenX / 2 - sx / 2, screenY / 2 - sy / 2

		dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240))

		dxDrawText(promptDatas["theQuestion"], x, y + respc(20), x + sx, y + respc(20), tocolor(255, 255, 255), 1, RobotoLighter, "center", "top", false, false, false, true)

		local sizeForButton = (sx - respc(60)) / 2

		y = y + sy - respc(40) - respc(20)

		drawButton2("acceptPrompt", "Igen", x + respc(20), y, sizeForButton, respc(40), 124, 197, 118, 1, RobotoLighter, 1)

		drawButton2("declinePrompt", "Nem", x + respc(40) + sizeForButton, y, sizeForButton, respc(40), 215, 89, 89, 1, RobotoLighter, 1)
	-- admin mód
	elseif panelState == "setcategories" then
		local sx, sy = respc(600), respc(480)
		local x, y = screenX / 2 - sx / 2, screenY / 2 - sy / 2

		-- ** Háttér
		dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240))

		-- ** Cím
		local titleSize = respc(40)
		local logoSize = titleSize * 0.75
		local logoOffset = titleSize / 2 - logoSize / 2

		dxDrawImage(math.floor(x + logoOffset), math.floor(y + logoOffset), logoSize, logoSize, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
		dxDrawText("Bolt - Ped kategóriák kezelése", x + logoOffset * 2 + logoSize, y, 0, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")

		-- ** Kilépés
		if activeButton == "exit" then
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(215, 89, 89))
			
			if getKeyState("mouse1") then
				unloadShop()
				return
			end
		else
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(255, 255, 255))
		end

		buttons["exit"] = {x + sx - respc(32) - logoOffset, y + titleSize / 2 - respc(16), respc(32), respc(32)}

		-- ** Elválasztó
		y = y + titleSize

		dxDrawRectangle(x + respc(5), y, sx - respc(10), respc(2), tocolor(255, 255, 255, 50))

		-- ** Content
		local sizeForRow = (sy - titleSize - respc(2) - respc(10)) / maxVisible

		y = y + respc(7)

		local y2 = y

		for k = 1, maxVisible do
			local x2 = x + respc(5)
			local sx2 = sx - respc(10)

			if activeButton == "setcat:" .. k + currentOffset then
				if not currentCategories[k + currentOffset] then
					dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(200, 50, 50, 50))
				else
					dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(50, 200, 50, 50))
				end
			elseif k % 2 ~= currentOffset % 2 then
				dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(0, 0, 0, 75))
			else
				dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(0, 0, 0, 50))
			end

			local v = mainCategories[k + currentOffset]

			if v then
				dxDrawText(v, x2 + respc(15), y, x2 + sx2, y + sizeForRow, tocolor(255, 255, 255), 1, RobotoFont, "left", "center")

				if not currentCategories[k + currentOffset] then
					dxDrawRectangle(x2, y, respc(5), sizeForRow, tocolor(200, 50, 50))
					dxDrawText("[NINCS ENGEDÉLYEZVE]", x2, y, x2 + sx2 - respc(10), y + sizeForRow, tocolor(200, 50, 50), 0.8, RobotoFont, "right", "center")
					--drawButton("addcat:" .. k + currentOffset, "Hozzáadás", x2 + sx2 - respc(160) - respc(10), y + respc(2), respc(160), sizeForRow - respc(4), 50, 179, 239, 1, RobotoLighter, 0.75, "", IconsFont, 0.75)
				else
					dxDrawRectangle(x2, y, respc(5), sizeForRow, tocolor(50, 200, 50))
					dxDrawText("[ENGEDÉLYEZVE]", x2, y, x2 + sx2 - respc(10), y + sizeForRow, tocolor(50, 200, 50), 0.8, RobotoFont, "right", "center")
					--drawButton("removecat:" .. k + currentOffset, "Eltávolítás", x2 + sx2 - respc(160) - respc(10), y + respc(2), respc(160), sizeForRow - respc(4), 200, 50, 50, 1, RobotoLighter, 0.75, "", IconsFont, 0.75)
				end

				buttons["setcat:" .. k + currentOffset] = {x2, y, sx2, sizeForRow}
			end

			y = y + sizeForRow
		end

		if #mainCategories > maxVisible then
			local totalSize = sizeForRow * maxVisible

			dxDrawRectangle(x + sx - respc(10), y2, respc(5), totalSize, tocolor(0, 0, 0, 100))
			dxDrawRectangle(x + sx - respc(10), y2 + (totalSize / #mainCategories) * math.min(currentOffset, #mainCategories - maxVisible), respc(5), (totalSize / #mainCategories) * maxVisible, tocolor(50, 179, 239))
		end

		if haveChanges then
			y = y2 + sy - titleSize - respc(7)

			dxDrawRectangle(x, y, sx, titleSize, tocolor(31, 31, 31, 240))

			if activeButton == "savecats" then
				dxDrawRectangle(x, y, sx, titleSize, tocolor(7, 112, 196, 175))
			else
				dxDrawRectangle(x, y, sx, titleSize, tocolor(7, 112, 196, 125))
			end

			dxDrawText("VÁLTOZTATÁSOK MENTÉSE", x, y, x + sx, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "center", "center")

			buttons["savecats"] = {x, y, sx, titleSize}
		end
	-- tulajdonosi mód
	elseif panelState == "ownermode" then
		local sx, sy = respc(1000), respc(480)
		local x, y = screenX / 2 - sx / 2, screenY / 2 - sy / 2

		-- ** Háttér
		dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240))

		-- ** Cím
		local titleSize = respc(40)
		local logoSize = titleSize * 0.75
		local logoOffset = titleSize / 2 - logoSize / 2

		dxDrawImage(math.floor(x + logoOffset), math.floor(y + logoOffset), logoSize, logoSize, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))

		local titleText

		if currentPedInterior > 0 then
			titleText = "Bolt - Tulajdonosi mód"
			dxDrawText(titleText, x + logoOffset * 2 + logoSize, y, 0, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")
		else
			titleText = "Bolt - Adminisztrátori mód (Állam NPC)"
			dxDrawText(titleText, x + logoOffset * 2 + logoSize, y, 0, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")
		end

		local buttonPosX = x + logoOffset * 2 + logoSize + respc(10) + dxGetTextWidth(titleText, 1, RobotoLighter)

		if isOwner then
			drawButton2("changeOwnerMode", "Vásárlói mód", buttonPosX, y + logoOffset, respc(230), logoSize, 7, 112, 196, 1, RobotoLighter, 1)

			buttonPosX = buttonPosX + respc(5) + respc(230)
		end

		if getElementData(localPlayer, "acc.adminLevel") >= 6 and getElementData(localPlayer, "adminDuty") then
			drawButton2("adminmode", "Kategóriák beállítása", buttonPosX, y + logoOffset, respc(230), logoSize, 200, 50, 50, 1, RobotoLighter, 1)
		end

		-- ** Kilépés
		if activeButton == "exit" then
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(215, 89, 89))
			
			if getKeyState("mouse1") then
				unloadShop()
				return
			end
		else
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(255, 255, 255))
		end

		buttons["exit"] = {x + sx - respc(32) - logoOffset, y + titleSize / 2 - respc(16), respc(32), respc(32)}

		-- ** Elválasztó
		y = y + titleSize

		dxDrawRectangle(x + respc(5), y, sx - respc(10), respc(2), tocolor(255, 255, 255, 50))

		-- ** Content
		local sizeForRow = (sy - titleSize - respc(2) - respc(10)) / maxVisible

		y = y + respc(7)

		local y2 = y

		for k = 1, maxVisible do
			local x2 = x + respc(5)
			local sx2 = sx - respc(10)
			local colorOfRow

			if k % 2 ~= currentOffset % 2 then
				colorOfRow = tocolor(53, 53, 53, 100)
			else
				colorOfRow = tocolor(53, 53, 53, 50)
			end

			local v = menuContainer[k + currentOffset]

			if v then
				if v[1] == "category" then
					local caretSize = sizeForRow * 0.75

					if v[3] then
						colorOfRow = tocolor(7, 112, 196)
					elseif activeButton == "togglecat:" .. k + currentOffset then
						colorOfRow = tocolor(53, 53, 53)
					end

					dxDrawRectangle(x2, y, sx2, sizeForRow, colorOfRow)

					if not v[3] then
						dxDrawImageSection(math.floor(x2), math.floor(y + sizeForRow / 2 - caretSize / 2), caretSize, caretSize, 0, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(255, 255, 255))
					else
						dxDrawImageSection(math.floor(x2), math.floor(y + sizeForRow / 2 - caretSize / 2), caretSize, caretSize, 0, 0, 32, 32, "files/buttons.png", 90, 0, 0, tocolor(255, 255, 255))
					end

					dxDrawText(v[2], x2 + caretSize, y, x2 + sx2, y + sizeForRow, tocolor(255, 255, 255), 1, RobotoFont, "left", "center")

					buttons["togglecat:" .. k + currentOffset] = {x2, y, sx2, sizeForRow}
				elseif v[1] == "noitem" and v[2] then
					local itemId = v[2]
					local itemSize = sizeForRow * 0.75

					dxDrawRectangle(x2, y, sx2, sizeForRow, colorOfRow)

					dxDrawImage(math.floor(x2 + respc(35)), math.floor(y + sizeForRow / 2 - itemSize / 2), itemSize, itemSize, ":sarp_inventory/files/items/" .. itemId .. ".png")
					dxDrawText(itemNames[v[2]], x2 + respc(45) + itemSize, y, x2 + sx2, y + sizeForRow, tocolor(255, 255, 255), 0.8, RobotoFont, "left", "center")

					local buttonSizeY = sizeForRow * 0.75

					drawButton2(
						"additem:" .. k + currentOffset,
						"Hozzáadás",
						x2 + sx2 - respc(120) - respc(10),
						y + sizeForRow / 2 - buttonSizeY / 2,
						respc(120),
						buttonSizeY,
						7, 112, 196,
						1,
						RobotoLighter, 0.8
					)
				elseif v[1] == "haveitem" and v[2] and currentItems[v[2]] then
					local itemId = v[2]
					local data = currentItems[itemId]
					local itemSize = sizeForRow * 0.75

					if activeButton == "togglesub:" .. k + currentOffset then
						colorOfRow = tocolor(53, 53, 53)
					end

					dxDrawRectangle(x2, y, sx2, sizeForRow, colorOfRow)

					dxDrawImage(math.floor(x2 + respc(35)), math.floor(y + sizeForRow / 2 - itemSize / 2), itemSize, itemSize, ":sarp_inventory/files/items/" .. itemId .. ".png")
					dxDrawText(itemNames[v[2]], x2 + respc(45) + itemSize, y, x2 + sx2, y + sizeForRow, tocolor(255, 255, 255), 0.8, RobotoFont, "left", "center")

					local buttonSizeY = sizeForRow * 0.75
					local buttonPosY = y + sizeForRow / 2 - buttonSizeY / 2

					if selectedActionItem == itemId then
						local buttonPosX = x2 + sx2 - respc(10) - respc(50)

						drawButton2("applyitemaction", "OK", buttonPosX, buttonPosY, respc(50), buttonSizeY, 7, 112, 196, 1, RobotoLighter, 0.8)

						buttonPosX = buttonPosX - respc(5) - respc(65)

						if selectedItemAction == "addstock" then
							dxDrawText("Rendelés:", x2, y, x2 + (buttonPosX - x2 - respc(10)), y + sizeForRow, tocolor(255, 255, 255, 255), 0.8, RobotoFont, "right", "center")

							drawInput("itemaction|6", data[2], buttonPosX, buttonPosY, respc(65), buttonSizeY, RobotoLighter, 0.8)
						elseif selectedItemAction == "setprice" then
							dxDrawText("Beárazás:", x2, y, x2 + (buttonPosX - x2 - respc(10)), y + sizeForRow, tocolor(255, 255, 255, 255), 0.8, RobotoFont, "right", "center")

							drawInput("itemaction|6", data[1], buttonPosX, buttonPosY, respc(65), buttonSizeY, RobotoLighter, 0.8)
						end
					else
						local buttonPosX = x2 + sx2 - respc(40) - respc(10)
						drawButton2("removeitem:" .. k + currentOffset, false, buttonPosX, buttonPosY, respc(40), buttonSizeY, 200, 50, 50, 1, RobotoLighter, 0.8, "", IconsFont, 1)

						if currentPedInterior > 0 then
							buttonPosX = buttonPosX - respc(5) - respc(40)
							drawButton2("addstock:" .. k + currentOffset, false, buttonPosX, buttonPosY, respc(40), buttonSizeY, 7, 112, 196, 1, RobotoLighter, 0.8, "", IconsFont, 1)
						end

						buttonPosX = buttonPosX - respc(5) - respc(40)
						drawButton2("setprice:" .. k + currentOffset, false, buttonPosX, buttonPosY, respc(40), buttonSizeY, 7, 112, 196, 1, RobotoLighter, 0.8, "", IconsFont, 1)

						if currentPedInterior > 0 then
							dxDrawText("Ár: " .. data[1] .. " $ | Nagyker ár: " .. itemBasePrices[itemId] .. " $ | Készleten: " .. data[2] .. " db", x2, y, x2 + (buttonPosX - x2 - respc(10)), y + sizeForRow, tocolor(225, 225, 225, 225), 0.8, RobotoFont, "right", "center")
						else
							dxDrawText("Ár: " .. data[1] .. " $ | Nagyker ár: " .. itemBasePrices[itemId] .. " $", x2, y, x2 + (buttonPosX - x2 - respc(10)), y + sizeForRow, tocolor(225, 225, 225, 225), 0.8, RobotoFont, "right", "center")
						end
					end
				else
					dxDrawText(v[1], x2 + respc(15), y, 0, y + sizeForRow, tocolor(175, 175, 175, 175), 1, RobotoFont, "left", "center")
				end
			else
				dxDrawRectangle(x2, y, sx2, sizeForRow, colorOfRow)
			end

			y = y + sizeForRow
		end

		if visibleCount > maxVisible then
			local totalSize = sizeForRow * maxVisible

			dxDrawRectangle(x + sx - respc(10), y2, respc(5), totalSize, tocolor(0, 0, 0, 100))
			dxDrawRectangle(x + sx - respc(10), y2 + (totalSize / visibleCount) * math.min(currentOffset, visibleCount - maxVisible), respc(5), (totalSize / visibleCount) * maxVisible, tocolor(50, 179, 239))
		end

		if currentPedInterior > 0 then
			y = y2 + sy - titleSize - respc(7)

			dxDrawRectangle(x, y, sx, titleSize + respc(5), tocolor(31, 31, 31, 240))

			dxDrawText("Jelenlegi egyenleg: " .. formatNumber(currentBalance) .. " $", x + respc(10), y, 0, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")

			if selectedItemAction == "putInMoney" then
				local buttonPosX = x + sx - respc(10) - respc(140)

				drawButton2("putInMoneyOk", "Befizetés", buttonPosX, y, respc(140), titleSize, 7, 112, 196, 1, RobotoLighter, 1)

				buttonPosX = buttonPosX - respc(10) - respc(140)

				drawInput("balance|7", "Összeg", buttonPosX, y, respc(140), titleSize, RobotoLighter, 1)
			elseif selectedItemAction == "getOutMoney" then
				local buttonPosX = x + sx - respc(10) - respc(140)

				drawButton2("getOutMoneyOk", "Kifizetés", buttonPosX, y, respc(140), titleSize, 200, 50, 50, 1, RobotoLighter, 1)

				buttonPosX = buttonPosX - respc(10) - respc(140)

				drawInput("balance|7", "Összeg", buttonPosX, y, respc(140), titleSize, RobotoLighter, 1)
			else
				local buttonPosX = x + sx - respc(10) - respc(140)
				drawButton2("getOutMoney", "Kifizetés", buttonPosX, y, respc(140), titleSize, 200, 50, 50, 1, RobotoLighter, 1)

				buttonPosX = buttonPosX - respc(10) - respc(140)
				drawButton2("putInMoney", "Befizetés", buttonPosX, y, respc(140), titleSize, 7, 112, 196, 1, RobotoLighter, 1)
			end
		end
	-- vásárlói mód
	elseif panelState then
		local sx, sy = respc(1000), respc(580)
		local x, y = screenX / 2 - sx / 2, screenY / 2 - sy / 2

		-- ** Háttér
		dxDrawRectangle(x, y, sx, sy, tocolor(31, 31, 31, 240))

		-- ** Cím
		local titleSize = respc(40)
		local logoSize = titleSize * 0.75
		local logoOffset = titleSize / 2 - logoSize / 2

		dxDrawImage(math.floor(x + logoOffset), math.floor(y + logoOffset), logoSize, logoSize, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
		dxDrawText("Bolt", x + logoOffset * 2 + logoSize, y, 0, y + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")

		local buttonPosX = x + logoOffset * 2 + logoSize + respc(10) + dxGetTextWidth("Bolt", 1, RobotoLighter)

		if isOwner then
			if currentPedInterior > 0 then
				drawButton2("changeOwnerMode", "Tulajdonosi mód", buttonPosX, y + logoOffset, respc(230), logoSize, 7, 112, 196, 1, RobotoLighter, 1)
			else
				drawButton2("changeOwnerMode", "Bolt kezelése", buttonPosX, y + logoOffset, respc(230), logoSize, 7, 112, 196, 1, RobotoLighter, 1)
			end

			buttonPosX = buttonPosX + respc(5) + respc(230)
		end

		if getElementData(localPlayer, "acc.adminLevel") >= 6 and getElementData(localPlayer, "adminDuty") then
			drawButton2("adminmode", "Kategóriák beállítása", buttonPosX, y + logoOffset, respc(230), logoSize, 200, 50, 50, 1, RobotoLighter, 1)
		end

		-- ** Kilépés
		if activeButton == "exit" then
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(215, 89, 89))
			
			if getKeyState("mouse1") then
				unloadShop()
				return
			end
		else
			dxDrawImageSection(math.floor(x + sx - respc(32) - logoOffset), math.floor(y + titleSize / 2 - respc(16)), respc(32), respc(32), 32, 0, 32, 32, "files/buttons.png", 0, 0, 0, tocolor(255, 255, 255))
		end

		buttons["exit"] = {x + sx - respc(32) - logoOffset, y + titleSize / 2 - respc(16), respc(32), respc(32)}

		-- ** Elválasztó
		y = y + titleSize

		dxDrawRectangle(x + respc(5), y, sx - respc(10), respc(2), tocolor(255, 255, 255, 50))

		-- ** Content
		local sizeForRow = (sy - titleSize - respc(5) - respc(20) - respc(30)) / maxVisible

		y = y + respc(7)

		local holderSize = (sx - respc(15)) / 2

		dxDrawText("Jelenlegi kínálat", x + respc(5), y, x + respc(5) + holderSize, y + respc(40), tocolor(255, 255, 255), 1, RobotoFont, "center", "center")

		dxDrawText("Kosár tartalma", x + respc(10) + holderSize, y, x + respc(10) + holderSize * 2, y + respc(40), tocolor(255, 255, 255), 1, RobotoFont, "center", "center")

		y = y + respc(40)

		local y2 = y

		-- ** Jelenlegi kínálat
		for k = 1, maxVisible do
			local x2 = x + respc(5)
			local sx2 = holderSize - respc(5)

			if k % 2 ~= currentOffset % 2 then
				dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(53, 53, 53, 100))
			else
				dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(53, 53, 53, 50))
			end

			local v = currentItemsEx[k + currentOffset]

			if v then
				local itemId = v[1]
				local itemData = v[2]
				local itemSize = sizeForRow * 0.75

				if activeButton == "addtocart:" .. k + currentOffset then
					dxDrawRectangle(x2, y, sx2, sizeForRow, tocolor(53, 53, 53))
				end

				dxDrawImage(math.floor(x2 + respc(5)), math.floor(y + sizeForRow / 2 - itemSize / 2), itemSize, itemSize, ":sarp_inventory/files/items/" .. itemId .. ".png")
				
				dxDrawText(itemNames[itemId], x2 + respc(10) + itemSize, y, x2 + sx2, y + sizeForRow, tocolor(255, 255, 255), 0.8, RobotoFont, "left", "center")

				if currentPedInterior > 0 and (not itemData[2] or itemData[2] == 0) then
					dxDrawText("Nincs készleten", x2, y, x2 + sx2 - respc(10), y + sizeForRow, tocolor(100, 100, 100, 255), 0.75, RobotoFont, "right", "center")
				else
					dxDrawText("Ár: " .. formatNumber(itemData[1]) .. " $/db", x2, y, x2 + sx2 - respc(10), y + sizeForRow, tocolor(200, 200, 200, 200), 0.75, RobotoFont, "right", "center")
				
					buttons["addtocart:" .. k + currentOffset] = {x2, y, sx2, sizeForRow}
				end
			end

			y = y + sizeForRow
		end

		if #currentItemsEx > maxVisible then
			local totalSize = sizeForRow * maxVisible

			dxDrawRectangle(x + respc(5) + holderSize - respc(5), y2, respc(5), totalSize, tocolor(0, 0, 0, 100))
			dxDrawRectangle(x + respc(5) + holderSize - respc(5), y2 + (totalSize / #currentItemsEx) * math.min(currentOffset, #currentItemsEx - maxVisible), respc(5), (totalSize / #currentItemsEx) * maxVisible, tocolor(50, 179, 239))
		end

		-- ** Kosár tartalma
		local y3 = y2

		for k = 1, maxVisible do
			local x2 = x + respc(15) + holderSize
			local sx2 = holderSize - respc(5)

			if k % 2 ~= cartOffset % 2 then
				dxDrawRectangle(x2, y2, sx2, sizeForRow, tocolor(53, 53, 53, 100))
			else
				dxDrawRectangle(x2, y2, sx2, sizeForRow, tocolor(53, 53, 53, 50))
			end

			local v = cartItems[k + cartOffset]

			if v then
				local itemId = v[1]
				local itemAmount = v[2]
				local itemSize = sizeForRow * 0.75

				if activeButton == "removefromcart:" .. k + cartOffset then
					dxDrawRectangle(x2, y2, sx2, sizeForRow, tocolor(53, 53, 53))
				end

				dxDrawImage(math.floor(x2 + respc(5)), math.floor(y2 + sizeForRow / 2 - itemSize / 2), itemSize, itemSize, ":sarp_inventory/files/items/" .. itemId .. ".png")
				
				dxDrawText(itemNames[itemId], x2 + respc(10) + itemSize, y2, x2 + sx2, y2 + sizeForRow, tocolor(255, 255, 255), 0.8, RobotoFont, "left", "center")

				dxDrawText("Kosárban: " .. itemAmount .. " db | Ár: " .. formatNumber(itemAmount * currentItems[itemId][1]) .. " $", x2, y2, x2 + sx2 - respc(10), y2 + sizeForRow, tocolor(200, 200, 200, 200), 0.75, RobotoFont, "right", "center")

				buttons["removefromcart:" .. k + cartOffset] = {x2, y2, sx2, sizeForRow}
			end

			y2 = y2 + sizeForRow
		end

		if #cartItems > maxVisible then
			local totalSize = sizeForRow * maxVisible

			dxDrawRectangle(x + respc(15) + holderSize * 2 - respc(5), y3, respc(5), totalSize, tocolor(0, 0, 0, 100))
			dxDrawRectangle(x + respc(15) + holderSize * 2 - respc(5), y3 + (totalSize / #cartItems) * math.min(cartOffset, #cartItems - maxVisible), respc(5), (totalSize / #cartItems) * maxVisible, tocolor(50, 179, 239))
		end

		if #cartItems > 0 then
			y3 = y3 + sizeForRow * maxVisible + respc(7)

			dxDrawRectangle(x, y3, sx, titleSize + respc(5), tocolor(31, 31, 31, 240))

			dxDrawRectangle(x, y3, sx, 2, tocolor(255, 255, 255))

			y3 = y3 + respc(5)

			local totalPrice = 0

			for k = 1, #cartItems do
				local v = cartItems[k]

				totalPrice = totalPrice + v[2] * currentItems[v[1]][1]
			end

			dxDrawText("Összesen: " .. formatNumber(totalPrice) .. " $", x + respc(10), y3, 0, y3 + titleSize, tocolor(255, 255, 255), 1, RobotoLighter, "left", "center")

			local buttonPosX = x + sx - respc(10) - respc(140)

			drawButton2("buyItems", "Fizetés", buttonPosX, y3, respc(140), titleSize - respc(5), 7, 112, 196, 1, RobotoLighter, 1)
		end
	end

	local relX, relY = getCursorPosition()

	activeButton = false

	if relX and relY then
		relX = relX * screenX
		relY = relY * screenY

		for k, v in pairs(buttons) do
			if relX >= v[1] and relX <= v[1] + v[3] and relY >= v[2] and relY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function showPrompt(question, accept_callback, decline_callback)
	promptDatas = {}
	promptDatas["theQuestion"] = question
	promptDatas["accept"] = accept_callback
	promptDatas["decline"] = decline_callback
end

function shopClickHandler(button, state)
	selectedInput = false

	if currentPedId and button == "left" and state == "up" and activeButton then
		local selected = split(activeButton, ":")

		if selected[1] == "acceptPrompt" then
			if promptDatas["accept"] then
				promptDatas["accept"]()
			end
			
			promptDatas = nil
		elseif selected[1] == "declinePrompt" then
			if promptDatas["decline"] then
				promptDatas["decline"]()
			end

			promptDatas = nil
		elseif selected[1] == "exit" then
			unloadShop()
		elseif selected[1] == "adminmode" then
			if getElementData(localPlayer, "acc.adminLevel") >= 6 and getElementData(localPlayer, "adminDuty") then
				panelState = "setcategories"
			end
		elseif selected[1] == "setcat" then
			if checkOwnership() then
				local id = tonumber(selected[2])

				if not originalData then
					originalData = deepcopy(currentCategories)
				end

				if not currentCategories[id] then
					currentCategories[id] = true
				else
					currentCategories[id] = nil
				end

				if not table_eq(originalData, currentCategories) then
					haveChanges = true
				else
					haveChanges = false
				end
			end
		elseif selected[1] == "savecats" then
			if checkOwnership() then
				haveChanges = false
				originalData = nil

				triggerServerEvent("refreshPedCategories", localPlayer, currentPedId, currentCategories)
			end
		elseif selected[1] == "togglecat" then
			if checkOwnership() then
				local id = tonumber(selected[2])
				local menu = menuContainer[id]

				if menu[1] == "category" then
					local categoryName = menu[2]

					collapsedCategories[categoryName] = not collapsedCategories[categoryName]

					collapseCategories()
				end
			end
		elseif selected[1] == "additem" then
			if checkOwnership() then
				local id = tonumber(selected[2])
				local itemId = menuContainer[id][2]
				
				if itemId then
					currentItems[itemId] = {itemBasePrices[itemId], 0}
					currentItemsEx = {}

					for k, v in pairs(currentItems) do
						table.insert(currentItemsEx, {k, v})
					end

					collapseCategories()

					triggerServerEvent("refreshPedItemList", localPlayer, currentPedId, currentItems)
				end
			end
		elseif selected[1] == "removeitem" then
			if checkOwnership() then
				local id = tonumber(selected[2])
				local itemId = menuContainer[id][2]
				
				if itemId then
					selectedItemAction = false
					selectedActionItem = false

					showPrompt("Biztos vagy benne, hogy törlöd a kiválasztott tételt?",
						function()
							currentItems[itemId] = nil
							currentItemsEx = {}

							for k, v in pairs(currentItems) do
								table.insert(currentItemsEx, {k, v})
							end

							collapseCategories()

							triggerServerEvent("refreshPedItemList", localPlayer, currentPedId, currentItems)
						end)
				end
			end
		elseif selected[1] == "addstock" or selected[1] == "setprice" then
			if checkOwnership() then
				local id = tonumber(selected[2])
				local itemId = menuContainer[id][2]

				if itemId then
					selectedItemAction = selected[1]
					selectedActionItem = itemId
				end
			end
		elseif selected[1] == "input" then
			selectedInput = selected[2]
		elseif selected[1] == "applyitemaction" then
			if checkOwnership() then
				if selectedActionItem then
					if selectedItemAction == "addstock" then
						local itemId = selectedActionItem
						local amount = tonumber(fakeInputs["itemaction|6"])

						fakeInputs["itemaction|6"] = ""

						if amount and amount > 0 then
							showPrompt("Biztos vagy benne, hogy megrendeled a kiválasztott mennyiséget?\nTétel: #32b3ef" .. itemNames[selectedActionItem] .. "\n#ffffffMennyiség: #32b3ef" .. amount .. " db\n#ffffffTeljes ár: #32b3ef" .. formatNumber(amount * itemBasePrices[selectedActionItem]) .. " $",
								function()
									triggerServerEvent("addToPedStock", localPlayer, currentPedId, itemId, amount)
								end)
						end

						selectedActionItem = false
						selectedItemAction = false
					elseif selectedItemAction == "setprice" then
						local amount = tonumber(fakeInputs["itemaction|6"])

						fakeInputs["itemaction|6"] = ""

						if amount and amount > 0 and currentItems[selectedActionItem][1] ~= amount then
							triggerServerEvent("setItemPrice", localPlayer, currentPedId, selectedActionItem, amount)
						end

						selectedActionItem = false
						selectedItemAction = false
					end
				end
			end
		elseif selected[1] == "putInMoney" or selected[1] == "getOutMoney" then
			if checkOwnership() then
				selectedItemAction = selected[1]
			end
		elseif selected[1] == "putInMoneyOk" then
			if checkOwnership() then
				local amount = tonumber(fakeInputs["balance|7"])

				fakeInputs["balance|7"] = ""

				if amount and amount > 0 then
					triggerServerEvent("putInMoney", localPlayer, currentPedId, amount)
				end

				selectedItemAction = false
			end
		elseif selected[1] == "getOutMoneyOk" then
			if checkOwnership() then
				local amount = tonumber(fakeInputs["balance|7"])

				fakeInputs["balance|7"] = ""

				if amount and amount > 0 then
					triggerServerEvent("getOutMoney", localPlayer, currentPedId, amount)
				end

				selectedItemAction = false
			end
		elseif selected[1] == "changeOwnerMode" then
			if checkOwnership() then
				if panelState == "ownermode" then
					panelState = true
				else
					panelState = "ownermode"
				end

				currentOffset = 0
				cartOffset = 0
				cartItems = {}
			end
		elseif selected[1] == "addtocart" then
			local id = tonumber(selected[2])
			local itemId = currentItemsEx[id][1]

			if itemId then
				local sameItem = false

				for k, v in pairs(cartItems) do
					if v[1] == itemId then
						sameItem = k
						break
					end
				end

				if sameItem then
					cartItems[sameItem][2] = cartItems[sameItem][2] + 1

					if currentPedInterior > 0 then
						if cartItems[sameItem][2] > currentItems[itemId][2] then
							cartItems[sameItem][2] = currentItems[itemId][2]
						end
					end
				else
					table.insert(cartItems, {itemId, 1})
				end
			end
		elseif selected[1] == "removefromcart" then
			local id = tonumber(selected[2])
			local itemId = cartItems[id][1]

			if itemId then
				table.remove(cartItems, id)
			end
		elseif selected[1] == "buyItems" then
			if #cartItems > 0 then
				local totalPrice = 0
				local totalSlot = 0
				local totalWeight = 0

				for k = 1, #cartItems do
					local v = cartItems[k]
					local itemId = v[1]
					local amount = v[2]

					totalPrice = totalPrice + amount * currentItems[itemId][1]
					totalWeight = totalWeight + amount * exports.sarp_inventory:getItemWeight(itemId)

					if nonStackableItems[itemId] then
						totalSlot = totalSlot + amount
					else
						totalSlot = totalSlot + 1
					end
				end

				if exports.sarp_core:getMoney(localPlayer) >= totalPrice then
					if exports.sarp_inventory:countEmptySlots() >= totalSlot then
						if exports.sarp_inventory:getCurrentWeight() + totalWeight <= exports.sarp_inventory:getWeightLimit("player", localPlayer) then
							showPrompt("Biztosan megvásárolod a kosárban lévő összes terméket?\nTeljes összeg: #32b3ef" .. formatNumber(totalPrice) .. " $",
								function()
									triggerServerEvent("buyItemsFromPed", localPlayer, currentPedId, cartItems, totalPrice, totalSlot, totalWeight)
									unloadShop()
								end)
						else
							exports.sarp_hud:showInfobox("error", "Nem bírsz el ennyi tárgyat!")
						end
					else
						exports.sarp_hud:showInfobox("error", "Nincs elég hely az inventorydban!")
					end
				else
					exports.sarp_hud:showInfobox("error", "Nincs nálad elegendő pénz!")
				end
			end
		end
	end
end

function shopKeyHandler(key, state)
	if currentPedId then
		if panelState == "setcategories" then
			if #mainCategories > maxVisible then
				if key == "mouse_wheel_down" then
					if currentOffset < #mainCategories - maxVisible then
						currentOffset = currentOffset + maxVisible
					end
				elseif key == "mouse_wheel_up" and currentOffset > 0 then
					currentOffset = currentOffset - maxVisible
				end
			end
		elseif panelState == "ownermode" then
			if visibleCount > maxVisible then
				if key == "mouse_wheel_down" then
					if currentOffset < visibleCount - maxVisible then
						currentOffset = currentOffset + 1
					end
				elseif key == "mouse_wheel_up" and currentOffset > 0 then
					currentOffset = currentOffset - 1
				end
			end
		elseif panelState then
			if #currentItemsEx > maxVisible then
				local cx, cy = getCursorPosition()

				if cx then
					cx, cy = cx * screenX, cy * screenY
				else
					cx, cy = -1, -1
				end

				if cx <= screenX / 2 - respc(5) then
					if key == "mouse_wheel_down" then
						if currentOffset < #currentItemsEx - maxVisible then
							currentOffset = currentOffset + 1
						end
					elseif key == "mouse_wheel_up" and currentOffset > 0 then
						currentOffset = currentOffset - 1
					end
				end
			end

			if #cartItems > maxVisible then
				local cx, cy = getCursorPosition()

				if cx then
					cx, cy = cx * screenX, cy * screenY
				else
					cx, cy = -1, -1
				end

				if cx > screenX / 2 + respc(5) then
					if key == "mouse_wheel_down" then
						if cartOffset < #cartItems - maxVisible then
							cartOffset = cartOffset + 1
						end
					elseif key == "mouse_wheel_up" and cartOffset > 0 then
						cartOffset = cartOffset - 1
					end
				end
			end
		end

		if selectedInput and state and key == "backspace" then
			if utf8.len(fakeInputs[selectedInput]) >= 1 then
				fakeInputs[selectedInput] = utf8.sub(fakeInputs[selectedInput], 1, -2)
			end
		end

		cancelEvent()
	end
end

function shopCharacterHandler(character)
	if selectedInput then
		local selected = split(selectedInput, "|")

		if utf8.len(fakeInputs[selectedInput]) < tonumber(selected[2]) then
			if tonumber(character) then
				fakeInputs[selectedInput] = fakeInputs[selectedInput] .. character
			end
		end
	end
end