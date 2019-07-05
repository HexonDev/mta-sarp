local checkForWarpTimer = {}

function endGrab()
	if checkForWarpTimer[source] then
		if isTimer(checkForWarpTimer[source]) then
			killTimer(checkForWarpTimer[source])
		end

		checkForWarpTimer[source] = nil
	end

	local theGrabber = getElementData(source, "player.Grabbed")

	if isElement(theGrabber) then
		setElementData(theGrabber, "grabbingPlayer", false)
		setElementData(source, "cuffAnimation", false)
	end

	local grabbingPlayer = getElementData(source, "grabbingPlayer")

	if isElement(grabbingPlayer) then
		setElementData(grabbingPlayer, "player.Grabbed", false)

		if getElementData(grabbingPlayer, "player.Cuffed") then
			setElementData(grabbingPlayer, "cuffAnimation", 3)
		else
			setElementData(grabbingPlayer, "cuffAnimation", false)
		end
	end
end
addEventHandler("onPlayerQuit", getRootElement(), endGrab)
addEventHandler("onPlayerWasted", getRootElement(), endGrab)

function grabFunction(sourcePlayer, commandName, targetPlayer)
	if not targetPlayer then
		outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Játékos név / ID]", sourcePlayer, 0, 0, 0, true)
	else
		targetPlayer, targetName = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

		if targetPlayer then
			triggerEvent("grabPlayer", sourcePlayer, targetPlayer)
		end
	end
end
addCommandHandler("grab", grabFunction)
addCommandHandler("visz", grabFunction)

function warpPlayerToGrabber(player, grabber)
	if isElement(player) and isElement(grabber) then
		local playerInterior = getElementInterior(player)
		local grabberInterior = getElementInterior(grabber)

		local playerDimension = getElementDimension(player)
		local grabberDimension = getElementDimension(grabber)

		local playerPosX, playerPosY, playerPosZ = getElementPosition(player)
		local grabberPosX, grabberPosY, grabberPosZ = getElementPosition(grabber)

		local _, _, playerRotZ = getElementRotation(player)
		local _, _, grabberRotZ = getElementRotation(grabber)

		local deltaX = grabberPosX - playerPosX
		local deltaY = grabberPosY - playerPosY

		local dist = deltaX * deltaX + deltaY * deltaY

		if playerInterior ~= grabberInterior or playerDimension ~= grabberDimension or dist > 10 then
			local customInterior = tonumber(getElementData(grabber, "currentCustomInterior") or 0)
			
			if customInterior and customInterior > 0 then
				triggerClientEvent(player, "loadCustomInterior", player, customInterior)
			end

			local angle = math.rad(grabberRotZ + 180 - playerRotZ)

			setElementPosition(player, grabberPosX + math.cos(angle) / 2, grabberPosY + math.sin(angle) / 2, grabberPosZ)
			setElementInterior(player, grabberInterior)
			setElementDimension(player, grabberDimension)
		end
	elseif isTimer(checkForWarpTimer[player]) then
		killTimer(checkForWarpTimer[player])
		checkForWarpTimer[player] = nil
	end
end

addEvent("grabPlayer", true)
addEventHandler("grabPlayer", getRootElement(),
	function (targetPlayer)
		if isElement(source) then
			if isElement(targetPlayer) then
				local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
				local targetPosX, targetPosY, targetPosZ = getElementPosition(targetPlayer)

				local sourceInterior = getElementInterior(source)
				local targetInterior = getElementInterior(targetPlayer)

				local sourceDimension = getElementDimension(source)
				local targetDimension = getElementDimension(targetPlayer)

				local distance = getDistanceBetweenPoints3D(sourcePosX, sourcePosY, sourcePosZ, targetPosX, targetPosY, targetPosZ)

				if distance <= 5 then
					if sourceInterior == targetInterior and sourceDimension == targetDimension then
						if getElementData(targetPlayer, "player.Cuffed") then
							if not getElementData(targetPlayer, "player.Grabbed") then
								local grabbingPlayer = getElementData(source, "grabbingPlayer")

								if not isElement(grabbingPlayer) then
									setElementData(source, "grabbingPlayer", targetPlayer)

									setElementData(targetPlayer, "player.Grabbed", source)

									setElementData(targetPlayer, "cuffAnimation", 1)

									if isTimer(checkForWarpTimer[targetPlayer]) then
										killTimer(checkForWarpTimer[targetPlayer])
									end

									checkForWarpTimer[targetPlayer] = setTimer(warpPlayerToGrabber, 1000, 0, targetPlayer, source)
								else
									outputChatBox(exports.sarp_core:getServerTag("error") .. "Egyszerre csak egy embert tudsz vezetni!", source, 0, 0, 0, true)
								end
							else
								outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékost már vezeti valaki!", source, 0, 0, 0, true)
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos nincs megbilincselve!", source, 0, 0, 0, true)
						end
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled!", source, 0, 0, 0, true)
				end
			end
		end
	end
)

function letgoFunction(sourcePlayer, commandName, targetPlayer)
	if not targetPlayer then
		outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Játékos név / ID]", sourcePlayer, 0, 0, 0, true)
	else
		targetPlayer, targetName = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

		if targetPlayer then
			triggerEvent("grabPlayerOff", sourcePlayer, targetPlayer)
		end
	end
end
addCommandHandler("letgo", letgoFunction)
addCommandHandler("elenged", letgoFunction)

addEvent("grabPlayerOff", true)
addEventHandler("grabPlayerOff", getRootElement(),
	function (targetPlayer)
		if isElement(source) then
			if isElement(targetPlayer) then
				local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
				local targetPosX, targetPosY, targetPosZ = getElementPosition(targetPlayer)

				local sourceInterior = getElementInterior(source)
				local targetInterior = getElementInterior(targetPlayer)

				local sourceDimension = getElementDimension(source)
				local targetDimension = getElementDimension(targetPlayer)

				local distance = getDistanceBetweenPoints3D(sourcePosX, sourcePosY, sourcePosZ, targetPosX, targetPosY, targetPosZ)

				if distance <= 5 then
					if sourceInterior == targetInterior and sourceDimension == targetDimension then
						if getElementData(targetPlayer, "player.Grabbed") then
							setElementData(source, "grabbingPlayer", false)

							setElementData(targetPlayer, "player.Grabbed", false)

							if getElementData(targetPlayer, "player.Cuffed") then
								setElementData(targetPlayer, "cuffAnimation", 3)
							else
								setElementData(targetPlayer, "cuffAnimation", false)
							end

							if isTimer(checkForWarpTimer[targetPlayer]) then
								killTimer(checkForWarpTimer[targetPlayer])
							end

							checkForWarpTimer[targetPlayer] = nil
						end
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled!", source, 0, 0, 0, true)
				end
			end
		end
	end
)

function cuffFunction(sourcePlayer, commandName, targetPlayer)
	if exports.sarp_groups:isPlayerHavePermission(sourcePlayer, "cuff") then
		if not targetPlayer then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Játékos név / ID]", sourcePlayer, 0, 0, 0, true)
		else
			targetPlayer, targetName = exports.sarp_core:findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				triggerEvent("cuffPlayer", sourcePlayer, targetPlayer)
			end
		end
	end
end
addCommandHandler("cuff", cuffFunction)
addCommandHandler("bilincs", cuffFunction)

addEvent("cuffPlayer", true)
addEventHandler("cuffPlayer", getRootElement(),
	function (targetPlayer)
		if isElement(source) then
			if isElement(targetPlayer) then
				local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(source)
				local targetPosX, targetPosY, targetPosZ = getElementPosition(targetPlayer)

				local sourceInterior = getElementInterior(source)
				local targetInterior = getElementInterior(targetPlayer)

				local sourceDimension = getElementDimension(source)
				local targetDimension = getElementDimension(targetPlayer)

				local distance = getDistanceBetweenPoints3D(sourcePosX, sourcePosY, sourcePosZ, targetPosX, targetPosY, targetPosZ)

				if distance <= 5 then
					if sourceInterior == targetInterior and sourceDimension == targetDimension then
						local cuffed = not getElementData(targetPlayer, "player.Cuffed")

						setElementData(targetPlayer, "player.Cuffed", cuffed)
						
						if cuffed then
							exports.sarp_controls:toggleControl(targetPlayer, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, false)
						else
							exports.sarp_controls:toggleControl(targetPlayer, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, true)
						end
					end
				else
					outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled!", source, 0, 0, 0, true)
				end
			end
		end
	end
)

--[[
addCommandHandler("cuff",
	function (player, command, target)
		if getElementData(player, "loggedIn") then
			if exports.sarp_groups:isPlayerHavePermission(player, "cuff") then
				if not target or utfLen(target) < 1 then
					outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Játékos név/ID]", player, 0, 0, 0, true)
				else
					target, targetName = exports.sarp_core:findPlayer(player, target)

					if target then
						local localX, localY, localZ = getElementPosition(player)
						local targetX, targetY, targetZ = getElementPosition(target)

						if getDistanceBetweenPoints3D(targetX, targetY, targetZ, localX, localY, localZ) <= 3 and getElementInterior(player) == getElementInterior(target) and getElementDimension(player) == getElementDimension(target) then
							if not getElementData(target, "player.Cuffed") then
								if exports.sarp_inventory:hasItem(player, 77) then
									exports.sarp_controls:toggleControl(target, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, false)
									triggerClientEvent("cuffThePlayer", player, target, true)
									setElementData(target, "player.Cuffed", true)
								else
									outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs nálad bilincs!", player, 0, 0, 0, true)
								end
							else
								outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos már meg van bilincselve!", player, 0, 0, 0, true)
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled!", player, 0, 0, 0, true)
						end
					end
				end
			end
		end
	end
)

addCommandHandler("uncuff",
	function (player, command, target)
		if getElementData(player, "loggedIn") then
			if exports.sarp_groups:isPlayerHavePermission(player, "cuff") then
				if not target or utfLen(target) < 1 then
					outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [Játékos név/ID]", player, 0, 0, 0, true)
				else
					target, targetName = exports.sarp_core:findPlayer(player, target)

					if target then
						local localX, localY, localZ = getElementPosition(player)
						local targetX, targetY, targetZ = getElementPosition(target)

						if getDistanceBetweenPoints3D(targetX, targetY, targetZ, localX, localY, localZ) <= 3 and getElementInterior(player) == getElementInterior(target) and getElementDimension(player) == getElementDimension(target) then
							if getElementData(target, "player.Cuffed") then
								if exports.sarp_inventory:hasItem(player, 78) then
									exports.sarp_controls:toggleControl(target, {"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, true)
									triggerClientEvent("cuffThePlayer", player, target, false)
									setElementData(target, "player.Cuffed", false)
								else
									outputChatBox(exports.sarp_core:getServerTag("error") .. "Nincs nálad bilincs kulcs!", player, 0, 0, 0, true)
								end
							else
								outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos nincs bilincselve!", player, 0, 0, 0, true)
							end
						else
							outputChatBox(exports.sarp_core:getServerTag("error") .. "A kiválasztott játékos túl messze van tőled!", player, 0, 0, 0, true)
						end
					end
				end
			end
		end
	end
)
]]