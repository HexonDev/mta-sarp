local screenX, screenY = guiGetScreenSize()
local showPanel = false
local util = exports["sarp_core"]

local Bebas = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", util:resp(18))
local Century15 = dxCreateFont(":sarp_assets/fonts/CenturyGothicRegular.ttf", util:resp(15))
local Century13 = dxCreateFont(":sarp_assets/fonts/CenturyGothicRegular.ttf", util:resp(13))

local selectedRowKey = nil

local buyableDogs = { -- Név, SkinID, Ár
    [1] = {"Németjuhász", 305, 9000},
    [2] = {"Husky", 311, 90000},
    [3] = {"Bullterrier", 308, 900000},
    [4] = {"Rottweiler", 310, 9000000},
}

setCursorAlpha(255)

addEventHandler("onClientClick", root, function(button, state, aX, aY, wX, wY, wZ, element)
    if state == "down" then
        if element and isElement(element) then
            if getElementData(element, "ped.dogseller") then
                showPanel = true
                selectedRowKey = nil
                showCursor(true)
            end
        end
    end
end)

function showDog(skin, state)
    if state then
        exports["sarp_3dview"]:processSkinPreview(skin, 0, 0, 0, 0)
        
    else
        exports["sarp_3dview"]:processSkinPreview()
    end
end

currentState = "dog"

local activeInputfield = -1
local inputfields = { -- Input név, Tartalom, Max karakter, Maszkolás, Valós tartalom (maszkolásnál), {X, Y, W, H}, Placeholder, Szöveg szín
	["dog"] = {
		{"dogname", "", 25, false, "", "Állat neve", tocolor(255, 255, 255, 255)},
	},
}

addEventHandler("onClientRender", root, function()
    if showPanel then
        local panelW, panelH = util:resp(700), util:resp(500)
        local panelX, panelY = (screenX / 2) - (panelW / 2), (screenY / 2) - (panelH / 2) 

        --dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0, 0, 0, 155))
        dxDrawRoundedRectangle(panelX, panelY, panelW, panelH, 10, tocolor(33,35,39, 180), "outer", tocolor(33, 35, 39, 180), false, false)

        dxDrawText("SAN ANDREAS", panelX, panelY, panelX + panelW, panelY + panelH, tocolor(255, 255, 255, 255), 1, Bebas, "left", "top")
        dxDrawText("ROLEPLAY", panelX + util:resp(65), panelY + util:resp(17), panelX + panelW, panelY + panelH, tocolor(255, 255, 255, 255), 1, Bebas, "left", "top")

        dxDrawText("Kisállat kereskedés", panelX, panelY, panelX + panelW, panelY + panelH, tocolor(255, 255, 255, 255), 1, Century15, "center", "top")

        local listW, listH = util:resp(300), panelH - util:resp(150)
        local listX, listY = panelX + (panelW - listW - util:resp(20)), panelY + util:resp(80)

        dxDrawRectangle(listX, listY, listW, listH, tocolor(15,15,15, 120))

        local cursorX, cursorY = getCursorPosition()
		local absX, absY = -1, -1
		if isCursorShowing() then
			absX, absY = cursorX * screenX, cursorY * screenY
		elseif cursorIsMoving then
			cursorIsMoving = false
		end

        local buttonW, buttonH = util:resp(100), util:resp(15)
        local buttonX, buttonY = panelX + (panelW - buttonW - util:resp(20)), panelY + (panelH - buttonH - util:resp(10))

        if selectedRowKey then
            local dogData = buyableDogs[selectedRowKey]
            dxDrawText(dogData[1], panelX, panelY + util:resp(80), panelX + (panelW / 2), panelY + panelH, tocolor(255, 255, 255, 255), 1, Century15, "center", "top")

            local dogImageW, dogImageH = util:resp(400), util:resp(400)
            local dogImageX, dogImageY = panelX, panelY - util:resp(30)
            exports["sarp_3dview"]:setSkinProjection(dogImageX, dogImageY, dogImageW, dogImageH, 255)

            local fontHeight = dxGetFontHeight(1, Century13)

            dxDrawText("Állat ára: #32B3EF" .. dogData[3] .. "#FFFFFF$", panelX, panelY + (panelH - fontHeight), panelX, panelY, tocolor(255, 255, 255, 255), 1, Century13, "left", "top", false, false, false, true)
            
            if cursorIsMoving then
                exports["sarp_3dview"]:rotateSkin(cursorX)
                setCursorPosition(screenX * 0.5, screenY * 0.5)
                
                if not getKeyState("mouse1") then
                    cursorIsMoving = false
                    setCursorAlpha(255)
                end
            elseif absX >= dogImageX - util:resp(250 * 0.5) and absX <= dogImageX + util:resp(250 * 0.5) and absY >= dogImageY and absY <= dogImageY + dogImageH and getKeyState("mouse1") then
                cursorIsMoving = true
                setCursorAlpha(0)
                setCursorPosition(screenX * 0.5, screenY * 0.5)
            end

            local buyX, buyY = buttonX - (buttonW + util:resp(40)), buttonY
            -- {"dogname", "", 25, false, "", "Állat neve", tocolor(255, 255, 255, 255)},
            local inputCount = 0
            if inputfields[currentState] then
                for input, value in ipairs(inputfields[currentState]) do -- 
                    local inputX, inputY, inputWidth, inputHeight, inputColor, textColor = panelX + util:resp(200), panelY + (panelH - util:resp(30)), util:resp(200), util:resp(30), tocolor(0, 0, 0, 100)

                    local inputfieldValueLength = dxGetTextWidth(value[2], 1.0, "default-bold")
                    
                    if activeInputfield ~= input and not cursorInBox(inputX, inputY, inputWidth, inputHeight) then
                        dxDrawRectangle(inputX, inputY, inputWidth, inputHeight, inputColor)
                    else
                        dxDrawRectangle(inputX, inputY, inputWidth, inputHeight, inputColor)
                    end
                    
                    if value[2] == "" then
                        dxDrawText(value[6], inputX + 10, inputY, inputX + 10 + inputWidth - 20, inputY + inputHeight, tocolor(255, 255, 255, 100), 1.0, "default-bold", "left", "center", true)
                    end

                    dxDrawText(value[2], inputX + 10, inputY, inputX + 10 + inputWidth - 20, inputY + inputHeight, textColor, 1.0, "default-bold", "left", "center", true)

                    
                    if activeInputfield == input then
                        dxDrawRectangle(inputX + 10 + inputfieldValueLength + 3, inputY + 5, 1, inputHeight - 10, tocolor(255, 255, 255, (getTickCount() % 1000 <= 500 and 0 or 500)))
                    end
                    
                    inputCount = inputCount + 1
                end
            end

            dxDrawRoundedRectangle(buyX, buyY, buttonW, buttonH, 10, tocolor(50, 179, 239, 150), "outer", tocolor(50, 179, 239, 150), false, false)
            dxDrawText("Megvesz", buyX, buyY, buyX + buttonW, buyY + buttonH, tocolor(255, 255, 255, 255), 1, Century13, "center", "center")
        end

        dxDrawRoundedRectangle(buttonX, buttonY, buttonW, buttonH, 10, tocolor(50, 179, 239, 150), "outer", tocolor(50, 179, 239, 150), false, false)
        dxDrawText("Bezár", buttonX, buttonY, buttonX + buttonW, buttonY + buttonH, tocolor(255, 255, 255, 255), 1, Century13, "center", "center")

        local rowW, rowH = listW, util:resp(40)

        for k, v in ipairs(buyableDogs) do
            local rowX, rowY = listX, listY + (rowH * (k - 1))
            
            local defaultColor = {0, 0, 0, 110}
            if k == selectedRowKey then
                defaultColor = {50, 179, 239, 150}
            else
                if k % 2 == 0 then
                    defaultColor = {0, 0, 0, 70}
                else
                    defaultColor = {0, 0, 0, 110}
                end
                
            end

            if k % 2 == 0 then
                dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4]))
            else
                dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4]))
            end
            dxDrawText(v[1], rowX, rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, Century13, "center", "center")
        end

    end
end)

addEventHandler("onClientClick", root, function(button, state)
    if showPanel then
        if state == "down" then

            


            local panelW, panelH = util:resp(700), util:resp(500)
            local panelX, panelY = (screenX / 2) - (panelW / 2), (screenY / 2) - (panelH / 2)       

            local listW, listH = util:resp(300), panelH - util:resp(150)
            local listX, listY = panelX + (panelW - listW - util:resp(20)), panelY + util:resp(80)

            local rowW, rowH = listW, util:resp(40)

            for k, v in ipairs(buyableDogs) do
                local rowX, rowY = listX, listY + (rowH * (k - 1))

                if cursorInBox(rowX, rowY, rowW, rowH) then
                    showDog(v[2], true)
                    exports["sarp_3dview"]:setSkin(v[2])
                    selectedRowKey = k
                end
            end

            activeInputfield = -1
		
            local inputCount = 0
            if inputfields[currentState] then
                for input, value in ipairs(inputfields[currentState]) do
                    local inputX, inputY, inputWidth, inputHeight, inputColor = panelX + util:resp(200), panelY + (panelH - util:resp(30)), util:resp(200), util:resp(30)
                    
                    if cursorInBox(inputX, inputY, inputWidth, inputHeight) then
                        activeInputfield = input
                        --outputDebugString("clicked: " .. inputfields[currentState][input][1])
                    end
                    
                    inputCount = inputCount + 1	
                end
            end

            local buttonW, buttonH = util:resp(100), util:resp(15)
            local buttonX, buttonY = panelX + (panelW - buttonW - util:resp(20)), panelY + (panelH - buttonH - util:resp(10))

            if cursorInBox(buttonX, buttonY, buttonW, buttonH) then
                showDog(nil, false)
                showPanel = false
                showCursor(false)
            elseif cursorInBox(buttonX - (buttonW + util:resp(40) ), buttonY, buttonW, buttonH) then
                if selectedRowKey then
                    local dogName = tostring(inputfields["dog"][1][2])
                    if string.len(dogName) > 3 then
                        --triggerClientEvent(localPlayer, "buyNewDog", localPlayer, dogName, buyableDogs[selectedRowKey][2], buyableDogs[selectedRowKey][3])
                        triggerServerEvent("buyNewDog", localPlayer, dogName, buyableDogs[selectedRowKey][2], buyableDogs[selectedRowKey][3])
                    else
                        exports["sarp_alert"]:showAlert("error", "A kutya nevének minimum", "4 karakternek kell lennie")
                    end
                end
            end
        end
    end
end)

addEventHandler("onClientCharacter", root, function(char)
	if activeInputfield ~= -1 then
		if #inputfields[currentState][activeInputfield][2] < inputfields[currentState][activeInputfield][3] then
            inputfields[currentState][activeInputfield][2] = inputfields[currentState][activeInputfield][2] .. char
            inputfields[currentState][activeInputfield][5] = inputfields[currentState][activeInputfield][5] .. char
		end
	end
end)

addEventHandler("onClientKey", root, function(key, pressed)
	if currentState ~= nil then
		if pressed then
			if key == "backspace" then
				if activeInputfield ~= -1 then
					if #inputfields[currentState][activeInputfield][2] > 0 then
						inputfields[currentState][activeInputfield][2] = string.sub(inputfields[currentState][activeInputfield][2], 1, #inputfields[currentState][activeInputfield][2] - 1)
						inputfields[currentState][activeInputfield][5] = string.sub(inputfields[currentState][activeInputfield][5], 1, #inputfields[currentState][activeInputfield][5] - 1)
					end
                end
            end
        end
    end
end)

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

local roundTexture = dxCreateTexture(":sarp_assets/images/alert/round.png", "argb", true, "clamp")

function dxDrawRoundedRectangle(x, y, w, h, radius, color, border, borderColor, postGUI, subPixelPositioning)
	radius = radius or 5
	
	if border == "outer" then
		dxDrawImage(x - radius, y - radius, radius, radius, roundTexture, 0, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w, y - radius, radius, radius, roundTexture, 90, 0, 0, borderColor, postGUI)
		dxDrawImage(x - radius, y + h, radius, radius, roundTexture, 270, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w, y + h, radius, radius, roundTexture, 180, 0, 0, borderColor, postGUI)
		
		dxDrawRectangle(x, y, w, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y - radius, w, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y + h, w, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x - radius, y, radius, h, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w, y, radius, h, borderColor, postGUI, subPixelPositioning)
	elseif border == "inner" then
		dxDrawImage(x, y, radius, radius, roundTexture, 0, 0, 0, borderColor, postGUI)
		dxDrawImage(x, y + h - radius, radius, radius, roundTexture, 270, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w - radius, y, radius, radius, roundTexture, 90, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w - radius, y + h - radius, radius, radius, roundTexture, 180, 0, 0, borderColor, postGUI)
		
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y + h - radius, w - radius * 2, radius, borderColor, postGUI, subPixelPositioning)
	else
		dxDrawImage(x, y, radius, radius, roundTexture, 0, 0, 0, color, postGUI)
		dxDrawImage(x, y + h - radius, radius, radius, roundTexture, 270, 0, 0, color, postGUI)
		dxDrawImage(x + w - radius, y, radius, radius, roundTexture, 90, 0, 0, color, postGUI)
		dxDrawImage(x + w - radius, y + h - radius, radius, radius, roundTexture, 180, 0, 0, color, postGUI)
		
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
	end
end