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

addEventHandler("onClientResourceStart", resourceRoot, function()
    loadFonts()
end)

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

local panelState = false
local selectedAnim = false

local panelAnimsW, panelAnimsH = respc(350), respc(450)
local panelAnimsX, panelAnimsY = (screenX - panelAnimsW) * 0.5, (screenY - panelAnimsH) * 0.5

local rowW, rowH = panelAnimsW - respc(20), respc(40)
local rowX, rowStartY = panelAnimsX + respc(10), panelAnimsY + 20

local seged = {}

addCommandHandler("animlist", function(cmd)
	panelState = not panelState
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
	for k, v in pairs(animations) do
		table.insert(seged, k)
	end
end)

addEventHandler("onClientKey", getRootElement(),
    function (key, press)
        if press then
            if panelState then
				local offset = scrollData["animsOffset"] or 0

				if key == "mouse_wheel_down" and offset < #seged - maxVisibleRow then
					offset = offset + 1
				elseif key == "mouse_wheel_up" and offset > 0 then
					offset = offset - 1
				end

				scrollData["animsOffset"] = offset
            end
        end
    end
)

addEventHandler("onClientRender", root, function()

	if not panelState then
		return
	end

	absX, absY = 0, 0

    if isCursorShowing() then
        local relX, relY = getCursorPosition()

        absX = screenX * relX
        absY = screenY * relY
    end

	--> Háttér
	dxDrawRectangle(panelAnimsX, panelAnimsY, panelAnimsW, panelAnimsH, tocolor(31, 31, 31, 240))

	--> Fejléc
	dxDrawRectangle(panelAnimsX, panelAnimsY, panelAnimsW, 30, tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(panelAnimsX + 3), math.floor(panelAnimsY + 3), 24, 24, ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
	dxDrawText("Animáció lista", panelAnimsX + 30, panelAnimsY, 0, panelAnimsY + 30, tocolor(255, 255, 255), 1, fonts.RobotoL, "left", "center")

	--> Bezárás
	local closeTextWidth = dxGetTextWidth("X", 1, fonts.RobotoL)
	local closeTextPosX = panelAnimsX + panelAnimsW - closeTextWidth - 5
	local closeColor = tocolor(255, 255, 255)

	if absX >= closeTextPosX and absY >= panelAnimsY and absX <= closeTextPosX + closeTextWidth and absY <= panelAnimsY + 30 then
		closeColor = tocolor(215, 89, 89)

		if getKeyState("mouse1") then
			panelState = false
			showCursor(false)
			selectedAnim = false
			return
		end
	end
	
	dxDrawText("X", closeTextPosX, panelAnimsY, 0, panelAnimsY + 30, closeColor, 1, fonts.RobotoL, "left", "center")

	--> Tartalom

	maxVisibleRow = 8 -- math.floor(panelAnimsH / (rowH + tileMarginOffset))
	--maxVisibleRow = math.floor(rowStartY / rowH)
	local animsOffset = scrollData["animsOffset"] or 0
	for i = 1, maxVisibleRow do
		local anim = seged[i + animsOffset]

		if anim then
			local rowY = rowStartY + (rowH * i)
			
			local colorOfRow = tocolor(10, 10, 10, 125)

			if i % 2 == 0 then
				colorOfRow = tocolor(10, 10, 10, 75)
			end
			
			if selectedAnim == anim then
				colorOfRow = tocolor(7, 112, 196, 190)
			end
			

			dxDrawRectangle(rowX, rowY, rowW, rowH, colorOfRow)
			dxDrawText(anim, rowX + respc(10), rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, fonts.Roboto11, "left", "center")
		end
	end

	if #seged > maxVisibleRow then
		drawScrollbar("anims", rowX + rowW - respc(12), rowStartY + rowH, respc(12), rowH * maxVisibleRow, maxVisibleRow, #seged)
	end

	if selectedAnim then
		dxDrawMetroButtonWithBorder("anim:play", "Lejátszás", panelAnimsX + respc(10), panelAnimsY + panelAnimsH - respc(50), panelAnimsW - respc(20), respc(40), {43, 87, 151, 125}, {43, 87, 151, 175}, {255, 255, 255}, fonts.Roboto14, "center", "center", nil, nil, nil, nil)
	end

	activeButtonChecker()
end)

addEventHandler("onClientClick", root, function(button, state)
	if not panelState then
		return
	end

	if button == "left" and state == "down" then
		if activeButton == "anim:play" then
			local animsOffset = scrollData["animsOffset"] or 0
			triggerServerEvent("sarp_animationS:playAnimation", root, localPlayer, selectedAnim)
		end

		for i = 1, maxVisibleRow do
			local animsOffset = scrollData["animsOffset"] or 0
			local anim = seged[i + animsOffset]
	
			if anim then
				local rowY = rowStartY + (rowH * i)
				if cursorInBox(rowX, rowY, rowW, rowH) then
					selectedAnim = anim
					break
				end
			end
		end
		
	end
end)