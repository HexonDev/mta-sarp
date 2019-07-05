local screenWidth, screenHeight = guiGetScreenSize()
local util = exports["sarp_core"]

local dxFont = dxCreateFont(":sarp_assets/fonts/CenturyGothicBold.ttf", util:respc(14), false, "cleartype")
local dxFont2 = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", util:respc(18), false, "cleartype")
local dxFont3 = dxCreateFont(":sarp_assets/fonts/CenturyGothicBold.ttf", util:respc(12), false, "cleartype")
local dxFont4 = dxCreateFont(":sarp_assets/fonts/CenturyGothicBold.ttf", util:respc(11), false, "cleartype")

local panelW, panelH = util:respc(1000), util:respc(450)
local panelX, panelY = (screenWidth/2) - (panelW/2), (screenHeight/2) - (panelH/2) -- (screenWidth - panelW) / 2

local markak = {
    "Audi", "BMW", "Skoda", "Mercedes", "Lada", "Subaru", "Honda", "Opel", "Suzuki", "Ford", "Mazda", "MTZ"
} 

local showVehicleshopPanel = false

local selectedBrand = 1
local currentVehicle = 1
local shopType = nil

local listCarsVisible = 8
local listPanelPage = 0

local hoveredBrand = false

function showCarshopPanel(state)
    listPanelPage = 0

    local car = createVehicle(598, 0, 0, 0, 255, 255, 255, "TESZT")
    if state then
        if isElement(car) then
            setVehicleColor(car, 255, 255, 255)
            exports["sarp_3dview"]:processVehiclePreview(car, 0, 0, 0, 0, false)
            exports["sarp_3dview"]:setVehicleAlpha(254)
        end
        addEventHandler("onClientRender", root, renderCarshopPanel)
        exports["sarp_3dview"]:setPreviewVehicleModel(vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][1])
    else
        removeEventHandler("onClientRender", root, renderCarshopPanel)
        if isElement(car) then
            destroyElement(car)
        end
        exports["sarp_3dview"]:processVehiclePreview()
    end

    showVehicleshopPanel = state
end
addCommandHandler("scp", showCarshopPanel)

function renderCarshopPanel()
    if showVehicleshopPanel then
        dxDrawRoundedRectangle(panelX, panelY, panelW, panelH, tocolor(0, 0, 0, 190))

        local cursorX, cursorY = getCursorPosition()
        local absX, absY = -1, -1
        if isCursorShowing() then
            absX, absY = cursorX * screenWidth, cursorY * screenHeight
        elseif cursorIsMoving then
            cursorIsMoving = false
        end

        local rowW, rowH = util:respc(150), util:respc(30)
        local rowColor = tocolor(10, 10, 10, 175)

        hoveredBrand = false

        local rowX = (panelX + panelW - rowW) - util:respc(20)

        for i = 1, listCarsVisible do
            local data = markak[i + listPanelPage]

            local rowY = (panelY + util:respc(30)) + (rowH * (i - 1))

            if markak[selectedBrand] == data then
                dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(50, 179, 239, 230))
            else
                if i % 2 == 0 then
                    dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(10, 10, 10, 175))
                else
                    dxDrawRectangle(rowX, rowY, rowW, rowH, tocolor(20, 20, 20, 175))
                end

                if absX >= rowX and absY >= rowY and absX <= rowX + rowW and absY <= rowY + rowH and not hoveredBrand and data then
                    hoveredBrand = i + listPanelPage
                end
            end

            if data then
                dxDrawText(data, rowX, rowY, rowX + rowW, rowY + rowH, tocolor(255, 255, 255, 255), 1, dxFont3, "center", "center")
            end
        end

        if #markak > listCarsVisible then
            local listHeight = rowH * listCarsVisible
            dxDrawRectangle(panelX + panelW - util:respc(17), panelY + util:respc(30), util:respc(15), listHeight, tocolor(0, 0, 0, 190))
            dxDrawRectangle(panelX + panelW - util:respc(17), panelY + util:respc(30) + (listHeight / #markak) * math.min(listPanelPage, #markak - listCarsVisible), util:respc(15), (listHeight / #markak) * listCarsVisible, tocolor(50, 179, 239, 230))
        end

        local buyButtonW, buyButtonH = util:respc(220), util:respc(50)
        local buyButtonX, buyButtonY = (panelX + panelW - util:respc(20) - buyButtonW),(panelY + panelH - util:respc(140))
        dxDrawRectangle(buyButtonX, buyButtonY, buyButtonW, buyButtonH, tocolor(100, 127, 59, 255)) -- Teljes gomb
        dxDrawRectangle(buyButtonX, buyButtonY, buyButtonH, buyButtonH, tocolor(63, 80, 38, 255)) -- Gomb bal oldalán lévő kép háttere
        dxDrawImage(buyButtonX + util:respc(5), buyButtonY + util:respc(5), buyButtonH - util:respc(10), buyButtonH - util:respc(10), ":sarp_assets/images/carshop/coin.png",0,0,0, tocolor(255,255,255) )
        dxDrawText("$" .. vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][2], buyButtonX + buyButtonH, buyButtonY - buyButtonH, buyButtonX + buyButtonW, buyButtonY + buyButtonH + buyButtonH, tocolor(255,255,255), 1, dxFont3, "center", "center", false, false, false, true )

        local closeButtonW, closeButtonH = util:respc(220), util:respc(50)
        local closeButtonX, closeButtonY = (panelX + panelW - util:respc(20) - closeButtonW),(panelY + panelH - util:respc(70) )
        dxDrawRectangle(closeButtonX, closeButtonY, closeButtonW, closeButtonH, tocolor(239, 50, 63, 255)) -- Teljes gomb
        dxDrawRectangle(closeButtonX, closeButtonY, closeButtonH, closeButtonH, tocolor(180, 37, 47, 255)) -- Gomb bal oldalán lévő kép háttere
        dxDrawImage(closeButtonX + util:respc(5), closeButtonY + util:respc(5), closeButtonH - util:respc(10), closeButtonH - util:respc(10), ":sarp_assets/images/carshop/close.png",0,0,0, tocolor(255,255,255) )
        dxDrawText("Bezár", closeButtonX + closeButtonH, closeButtonY - closeButtonH, closeButtonX + closeButtonW, closeButtonY + closeButtonH + closeButtonH, tocolor(255,255,255), 1, dxFont3, "center", "center", false, false, false, true )


        local bckW, bckH = util:respc(620), util:respc(240)
        local bckX, bckY = panelX + util:respc(50), (panelY  + util:respc(30))
        --dxDrawRectangle(bckX, bckY, bckW, bckH, tocolor(100, 127, 59, 255)) -- 3D autó helye
        exports["sarp_3dview"]:setVehicleProjection(bckX, bckY, bckW, bckH, 255)

        if cursorIsMoving then
            exports["sarp_3dview"]:rotateVehicle(cursorX)
            setCursorPosition(screenWidth * 0.5, screenHeight * 0.5)
            
            if not getKeyState("mouse1") then
                cursorIsMoving = false
                setCursorAlpha(255)
            end
        elseif absX >= bckX and absX <= bckX + bckW and absY >= bckY and absY <= bckY + bckH and getKeyState("mouse1") then
            cursorIsMoving = true
            setCursorAlpha(0)
            setCursorPosition(screenWidth * 0.5, screenHeight * 0.5)
        end
        
        if absX >= bckX and absX <= bckX + bckW and absY >= bckY and absY <= bckY + bckH then
            carHoveredForRotation = true
        end

        local barW, barH = util:respc(200), util:respc(10)
        local bar1X, bar1Y = panelX + util:respc(20), (panelY + panelH) - util:respc(140)
        dxDrawRoundedRectangle(bar1X, bar1Y, barW, barH, tocolor(33, 99, 130, 230))
        dxDrawText("Sebesség", bar1X, bar1Y - util:respc(25), barW, barH, tocolor(255, 255, 255), 1, dxFont3)

        local bar2X, bar2Y = panelX + util:respc(20), (panelY + panelH) - util:respc(90)
        dxDrawRoundedRectangle(bar2X, bar2Y, barW, barH, tocolor(33, 99, 130, 230))
        dxDrawText("Fogyasztás", bar2X, bar2Y - util:respc(25), barW, barH, tocolor(255, 255, 255), 1, dxFont3)

        local bar3X, bar3Y = panelX + util:respc(260), (panelY + panelH) - util:respc(140)
        dxDrawRoundedRectangle(bar3X, bar3Y, barW, barH, tocolor(33, 99, 130, 230))
        dxDrawText("Gyorsulás", bar3X, bar3Y - util:respc(25), barW, barH, tocolor(255, 255, 255), 1, dxFont3)

        local bar4X, bar4Y = panelX + util:respc(260), (panelY + panelH) - util:respc(90)
        dxDrawRoundedRectangle(bar4X, bar4Y, barW, barH, tocolor(33, 99, 130, 230))
        dxDrawText("Fék hatás", bar4X, bar4Y - util:respc(25), barW, barH, tocolor(255, 255, 255), 1, dxFont3)

        local textW, textH = util:respc(620), util:respc(240)
        local textX, textY = panelX + util:respc(50), (panelY + util:respc(30))
        dxDrawText(getVehicleNameFromModel(vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][1]) .. " -", textX, textY + (panelH + util:respc(70) - dxGetFontHeight(1, dxFont3)), textX + textW, textY + textH, tocolor(255,255,255), 1, dxFont3, "center", "center", false, false, false, true)
        dxDrawText("A márkán belüli járművek megtekintéséhez használd a#32b3ef balra#ffffff és#32b3ef jobbra#ffffff nyilakat.", textX, textY + (panelH + util:respc(90)), textX + textW, textY + textH, tocolor(255,255,255), 1, dxFont3, "center", "center", false, false, false, true)
        
        
    end
end

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if state == "down" then
        if showVehicleshopPanel then
            if hoveredBrand then
                selectedBrand = hoveredBrand
                exports["sarp_3dview"]:setPreviewVehicleModel(vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][1])
            end

            local buyButtonW, buyButtonH = util:respc(220), util:respc(50)
            local buyButtonX, buyButtonY = (panelX + panelW - util:respc(20) - buyButtonW),(panelY + panelH - util:respc(140))

            if cursorInBox(buyButtonX, buyButtonY, buyButtonW, buyButtonH) then
                local cost = vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][2]
                local id = vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][1]
                triggerServerEvent("sarp_carshopS:buyVehicle", localPlayer, localPlayer, id, cost)
            end

            local closeButtonW, closeButtonH = util:respc(220), util:respc(50)
            local closeButtonX, closeButtonY = (panelX + panelW - util:respc(20) - closeButtonW),(panelY + panelH - util:respc(70) )

            if cursorInBox(closeButtonX, closeButtonY, closeButtonW, closeButtonH) then
                showCarshopPanel(false)
            end
        else
            if clickedElement and isElement(clickedElement) then
                if getElementData(clickedElement, "ped.type") == 3 then
                    if exports.sarp_core:inDistance3D(getLocalPlayer(), clickedElement, 2) then
                        shopType = getElementData(clickedElement, "ped.subtype") or 1
                        showCarshopPanel(true)
                    end
                end
            end
        end
    end
end)

addCommandHandler("scp2", function() 
    showCarshopPanel(false)
end)

addEventHandler("onClientKey", root, function(button, press)
    if showVehicleshopPanel then
        if press then
            if button == "arrow_l" then
                currentVehicle = currentVehicle - 1
                if currentVehicle < 1 then
                    currentVehicle = #vehiclesInShop[shopType][markak[selectedBrand]]
                end
            elseif button == "arrow_r" then
                currentVehicle = currentVehicle + 1
                if currentVehicle > #vehiclesInShop[shopType][markak[selectedBrand]] then
                    currentVehicle = 1
                end
            end

            if #markak > listCarsVisible then
                if button == "mouse_wheel_down" and listPanelPage < #markak - listCarsVisible then
                    listPanelPage = listPanelPage + listCarsVisible
                elseif button == "mouse_wheel_up" and listPanelPage > 0 then
                    listPanelPage = listPanelPage - listCarsVisible
                end
            end

            exports["sarp_3dview"]:setPreviewVehicleModel(vehiclesInShop[shopType][markak[selectedBrand]][currentVehicle][1])
        end
    end
end)

function dxDrawRoundedRectangle(x, y, w, h, borderColor, bgColor, postGUI)
	borderColor = borderColor or tocolor(0, 0, 0, 200)
	bgColor = bgColor or borderColor

	dxDrawRectangle(x, y, w, h, bgColor, postGUI)
	dxDrawRectangle(x + 2, y - 1, w - 4, 1, borderColor, postGUI)
	dxDrawRectangle(x + 2, y + h, w - 4, 1, borderColor, postGUI)
	dxDrawRectangle(x - 1, y + 2, 1, h - 4, borderColor, postGUI)
	dxDrawRectangle(x + w, y + 2, 1, h - 4, borderColor, postGUI)
end

function dxDrawRoundedBorder(x, y, w, h, borderColor, postGUI)
	borderColor = borderColor or tocolor(0, 0, 0, 200)
	dxDrawRectangle(x + 1, y - 1, w - 2, 1, borderColor, postGUI)
	dxDrawRectangle(x + 1, y + h, w - 2, 1, borderColor, postGUI)
	dxDrawRectangle(x - 1, y + 1, 1, h - 2, borderColor, postGUI)
	dxDrawRectangle(x + w, y + 1, 1, h - 2, borderColor, postGUI)
end

function cursorInBox(x, y, w, h)
	if x and y and w and h then
		if isCursorShowing() then
			if not isMTAWindowActive() then
				local cursorX, cursorY = getCursorPosition()
				
				cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
				
				if cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
					return true
				end
			end
		end
	end
	
	return false
end
