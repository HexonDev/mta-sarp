
local util = exports["sarp_core"]

local showDogControlPanel = false
local selectedDog
local screenX, screenY = guiGetScreenSize()

local dogSkins = 

addEventHandler("onClientClick", root, function(button, state, aX, aY, wX, wY, wZ, element)
	if state == "down" then
		if element and isElement(element) and not showDogControlPanel then
			if getElementData(element, "dog.id") then
				local dogOwner = tostring(getElementData(element, "dog.owner"))
				local playerDBID = tostring(getElementData(localPlayer, "dbid"))
				if dogOwner == playerDBID then
					local dX, dY, dZ = getElementPosition(element)
					local pX, pY, pZ = getElementPosition(localPlayer)
					local distance = getDistanceBetweenPoints3D(dX, dY, dZ, pX, pY, pZ)
					if distance <= 5 then
						if getElementData(element, "dog.id") then
							selectedDog = element
							showDogControlPanel = true
						end
					end
					
				else
					exports["sarp_alert"]:showAlert("error", "A kiválasztott kutya nem a te", "tulajdonodban van!")
				end
				--outputChatBox(tostring(getElementData(element, "dog.owner")) .. " cid:" .. getElementData(localPlayer, "dbid"))
				--outputChatBox(tostring(getElementData(element, "dog.owner") == getElementData(localPlayer, "dbid")))
			end
        end
    end
end)

local panelW, panelH = util:resp(365), util:resp(327)
local panelX, panelY = screenX - panelW - util:resp(20), (screenY / 2) - (panelH / 2) 
local buttonW, buttonH = util:resp(150), util:resp(30)
local buttonX, buttonY = panelX + util:resp(20), (panelY + util:resp(75)) + util:resp(40)
local inputW, inputH = util:resp(150), util:resp(30)
local inputMainX, inputMainY = panelX + (panelW / 2) - (inputW / 2),  panelY + panelH - util:resp(40) - (inputH / 2)

local century = dxCreateFont("fonts/CenturyGothicRegular.ttf", util:resp(14))
local bebas = dxCreateFont("fonts/BebasNeue.otf", util:resp(20))

local menuButtons = {
	{"Marad", buttonX, buttonY, buttonW, buttonH, tocolor(50, 179, 239, 200)},
	{"Gyere", buttonX + (buttonW + util:resp(20)), buttonY, buttonW, buttonH, tocolor(50, 179, 239, 200)},
	{"Fekszik", buttonX, buttonY + (buttonH + util:resp(20)), buttonW, buttonH, tocolor(50, 179, 239, 200)},
	{"Bezárás", buttonX + (buttonW + util:resp(20)), buttonY + (buttonH + util:resp(20)), buttonW, buttonH, tocolor(50, 179, 239, 200)},
}

local activeInputfield = -1
local inputfields = { -- Input név, Tartalom, Max karakter, Maszkolás, Valós tartalom (maszkolásnál), {X, Y, W, H}, Placeholder, Szöveg szín
	["dogpanel"] = {
		{"playerid", "", 25, false, "", {inputMainX, inputMainY, inputW, inputH, tocolor(0, 0, 0, 255)}, "Célpont játékos ID", tocolor(255, 255, 255, 255)},
	},
}

addEventHandler("onClientRender", root, function()
	if getElementData(localPlayer, "loggedin") == 1 then
		if showDogControlPanel then

			dxDrawImage(panelX, panelY, panelW, panelH, "imgs/kutyapanel.png")
			dxDrawText("Kutya: " .. getElementData(selectedDog, "dog.name"), panelX, panelY + 70, panelX + panelW, panelY, tocolor(255, 255, 255, 255), 1, bebas, "center", "top")

			for button, v in ipairs(menuButtons) do
				local rX, rY, rW, rH, rC = v[2], v[3], v[4], v[5], v[6]
				dxDrawRoundedRectangle(rX, rY, rW, rH, rC, rC, false)
				dxDrawText(v[1], rX, rY, rX + rW, rY + rH, tocolor(255, 255, 255, 255), 1, century, "center", "center")
			end
		end
	end
end)  

addEventHandler("onClientClick", root, function(button, state)
	if getElementData(localPlayer, "loggedin") == 1 and showDogControlPanel then
		if button == "left" and state == "down" then
		

			for button, v in ipairs(menuButtons) do
				local rX, rY, rW, rH, rC = v[2], v[3], v[4], v[5], v[6]
				
				if cursorInBox(rX, rY, rW, rH) then
					if v[1] == "Bezárás" then
						showDogControlPanel = false	
						selectedDog = nil
					elseif v[1] == "Marad" then
						--stayHere(selectedDog)
						triggerServerEvent("stayHere", localPlayer, selectedDog )
					elseif v[1] == "Gyere" then
						--followTarget(selectedDog, localPlayer)
						triggerServerEvent("followTarget", localPlayer, selectedDog, localPlayer )
					elseif v[1] == "Fekszik" then
						triggerServerEvent("dogLie", localPlayer, selectedDog )
						
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

function dxDrawRoundedRectangle(x, y, w, h, borderColor, bgColor, postGUI)
	if (x and y and w and h) then
		if (not borderColor) then
			borderColor = tocolor(0, 0, 0, 200);
		end
		
		if (not bgColor) then
			bgColor = borderColor;
		end
		
		--> Background
		dxDrawRectangle(x, y, w, h, bgColor, postGUI);
		
		--> Border
		dxDrawRectangle(x + 2, y - 1, w - 4, 1, borderColor, postGUI); -- top
		dxDrawRectangle(x + 2, y + h, w - 4, 1, borderColor, postGUI); -- bottom
		dxDrawRectangle(x - 1, y + 2, 1, h - 4, borderColor, postGUI); -- left
		dxDrawRectangle(x + w, y + 2, 1, h - 4, borderColor, postGUI); -- right
	end
end