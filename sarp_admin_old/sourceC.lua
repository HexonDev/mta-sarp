local screenWidth, screenHeight = guiGetScreenSize()
dxFont = dxCreateFont(":sarp_assets/fonts/CenturyGothicBold.ttf", 14, false, "cleartype")
local dxFont2 = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", 18, false, "cleartype")

local listPanelItems = false
local listPanelItemsVisible = 12
local listPanelPage = 0
local listPanelHeight = screenHeight * 0.6375
local listPanelItemHeight = (listPanelHeight - 45 - 35) / listPanelItemsVisible
local listPanelWidth = screenWidth * 0.5
local listPanelX = (screenWidth - listPanelWidth) * 0.5
local listPanelY = (screenHeight - listPanelHeight) * 0.5
local listPanelSearch = ""
local listPanelState = false

local adminCommands = {}

local flyingState = false
local flyKeys = {}

local spectateTarget = false
local lastSpectateUpdate = 0

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if dataName == "spectateTarget" and source == localPlayer then
			spectateTarget = getElementData(localPlayer, "spectateTarget")

			if spectateTarget then
				local targetInterior = getElementInterior(spectateTarget)
				local targetDimension = getElementDimension(spectateTarget)

				triggerServerEvent("updateSpectatePosition", localPlayer, targetInterior, targetDimension, tonumber(getElementData(spectateTarget, "currentCustomInterior") or 0))
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		if spectateTarget and isElement(spectateTarget) then
			local updatePosition = false
			local currentInterior = getElementInterior(localPlayer)
			local currentDimension = getElementDimension(localPlayer)
			local targetInterior = getElementInterior(spectateTarget)
			local targetDimension = getElementDimension(spectateTarget)

			if currentInterior ~= targetInterior then
				updatePosition = true
			end

			if currentDimension ~= targetDimension then
				updatePosition = true
			end

			if updatePosition and lastSpectateUpdate + 1000 <= getTickCount() then
				local customInterior = tonumber(getElementData(spectateTarget, "currentCustomInterior") or 0)

				triggerServerEvent("updateSpectatePosition", localPlayer, targetInterior, targetDimension, customInterior)

				lastSpectateUpdate = getTickCount()
			end
		end
	end
)

addEvent("sarp_adminC:toggleFly", true)
addEventHandler("sarp_adminC:toggleFly", root, 
	function ()
		if not isPedInVehicle(localPlayer) then
			toggleFly()
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if dataName == "flyMode" then
			if getElementData(source, dataName) then
				setElementCollisionsEnabled(source, false)
			else
				setElementCollisionsEnabled(source, true)
			end
		end
	end
)

function toggleFly()
	flyingState = not flyingState

	if flyingState then
		addEventHandler("onClientRender", getRootElement(), flyingRender)

		bindKey("lshift", "both", keyHandler)
		bindKey("rshift", "both", keyHandler)
		bindKey("lctrl", "both", keyHandler)
		bindKey("rctrl", "both", keyHandler)
		bindKey("mouse1", "both", keyHandler)

		bindKey("forwards", "both", keyHandler)
		bindKey("backwards", "both", keyHandler)
		bindKey("left", "both", keyHandler)
		bindKey("right", "both", keyHandler)

		bindKey("lalt", "both", keyHandler)
		bindKey("ralt", "both", keyHandler)

		bindKey("space", "both", keyHandler)

		setElementCollisionsEnabled(localPlayer, false)
	else
		removeEventHandler("onClientRender", getRootElement(), flyingRender)

		unbindKey("lshift", "both", keyHandler)
		unbindKey("rshift", "both", keyHandler)
		unbindKey("lctrl", "both", keyHandler)
		unbindKey("rctrl", "both", keyHandler)
		unbindKey("mouse1", "both", keyHandler)

		unbindKey("forwards", "both", keyHandler)
		unbindKey("backwards", "both", keyHandler)
		unbindKey("left", "both", keyHandler)
		unbindKey("right", "both", keyHandler)

		unbindKey("lalt", "both", keyHandler)
		unbindKey("ralt", "both", keyHandler)

		unbindKey("space", "both", keyHandler)

		setElementCollisionsEnabled(localPlayer, true)
	end
end

function flyingRender()
	local x, y, z = getElementPosition(localPlayer)
	local speed = 10

	if flyKeys.a == "down" then
		speed = 3
	elseif flyKeys.s == "down" then
		speed = 50
	end

	if flyKeys.f == "down" then
		local angle = getRotationFromCamera(0)

		setElementRotation(localPlayer, 0, 0, angle)

		angle = math.rad(angle)
		x = x + math.sin(angle) * 0.1 * speed
		y = y + math.cos(angle) * 0.1 * speed
	elseif flyKeys.b == "down" then
		local angle = getRotationFromCamera(180)

		setElementRotation(localPlayer, 0, 0, angle)

		angle = math.rad(angle)
		x = x + math.sin(angle) * 0.1 * speed
		y = y + math.cos(angle) * 0.1 * speed
	end

	if flyKeys.l == "down" then
		local angle = getRotationFromCamera(-90)

		setElementRotation(localPlayer, 0, 0, angle)

		angle = math.rad(angle)
		x = x + math.sin(angle) * 0.1 * speed
		y = y + math.cos(angle) * 0.1 * speed
	elseif flyKeys.r == "down" then
		local angle = getRotationFromCamera(90)

		setElementRotation(localPlayer, 0, 0, angle)

		angle = math.rad(angle)
		x = x + math.sin(angle) * 0.1 * speed
		y = y + math.cos(angle) * 0.1 * speed
	end

	if flyKeys.up == "down" then
		z = z + 0.1 * speed
	elseif flyKeys.down == "down" then
		z = z - 0.1 * speed
	end

	setElementPosition(localPlayer, x, y, z)
end

function keyHandler(key, state)
	if key == "lshift" or key == "rshift" or key == "mouse1" then
		flyKeys.s = state
	end
	if key == "lctrl" or key == "rctrl" then
		flyKeys.down = state
	end

	if key == "forwards" then
		flyKeys.f = state
	end
	if key == "backwards" then
		flyKeys.b = state
	end

	if key == "left" then
		flyKeys.l = state
	end
	if key == "right" then
		flyKeys.r = state
	end

	if key == "lalt" or key == "ralt" then
		flyKeys.a = state
	end

	if key == "space" then
		flyKeys.up = state
	end
end

function getRotationFromCamera(offset)
	local cameraX, cameraY, _, faceX, faceY = getCameraMatrix()
	local deltaX, deltaY = faceX - cameraX, faceY - cameraY
	local rotation = math.deg(math.atan(deltaY / deltaX))

	if (deltaY >= 0 and deltaX <= 0) or (deltaY <= 0 and deltaX <= 0) then
		rotation = rotation + 180
	end

	return -rotation + 90 + offset
end

addCommandHandler("getpos",
	function ()
		if (getElementData(localPlayer, "acc.adminLevel") or 0) >= 1 then
			outputChatBox("Pozíció: " .. table.concat({getElementPosition(localPlayer)}, ", "))
			outputChatBox("Rotácíó: " .. table.concat({getElementRotation(localPlayer)}, ", "))
			outputChatBox("Interior: " .. getElementInterior(localPlayer))
			outputChatBox("Dimenzió: " .. getElementDimension(localPlayer))

			local cx, cy, cz, lx, ly, lz = getCameraMatrix()
			outputChatBox("Kamera pozíció: " .. table.concat({cx, cy, cz}, ", "))
			outputChatBox("Kamera rotácíó: " .. table.concat({lx, ly, lz}, ", "))
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		triggerServerEvent("requestAdminCommands", localPlayer)
	end
)

addEvent("receiveAdminCommands", true)
addEventHandler("receiveAdminCommands", getRootElement(),
	function (data)
		adminCommands = data
	end
)

addCommandHandler("adminhelp",
	function ()
		if (getElementData(localPlayer, "acc.adminLevel") or 0) >= 6 then
			listPanelState = not listPanelState
			
			if listPanelState then
				if not listPanelItems then
					listPanelItems = {}
					
					for k,v in pairs(adminCommands) do
						if adminCMDs[k][1] <= getElementData(localPlayer, "acc.adminLevel") then
							table.insert(listPanelItems, {k, v})
						end
					end
				end
				
				addEventHandler("onClientRender", getRootElement(), onHelpRender, true, "low-1000")
				addEventHandler("onClientCharacter", getRootElement(), onHelpCharacter)
				addEventHandler("onClientKey", getRootElement(), onHelpKey)
				showCursor(true)
			else
				removeEventHandler("onClientRender", getRootElement(), onHelpRender)
				removeEventHandler("onClientCharacter", getRootElement(), onHelpCharacter)
				removeEventHandler("onClientKey", getRootElement(), onHelpKey)
				showCursor(false)
			end
		end
	end
)

function onHelpKey(key, pressDown)
	cancelEvent()

	if #listPanelItems > listPanelItemsVisible then
		if key == "mouse_wheel_down" and listPanelPage < #listPanelItems - listPanelItemsVisible then
			listPanelPage = listPanelPage + listPanelItemsVisible
		elseif key == "mouse_wheel_up" and listPanelPage > 0 then
			listPanelPage = listPanelPage - listPanelItemsVisible
		end
	end
	
	if pressDown and key == "backspace" then
		listPanelSearch = utf8.sub(listPanelSearch, 1, utf8.len(listPanelSearch) - 1)
		searchCommands()
	end
end

function onHelpCharacter(character)
	if isCursorShowing() then
		listPanelSearch = listPanelSearch .. character
		searchCommands()
	end
end

function searchCommands()
	listPanelItems = {}
	
	if utf8.len(listPanelSearch) < 1 then
		for k,v in pairs(adminCommands) do
			table.insert(listPanelItems, {k, v})
		end
	elseif tonumber(listPanelSearch) then
		if adminCommands[listPanelSearch] then
			table.insert(listPanelItems, tonumber(listPanelSearch))
		end
	else
		for k,v in pairs(adminCommands) do
			if utf8.find(utf8.lower(k), utf8.lower(listPanelSearch)) then
				table.insert(listPanelItems, {k, v})
			end
		end
	end
	
	listPanelPage = 0
end

function onHelpRender()
	dxDrawRoundedRectangle(listPanelX, listPanelY, listPanelWidth, listPanelHeight)
	
	dxDrawRectangle(listPanelX, listPanelY, listPanelWidth, 45, tocolor(50, 50, 50, 75))
	dxDrawText("#32b3efSA#ffffff:RP", listPanelX + 10, listPanelY + 10, 0, listPanelY + 10 + 30, tocolor(255, 255, 255), 1, dxFont2, "left", "center", false, false, false, true)
	dxDrawText("Admin parancsok", listPanelX + 10 + dxGetTextWidth("#32b3efSA#ffffff:RP", 1, dxFont2, true) + 10, listPanelY + 10, 0, listPanelY + 10 + 30, tocolor(255, 255, 255), 0.8, dxFont, "left", "center", false, false, false, true)

	local cursorX, cursorY = -1, -1
	if isCursorShowing() then
		local relX, relY = getCursorPosition()
		cursorX, cursorY = relX * screenWidth, relY * screenHeight
	end

	if cursorX >= listPanelX + listPanelWidth - 10 - 75 and cursorX <= listPanelX + listPanelWidth - 10 and cursorY >= listPanelY + (45 - 25) * 0.5 and cursorY <= listPanelY + (45 + 25) * 0.5 then
		dxDrawRoundedRectangle(listPanelX + listPanelWidth - 10 - 75, listPanelY + (45 - 25) * 0.5, 75, 25, tocolor(50, 179, 239))
		if getKeyState("mouse1") then
			listPanelState = false
			removeEventHandler("onClientRender", getRootElement(), onHelpRender)
			removeEventHandler("onClientCharacter", getRootElement(), onHelpCharacter)
			removeEventHandler("onClientKey", getRootElement(), onHelpKey)
			showCursor(false)
			return
		end
	else
		dxDrawRoundedRectangle(listPanelX + listPanelWidth - 10 - 75, listPanelY + (45 - 25) * 0.5, 75, 25, tocolor(50, 179, 239, 175))
	end
	dxDrawText("Bezárás", listPanelX + listPanelWidth - 10 - 75, listPanelY + (45 - 25) * 0.5, listPanelX + listPanelWidth - 10, listPanelY + (45 + 25) * 0.5, tocolor(255, 255, 255), 0.75, dxFont, "center", "center")

	for i = 1, listPanelItemsVisible do
		local y = listPanelY + 45 + (listPanelItemHeight * (i - 1))

		if i % 2 == 0 then
			dxDrawRectangle(listPanelX + 5, y, listPanelWidth - 15, listPanelItemHeight, tocolor(0, 0, 0, 75))
		else
			dxDrawRectangle(listPanelX + 5, y, listPanelWidth - 15, listPanelItemHeight, tocolor(0, 0, 0, 125))
		end

		local itemData = listPanelItems[i + listPanelPage]
		if itemData then
			dxDrawText("#32b3ef/" .. itemData[1] .. "#ffffff - " .. itemData[2], listPanelX + 10, y, 0, y + listPanelItemHeight, tocolor(255, 255, 255), 0.8, dxFont, "left", "center", false, false, false, true)
		end
	end

	if #listPanelItems > listPanelItemsVisible then
		local listHeight = listPanelItemHeight * listPanelItemsVisible
		dxDrawRectangle(listPanelX + listPanelWidth - 10, listPanelY + 45, 5, listHeight, tocolor(0, 0, 0, 200))
		dxDrawRectangle(listPanelX + listPanelWidth - 10, listPanelY + 45 + (listHeight / #listPanelItems) * math.min(listPanelPage, #listPanelItems - listPanelItemsVisible), 5, (listHeight / #listPanelItems) * listPanelItemsVisible, tocolor(50, 179, 239))
	end

	dxDrawRectangle(listPanelX, listPanelY + listPanelHeight - 35, listPanelWidth, 35, tocolor(50, 50, 50, 75))
	if utfLen(listPanelSearch) > 0 then
		dxDrawText(listPanelSearch, listPanelX + 10, listPanelY + listPanelHeight - 35, listPanelX + 10 + listPanelWidth - 20, listPanelY + listPanelHeight, tocolor(255, 255, 255), 0.8, dxFont, "left", "center")
	else
		dxDrawText("A kereséshez kezdj el gépelni...", listPanelX + 10, listPanelY + listPanelHeight - 35, listPanelX + 10 + listPanelWidth - 20, listPanelY + listPanelHeight, tocolor(200, 200, 200), 0.7, dxFont, "left", "center")
	end
end

function dxDrawRoundedRectangle(x, y, w, h, borderColor, bgColor, postGUI)
	borderColor = borderColor or tocolor(0, 0, 0, 200)
	bgColor = bgColor or borderColor

	dxDrawRectangle(x, y, w, h, bgColor, postGUI)
	dxDrawRectangle(x + 2, y - 1, w - 4, 1, borderColor, postGUI)
	dxDrawRectangle(x + 2, y + h, w - 4, 1, borderColor, postGUI)
	dxDrawRectangle(x - 1, y + 2, 1, h - 4, borderColor, postGUI)
	dxDrawRectangle(x + w, y + 2, 1, h - 4, borderColor, postGUI)
end