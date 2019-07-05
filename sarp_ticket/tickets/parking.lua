screenX, screenY = guiGetScreenSize()

local ticketW, ticketH = respc(512 * 0.7), respc(1024 * 0.7)
local ticketX, ticketY = (screenX - ticketW) * 0.5, (screenY - ticketH) * 0.5

local inputH = respc(49)

local signStart = nil
local inEdit = false

Tickets["Parking"] = {}

Tickets["Parking"]["Render"] = function(TicketData, isEdit)
	dxDrawImage(ticketX, ticketY, ticketW, ticketH, "files/parking.png")
	inEdit = isEdit
	--[[dxDrawRectangle(ticketX + respc(11), ticketY + respc(125), respc(170), inputH, tocolor(50, 50, 50, 100)) -- DÁTUM
	dxDrawRectangle(ticketX + respc(11 + 170), ticketY + respc(125), respc(167), inputH, tocolor(50, 50, 50, 100)) -- IDŐ
	dxDrawRectangle(ticketX + respc(11), ticketY + respc(175), respc(337), inputH, tocolor(50, 50, 50, 100)) -- RENDSZÁM
	dxDrawRectangle(ticketX + respc(11), ticketY + respc(229), respc(337), inputH, tocolor(50, 50, 50, 100)) -- Típus
	dxDrawRectangle(ticketX + respc(11), ticketY + respc(229 + 54), respc(337), inputH, tocolor(50, 50, 50, 100)) -- Helyszín
	dxDrawRectangle(ticketX + respc(11), ticketY + respc(229 + 108), respc(337), inputH, tocolor(50, 50, 50, 100)) -- Indok
	dxDrawRectangle(ticketX + respc(11), ticketY + respc(229 + 160), respc(337), inputH, tocolor(50, 50, 50, 100)) -- Hatóság

	dxDrawRectangle(ticketX + respc(11), ticketY + ticketH - inputH - respc(30), respc(152), inputH, tocolor(50, 50, 50, 100)) -- ALÁRÍR (SZEGŐ)
	dxDrawRectangle(ticketX + respc(188), ticketY + ticketH - inputH - respc(30), respc(152), inputH, tocolor(50, 50, 50, 100)) -- ALÁRÍR (ŐR)--]]

	if isEdit then
		drawInput("date|-|16", ticketX + respc(11), ticketY + respc(125), respc(170), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))
		drawInput("money|num-only|6", ticketX + respc(11 + 170), ticketY + respc(125), respc(167), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166), "$")
		drawInput("numberplate|-|8", ticketX + respc(11), ticketY + respc(175), respc(337), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))
		drawInput("type|-|35", ticketX + respc(11), ticketY + respc(229), respc(337), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))
		drawInput("location|-|35", ticketX + respc(11), ticketY + respc(229 + 54), respc(337), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))
		drawInput("reason|-|35", ticketX + respc(11), ticketY + respc(229 + 108), respc(337), inputH, fonts.handFont,0.65, tocolor(0, 84, 166))
		drawInput("agency|-|35", ticketX + respc(11), ticketY + respc(229 + 160), respc(337), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))

		if signStart then
			local elapsedTime = getTickCount() - signStart
			local progress = elapsedTime / 3579

			local theName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
			local nameWidth = dxGetTextWidth(theName, 0.7, fonts.lunabar)

			local middleX = (respc(180) - nameWidth) / 2

			dxDrawText(theName, ticketX + respc(188) + middleX, ticketY + ticketH - inputH - respc(10),  ticketX + respc(188) + middleX + nameWidth * progress, ticketY + ticketH - inputH - respc(30) + inputH, tocolor(0, 84, 166), 0.7, fonts.lunabar, "left", "center", true) -- VÉTSÉG

			if progress > 1.25 then
				signStart = false
				showTicket(false)
				playSound("files/paper-rip.mp3")
				exports.sarp_chat:sendLocalMeAction(localPlayer, "kitépi a bírságot a füzetből.")	
			end
		end
	else
		dxDrawText(TicketData["date"], ticketX + respc(16), ticketY + respc(145), respc(170), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont) -- NÉV
		dxDrawText(TicketData["fine"] .. "$", ticketX + respc(16 + 170), ticketY + respc(145), respc(167), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont) -- HELYSÍZN
		dxDrawText(TicketData["numberplate"], ticketX + respc(16), ticketY + respc(195), respc(337), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont) -- RENDSZÁM
		dxDrawText(TicketData["type"], ticketX + respc(16), ticketY + respc(249), respc(337), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont) -- VÉTSÉG
		dxDrawText(TicketData["location"], ticketX + respc(16), ticketY + respc(249 + 54), respc(337), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont)
		dxDrawText(TicketData["reason"], ticketX + respc(16), ticketY + respc(249 + 108), respc(337), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont)
		dxDrawText(TicketData["agency"], ticketX + respc(16), ticketY + respc(249 + 160), respc(337), inputH, tocolor(0, 84, 166), 0.7, fonts.handFont)

		--dxDrawText(TicketData["agency"], ticketX + respc(355 + 10), ticketY + respc(115) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.65, fonts.handFont) -- NÉV
		--dxDrawText(TicketData["officer"], ticketX + respc(355 + 10), ticketY + respc(163) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- HELYSÍZN
		--dxDrawText(TicketData["fine"], ticketX + respc(355 + 10), ticketY + respc(210) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- RENDSZÁM
		--dxDrawText(TicketData["date"], ticketX + respc(355 + 10), ticketY + respc(258) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- VÉTSÉG

		dxDrawText(TicketData["officer"] or getPlayerName(localPlayer):gsub("_", " "), ticketX + respc(188), ticketY + ticketH - inputH - respc(10), ticketX + respc(188) + respc(152), ticketY + ticketH - inputH - respc(30) + inputH, tocolor(0, 84, 166), 0.7, fonts.lunabar, "center", "center") -- VÉTSÉG
	end

	

	--dxDrawRectangle(ticketX + respc(355 + 7 + 147), ticketY + respc(291), respc(180), inputH, tocolor(50, 50, 50, 100))
end

Tickets["Parking"]["Event"] = {}
Tickets["Parking"]["Event"]["onClientClick"] = function(button, state)
	if button == "left" and state == "down" then
		if inEdit then
			if cursorInBox(ticketX + respc(188), ticketY + ticketH - inputH - respc(30), respc(152), inputH) then
				if signStart then
					return
				end
				
				if utf8.len(inputValues["location|-|35"]) < 4 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Név\" rész kevesebb, mint 4 karakter")
					return
				end

				if utf8.len(inputValues["reason|-|35"]) < 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Indok\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["type|-|35"]) < 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Jármű Típusa\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["numberplate|-|8"]) < 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Rendszám\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["agency|-|35"]) < 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Hatóság\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["money|num-only|6"]) < 1 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Bírság Összege\" rész kevesebb, mint 1 karakter")
					return
				end

				if utf8.len(inputValues["date|-|16"]) < 7 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Büntetés Dátuma\" rész kevesebb, mint 7 karakter")
					return
				end

				local theVehicle = getVehicleByNumberplate(inputValues["numberplate|-|8"])

				if not theVehicle then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A jármű nem található vagy nincs a közeledben.")
					return
				end

				exports.sarp_chat:sendLocalMeAction(localPlayer, "elkezd megírni egy csekket.")

				signStart = getTickCount()
				playSound("files/sign.mp3")

				local data = {
					["location"] = inputValues["location|-|35"],
					["officer"] = getElementData(localPlayer, "visibleName"):gsub("_", " "),
					["numberplate"] = inputValues["numberplate|-|8"],
					["reason"] = inputValues["reason|-|35"],
					["type"] = inputValues["type|-|35"],
					["agency"] = inputValues["agency|-|35"],
					["fine"] = inputValues["money|num-only|6"],
					["date"] = inputValues["date|-|16"]
				}
				
				if isElement(theVehicle) then
					triggerServerEvent("ticketTheVehicle", localPlayer, theVehicle, data)
				else
					exports.sarp_hud:showAlert("error", "A megadott rendszámhoz nincs társított jármű!")
				end
			end
		end
	end
end

function getVehicleByNumberplate(numplate)
	local vehicle = false

	if numplate then
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
		local vehicles = getElementsByType("vehicle", getRootElement(), true)

		for k = 1, #vehicles do
			local v = vehicles[k]

			if v then
				local vehiclePosX, vehiclePosY, vehiclePosZ = getElementPosition(v)
				local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, vehiclePosX, vehiclePosY, vehiclePosZ)

				if distance <= 8 and getVehiclePlateText(v) == numplate then
					vehicle = v
					break
				end
			end
		end
	end

	return vehicle
end