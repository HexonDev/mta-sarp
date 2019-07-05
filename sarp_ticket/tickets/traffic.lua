screenX, screenY = guiGetScreenSize()

local ticketW, ticketH = respc(1024 * 0.7), respc(512 * 0.7)
local ticketX, ticketY = (screenX - ticketW) * 0.5, (screenY - ticketH) * 0.5

local inputH = respc(42)

local signStart = nil
local inEdit = false

Tickets["Traffic"] = {}

Tickets["Traffic"]["Render"] = function(TicketData, isEdit)
	dxDrawImage(ticketX, ticketY, ticketW, ticketH, "files/traffic.png")
	inEdit = isEdit
	--dxDrawRectangle(ticketX + respc(7), ticketY + respc(115), respc(355), inputH, tocolor(50, 50, 50, 100)) -- NÉV 
	--dxDrawRectangle(ticketX + respc(7), ticketY + respc(163), respc(355), inputH, tocolor(50, 50, 50, 100)) -- HELYSZÍN
	--dxDrawRectangle(ticketX + respc(7), ticketY + respc(210), respc(355), inputH, tocolor(50, 50, 50, 100)) -- RENDSZÁM
	--dxDrawRectangle(ticketX + respc(7), ticketY + respc(258), respc(355), inputH, tocolor(50, 50, 50, 100)) -- SZABÁLYSÉRTÉS

	--dxDrawRectangle(ticketX + respc(355 + 7), ticketY + respc(115), respc(350), inputH, tocolor(50, 50, 50, 100)) -- HATÓSÁG 
	--dxDrawRectangle(ticketX + respc(355 + 7), ticketY + respc(163), respc(350), inputH, tocolor(50, 50, 50, 100)) -- KIÁLLÍTÓ
	--dxDrawRectangle(ticketX + respc(355 + 7), ticketY + respc(210), respc(350), inputH, tocolor(50, 50, 50, 100)) -- BÍRÁSG
	--dxDrawRectangle(ticketX + respc(355 + 7), ticketY + respc(258), respc(350), inputH, tocolor(50, 50, 50, 100)) -- IDŐ

	--dxDrawRectangle(ticketX + respc(355 + 7 + 147), ticketY + respc(291), respc(180), inputH, tocolor(50, 50, 50, 100)) -- ALÁRÍR

	if isEdit then
		drawInput("name|-|28", ticketX + respc(7), ticketY + respc(115), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))
		drawInput("location|-|28", ticketX + respc(7), ticketY + respc(163), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))
		drawInput("numberplate|-|8", ticketX + respc(7), ticketY + respc(210), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))
		drawInput("reason|-|40", ticketX + respc(7), ticketY + respc(258), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))

		drawInput("agency|-|40", ticketX + respc(365), ticketY + respc(115), respc(355), inputH, fonts.handFont, 0.65, tocolor(0, 84, 166))
		drawInput("officer|-|28", ticketX + respc(365), ticketY + respc(163), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))
		drawInput("money|num-only|6", ticketX + respc(365), ticketY + respc(210), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166), "$")
		drawInput("date|-|28", ticketX + respc(365), ticketY + respc(258), respc(355), inputH, fonts.handFont, 0.7, tocolor(0, 84, 166))

		if signStart then
			local elapsedTime = getTickCount() - signStart
			local progress = elapsedTime / 3579

			local theName = getElementData(localPlayer, "visibleName"):gsub("_", " ")
			local nameWidth = dxGetTextWidth(theName, 0.7, fonts.lunabar)

			local middleX = (respc(180) - nameWidth) / 2

			dxDrawText(theName, ticketX + respc(355 + 7 + 147) + middleX, ticketY + respc(291 + 20), ticketX + respc(355 + 7 + 147) + middleX + nameWidth * progress, ticketY + respc(291) + inputH, tocolor(0, 84, 166), 0.7, fonts.lunabar, "left", "center", true) -- VÉTSÉG

			if progress > 1.25 then
				signStart = false
				showTicket(false)
				playSound("files/paper-rip.mp3")
				exports.sarp_chat:sendLocalMeAction(localPlayer, "kitépi a bírságot a füzetből.")	
			end
		end
	else
		dxDrawText(TicketData["name"], ticketX + respc(10), ticketY + respc(115) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- NÉV
		dxDrawText(TicketData["location"], ticketX + respc(10), ticketY + respc(163) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- HELYSÍZN
		dxDrawText(TicketData["numberplate"], ticketX + respc(10), ticketY + respc(210) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- RENDSZÁM
		dxDrawText(TicketData["reason"], ticketX + respc(10), ticketY + respc(258) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- VÉTSÉG

		dxDrawText(TicketData["agency"], ticketX + respc(355 + 10), ticketY + respc(115) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.65, fonts.handFont) -- NÉV
		dxDrawText(TicketData["officer"], ticketX + respc(355 + 10), ticketY + respc(163) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- HELYSÍZN
		dxDrawText(TicketData["fine"], ticketX + respc(355 + 10), ticketY + respc(210) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- RENDSZÁM
		dxDrawText(TicketData["date"], ticketX + respc(355 + 10), ticketY + respc(258) + respc(15), ticketX + respc(7), ticketY + respc(115), tocolor(0, 84, 166), 0.7, fonts.handFont) -- VÉTSÉG

		dxDrawText(TicketData["officer"], ticketX + respc(355 + 7 + 147), ticketY + respc(291 + 20), ticketX + respc(355 + 7 + 147) + respc(180), ticketY + respc(291) + inputH, tocolor(0, 84, 166), 0.7, fonts.lunabar, "center", "center") -- VÉTSÉG
	end

	

	--dxDrawRectangle(ticketX + respc(355 + 7 + 147), ticketY + respc(291), respc(180), inputH, tocolor(50, 50, 50, 100))
end

Tickets["Traffic"]["Event"] = {}
Tickets["Traffic"]["Event"]["onClientClick"] = function(button, state)
	if button == "left" and state == "down" then
		if inEdit then
			if cursorInBox(ticketX + respc(355 + 7 + 147), ticketY + respc(291), respc(180), inputH) then
				if signStart then
					return
				end
				
				if utf8.len(inputValues["name|-|28"]) <= 4 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Név\" rész kevesebb, mint 4 karakter")
					return
				end

				if utf8.len(inputValues["reason|-|40"]) <= 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Szabálysértés/Vétség\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["officer|-|28"]) <= 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Kiállító személy\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["agency|-|40"]) <= 5 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Hatóság\" rész kevesebb, mint 5 karakter")
					return
				end

				if utf8.len(inputValues["money|num-only|6"]) <= 1 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Bírság összege\" rész kevesebb, mint 1 karakter")
					return
				end

				if utf8.len(inputValues["date|-|28"]) <= 7 then
					exports.sarp_hud:showAlert("error", "Nem megfelelő kitöltés", "A \"Kiállítás időpontja\" rész kevesebb, mint 7 karakter")
					return
				end

				local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
				local players = getElementsByType("player", root, true)
				local targetPlayer = false

				for k = 1, #players do
					local v = players[k]
					local targetPosX, targetPosY, targetPosZ = getElementPosition(v)
					local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, targetPosX, targetPosY, targetPosZ)

					if distance <= 5 then
						local targetName = getElementData(v, "visibleName")

						if utf8.lower(targetName) == utf8.lower(utf8.gsub(inputValues["name|-|28"], " ", "_")) then
							inputValues["name|-|28"] = targetName
							targetPlayer = v
							break
						end
					end
				end

				if targetPlayer == localPlayer then
					exports.sarp_hud:showAlert("error", "Magadnak nem állíthatsz ki csekket!")
					return
				end

				if not targetPlayer then
					exports.sarp_hud:showInfobox("error", "A \"Név\" résznél beírt személy nincs a közeledben!")
					return
				end

				exports.sarp_chat:sendLocalMeAction(localPlayer, "elkezd megírni egy csekket.")

				signStart = getTickCount()
				playSound("files/sign.mp3")

				local data = {
					["name"] = inputValues["name|-|28"],
					["location"] = inputValues["location|-|28"],
					["numberplate"] = inputValues["numberplate|-|8"],
					["reason"] = inputValues["reason|-|40"],
					["officer"] = inputValues["officer|-|28"],
					["agency"] = inputValues["agency|-|40"],
					["fine"] = inputValues["money|num-only|6"],
					["date"] = inputValues["date|-|28"], 
				}

				local characterId = getElementData(targetPlayer, "char.ID") or 0

				if characterId > 0 then
					triggerServerEvent("addItem", localPlayer, targetPlayer, 119, 1, false, toJSON(data), characterId)
				end
			end
		end
	end
end