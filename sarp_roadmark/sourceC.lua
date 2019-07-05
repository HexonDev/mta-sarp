local screenWidth, screenHeight = guiGetScreenSize()

function reMap(value, low1, high1, low2, high2)
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

local responsiveMultiplier = reMap(screenWidth, 1024, 1920, 0.75, 1)

function resp(value)
	return value * responsiveMultiplier
end

function respc(value)
	return math.ceil(value * responsiveMultiplier)
end

function isCursorWithinArea(cx, cy, x, y, w, h)
	if isCursorShowing() then
		if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
			return true
		end
	end
	
	return false
end

function isEventHandlerAdded(eventName, attachedTo, func)
	if type(eventName) == "string" and  isElement(attachedTo) and type(func) == "function" then
		local isAttached = getEventHandlers(eventName, attachedTo)
		
		if type(isAttached) == "table" and #isAttached > 0 then
			for i, v in ipairs(isAttached) do
				if v == func then
					return true
				end
			end
		end
	end
	
	return false
end

local RobotoFont = dxCreateFont("files/Roboto.ttf", resp(14), false, "antialiased")
local RobotoFontHeight = dxGetFontHeight(1, RobotoFont)
local RobotoLightFont = dxCreateFont("files/Roboto.ttf", resp(15), false, "cleartype")
local RobotoLightFontHeight = dxGetFontHeight(1, RobotoLightFont)

local panelCategoryPages = {}
local panelCategoryOldPages = {}

local roadmarksList = {}

for k,v in pairs(textureData) do
	roadmarksList[k] = {}
	panelCategoryPages[k] = 0
	panelCategoryOldPages[k] = false
	
	for i = 1, v do
		roadmarksList[k][i] = dxCreateTexture("files/marks/" .. k .. "/" .. i .. ".png", "dxt5")
	end
end

local isEditorActive = false
local isPanelActive = false

local panelFadeProgress = 0
local panelFadeIn = false
local panelFadeOut = false

local panelWidth = screenWidth
local panelHeight = respc(140)
local panelPosX = 0
local panelPosY = screenHeight - panelHeight

local panelVisibleItems = math.ceil((screenWidth / 140) + 1)
local panelItemWidth = screenWidth / panelVisibleItems
local panelItemHeight = panelHeight
local panelItemScale = 0.75

local activePanelCategory = 1
local selectedPanelItem = false

local activeItem = false
local snapRotation = false

local adminMode = false

local menuPaddingX = 12
local menuPaddingY = 8
local menuIconSize = 36
local menuIconSpace = 30
local menuWidth = menuPaddingX * 2 + menuIconSize * #textureData + menuIconSpace * (#textureData - 1)
local menuHeight = menuPaddingY * 2 + menuIconSize
local menuPosY = panelPosY - menuHeight

local colorPanel = {
	isActive = false,
	hue = 0.5,
	saturation = 0,
	lightness = 1,
	colorInputs = {
		rgb = {
			width = dxGetTextWidth("255", 1, RobotoFont) + 10,
			red = 255,
			green = 255,
			blue = 255
		},
		hex = {
			width = dxGetTextWidth("#FFFFFF", 1, RobotoFont) + 10,
			hex = "#FFFFFF"
		}
	},
	selectedColor = tocolor(255, 255, 255)
}

colorPanel.width = 320
colorPanel.height = 140
colorPanel.posX = (screenWidth - colorPanel.width) * 0.5
colorPanel.posY = screenHeight - panelHeight - menuHeight - colorPanel.height
colorPanel.barHeight = 25
colorPanel.paletteWidth = colorPanel.width - 20
colorPanel.paletteHeight = colorPanel.height - 20 - colorPanel.barHeight * 2
colorPanel.palettePosX = colorPanel.posX + 10
colorPanel.palettePosY = colorPanel.posY + 10
colorPanel.inputPosY = colorPanel.palettePosY + colorPanel.paletteHeight + 5
colorPanel.luminancePosY = colorPanel.inputPosY + colorPanel.barHeight + 5
colorPanel.luminanceHeight = 10

local activeColorInput = false
local hoveredInputfield = false

local mainMenuWidth = 0
local mainMenuPosX = screenWidth + 1000

local mainMenuData = {}
function processMainMenu()
	mainMenuData = {
		{"exit", "Kilépés mentés nélkül", {215, 89, 89}},
		{"save", "Változtatások mentése", {124, 197, 118}}
	}
	
	if activeItem then
		if not activeItem.isStripe then
			local snapImage = "snapoffr"
			local snapText = "kikapcsolva"
			if snapRotation == 5 then
				snapImage = "snap1r"
				snapText = "5°"
			elseif snapRotation == 10 then
				snapImage = "snap2r"
				snapText = "10°"
			elseif snapRotation == 90 then
				snapImage = "snap3r"
				snapText = "90°"
			end

			table.insert(mainMenuData, {snapImage, "Forgatási illesztés: " .. snapText})
		end
		
		local colorState = colorPanel.isActive and "bezárása" or "megnyitása"
		table.insert(mainMenuData, {"color", (getElementData(localPlayer, "acc.adminLevel") or 0) >= adminLevelForCustomColors and "Színkeverő " .. colorState or "Szín panel " .. colorState})
	end
	
	if (getElementData(localPlayer, "acc.adminLevel") or 0) >= 1 then
		if adminMode then
			mainMenuData[2] = nil
			mainMenuData[3] = nil
		end
		table.insert(mainMenuData, {"admin", "Adminisztrátori mód " .. (adminMode and "kikapcsolása" or "bekapcsolása")})
	else
		adminMode = false
	end
	
	mainMenuWidth = menuPaddingX * 2 + menuIconSize * #mainMenuData + menuIconSpace * (#mainMenuData - 1)
	mainMenuPosX = screenWidth - mainMenuWidth
end
processMainMenu()

local textBoxWidth = menuPaddingX * 2 + dxGetTextWidth(categoryNames[activePanelCategory], 1, RobotoFont)
local textBoxWidthTarget = textBoxWidth

local tooltipBoxWidth = 0
local tooltipBoxWidthTarget = 0

local scrollbarWidth = screenWidth
local scrollbarHeight = 5
local scrollbarPosX = 0
local scrollbarPosY = screenHeight - scrollbarHeight
local scrollbarPosition = 0
local scrollbarInterpolationTick = false

local activeDirectX = false
local lastActiveDirectX = false

local cursorX = -1
local cursorY = -1

local realRoadmarks = {}

local rotateIcon = dxCreateTexture("files/icons2/rotate.png")
local scaleIcon = dxCreateTexture("files/icons2/scale.png")
local moveIcon = dxCreateTexture("files/icons2/move.png")

local currentInterior = getElementInterior(localPlayer)
local currentDimension = getElementDimension(localPlayer)

local size32 = respc(32)
local alpha255 = 0

local lastPreRotation = 0
local rotationSoundTick = 0

local streamerThread = false
local streamedRoadmarks = {}

local streamedStripes = {}
local stripeSelection = false
local newStripePoint = false

addCommandHandler("roadmarks",
	function ()
		toggleRoadmarksPanel(true)
	end
)

function toggleRoadmarksPanel(state)
	if state == "exitByRender" then
		isPanelActive = false
		
		if isEventHandlerAdded("onClientRender", getRootElement(), onClientPanelRender) then
			removeEventHandler("onClientRender", getRootElement(), onClientPanelRender)
			removeEventHandler("onClientPreRender", getRootElement(), onClientPanelPreRender)
			removeEventHandler("onClientClick", getRootElement(), onClientPanelClick)
			removeEventHandler("onClientDoubleClick", getRootElement(), onClientPanelDoubleClick)
			removeEventHandler("onClientKey", getRootElement(), onClientPanelKey)
			removeEventHandler("onClientCharacter", getRootElement(), onClientPanelCharacter)
		end
	elseif state then
		if isPanelActive ~= state then
			isPanelActive = true
			
			if not isEventHandlerAdded("onClientRender", getRootElement(), onClientPanelRender) then
				addEventHandler("onClientRender", getRootElement(), onClientPanelRender)
				addEventHandler("onClientPreRender", getRootElement(), onClientPanelPreRender)
				addEventHandler("onClientClick", getRootElement(), onClientPanelClick)
				addEventHandler("onClientDoubleClick", getRootElement(), onClientPanelDoubleClick)
				addEventHandler("onClientKey", getRootElement(), onClientPanelKey)
				addEventHandler("onClientCharacter", getRootElement(), onClientPanelCharacter)
			end
			
			panelFadeIn = getTickCount()
			panelFadeOut = false
		end
	else
		isPanelActive = false
		panelFadeIn = false
		panelFadeOut = getTickCount()
	end
end

function onClientPanelRender()
	lastActiveDirectX = activeDirectX
	activeDirectX = false
	
	if hoveredInputfield then
		hoveredInputfield = false
	end
	
	cursorX, cursorY = -1, -1
	if isCursorShowing() then
		local relativeX, relativeY = getCursorPosition()
		cursorX, cursorY = relativeX * screenWidth, relativeY * screenHeight
	end
	
	local currentTick = getTickCount()
		
	if panelFadeIn and currentTick >= panelFadeIn then
		local animProgress = (currentTick - panelFadeIn) / 350
		panelFadeProgress = interpolateBetween(0, 0, 0, 1, 0, 0, animProgress, "InQuad")
		
		if animProgress > 1 then
			panelFadeProgress = 1
			panelFadeIn = false
		end
	elseif panelFadeOut and currentTick >= panelFadeOut then
		local animProgress = (currentTick - panelFadeOut) / 350
		panelFadeProgress = interpolateBetween(1, 0, 0, 0, 0, 0, animProgress, "OutQuad")
		
		if animProgress > 1 then
			panelFadeProgress = 0
			panelFadeOut = false
			toggleRoadmarksPanel("exitByRender")
			return
		end
	end
	
	alpha255 = 255 * panelFadeProgress
	
	drawMainMenu()
	drawMenu()
	dxDrawRectangle(panelPosX, panelPosY, panelWidth, panelHeight, tocolor(42, 40, 42, 230 * panelFadeProgress))
	
	for i = 1, panelVisibleItems do
		local realId = i + panelCategoryPages[activePanelCategory]
		local item = roadmarksList[activePanelCategory][realId]
		if item then
			local itemX = panelItemWidth * (i - 1)
			
			local backgroundColor = 0
			if selectedPanelItem == realId and not adminMode then
				backgroundColor = tocolor(0, 149, 217, 128 * panelFadeProgress)
			elseif isCursorWithinArea(cursorX, cursorY, itemX, panelPosY, panelItemWidth, panelItemHeight) and not adminMode then
				backgroundColor = tocolor(80, 80, 80, 150 * panelFadeProgress)
				activeDirectX = "panelItem:" .. realId
			end
			dxDrawRectangle(itemX, panelPosY, panelItemWidth, panelItemHeight, backgroundColor)
			
			local scaleInverse = 1 - panelItemScale
			dxDrawImage(itemX + panelItemWidth * (scaleInverse * 0.5), panelPosY + panelItemHeight * (scaleInverse * 0.5), panelItemWidth * panelItemScale, panelItemHeight * panelItemScale, item, 0, 0, 0, not adminMode and tocolor(255, 255, 255, alpha255) or tocolor(60, 60, 60, alpha255))
		end
	end
	
	if #roadmarksList[activePanelCategory] > panelVisibleItems then
		local scrollbarCalculatedWidth = (panelItemWidth * panelVisibleItems) / #roadmarksList[activePanelCategory]
		
		if scrollbarInterpolationTick and currentTick >= scrollbarInterpolationTick then
			local scrollbarMoveAnimation = interpolateBetween(scrollbarPosition, 0, 0, scrollbarCalculatedWidth * panelCategoryPages[activePanelCategory], 0, 0, (currentTick - scrollbarInterpolationTick) / 500, "OutQuad")
			scrollbarPosition = scrollbarMoveAnimation
		end
		
		dxDrawRectangle(scrollbarPosX, scrollbarPosY, scrollbarWidth, scrollbarHeight, tocolor(255, 255, 255, 50 * panelFadeProgress))
		dxDrawRectangle(scrollbarPosX + scrollbarPosition, scrollbarPosY, scrollbarCalculatedWidth * panelVisibleItems, scrollbarHeight, not adminMode and tocolor(0, 149, 217, alpha255) or tocolor(125, 125, 125, alpha255))
	end
	
	drawColorPicker()
	drawActiveMarkMenu()
	
	if activeDirectX ~= lastActiveDirectX and activeDirectX then
		playSound("files/sounds/highlight.mp3")
	end
end

function drawMenu()
	dxDrawRectangle(panelPosX, menuPosY, menuWidth, menuHeight, tocolor(32, 30, 32, 230 * panelFadeProgress))
	
	local x, y = panelPosX + menuPaddingX, menuPosY + menuPaddingY
	for i = 1, #textureData do
		local color = not adminMode and tocolor(255, 255, 255, alpha255) or tocolor(80, 80, 80, alpha255)
		
		if not adminMode and isCursorWithinArea(cursorX, cursorY, x, y, menuIconSize, menuIconSize) and activePanelCategory ~= i then
			color = tocolor(0, 149, 217, alpha255)
			activeDirectX = "category:" .. i
		end
		
		if activePanelCategory == i then
			color = not adminMode and tocolor(0, 149, 217, alpha255) or tocolor(175, 175, 175, alpha255)
			dxDrawRectangle(x, y, menuIconSize, menuIconSize, tocolor(50, 50, 50, alpha255))
		end
		
		dxDrawImage(x, y, menuIconSize, menuIconSize, "files/icons/section" .. i .. ".png", 0, 0, 0, color)
		
		x = x + menuIconSize + menuIconSpace
	end
	
	dxDrawRectangle(panelPosX + menuWidth, menuPosY, textBoxWidth, menuHeight, tocolor(45, 45, 45, 175 * panelFadeProgress))
	dxDrawText(categoryNames[activePanelCategory], panelPosX + menuWidth, menuPosY, panelPosX + menuWidth + textBoxWidth, menuPosY + menuHeight, tocolor(255, 255, 255, alpha255), 1, RobotoLightFont, "center", "center", true, false, false, false, true)
end

function drawMainMenu()
	dxDrawRectangle(mainMenuPosX, menuPosY, mainMenuWidth, menuHeight, tocolor(32, 30, 32, 230 * panelFadeProgress))
	
	local x, y = mainMenuPosX + menuPaddingX, menuPosY + menuPaddingY
	for i = #mainMenuData, 1, -1 do
		local color = tocolor(50, 50, 50, alpha255)
		
		if isCursorWithinArea(cursorX, cursorY, x, y, menuIconSize, menuIconSize) then
			color = mainMenuData[i][3] and tocolor(mainMenuData[i][3][1], mainMenuData[i][3][2], mainMenuData[i][3][3], alpha255) or tocolor(0, 149, 217, alpha255)
			activeDirectX = "nav:" .. mainMenuData[i][1] .. ":" .. i
		end
		
		dxDrawRectangle(x, y, menuIconSize, menuIconSize, color)
		dxDrawImage(x, y, menuIconSize, menuIconSize, "files/icons/" .. mainMenuData[i][1] .. ".png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
		
		x = x + menuIconSize + menuIconSpace
	end
	
	if activeDirectX and string.find(activeDirectX, "nav:") then
		local tooltipText = mainMenuData[tonumber(split(activeDirectX, ":")[3])][2]
		tooltipBoxWidthTarget = dxGetTextWidth(tooltipText, 1, RobotoLightFont) + 15
		local tooltipPosX = mainMenuPosX - tooltipBoxWidth
		
		dxDrawRectangle(tooltipPosX, menuPosY, tooltipBoxWidth, menuHeight, tocolor(45, 45, 45, 175 * panelFadeProgress))
		dxDrawText(tooltipText, tooltipPosX, menuPosY, tooltipPosX + tooltipBoxWidth, menuPosY + menuHeight, tocolor(255, 255, 255, alpha255), 1, RobotoLightFont, "center", "center", true)
	elseif tooltipBoxWidth ~= 0 then
		tooltipBoxWidth = 0
		tooltipBoxWidthTarget = 0
	end
end

function onClientPanelClick(button, state, _, _, worldX, worldY, worldZ)
	if not isPanelActive then
		return
	end
	
	if colorPanel.isActive and button == "left" and state == "down" then
		activeColorInput = false
		if hoveredInputfield then
			activeColorInput = hoveredInputfield
		end
	end
	
	if button == "left" and state == "up" and not activeColorInput then
		if activeDirectX then
			local splitData = split(activeDirectX, ":")
			
			if splitData[1] == "category" then
				activePanelCategory = tonumber(splitData[2])
				textBoxWidthTarget = menuPaddingX * 2 + dxGetTextWidth(categoryNames[activePanelCategory], 1, RobotoLightFont)
				playSound("files/sounds/category.mp3")
				selectedPanelItem = false
			elseif splitData[1] == "panelItem" then
				selectedPanelItem = tonumber(splitData[2])
				playSound("files/sounds/select.mp3")
				
				if activePanelCategory == stripeCategory[1] and selectedPanelItem == stripeCategory[2] and not activeItem then
					processItemSelect(false, false, -1000, -1000, -1000)
				end
				
				if activeItem and not activeItem.isStripe then
					if activePanelCategory == stripeCategory[1] and selectedPanelItem == stripeCategory[2] then
						return
					end
					
					activeItem.material = roadmarksList[activePanelCategory][selectedPanelItem]
					activeItem.textureData = activePanelCategory .. ";" .. selectedPanelItem
				end
			elseif splitData[1] == "nav" then
				if splitData[2] == "exit" then
					unloadEditor()
				elseif string.find(splitData[2], "snap") then
					if splitData[2] == "snapoffr" then
						snapRotation = 5
					elseif splitData[2] == "snap1r" then
						snapRotation = 10
					elseif splitData[2] == "snap2r" then
						snapRotation = 90
					elseif splitData[2] == "snap3r" then
						snapRotation = false
					end
					
					processMainMenu()
					playSound("files/sounds/select.mp3")
				elseif splitData[2] == "save" then
					if activeItem then
						if activeItem.isStripe then
							if activeItem.width <= stripeMinWidth or activeItem.height <= stripeMinHeight then
								outputChatBox("#32b3ef[Roadmark]:#ffffff A rács mérete túl kicsi!", 255, 255, 255, true)
								return
							end
							
							if activeItem.width > stripeMaxWidth or activeItem.height > stripeMaxHeight then
								outputChatBox("#32b3ef[Roadmark]:#ffffff A rács mérete túl nagy!", 255, 255, 255, true)
								return
							end
						end
						
						triggerServerEvent("createRoadmark", localPlayer, activeItem)
						activeItem = false
						processMainMenu()
					else
						outputChatBox("#32b3ef[Roadmark]:#ffffff Nincs mit menteni!", 255, 255, 255, true)
						playSound("files/sounds/fail.mp3")
					end
				elseif splitData[2] == "admin" then
					setElementData(localPlayer, "isEditingRoadmark", false)
					adminMode = not adminMode
					processMainMenu()
					playSound("files/sounds/select.mp3")
				elseif splitData[2] == "color" then
					showColorPicker()
					playSound("files/sounds/select.mp3")
				end
			elseif splitData[1] == "activeMode" and activeItem then
				if splitData[2] == "delete" then
					if activeItem.tableId then
						triggerServerEvent("deleteRoadmark", localPlayer, activeItem.tableId, realRoadmarks[activeItem.tableId])
					end
					activeItem = false
					processMainMenu()
					playSound("files/sounds/delete.mp3")
				elseif splitData[2] == "exit" then
					setElementData(localPlayer, "isEditingRoadmark", false)
					activeItem = false
					processMainMenu()
					playSound("files/sounds/select.mp3")
				elseif splitData[2] == "move" then
					activeItem.mode = "move"
					processMainMenu()
					playSound("files/sounds/select.mp3")
				elseif activeItem.mode ~= splitData[2] then
					activeItem.canFreeMove = false
					activeItem.mode = splitData[2]
					playSound("files/sounds/select.mp3")
				end
			elseif splitData[1] == "defaultColor" then
				if activeItem then
					local currentRed, currentGreen, currentBlue = getColorFromDecimal(activeItem.color)
					local colorData = availableColorsForItem[tonumber(splitData[2])]
					
					if table.concat({currentRed, currentGreen, currentBlue}, "") ~= table.concat({colorData[1], colorData[2], colorData[3]}, "") then
						activeItem.color = tocolor(colorData[1], colorData[2], colorData[3])
						playSound("files/sounds/select2.mp3")
					end
				end
			elseif adminMode then
				if splitData[1] == "adminMode" then
					if splitData[2] == "togProtect" then
						local roadmarkId = splitData[3]
						if realRoadmarks[roadmarkId] then
							triggerServerEvent("protectRoadmark", localPlayer, roadmarkId, not realRoadmarks[roadmarkId].isProtected)
							playSound("files/sounds/select2.mp3")
						end
					elseif splitData[2] == "delete" then
						local roadmarkId = splitData[3]
						if realRoadmarks[roadmarkId] then
							if not realRoadmarks[roadmarkId].isProtected then
								triggerServerEvent("deleteRoadmark", localPlayer, roadmarkId, realRoadmarks[roadmarkId])
								playSound("files/sounds/select2.mp3")
							end
						end
					end
				end
			elseif not activeItem then
				if splitData[1] == "editMark" and not splitData[3] then
					local roadmarkId = splitData[2]
					if realRoadmarks[roadmarkId] and not realRoadmarks[roadmarkId].isEditing then
						setElementData(localPlayer, "isEditingRoadmark", false)
						setElementData(localPlayer, "isEditingRoadmark", roadmarkId)
						playSound("files/sounds/select2.mp3")
					end
				elseif splitData[1] == "editMark" and splitData[3] == "copy" then
					local roadmarkId = splitData[2]
					if realRoadmarks[roadmarkId] then
						processItemSelect(roadmarkId, true)
						playSound("files/sounds/select2.mp3")
					end
				elseif splitData[1] == "deleteStripe" then
					local roadmarkId = splitData[2]
					if realRoadmarks[roadmarkId] then
						if not realRoadmarks[roadmarkId].isProtected then
							triggerServerEvent("deleteRoadmark", localPlayer, roadmarkId, realRoadmarks[roadmarkId])
							playSound("files/sounds/select2.mp3")
						end
					end
				end
			end
		end
	elseif button == "left" and state == "down" then
		if not isCursorWithinPanel() then
			if activePanelCategory == stripeCategory[1] and selectedPanelItem == stripeCategory[2] then
				if not activeItem or activeItem and activeItem.createdPosX == -1000 then
					processItemSelect(false, false, worldX, worldY, worldZ)
					playSound("files/sounds/select2.mp3")
				end
			elseif activeItem and activeItem.canFreeMove and not activeItem.isStripe then
				if activeItem.canPlace then
					activeItem.canFreeMove = false
					processMainMenu()
					playSound("files/sounds/place.mp3")
				else
					playSound("files/sounds/fail.mp3")
				end
			end
		end
	end
end

function showColorPicker()
	if colorPanel.isActive then
		colorPanel.isActive = false
	else
		if (getElementData(localPlayer, "acc.adminLevel") or 0) >= adminLevelForCustomColors then
			colorPanel.isActive = "admin"
		else
			colorPanel.isActive = true
		end
	end
	
	processMainMenu()
end

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if getElementType(source) == "player" then
			if dataName == "isEditingRoadmark" then
				local dataValue = getElementData(source, dataName) or false
				
				if dataValue and realRoadmarks[dataValue] then
					realRoadmarks[dataValue].isEditing = true
					
					if source == localPlayer then
						processItemSelect(dataValue)
					end
				elseif oldValue and realRoadmarks[oldValue] then
					realRoadmarks[oldValue].isEditing = false
					
					if activeItem and activeItem.tableId and activeItem.tableId == oldValue then
						activeItem = false
					end
				end
			elseif dataName == "acc.adminLevel" then
				processMainMenu()
			end
		end
	end
)

function onClientPanelDoubleClick(button)
	if not isPanelActive then
		return
	end
	
	if button == "left" and activeItem and not adminMode and activeDirectX then
		local splitData = split(activeDirectX, ":")
		if splitData[1] == "activeMode" then
			if splitData[2] == "move" then
				activeItem.mode = "move"
				activeItem.canFreeMove = true
				processMainMenu()
				playSound("files/sounds/select.mp3")
			end
		end
	end
	
	if activePanelCategory == stripeCategory[1] and selectedPanelItem == stripeCategory[2] then
		return
	end
	
	if button == "left" and selectedPanelItem and not adminMode then
		if isCursorWithinArea(cursorX, cursorY, panelPosX, panelPosY, panelWidth, panelHeight) then
			setElementData(localPlayer, "isEditingRoadmark", false)
			processItemSelect()
			playSound("files/sounds/select2.mp3")
		end
	end
end

function processItemSelect(id, copy, x, y, z)
	if not x then
		if id then
			if copy then
				activeItem = {
					material = roadmarksList[realRoadmarks[id].section][realRoadmarks[id].textureId],
					textureData = realRoadmarks[id].section .. ";" .. realRoadmarks[id].textureId,
					canFreeMove = true,
					mode = "move",
					rotation = realRoadmarks[id].rotation,
					scale = realRoadmarks[id].scale,
					color = realRoadmarks[id].color
				}
			else
				activeItem = {
					tableId = id,
					material = roadmarksList[realRoadmarks[id].section][realRoadmarks[id].textureId],
					textureData = realRoadmarks[id].section .. ";" .. realRoadmarks[id].textureId,
					canFreeMove = false,
					mode = "move",
					rotation = realRoadmarks[id].rotation,
					scale = realRoadmarks[id].scale,
					oldPosX = realRoadmarks[id].x0,
					oldPosY = realRoadmarks[id].y0,
					oldPosZ = realRoadmarks[id].z0 - 0.0375,
					middlePosX = realRoadmarks[id].x0,
					middlePosY = realRoadmarks[id].y0,
					middlePosZ = realRoadmarks[id].z0,
					startPosX = realRoadmarks[id].x1,
					startPosY = realRoadmarks[id].y1,
					startPosZ = realRoadmarks[id].z1,
					endPosX = realRoadmarks[id].x2,
					endPosY = realRoadmarks[id].y2,
					endPosZ = realRoadmarks[id].z2,
					faceTowardX = realRoadmarks[id].x3,
					faceTowardY = realRoadmarks[id].y3,
					faceTowardZ = realRoadmarks[id].z3,
					color = realRoadmarks[id].color,
					isProtected = realRoadmarks[id].isProtected,
					canPlace = true
				}
			end
		else
			local _, _, playerRotZ = getElementRotation(localPlayer)
		
			activeItem = {
				material = roadmarksList[activePanelCategory][selectedPanelItem],
				textureData = activePanelCategory .. ";" .. selectedPanelItem,
				canFreeMove = true,
				mode = "move",
				rotation = (playerRotZ - 90) % 360,
				scale = 4,
				color = tocolor(255, 255, 255)
			}
		end
	else
		activeItem = {
			isStripe = true,
			canFreeMove = false,
			mode = "create",
			canResize = true,
			createdPosX = x,
			createdPosY = y,
			createdPosZ = z,
			middlePosX = x,
			middlePosY = y,
			middlePosZ = z,
			width = 0,
			height = 0,
			color = tocolor(255, 255, 255)
		}
	end
	
	processMainMenu()
end

function onClientPanelPreRender(deltaTime)
	textBoxWidth = textBoxWidth + (textBoxWidthTarget - textBoxWidth) * deltaTime * 0.0075
	tooltipBoxWidth = tooltipBoxWidth + (tooltipBoxWidthTarget - tooltipBoxWidth) * deltaTime * 0.0075
end

function processStripe(id, retarget, startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)
	local tableSwitch = id == "new" and activeItem or realRoadmarks[id]
	
	if not tableSwitch or tableSwitch.createdPosX == -1000 then
		return
	end
	
	if endPosX and endPosY then
		if tableSwitch.width == endPosX - startPosX or tableSwitch.height == endPosY - startPosY then
			return
		end
	end
	
	if ((endPosX and endPosY and endPosZ) or retarget) and isElement(tableSwitch.renderTarget) then
		destroyElement(tableSwitch.renderTarget)
	end
	
	if endPosX and endPosY then
		if endPosX - startPosX <= 0 then
			local tempStartPosX = startPosX
			startPosX = endPosX
			endPosX = tempStartPosX
			tempStartPosX = nil
		end
		
		if endPosY - startPosY <= 0 then
			local tempStartPosY = startPosY
			startPosY = endPosY
			endPosY = tempStartPosY
			tempStartPosY = nil
		end
	end
	
	local finalWidth = endPosX and endPosX - startPosX or tableSwitch.width
	local finalHeight = endPosY and endPosY - startPosY or tableSwitch.height
	
	if finalWidth >= stripeMaxWidth then
		finalWidth = stripeMaxWidth
	end
	
	if finalHeight >= stripeMaxHeight then
		finalHeight = stripeMaxHeight
	end
	
	createStripe(id, (endPosX and endPosY and endPosZ) or retarget, startPosX or tableSwitch.createdPosX, startPosY or tableSwitch.createdPosY, ((endPosZ and endPosZ + 0.0375) or (startPosZ and startPosZ + 0.0375)) or tableSwitch.createdPosZ, finalWidth, finalHeight)
end

function createStripe(id, resizing, x, y, z, width, height)
	local tableSwitch = id == "new" and activeItem or realRoadmarks[id]
	
	x = x or activeItem.normalPosX
	y = y or activeItem.normalPosY
	z = z or activeItem.normalPosZ
	width = width or activeItem.width
	height = height or activeItem.height
	
	if width >= stripeMaxWidth then
		width = stripeMaxWidth
	end
	
	if height >= stripeMaxHeight then
		height = stripeMaxHeight
	end
	
	local halfWidth = width * 0.5
	local halfHeight = height * 0.5
	
	if id == "new" then
		activeItem.normalPosX = x
		activeItem.normalPosY = y
		activeItem.normalPosZ = z
		
		activeItem.middlePosX = x + halfWidth
		activeItem.middlePosY = y + halfHeight
		activeItem.middlePosZ = z
		
		activeItem.startPosX = activeItem.middlePosX
		activeItem.startPosY = y
		activeItem.startPosZ = z
		
		activeItem.endPosX = activeItem.middlePosX
		activeItem.endPosY = y + height
		activeItem.endPosZ = z
		
		activeItem.faceTowardX = activeItem.middlePosX
		activeItem.faceTowardY = activeItem.middlePosY
		activeItem.faceTowardZ = z + 10
	else
		tableSwitch.x0 = x
		tableSwitch.y0 = y
		tableSwitch.z0 = z
		
		tableSwitch.x0mid = x + halfWidth
		tableSwitch.y0mid = y + halfHeight
		tableSwitch.z0mid = z
		
		tableSwitch.x1 = x + halfWidth
		tableSwitch.y1 = y
		tableSwitch.z1 = z
		
		tableSwitch.x2 = x + halfWidth
		tableSwitch.y2 = y + height
		tableSwitch.z2 = z
		
		tableSwitch.x3 = x + halfWidth
		tableSwitch.y3 = y + halfHeight
		tableSwitch.z3 = z + 10
	end
	
	tableSwitch.width = width
	tableSwitch.height = height
	
	if tableSwitch.width >= stripeMinWidth and tableSwitch.height >= stripeMinHeight then
		if resizing then
			if isElement(tableSwitch.renderTarget) then
				destroyElement(tableSwitch.renderTarget)
			end
			
			tableSwitch.renderTarget = dxCreateRenderTarget(tableSwitch.width * 48, tableSwitch.height * 48, true)
			
			dxSetRenderTarget(tableSwitch.renderTarget)
			
			for x = 0, tableSwitch.width * 2 do
				for y = 0, tableSwitch.height * 2 do
					dxDrawImage(x * 24, y * 24, 24, 24, "files/stripe/stripe.png", 0, 0, 0)
				end
			end

			dxDrawRectangle(0, 0, 8, tableSwitch.height * 48)
			dxDrawRectangle(tableSwitch.width * 48 - 8, 0, 8, tableSwitch.height * 48)
			dxDrawRectangle(0, 0, tableSwitch.width * 48, 8)
			dxDrawRectangle(0, tableSwitch.height * 48 - 8, tableSwitch.width * 48, 8)

			dxSetRenderTarget()
		end
	end
end

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		if getElementData(localPlayer, "isEditingRoadmark") then
			setElementData(localPlayer, "isEditingRoadmark", false)
		end
		
		streamerThread = coroutine.create(streamRoadmarks)
		setTimer(triggerServerEvent, 2000, 1, "requestRoadmarksList", localPlayer)
	end
)

addEvent("receiveRoadmarksList", true)
addEventHandler("receiveRoadmarksList", getRootElement(),
	function (list)
		realRoadmarks = list
		
		for k,v in pairs(list) do
			if v.textureData then
				local splitData = split(v.textureData, ";")
				realRoadmarks[k].section = tonumber(splitData[1])
				realRoadmarks[k].textureId = tonumber(splitData[2])
			else
				realRoadmarks[k].isStripe = true
			end
		end
	end
)

addEvent("createRoadmark", true)
addEventHandler("createRoadmark", getRootElement(),
	function (fromClient, data, id)
		realRoadmarks[id] = data
		
		if realRoadmarks[id].textureData then
			local splitData = split(realRoadmarks[id].textureData, ";")
			realRoadmarks[id].section = tonumber(splitData[1])
			realRoadmarks[id].textureId = tonumber(splitData[2])
		elseif realRoadmarks[id].width and realRoadmarks[id].height then
			realRoadmarks[id].isStripe = true
		end
		
		if fromClient == localPlayer then
			--outputChatBox("Roadmark saved.")
		end
	end
)

addEvent("protectRoadmark", true)
addEventHandler("protectRoadmark", getRootElement(),
	function (id, state)
		if realRoadmarks[id] then
			realRoadmarks[id].isProtected = state
		end
	end
)

addEvent("deleteRoadmark", true)
addEventHandler("deleteRoadmark", getRootElement(),
	function (id, data)
		if realRoadmarks[id] then
			realRoadmarks[id] = nil
		end
	end
)

local stripeCursor = dxCreateTexture("files/stripe/creation.png")

function drawStripeBorder(x1, y1, z1, x2, y2, z2)
	local w = x2 - x1
	local h = y2 - y1
	
	if w >= stripeMaxWidth then
		w = stripeMaxWidth
	end
	
	if h >= stripeMaxHeight then
		h = stripeMaxHeight
	end
	
	dxDrawLine3D(x1, y1, z1, x1 + w, y1, z1, tocolor(124, 197, 118), 5) -- teteje
	dxDrawLine3D(x1, y1 + h, z1, x1 + w, y1 + h, z1, tocolor(124, 197, 118), 5) -- alja
	dxDrawLine3D(x1, y1, z1, x1, y1 + h, z1, tocolor(124, 197, 118), 5) -- bal
	dxDrawLine3D(x1 + w, y1, z1, x1 + w, y1 + h, z1, tocolor(124, 197, 118), 5) -- jobb
end

addEventHandler("onClientRestore", getRootElement(),
	function ()
		if activeItem and activeItem.isStripe then
			createStripe(activeItem.tableId or "new", true)
		end
		
		for k in pairs(streamedRoadmarks) do
			local markData = realRoadmarks[k]
			if markData and markData.isStripe then
				if markData.interior == currentInterior and markData.dimension == currentDimension then
					createStripe(k, true, markData.x0, markData.y0, markData.z0, markData.width, markData.height)
				end
			end
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		coroutine.resume(streamerThread)
		
		currentInterior = getElementInterior(localPlayer)
		currentDimension = getElementDimension(localPlayer)
		
		for k in pairs(streamedRoadmarks) do
			local markData = realRoadmarks[k]
			if markData and not markData.isStripe and not markData.isEditing and roadmarksList[markData.section][markData.textureId] then
				if markData.interior == currentInterior and markData.dimension == currentDimension then
					dxDrawMaterialLine3D(markData.x1, markData.y1, markData.z1, markData.x2, markData.y2, markData.z2, roadmarksList[markData.section][markData.textureId], markData.scale, markData.color or -1, markData.x3, markData.y3, markData.z3)
				end
			elseif markData and markData.isStripe and not markData.isEditing then
				if markData.interior == currentInterior and markData.dimension == currentDimension then
					dxDrawMaterialLine3D(markData.x1, markData.y1, markData.z1, markData.x2, markData.y2, markData.z2, markData.renderTarget, markData.width, markData.color or -1, markData.x3, markData.y3, markData.z3)
				end
			end
		end
		
		if not activeItem then
			return
		end

		local hitCollision, hitPosX, hitPosY, hitPosZ
		if isCursorShowing() then
			local cameraPosX, cameraPosY, cameraPosZ = getCameraMatrix()
			local cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ = getWorldFromScreenPosition(cursorX, cursorY, 1000)
			local hit, hitX, hitY, hitZ, hitElement, normalX, normalY, normalZ = processLineOfSight(cameraPosX, cameraPosY, cameraPosZ, cursorWorldPosX, cursorWorldPosY, cursorWorldPosZ, true, false, false, true, false)
			hitCollision, hitPosX, hitPosY, hitPosZ = hit, hitX, hitY, hitZ
		
			if hitCollision and not isCursorWithinPanel() then
				local goodPlace = (normalX > -0.5 and normalX <= 0.5) and (normalY > -0.5 and normalY <= 0.5) and (normalZ > -0.5 and normalZ <= 1)
					
				if activeItem.mode == "move" and not activeItem.canFreeMove and getKeyState("mouse1") and activeItemOffsets and activeItemOffsets[7] == "move" and goodPlace then
					activeItem.zLevelForMoveArrows = hitPosZ + 0.05
				end
				
				if activeItem.isStripe and activeItem.mode == "scale" and goodPlace then
					activeItem.zLevelForMoveArrows = hitPosZ + 0.05
				end
				
				if not activeItem.isStripe then
					if (activeItem.mode == "move" and activeItem.canFreeMove) or ((activeItem.mode == "rotate" or activeItem.mode == "scale") and getKeyState("mouse1")) then
						if (activeItem.canFreeMove and goodPlace) or not activeItem.canFreeMove then
							if activeItem.canFreeMove and activeItem.mode == "move" then
								activeItem.oldPosX = false
								activeItem.oldNormalX = false
							else
								hitX, hitY, hitZ = activeItem.oldPosX, activeItem.oldPosY, activeItem.oldPosZ
								
								if activeItem.oldNormalX then
									normalX, normalY, normalZ = activeItem.oldNormalX, activeItem.oldNormalY, activeItem.oldNormalZ
								end
							end
							
							local halfScale = activeItem.scale / 2
							local angle = math.rad(-activeItem.rotation)
							local sizeX = math.cos(angle) * halfScale
							local sizeY = math.sin(angle) * halfScale

							local directionX = normalZ * sizeY
							local directionY = normalZ * sizeX
							local directionZ = normalX * sizeY - normalY * sizeX

							local offsetX = directionY * normalZ - directionZ * normalY
							local offsetY = directionZ * normalX - directionX * normalZ
							local offsetZ = directionX * normalY - directionY * normalX

							local deltaLength = halfScale / getDistanceBetweenPoints3D(0, 0, 0, offsetX, offsetY, offsetZ)
							local normalLength = 1 / getDistanceBetweenPoints3D(0, 0, 0, normalX, normalY, normalZ)

							offsetX = offsetX * deltaLength
							offsetY = offsetY * deltaLength
							offsetZ = offsetZ * deltaLength

							normalX = normalX * normalLength
							normalY = normalY * normalLength
							normalZ = normalZ * normalLength

							local middlePosX = hitX + normalX * 0.02
							local middlePosY = hitY + normalY * 0.02
							local middlePosZ = hitZ + normalZ * 0.04

							local startPosX = middlePosX + offsetX
							local startPosY = middlePosY + offsetY
							local startPosZ = middlePosZ + offsetZ

							local endPosX = middlePosX - offsetX
							local endPosY = middlePosY - offsetY
							local endPosZ = middlePosZ - offsetZ
							
							if not activeItem.oldPosX then
								activeItem.oldPosX = hitX
								activeItem.oldPosY = hitY
								activeItem.oldPosZ = hitZ
							end
							
							if not activeItem.oldNormalX then
								activeItem.oldNormalX = normalX
								activeItem.oldNormalY = normalY
								activeItem.oldNormalZ = normalZ
							end
							
							activeItem.middlePosX = middlePosX
							activeItem.middlePosY = middlePosY
							activeItem.middlePosZ = middlePosZ
							activeItem.startPosX = startPosX
							activeItem.startPosY = startPosY
							activeItem.startPosZ = startPosZ
							activeItem.endPosX = endPosX
							activeItem.endPosY = endPosY
							activeItem.endPosZ = endPosZ
							activeItem.faceTowardX = startPosX + normalX
							activeItem.faceTowardY = startPosY + normalY
							activeItem.faceTowardZ = startPosZ + normalZ
							
							if not activeItem.canPlace then
								activeItem.canPlace = true
							end
						elseif activeItem.canPlace then
							activeItem.canPlace = false
						end
					end
				end
			end
		end
		
		if not hitCollision then
			hitPosX, hitPosY, hitPosZ = -1000, -1000, -1000
		end
		
		if activeItem.canPlace and activeItem.middlePosX and activeItem.middlePosY and activeItem.middlePosZ then
			dxDrawMaterialLine3D(activeItem.startPosX, activeItem.startPosY, activeItem.startPosZ, activeItem.endPosX, activeItem.endPosY, activeItem.endPosZ, activeItem.material, activeItem.scale, activeItem.color or -1, activeItem.faceTowardX, activeItem.faceTowardY, activeItem.faceTowardZ)
		end
		
		if activeItem.isStripe then
			if isElement(activeItem.renderTarget) then
				dxDrawMaterialLine3D(activeItem.startPosX, activeItem.startPosY, activeItem.startPosZ, activeItem.endPosX, activeItem.endPosY, activeItem.endPosZ, activeItem.renderTarget, activeItem.width, activeItem.color or -1, activeItem.faceTowardX, activeItem.faceTowardY, activeItem.faceTowardZ)
			end
			
			if hitCollision and hitPosX ~= -1000 then
				if not isCursorWithinPanel() and not activeDirectX then
					if getKeyState("mouse1") and activeItem.canResize then
						processStripe(activeItem.tableId or "new", true, activeItem.createdPosX, activeItem.createdPosY, activeItem.createdPosZ, hitPosX, hitPosY, hitPosZ)
					elseif activeItem.canResize and activeItem.renderTarget then
						activeItem.canResize = false
						if activeItem.mode == "create" then
							playSound("files/sounds/place.mp3")
							selectedPanelItem = false
						end
					end
					
					if activeItem.canResize or activeItem.mode == "scale" then
						drawStripeBorder(activeItem.createdPosX, activeItem.createdPosY, activeItem.createdPosZ, hitPosX, hitPosY, hitPosZ)
						dxDrawMaterialLine3D(hitPosX, hitPosY, hitPosZ + (512 * 0.375) / 75, hitPosX, hitPosY, hitPosZ, stripeCursor, (64 * 0.375) / 75, -1, _, _, hitPosZ + 10)
					end
				end
			end
		end
		
		if not activeItem.isStripe then
			if activeItem.mode == "rotate" then
				local smallerScale = activeItem.scale * 0.7
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - smallerScale and hitPosX <= activeItem.middlePosX + smallerScale and hitPosY >= activeItem.middlePosY - smallerScale and hitPosY <= activeItem.middlePosY + smallerScale and hitPosZ >= activeItem.middlePosZ - 0.5 and hitPosZ <= activeItem.middlePosZ + 0.5) or activeItemOffsets and activeItemOffsets[4] == "rotate" then
					moveRoadmark(hitPosX, hitPosY, "rotate")
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale, activeItem.middlePosY, activeItem.middlePosZ, activeItem.middlePosX + smallerScale, activeItem.middlePosY, activeItem.middlePosZ, rotateIcon, smallerScale * 2, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale, activeItem.middlePosY, activeItem.middlePosZ, activeItem.middlePosX + smallerScale, activeItem.middlePosY, activeItem.middlePosZ, rotateIcon, smallerScale * 2, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 10)
				end
			elseif activeItem.mode == "scale" then
				local smallerScale = activeItem.scale * 0.65
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - smallerScale and hitPosX <= activeItem.middlePosX + smallerScale and hitPosY >= activeItem.middlePosY - smallerScale and hitPosY <= activeItem.middlePosY + smallerScale and hitPosZ >= activeItem.middlePosZ - 0.5 and hitPosZ <= activeItem.middlePosZ + 0.5) or activeItemOffsets and activeItemOffsets[4] == "scale" then
					moveRoadmark(hitPosX, hitPosY, "scale")
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale, activeItem.middlePosY, activeItem.middlePosZ, activeItem.middlePosX + smallerScale, activeItem.middlePosY, activeItem.middlePosZ, scaleIcon, smallerScale * 2, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale, activeItem.middlePosY, activeItem.middlePosZ, activeItem.middlePosX + smallerScale, activeItem.middlePosY, activeItem.middlePosZ, scaleIcon, smallerScale * 2, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 10)
				end
			elseif activeItem.mode == "move" and not activeItem.canFreeMove then
				local smallerScale = activeItem.scale * 0.5
				local zLevel = activeItem.zLevelForMoveArrows or activeItem.middlePosZ
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - smallerScale - 1 and hitPosX <= activeItem.middlePosX - smallerScale and hitPosY >= activeItem.middlePosY - 0.5 and hitPosY <= activeItem.middlePosY + 0.5 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[3] == -1 then
					moveRoadmark(hitPosX, hitPosY, "move", -1, 0)
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale - 1, activeItem.middlePosY, zLevel, activeItem.middlePosX - smallerScale, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerScale - 1, activeItem.middlePosY, zLevel, activeItem.middlePosX - smallerScale, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX + smallerScale and hitPosX <= activeItem.middlePosX + smallerScale + 1 and hitPosY >= activeItem.middlePosY - 0.5 and hitPosY <= activeItem.middlePosY + 0.5 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[3] == 1 then
					moveRoadmark(hitPosX, hitPosY, "move", 1, 0)
					dxDrawMaterialLine3D(activeItem.middlePosX + smallerScale + 1, activeItem.middlePosY, zLevel, activeItem.middlePosX + smallerScale, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX + smallerScale + 1, activeItem.middlePosY, zLevel, activeItem.middlePosX + smallerScale, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
		
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - 0.5 and hitPosX <= activeItem.middlePosX + 0.5 and hitPosY >= activeItem.middlePosY - smallerScale - 1 and hitPosY <= activeItem.middlePosY - smallerScale and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[4] == -1 then
					moveRoadmark(hitPosX, hitPosY, "move", 0, -1)
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY - smallerScale - 1, zLevel, activeItem.middlePosX, activeItem.middlePosY - smallerScale, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY - smallerScale - 1, zLevel, activeItem.middlePosX, activeItem.middlePosY - smallerScale, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
			
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - 0.5 and hitPosX <= activeItem.middlePosX + 0.5 and hitPosY >= activeItem.middlePosY + smallerScale and hitPosY <= activeItem.middlePosY + smallerScale + 1 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[4] == 1 then
					moveRoadmark(hitPosX, hitPosY, "move", 0, 1)
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY + smallerScale + 1, zLevel, activeItem.middlePosX, activeItem.middlePosY + smallerScale, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY + smallerScale + 1, zLevel, activeItem.middlePosX, activeItem.middlePosY + smallerScale, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
			end
		else
			if activeItem.mode == "move" and not activeItem.canFreeMove then
				local smallerWidth = activeItem.width * 0.5
				local smallerHeight = activeItem.height * 0.5
				local zLevel = activeItem.zLevelForMoveArrows or activeItem.middlePosZ
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - smallerWidth - 1 and hitPosX <= activeItem.middlePosX - smallerWidth and hitPosY >= activeItem.middlePosY - 0.5 and hitPosY <= activeItem.middlePosY + 0.5 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[3] == -1 then
					moveRoadmark(hitPosX, hitPosY, "move", -1, 0)
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerWidth - 1, activeItem.middlePosY, zLevel, activeItem.middlePosX - smallerWidth, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX - smallerWidth - 1, activeItem.middlePosY, zLevel, activeItem.middlePosX - smallerWidth, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
				
				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX + smallerWidth and hitPosX <= activeItem.middlePosX + smallerWidth + 1 and hitPosY >= activeItem.middlePosY - 0.5 and hitPosY <= activeItem.middlePosY + 0.5 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[3] == 1 then
					moveRoadmark(hitPosX, hitPosY, "move", 1, 0)
					dxDrawMaterialLine3D(activeItem.middlePosX + smallerWidth + 1, activeItem.middlePosY, zLevel, activeItem.middlePosX + smallerWidth, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX + smallerWidth + 1, activeItem.middlePosY, zLevel, activeItem.middlePosX + smallerWidth, activeItem.middlePosY, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end

				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - 0.5 and hitPosX <= activeItem.middlePosX + 0.5 and hitPosY >= activeItem.middlePosY - smallerHeight - 1 and hitPosY <= activeItem.middlePosY - smallerHeight and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[4] == -1 then
					moveRoadmark(hitPosX, hitPosY, "move", 0, -1)
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY - smallerHeight - 1, zLevel, activeItem.middlePosX, activeItem.middlePosY - smallerHeight, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY - smallerHeight - 1, zLevel, activeItem.middlePosX, activeItem.middlePosY - smallerHeight, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end

				if not isCursorWithinPanel() and not activeItemOffsets and not activeDirectX and (hitPosX >= activeItem.middlePosX - 0.5 and hitPosX <= activeItem.middlePosX + 0.5 and hitPosY >= activeItem.middlePosY + smallerHeight and hitPosY <= activeItem.middlePosY + smallerHeight + 1 and hitPosZ >= zLevel - 0.5 and hitPosZ <= zLevel + 0.5) or activeItemOffsets and activeItemOffsets[7] == "move" and activeItemOffsets[4] == 1 then
					moveRoadmark(hitPosX, hitPosY, "move", 0, 1)
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY + smallerHeight + 1, zLevel, activeItem.middlePosX, activeItem.middlePosY + smallerHeight, zLevel, moveIcon, 1, tocolor(124, 197, 118, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				else
					dxDrawMaterialLine3D(activeItem.middlePosX, activeItem.middlePosY + smallerHeight + 1, zLevel, activeItem.middlePosX, activeItem.middlePosY + smallerHeight, zLevel, moveIcon, 1, tocolor(255, 255, 255, 200), activeItem.middlePosX, activeItem.middlePosY, zLevel + 10)
				end
			elseif activeItem.mode == "scale" and getKeyState("mouse1") then
				if not activeItem.canResize then
					activeItem.canResize = true
				end
			end
		end
	end
)

function moveRoadmark(x, y, mode, x2, y2)
	if getKeyState("mouse1") then
		if mode == "rotate" then
			if not activeItemOffsets then
				activeItemOffsets = {
					activeItem.middlePosX,
					activeItem.middlePosY,
					math.atan2(y - activeItem.middlePosY, x - activeItem.middlePosX) + math.rad(90) - math.rad(activeItem.rotation),
					mode
				}
			end
			
			if x ~= -1000 then
				local preRotation = math.atan2(y - activeItemOffsets[2], x - activeItemOffsets[1]) + math.rad(90) - activeItemOffsets[3]
				
				if snapRotation then
					preRotation = math.ceil(preRotation / math.rad(snapRotation)) * math.rad(snapRotation)
				end
				
				activeItem.rotation = math.ceil(math.deg(preRotation) % 360)
				
				if snapRotation == 90 and math.floor(lastPreRotation) ~= activeItem.rotation and getTickCount() - rotationSoundTick >= 175 then
					playSound("files/sounds/rotate.mp3")
					rotationSoundTick = getTickCount()
				end
				lastPreRotation = activeItem.rotation
			end
		elseif mode == "scale" then
			local cameraX, cameraY, cameraZ, faceTowardX, faceTowardY, faceTowardZ = getCameraMatrix()
			local cameraAndItemRotation = math.atan2(faceTowardX - cameraX, faceTowardY - cameraY) + math.rad(activeItem.rotation)
			
			if not activeItemOffsets then
				local xoff = ((activeItem.middlePosY - y) * math.sin(cameraAndItemRotation) + (activeItem.middlePosX - x) * -math.cos(cameraAndItemRotation))
				local yoff = ((activeItem.middlePosY - y) * math.cos(cameraAndItemRotation) + (activeItem.middlePosX - y) * math.sin(cameraAndItemRotation))
				activeItemOffsets = {
					activeItem.middlePosX,
					activeItem.middlePosY,
					activeItem.scale + (xoff + yoff),
					mode
				}
			end
			
			if x ~= -1000 then
				local xoff = ((activeItemOffsets[2] - y) * math.sin(cameraAndItemRotation) + (activeItemOffsets[1] - x) * -math.cos(cameraAndItemRotation))
				local yoff = ((activeItemOffsets[2] - y) * math.cos(cameraAndItemRotation) + (activeItemOffsets[1] - y) * math.sin(cameraAndItemRotation))
				activeItem.scale = activeItemOffsets[3] - (xoff + yoff)
				activeItem.scale = math.max(itemScaleMinimum, math.min(itemScaleMaximum, activeItem.scale))
			end
		elseif mode == "move" then
			if not activeItemOffsets then
				activeItemOffsets = {x, y, x2, y2, activeItem.middlePosX, activeItem.middlePosY, mode, activeItem.startPosX, activeItem.startPosY, activeItem.endPosX, activeItem.endPosY, activeItem.faceTowardX, activeItem.faceTowardY, activeItem.createdPosX, activeItem.createdPosY, activeItem.normalPosX, activeItem.normalPosY}
			end
			
			if x ~= -1000 then
				local xoff = (x - activeItemOffsets[1]) * math.abs(activeItemOffsets[3])
				local yoff = (y - activeItemOffsets[2]) * math.abs(activeItemOffsets[4])
				
				activeItem.middlePosX = activeItemOffsets[5] + xoff
				activeItem.middlePosY = activeItemOffsets[6] + yoff
				activeItem.oldPosX = activeItem.middlePosX
				activeItem.oldPosY = activeItem.middlePosY
				activeItem.startPosX = activeItemOffsets[8] + xoff
				activeItem.startPosY = activeItemOffsets[9] + yoff
				activeItem.endPosX = activeItemOffsets[10] + xoff
				activeItem.endPosY = activeItemOffsets[11] + yoff
				activeItem.faceTowardX = activeItemOffsets[12] + xoff
				activeItem.faceTowardY = activeItemOffsets[13] + yoff
				
				if activeItem.isStripe then
					activeItem.createdPosX = activeItemOffsets[14] + xoff
					activeItem.createdPosY = activeItemOffsets[15] + yoff
					activeItem.normalPosX = activeItemOffsets[16] + xoff
					activeItem.normalPosY = activeItemOffsets[17] + yoff
				end
			end
		end
	elseif activeItemOffsets then
		activeItemOffsets = nil
	end
end

function streamRoadmarks()
	while true do
		local cameraX, cameraY, cameraZ = getCameraMatrix()
		local processedThreads = 0
		
		for k,v in pairs(realRoadmarks) do
			local x, y, z = (v.x1 or v.x0) - cameraX, (v.y1 or v.y0) - cameraY, (v.z1 or v.z0) - cameraZ
			local distance = x * x + y * y + z * z
			local visibility = (v.scale or 2) * maxVisibleDistanceForRoadmarks
			visibility = visibility * visibility
			
			if streamedRoadmarks[k] then
				if distance > visibility then
					if v.isStripe then
						if isElement(v.renderTarget) then
							destroyElement(v.renderTarget)
						end
					end
					
					streamedRoadmarks[k] = nil
				end
			elseif distance <= visibility then
				streamedRoadmarks[k] = true
				
				if v.isStripe then
					createStripe(k, true, v.x0, v.y0, v.z0, v.width, v.height)
				end
			end
			
			processedThreads = processedThreads + 1
			if processedThreads == 64 then
				coroutine.yield()
				processedThreads = 0
				cameraX, cameraY, cameraZ = getCameraMatrix()
			end
		end
		
		coroutine.yield()
	end
end

function unloadEditor()
	setElementData(localPlayer, "isEditingRoadmark", false)
	activeItem = nil
	selectedPanelItem = false
	processMainMenu()
	isPanelActive = false
	panelFadeIn = false
	panelFadeOut = getTickCount()
end

function drawTooltip(text)
	local tooltipWidth = dxGetTextWidth(text, 0.8, RobotoLightFont) + 15
	dxDrawRectangle(cursorX + 16.5, cursorY + 15.5, tooltipWidth, RobotoLightFontHeight, tocolor(22, 20, 22, 230 * panelFadeProgress), true)
	dxDrawText(text, cursorX + 16.5, cursorY + 15.5, cursorX + 16.5 + tooltipWidth, cursorY + 15.5 + RobotoLightFontHeight, tocolor(255, 255, 255, alpha255), 0.8, RobotoLightFont, "center", "center", false, false, true)
end

setCursorAlpha(255)

function drawActiveMarkMenu()
	if adminMode then
		local cameraX, cameraY, cameraZ = getCameraMatrix()
		local alpha225 = 225 * panelFadeProgress
		
		for k in pairs(streamedRoadmarks) do
			local markData = realRoadmarks[k]
			if markData and not markData.isEditing then
				if markData.interior == currentInterior and markData.dimension == currentDimension then
					local middleX, middleY, middleZ = markData.x0, markData.y0, markData.z0
					if markData.isStripe then
						middleX = markData.x0mid
						middleY = markData.y0mid
						middleZ = markData.z0mid
					end
					
					local menuPosX, menuPosY = getScreenFromWorldPosition(middleX, middleY, middleZ + 0.25)
					if menuPosX and menuPosY then
						local distanceBetweenMark = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, middleX, middleY, middleZ + 0.25)
							
						if distanceBetweenMark <= 20 then
							local distanceMultiplier = interpolateBetween(1, 0, 0, 0, 0, 0, distanceBetweenMark / 100, "OutQuad")
							
							if distanceMultiplier > 0 then
								local menuIconSize = size32 * distanceMultiplier
								local barX = menuPosX - (menuIconSize * 2) * 0.5
								local barY = menuPosY - menuIconSize
							
								local drawedTimestamp = getRealTime(markData.creationTime)
								local drawedTime = string.format("%.4i/%.2i/%.2i %.2i:%.2i:%.2i", drawedTimestamp.year + 1900, drawedTimestamp.month + 1, drawedTimestamp.monthday, drawedTimestamp.hour, drawedTimestamp.minute, drawedTimestamp.second)
								
								local labelText = markData.playerName .. " (A:#0095d9" .. markData.accountId  .. "#ffffff;C:#0095d9" .. markData.characterId .. "#ffffff)\n" .. drawedTime .. ((not markData.isProtected and "") or "\n#dc143cPROTECTED")
								local labelWidth, labelHeight = dxGetTextWidth(labelText, distanceMultiplier, RobotoFont, true), RobotoFontHeight * distanceMultiplier
								local labelPosX, labelPosY = menuPosX - labelWidth * 0.5, barY - menuIconSize * 1.25 -  (labelHeight * distanceMultiplier) * 0.5
								
								dxDrawText(string.gsub(labelText, "#%x%x%x%x%x%x", ""), labelPosX + 1, labelPosY + 1, labelPosX + labelWidth + 1, labelPosY + labelHeight + 1, tocolor(0, 0, 0, alpha255), distanceMultiplier, RobotoFont, "center", "center", false, false, false, true, true)
								dxDrawText(labelText, labelPosX, labelPosY, labelPosX + labelWidth, labelPosY + labelHeight, tocolor(255, 255, 255, alpha255), distanceMultiplier, RobotoFont, "center", "center", false, false, false, true, true)
							
								if distanceBetweenMark <= 15 then
									dxDrawRectangle(barX, barY, menuIconSize * 2, menuIconSize, tocolor(32, 30, 32, alpha225))
									
									local protectIcon = markData.isProtected and "unlock" or "lock"
									if isCursorWithinArea(cursorX, cursorY, barX, barY, menuIconSize, menuIconSize) then
										activeDirectX = "adminMode:togProtect:" .. k
										drawTooltip(markData.isProtected and "Levédés feloldása" or "Levédés")
										dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/" .. protectIcon .. ".png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
									else
										dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/" .. protectIcon .. ".png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
									end
									
									if markData.isProtected then
										dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(80, 80, 80, alpha255))
									else
										if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize, barY, menuIconSize, menuIconSize) then
											activeDirectX = "adminMode:delete:" .. k
											drawTooltip("Törlés")
											dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(215, 89, 89, alpha255))
										else
											dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										end
									end
								end
							end
						end
					end
				end
			end
		end
	elseif not activeItem then
		local cameraX, cameraY, cameraZ = getCameraMatrix()
		local alpha225 = 225 * panelFadeProgress
		
		for k in pairs(streamedRoadmarks) do
			local markData = realRoadmarks[k]
			if markData and not markData.isEditing then
				if markData.interior == currentInterior and markData.dimension == currentDimension then
					local middleX, middleY, middleZ = markData.x0, markData.y0, markData.z0
					if markData.isStripe then
						middleX = markData.x0mid
						middleY = markData.y0mid
						middleZ = markData.z0mid
					end
					
					local menuPosX, menuPosY = getScreenFromWorldPosition(middleX, middleY, middleZ + 0.25)
					if menuPosX and menuPosY then
						local distanceBetweenMark = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, middleX, middleY, middleZ + 0.25)
							
						if distanceBetweenMark <= 10 then
							local distanceMultiplier = interpolateBetween(1, 0, 0, 0, 0, 0, distanceBetweenMark / 150, "OutQuad")
							
							if distanceMultiplier > 0 then
								local iconsVisible = markData.isProtected and 1 or (markData.isStripe and 1 or 2)
								local menuIconSize = size32 * distanceMultiplier
								local barX = menuPosX - (menuIconSize * iconsVisible) * 0.5
								local barY = menuPosY - menuIconSize
								
								if markData.isProtected then
									dxDrawRectangle(barX, barY, menuIconSize, menuIconSize, tocolor(32, 30, 32, alpha225))
									dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/lock.png", 0, 0, 0, tocolor(125, 125, 125, alpha255))
								else
									if not markData.isStripe then
										if isCursorWithinArea(cursorX, cursorY, barX, barY, menuIconSize, menuIconSize) then
											activeDirectX = "editMark:" .. k
											drawTooltip("Szerkesztés")
											dxDrawRectangle(barX, barY, menuIconSize, menuIconSize, tocolor(0, 149, 217, alpha225))
											dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/edit.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										else
											dxDrawRectangle(barX, barY, menuIconSize, menuIconSize, tocolor(32, 30, 32, alpha225))
											dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/edit.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										end
										
										if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize, barY, menuIconSize, menuIconSize) then
											activeDirectX = "editMark:" .. k .. ":copy"
											drawTooltip("Másolás")
											dxDrawRectangle(barX + menuIconSize, barY, menuIconSize, menuIconSize, tocolor(0, 149, 217, alpha225))
											dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/copy.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										else
											dxDrawRectangle(barX + menuIconSize, barY, menuIconSize, menuIconSize, tocolor(32, 30, 32, alpha225))
											dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/copy.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										end
									else
										if isCursorWithinArea(cursorX, cursorY, barX, barY, menuIconSize, menuIconSize) then
											activeDirectX = "deleteStripe:" .. k
											drawTooltip("Törlés")
											dxDrawRectangle(barX, barY, menuIconSize, menuIconSize, tocolor(0, 149, 217, alpha225))
											dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										else
											dxDrawRectangle(barX, barY, menuIconSize, menuIconSize, tocolor(32, 30, 32, alpha225))
											dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	if activeItem and not adminMode then
		if not activeItem.canFreeMove and not activeItem.isStripe or not activeItem.canFreeMove and activeItem.isStripe and activeItem.width >= stripeMinWidth and activeItem.height >= stripeMinHeight then
			local menuPosX, menuPosY = getScreenFromWorldPosition(activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 0.25)
			if menuPosX and menuPosY then
				local cameraX, cameraY, cameraZ = getCameraMatrix()
				local distanceBetweenMark = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, activeItem.middlePosX, activeItem.middlePosY, activeItem.middlePosZ + 0.25)
				
				if distanceBetweenMark <= 20 then
					local distanceMultiplier = interpolateBetween(1, 0, 0, 0, 0, 0, distanceBetweenMark / 100, "OutQuad")
					
					if distanceMultiplier > 0 then
						local menuIconSize = size32 * distanceMultiplier
						local barY = menuPosY - menuIconSize
						
						if not activeItem.isStripe then
							local barX = menuPosX - (menuIconSize * 5) * 0.5
							
							dxDrawRectangle(barX, barY, menuIconSize * 5, menuIconSize, tocolor(32, 30, 32, 225 * panelFadeProgress))
							
							if isCursorWithinArea(cursorX, cursorY, barX, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:move"
								drawTooltip("Mozgatás mód (Mozgatás egérrel: duplaklikk)")
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							elseif activeItem.mode == "move" then
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:rotate"
								drawTooltip("Forgatás mód")
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/rotate.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							elseif activeItem.mode == "rotate" then
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/rotate.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/rotate.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:scale"
								drawTooltip("Méretezés mód")
								dxDrawImage(barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							elseif activeItem.mode == "scale" then
								dxDrawImage(barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:exit"
								drawTooltip("Kilépés a szerkesztésből")
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:delete"
								drawTooltip("Törlés")
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/trash.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/trash.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if activeItem.mode == "rotate" then
								local barText = math.floor(activeItem.rotation * 10) / 10 .. "°"
								local barWidth = dxGetTextWidth(barText, 1, RobotoLightFont) * distanceMultiplier
								local barX = menuPosX - barWidth * 0.5
								local barY = barY - menuIconSize - respc(5) * distanceMultiplier
								local barHeight = (RobotoLightFontHeight + respc(4)) * distanceMultiplier
								barWidth = barWidth + respc(6) * distanceMultiplier
								
								dxDrawRectangle(barX, barY, barWidth, barHeight, tocolor(0, 0, 0, 150 * panelFadeProgress))
								dxDrawText(barText, barX, barY, barX + barWidth, barY + barHeight, tocolor(255, 255, 255, alpha255), distanceMultiplier, RobotoLightFont, "center", "center")
							elseif activeItem.mode == "scale" then
								local barText = math.floor(activeItem.scale * 10) / 10 .. "x"
								local barWidth = dxGetTextWidth(barText, 1, RobotoLightFont) * distanceMultiplier
								local barX = menuPosX - barWidth * 0.5
								local barY = barY - menuIconSize - respc(5) * distanceMultiplier
								local barHeight = (RobotoLightFontHeight + respc(4)) * distanceMultiplier
								barWidth = barWidth + respc(6) * distanceMultiplier
								
								dxDrawRectangle(barX, barY, barWidth, barHeight, tocolor(0, 0, 0, 150 * panelFadeProgress))
								dxDrawText(barText, barX, barY, barX + barWidth, barY + barHeight, tocolor(255, 255, 255, alpha255), distanceMultiplier, RobotoLightFont, "center", "center")
							end
						else
							local barX = menuPosX - (menuIconSize * 4) * 0.5
						
							dxDrawRectangle(barX, barY, menuIconSize * 4, menuIconSize, tocolor(32, 30, 32, 225 * panelFadeProgress))
							
							if isCursorWithinArea(cursorX, cursorY, barX, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:move"
								drawTooltip("Mozgatás mód (Mozgatás egérrel: duplaklikk)")
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							elseif activeItem.mode == "move" then
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX, barY, menuIconSize, menuIconSize, "files/icons/move.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:scale"
								drawTooltip("Méretezés mód")
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							elseif activeItem.mode == "scale" then
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/scale.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:exit"
								drawTooltip("Kilépés a szerkesztésből")
								dxDrawImage(barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/delete.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
							
							if isCursorWithinArea(cursorX, cursorY, barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize) then
								activeDirectX = "activeMode:delete"
								drawTooltip("Törlés")
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/trash.png", 0, 0, 0, tocolor(0, 149, 217, alpha255))
							else
								dxDrawImage(barX + menuIconSize + menuIconSize + menuIconSize, barY, menuIconSize, menuIconSize, "files/icons/trash.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
							end
						end
					end
				end
			end
		end
	end
	
	if not isMainMenuActive() then
		if isCursorShowing() then
			if activeItem and activeItem.isStripe then
				if isCursorWithinPanel() or not activeItem.canResize and activeItem.mode ~= "scale" then
					dxDrawImage(cursorX, cursorY, 21.5, 29, "files/icons2/normal.png", 0, 0, 0, tocolor(255, 255, 255, alpha255), true)
				end
			else
				if activeItem and not activeItem.canPlace then
					dxDrawImage(cursorX, cursorY, 33, 31, "files/icons2/impossible.png", 0, 0, 0, tocolor(255, 255, 255, alpha255), true)
				elseif not activeItem or activeItem then
					dxDrawImage(cursorX, cursorY, 21.5, 29, "files/icons2/normal.png", 0, 0, 0, tocolor(255, 255, 255, alpha255), true)
				end
			end
		end
		setCursorAlpha(255 - alpha255)
	else
		setCursorAlpha(255)
	end
end

function onClientPanelKey(key, press)
	if not isPanelActive then
		return
	end
	
	if not press then
		return
	end
	
	if activeColorInput then
		if key == "backspace" then
			cancelEvent()
			
			if activeColorInput == "hex" then
				if utf8.len(colorPanel.colorInputs.hex[activeColorInput]) > 1 then
					colorPanel.colorInputs.hex[activeColorInput] = utf8.sub(colorPanel.colorInputs.hex[activeColorInput], 1, utf8.len(colorPanel.colorInputs.hex[activeColorInput]) - 1)
				end
			else
				if utf8.len(colorPanel.colorInputs.rgb[activeColorInput]) > 0 then
					colorPanel.colorInputs.rgb[activeColorInput] = tonumber(utf8.sub(colorPanel.colorInputs.rgb[activeColorInput], 1, utf8.len(colorPanel.colorInputs.rgb[activeColorInput]) - 1)) or 0
					
					colorPanel.hue, colorPanel.saturation, colorPanel.lightness = rgbToHsl(colorPanel.colorInputs.rgb.red / 255, colorPanel.colorInputs.rgb.green / 255, colorPanel.colorInputs.rgb.blue / 255)
					colorPanel.colorInputs.hex.hex = rgbToHex(colorPanel.colorInputs.rgb.red, colorPanel.colorInputs.rgb.green, colorPanel.colorInputs.rgb.blue)
					colorPanel.selectedColor = tocolor(colorPanel.colorInputs.rgb.red, colorPanel.colorInputs.rgb.green, colorPanel.colorInputs.rgb.blue)
					
					if activeItem then
						activeItem.color = colorPanel.selectedColor
					end
				end
			end
		end
	end
	
	if isCursorWithinArea(cursorX, cursorY, panelPosX, panelPosY, panelWidth, panelHeight) then
		if key == "mouse_wheel_down" then
			if #roadmarksList[activePanelCategory] > panelVisibleItems and panelCategoryPages[activePanelCategory] < #roadmarksList[activePanelCategory] - panelVisibleItems then
				scrollbarInterpolationTick = getTickCount()
				panelCategoryPages[activePanelCategory] = panelCategoryPages[activePanelCategory] + panelVisibleItems
				
				if panelCategoryPages[activePanelCategory] > #roadmarksList[activePanelCategory] - panelVisibleItems then
					panelCategoryOldPages[activePanelCategory] = panelCategoryPages[activePanelCategory] - (#roadmarksList[activePanelCategory] - panelVisibleItems)
					panelCategoryPages[activePanelCategory] = #roadmarksList[activePanelCategory] - panelVisibleItems
				end
			end
		elseif key == "mouse_wheel_up" then
			if #roadmarksList[activePanelCategory] > panelVisibleItems and panelCategoryPages[activePanelCategory] > 0 then
				scrollbarInterpolationTick = getTickCount()
				
				if panelCategoryOldPages[activePanelCategory] then
					panelCategoryPages[activePanelCategory] = panelCategoryPages[activePanelCategory] - panelVisibleItems + panelCategoryOldPages[activePanelCategory]
					panelCategoryOldPages[activePanelCategory] = false
				else
					panelCategoryPages[activePanelCategory] = panelCategoryPages[activePanelCategory] - panelVisibleItems
				end
				
				if panelCategoryPages[activePanelCategory] < 0 then
					panelCategoryPages[activePanelCategory] = 0
				end
			end
		end
	end
end

function drawColorPicker()
	if not activeItem then
		return
	end
	
	if not colorPanel.isActive then
		return
	end
	
	if colorPanel.isActive == "admin" then
		dxDrawRectangle(colorPanel.posX, colorPanel.posY, colorPanel.width, colorPanel.height, tocolor(12, 10, 12, 200 * panelFadeProgress))
		dxDrawImage(colorPanel.palettePosX, colorPanel.palettePosY, colorPanel.paletteWidth, colorPanel.paletteHeight, "files/colorpalette.png", 0, 0, 0, tocolor(255, 255, 255, alpha255))
		
		if isCursorWithinArea(cursorX, cursorY, colorPanel.palettePosX, colorPanel.palettePosY, colorPanel.paletteWidth, colorPanel.paletteHeight) and getKeyState("mouse1") and not activeItem.canFreeMove then
			colorPanel.hue = (cursorX - colorPanel.palettePosX) / colorPanel.paletteWidth
			colorPanel.saturation = (colorPanel.paletteHeight + colorPanel.palettePosY - cursorY) / colorPanel.paletteHeight

			local r, g, b = hslToRgb(colorPanel.hue, colorPanel.saturation, colorPanel.lightness)
			colorPanel.selectedColor = tocolor(r * 255, g * 255, b * 255, 255)
			
			processColorpickerUpdate(true)
		end
		
		local colorX = (colorPanel.palettePosX + (colorPanel.hue * colorPanel.paletteWidth)) - 5
		local colorY = (colorPanel.palettePosY + (1 - colorPanel.saturation) * colorPanel.paletteHeight) - 5
		local r, g, b = hslToRgb(colorPanel.hue, colorPanel.saturation, 0.5)
		
		dxDrawRectangle(colorX - 1, colorY - 1, 10 + 2, 10 + 2, tocolor(0, 0, 0, alpha255))
		dxDrawRectangle(colorX, colorY, 10, 10, tocolor(r * 255, g * 255, b * 255, alpha255))
		
		dxDrawText("RGB:", colorPanel.palettePosX, colorPanel.inputPosY, colorPanel.palettePosX + colorPanel.paletteWidth, colorPanel.inputPosY + colorPanel.barHeight, tocolor(255, 255, 255, alpha255), 1, RobotoLightFont, "left", "center")
		
		for k, v in ipairs({"red", "green", "blue"}) do
			local rowX = colorPanel.palettePosX + 45 + ((k - 1) * (colorPanel.colorInputs.rgb.width + 3))
			
			if activeColorInput == v then
				dxDrawRectangle(rowX - 2, colorPanel.inputPosY - 2, colorPanel.colorInputs.rgb.width + 4, colorPanel.barHeight + 4, tocolor(0, 149, 217, alpha255))
			end
			dxDrawRectangle(rowX, colorPanel.inputPosY, colorPanel.colorInputs.rgb.width, colorPanel.barHeight, tocolor(0, 0, 0, 125 * panelFadeProgress))
		
			if isCursorWithinArea(cursorX, cursorY, rowX, colorPanel.inputPosY, colorPanel.colorInputs.rgb.width, colorPanel.barHeight) and not activeItem.canFreeMove then
				hoveredInputfield = v
			end
			
			dxDrawText(colorPanel.colorInputs.rgb[v], rowX, colorPanel.inputPosY, rowX + colorPanel.colorInputs.rgb.width, colorPanel.inputPosY + colorPanel.barHeight, tocolor(255, 255, 255, alpha255), 1, RobotoFont, "center", "center")
		end
		
		dxDrawText("HEX:", colorPanel.palettePosX, colorPanel.inputPosY, colorPanel.palettePosX + colorPanel.paletteWidth - colorPanel.colorInputs.hex.width - 5, colorPanel.inputPosY + colorPanel.barHeight, tocolor(255, 255, 255, alpha255), 1, RobotoLightFont, "right", "center")
		if activeColorInput == "hex" then
			dxDrawRectangle(colorPanel.palettePosX + colorPanel.paletteWidth - colorPanel.colorInputs.hex.width - 2, colorPanel.inputPosY - 2, colorPanel.colorInputs.hex.width + 4, colorPanel.barHeight + 4, tocolor(0, 149, 217, alpha255))
		end
		dxDrawRectangle(colorPanel.palettePosX + colorPanel.paletteWidth - colorPanel.colorInputs.hex.width, colorPanel.inputPosY, colorPanel.colorInputs.hex.width, colorPanel.barHeight, tocolor(0, 0, 0, 125 * panelFadeProgress))
		
		if isCursorWithinArea(cursorX, cursorY, colorPanel.palettePosX + colorPanel.paletteWidth - colorPanel.colorInputs.hex.width, colorPanel.inputPosY, colorPanel.colorInputs.hex.width, colorPanel.barHeight) and not activeItem.canFreeMove then
			hoveredInputfield = "hex"
		end
		dxDrawText(colorPanel.colorInputs.hex.hex, colorPanel.palettePosX + colorPanel.paletteWidth - colorPanel.colorInputs.hex.width, colorPanel.inputPosY, colorPanel.palettePosX + colorPanel.paletteWidth, colorPanel.inputPosY + colorPanel.barHeight, tocolor(255, 255, 255, alpha255), 1, RobotoFont, "center", "center")
		
		dxDrawRectangle(colorPanel.palettePosX - 1, colorPanel.luminancePosY - 1, colorPanel.paletteWidth + 2, colorPanel.luminanceHeight + 2, tocolor(255, 255, 255, alpha255))
		
		for i = 0, colorPanel.paletteWidth do
			local r, g, b = hslToRgb(colorPanel.hue, colorPanel.saturation, i / colorPanel.paletteWidth)
			
			dxDrawRectangle(colorPanel.palettePosX + i, colorPanel.luminancePosY, 1, colorPanel.luminanceHeight, tocolor(r * 255, g * 255, b * 255, alpha255))
		end
		
		dxDrawRectangle(colorPanel.palettePosX + reMap(colorPanel.lightness, 0, 1, 0, colorPanel.paletteWidth), colorPanel.luminancePosY - 5, 5, colorPanel.luminanceHeight + 10, tocolor(255, 255, 255, alpha255))
		
		if isCursorWithinArea(cursorX, cursorY, colorPanel.palettePosX - 5, colorPanel.luminancePosY - 5, colorPanel.paletteWidth + 10, colorPanel.luminanceHeight + 10) and getKeyState("mouse1") and not activeItem.canFreeMove then
			colorPanel.lightness = reMap(cursorX - colorPanel.palettePosX, 0, colorPanel.paletteWidth, 0, 1)
			processColorpickerUpdate(true)
		end
	elseif colorPanel.isActive then
		local width = colorPanel.width / #availableColorsForItem
		local y = colorPanel.posY + colorPanel.height - 40
		
		dxDrawRectangle(colorPanel.posX - 3, y - 3, colorPanel.width + 6, 40 + 6, tocolor(0, 0, 0, 200 * panelFadeProgress))
		
		for i = 1, #availableColorsForItem do
			local x = colorPanel.posX + ((i - 1) * width)
		
			if isCursorWithinArea(cursorX, cursorY, x, y, width, 40) and not activeDirectX then
				activeDirectX = "defaultColor:" .. i
			else
				local color = availableColorsForItem[i]
				dxDrawRectangle(x, y, width, 40, tocolor(color[1], color[2], color[3], alpha255))
			end
		end
		
		if activeDirectX and string.find(activeDirectX, "defaultColor:") then
			local i = tonumber(split(activeDirectX, ":")[2])
			local color = availableColorsForItem[i]
			dxDrawRectangle(colorPanel.posX + ((i - 1) * width), y, width, 40, tocolor(color[1], color[2], color[3], 150 * panelFadeProgress))
			dxDrawRectangle(colorPanel.posX + ((i - 1) * width) + 3, y + 3, width - 6, 40 - 6, tocolor(color[1], color[2], color[3], alpha255))
		end
	end
end

function isCursorWithinPanel()
	if isCursorWithinArea(cursorX, cursorY, panelPosX, panelPosY, panelWidth, panelHeight) or isCursorWithinArea(cursorX, cursorY, panelPosX, menuPosY, menuWidth, menuHeight) or isCursorWithinArea(cursorX, cursorY, mainMenuPosX, menuPosY, mainMenuWidth, menuHeight) or activeDirectX then
		return true
	end
	
	return false
end

function rotateAround(angle, x, y)
	angle = math.rad(angle)
	local cosinus, sinus = math.cos(angle), math.sin(angle)
	return x * cosinus - y * sinus, x * sinus + y * cosinus
end

function onClientPanelCharacter(character)
	if not colorPanel.isActive then
		return
	end
	
	if not activeColorInput then
		return
	end
	
	character = utf8.upper(character)
	
	if activeColorInput == "hex" then
		if utf8.len(colorPanel.colorInputs.hex[activeColorInput]) < 7 and utf8.find("0123456789ABCDEF", character) then
			colorPanel.colorInputs.hex[activeColorInput] = colorPanel.colorInputs.hex[activeColorInput] .. character
		end
		
		if utf8.len(colorPanel.colorInputs.hex[activeColorInput]) >= 7 then
			local r, g, b = fixRGB(hexToRgb(colorPanel.colorInputs.hex[activeColorInput]))
			
			colorPanel.hue, colorPanel.saturation, colorPanel.lightness = rgbToHsl(r / 255, g / 255, b / 255)
			colorPanel.colorInputs.rgb.red = r
			colorPanel.colorInputs.rgb.green = g
			colorPanel.colorInputs.rgb.blue = b
			colorPanel.selectedColor = tocolor(r, g, b)
			
			if activeItem then
				activeItem.color = colorPanel.selectedColor
			end
		end
	else
		if tonumber(character) then
			if utf8.len(colorPanel.colorInputs.rgb[activeColorInput]) < 3 then
				colorPanel.colorInputs.rgb[activeColorInput] = tonumber(colorPanel.colorInputs.rgb[activeColorInput] .. character)
			end
			
			colorPanel.hue, colorPanel.saturation, colorPanel.lightness = rgbToHsl(colorPanel.colorInputs.rgb.red / 255, colorPanel.colorInputs.rgb.green / 255, colorPanel.colorInputs.rgb.blue / 255)
			colorPanel.colorInputs.hex.hex = rgbToHex(colorPanel.colorInputs.rgb.red, colorPanel.colorInputs.rgb.green, colorPanel.colorInputs.rgb.blue)
			colorPanel.selectedColor = tocolor(colorPanel.colorInputs.rgb.red, colorPanel.colorInputs.rgb.green, colorPanel.colorInputs.rgb.blue)
			
			if activeItem then
				activeItem.color = colorPanel.selectedColor
			end
		end
	end
end

function processColorpickerUpdate(selecting)
	if selecting then
		local r, g, b = hslToRgb(colorPanel.hue, colorPanel.saturation, colorPanel.lightness)
		r, g, b = fixRGB(r * 255, g * 255, b * 255)
		
		colorPanel.colorInputs.rgb.red = r
		colorPanel.colorInputs.rgb.green = g
		colorPanel.colorInputs.rgb.blue = b
		colorPanel.colorInputs.hex.hex = rgbToHex(r, g, b)
		colorPanel.selectedColor = tocolor(r, g, b)
		
		if activeItem then
			activeItem.color = colorPanel.selectedColor
		end
	else
		local r, g, b, a = fixRGB(getColorFromDecimal(colorPanel.selectedColor))
		
		colorPanel.hue, colorPanel.saturation, colorPanel.lightness = rgbToHsl(r / 255, g / 255, b / 255)
		colorPanel.colorInputs.rgb.red = r
		colorPanel.colorInputs.rgb.green = g
		colorPanel.colorInputs.rgb.blue = b
		colorPanel.colorInputs.hex.hex = rgbToHex(r, g, b)
	end
end

function fixRGB(r, g, b, a)
	r = math.max(0, math.min(255, math.floor(r)))
	g = math.max(0, math.min(255, math.floor(g)))
	b = math.max(0, math.min(255, math.floor(b)))
	a = a and math.max(0, math.min(255, math.floor(a))) or 255
	
	return r, g, b, a
end

function hexToRgb(code)
	code = string.gsub(code, "#", "")
	return tonumber("0x" .. string.sub(code, 1, 2)), tonumber("0x" .. string.sub(code, 3, 4)), tonumber("0x" .. string.sub(code, 5, 6))
end

function rgbToHex(r, g, b, a)
	if (r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255) or (a and (a < 0 or a > 255)) then
		return nil
	end
	
	if a then
		return string.format("#%.2X%.2X%.2X%.2X", r, g, b, a)
	else
		return string.format("#%.2X%.2X%.2X", r, g, b)
	end
end

function hslToRgb(h, s, l)
	local lightnessValue
	
	if l < 0.5 then
		lightnessValue = l * (s + 1)
	else
		lightnessValue = (l + s) - (l * s)
	end
	
	local lightnessValue2 = l * 2 - lightnessValue
	local r = hueToRgb(lightnessValue2, lightnessValue, h + 1 / 3)
	local g = hueToRgb(lightnessValue2, lightnessValue, h)
	local b = hueToRgb(lightnessValue2, lightnessValue, h - 1 / 3)
	
	return r, g, b
end

function hueToRgb(l, l2, h)
	if h < 0 then
		h = h + 1
	elseif h > 1 then
		h = h - 1
	end

	if h * 6 < 1 then
		return l + (l2 - l) * h * 6
	elseif h * 2 < 1 then
		return l2
	elseif h * 3 < 2 then
		return l + (l2 - l) * (2 / 3 - h) * 6
	else
		return l
	end
end

function rgbToHsl(r, g, b)
	local maxValue = math.max(r, g, b)
	local minValue = math.min(r, g, b)
	local h, s, l = 0, 0, (minValue + maxValue) / 2

	if maxValue == minValue then
		h, s = 0, 0
	else
		local different = maxValue - minValue

		if l < 0.5 then
			s = different / (maxValue + minValue)
		else
			s = different / (2 - maxValue - minValue)
		end

		if maxValue == r then
			h = (g - b) / different
			
			if g < b then
				h = h + 6
			end
		elseif maxValue == g then
			h = (b - r) / different + 2
		else
			h = (r - g) / different + 4
		end

		h = h / 6
	end

	return h, s, l
end

function getColorFromDecimal(decimal)
	local red = bitExtract(decimal, 16, 8)
	local green = bitExtract(decimal, 8, 8)
	local blue = bitExtract(decimal, 0, 8)
	local alpha = bitExtract(decimal, 24, 8)
	
	return red, green, blue, alpha
end