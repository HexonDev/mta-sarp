connection = false

local Developers = {
	["575B9706754CE444F42A12FEC29BA3A1"] = true,
	["94B3C976D1477E05C6F7146A6868FC04"] = true,
	["A7AFFD556B71B092D01258018AFC2993"] = true,
}

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
				connection = exports.sarp_database:getConnection()
			end
		end
	end
)

logs = exports.sarp_logs

outputUsageText = function(command, element)
	assert(type(command) == "string", "Bad argument @ 'outputUsageText' [expected string at argument 1, got "..type(command).."]")
	outputChatBox(exports.sarp_core:getServerTag("usage") .. "" .. string.gsub(adminCMDs[command][2], "#cmd", command), element, 0, 0, 0, true)
end

outputErrorText = function(text, element)
	--triggerClientEvent(element, "playClientSound", element, ":sarp_assets/audio/admin/error.ogg")
	exports.sarp_core:playSoundForElement(element, ":sarp_assets/audio/admin/error.ogg")
	assert(type(text) == "string", "Bad argument @ 'outputErrorText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("error") .. "" .. text, element, 0, 0, 0, true)
end

outputInfoText = function(text, element)
	assert(type(text) == "string", "Bad argument @ 'outputInfoText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("info") .. text, element, 0, 0, 0, true)
end

getPlayerName_ = getPlayerName
getPlayerName = function(player, withOutHex)
	if isElement(player) then
		if (tonumber(getElementData(player, "acc.adminLevel")) or 0) > 0 and getElementData(player, "adminDuty") then
			player = getElementData(player, "acc.adminNick") or "Admin"
		else
			player = getPlayerName_(player):gsub("_", " ")
		end
		if withOutHex then
			return player:gsub("_", " " ) or player
		else
			return "#ffff99" .. player:gsub("_", " " ) .. "#ffffff" or "#ffff99" .. player .. "#ffffff"
		end
	end
end


hasPermission = function(command, element, inDuty)
	assert(type(command) == "string", "Bad argument @ 'hasPermission' [expected string at argument 1, got "..type(command).."]")
	assert(type(element) == "userdata", "Bad argument @ 'hasPermission' [expected userdata at argument 2, got "..type(element).."]")
	--assert(type(inDuty) == "boolean", "Bad argument @ 'hasPermission' [expected boolean at argument 3, got "..type(inDuty).."]")

	if getElementData(element, "acc.adminLevel") >= 9 then
		return true
	end

	if inDuty == nil then
		inDuty = true
	end

	if getElementData(element, "loggedIn") and getElementData(element, "acc.adminLevel") >= adminCMDs[command][1] and getElementData(element,  "acc.adminLevel") ~= 0 then
		if inDuty then
			if getElementData(element, "adminDuty") then
				return true
			else
				outputErrorText("Csak admin szolgálatban használhatsz admin parancsokat.", element)
				logs:toLog("adminwithoutduty", getPlayerName(element, true) .." megpróbálta használni a(z) " .. command .. " parancsot admin szolgálaton kívűl.")
			end
		else
			return true
		end
	end

	return false
end

addEventHandler("onPlayerChangeNick", getRootElement(),
	function (oldNick, newNick, changedByUser)
		if changedByUser then
			cancelEvent()
		end
	end
)

function adminduty(player, cmd)
	if hasPermission(cmd, player, false) then
		local adminduty = getElementData(player, "adminDuty")

		if adminduty then
			exports.sarp_hud:showAlert(root, "aduty", "".. getPlayerName(player, true) .. " kilépett az adminszolgálatból.")
			logs:toLog("adminduty", getPlayerName(player, true) .. " kilépett az adminszolgálatból.")
			setElementData(player, "adminDuty", false)
			setElementData(player, "visibleName", getPlayerName_(player))
			setElementData(player, "invulnerable", false)
		else
			setElementData(player, "invulnerable", true)
			setElementData(player, "adminDuty", true)
			setElementData(player, "visibleName", (getElementData(player, "acc.adminNick") or "Admin"))
			exports.sarp_hud:showAlert(root, "aduty", "".. getPlayerName(player, true) .. " adminszolgálatba lépett.", "/pm " .. getElementData(player, "playerID") .. " paranccsal üzenhetsz neki")
			logs:toLog("adminduty", getPlayerName(player, true) .. " adminszolgálatba lépett.")
		end
	end
end
addAdminCommand("adminduty", adminduty, "Admin szolgálatba lépés")

function gotoPosition(player, cmd, x, y, z)
	if hasPermission(cmd, player, false) then
		if not x or not y or not z then
			outputUsageText(cmd, player)
		else
			setElementPosition(player, tonumber(x), tonumber(y), tonumber(z))
		end
	end
end
addAdminCommand("gotopos", gotoPosition, "Pozicióra teleportálás")

function gotoPlayer(thePlayer, cmd, target)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)
				
			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					local x, y, z = getElementPosition(targetPlayer)
					local interior = getElementInterior(targetPlayer)
					local dimension = getElementDimension(targetPlayer)
					local r = getPedRotation(targetPlayer)

					x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
					y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )
					
					setCameraInterior(thePlayer, interior)

					local customInterior = tonumber(getElementData(targetPlayer, "currentCustomInterior") or 0)
					if customInterior and customInterior > 0 then
						triggerClientEvent(thePlayer, "loadCustomInterior", thePlayer, customInterior)
					end
					
					if (isPedInVehicle(thePlayer)) then
						local veh = getPedOccupiedVehicle(thePlayer)
						setVehicleTurnVelocity(veh, 0, 0, 0)
						setElementInterior(thePlayer, interior)
						setElementDimension(thePlayer, dimension)
						setElementInterior(veh, interior)
						setElementDimension(veh, dimension)
						setElementPosition(veh, x, y, z + 1)
						warpPedIntoVehicle ( thePlayer, veh ) 
						setTimer(setVehicleTurnVelocity, 50, 20, veh, 0, 0, 0)
					else
						setElementPosition(thePlayer, x, y, z)
						setElementInterior(thePlayer, interior)
						setElementDimension(thePlayer, dimension)
					end

					outputInfoText(getPlayerName(thePlayer) .. " hozzád teleportált", targetPlayer)
					outputInfoText("Elteleportáltál " .. getPlayerName(targetPlayer) .. " játékoshoz", thePlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " elteleportált " .. getPlayerName(targetPlayer) .. " játékoshoz")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " elteleportált " .. getPlayerName(targetPlayer, true) .. " játékoshoz")
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)
				end
			end
		end
	end
end
addAdminCommand("goto", gotoPlayer, "Teleportálás a játékoshoz")

function getPlayer(thePlayer, cmd, target)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)
				
			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					local x, y, z = getElementPosition(targetPlayer)
					local interior = getElementInterior(targetPlayer)
					local dimension = getElementDimension(targetPlayer)
					local r = getPedRotation(targetPlayer)

					setElementFrozen(targetPlayer, true)

					local customInterior = tonumber(getElementData(thePlayer, "currentCustomInterior") or 0)
					if customInterior and customInterior > 0 then
						triggerClientEvent(targetPlayer, "loadCustomInterior", targetPlayer, customInterior)
					end

					x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
					y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )
					
					setCameraInterior(thePlayer, interior)
					
					local x, y, z = getElementPosition(thePlayer)
					local interior = getElementInterior(thePlayer)
					local dimension = getElementDimension(thePlayer)
					local r = getPedRotation(thePlayer)
					setCameraInterior(targetPlayer, interior)

					x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
					y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )

					if (isPedInVehicle(targetPlayer)) then
						local veh = getPedOccupiedVehicle(targetPlayer)
						setVehicleTurnVelocity(veh, 0, 0, 0)
						setElementPosition(veh, x, y, z + 1)
						setTimer(setVehicleTurnVelocity, 50, 20, veh, 0, 0, 0)
						setElementInterior(veh, interior)
						setElementDimension(veh, dimension)
						
					else
						setElementPosition(targetPlayer, x, y, z)
						setElementInterior(targetPlayer, interior)
						setElementDimension(targetPlayer, dimension)
					end
					setElementFrozen(targetPlayer, false)

					outputInfoText(getPlayerName(thePlayer) .. " magához teleportált", targetPlayer)
					outputInfoText("Magadhoz teleportáltad " .. getPlayerName(targetPlayer) .. " játékost", thePlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " magához teleportálta " .. getPlayerName(targetPlayer) .. " játékost")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " magához teleportálta " .. getPlayerName(targetPlayer, true) .. " játékost")
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)
				end
			end
		end
	end
end
addAdminCommand("gethere", getPlayer, "Játékos teleportálása magadhoz")


function playerAnswer(thePlayer, cmd, target, ...)
	if hasPermission(cmd, thePlayer, true) then
		if not target or not ... then
			outputUsageText(cmd, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				if thePlayer ~= targetPlayer then
					if not getElementData(targetPlayer, "adminDuty") then
						local text = table.concat({...}, " ")
						outputInfoText("Válaszod " .. getPlayerName(targetPlayer) .. " számára: " .. text, thePlayer)
						triggerClientEvent(thePlayer, "playClientSound", thePlayer, ":sarp_assets/audio/admin/outmsg.ogg")
						outputInfoText(getPlayerName(thePlayer) .. "#ff4646 válasza: #ffffff" .. text, targetPlayer)
						triggerClientEvent(targetPlayer, "playClientSound", targetPlayer, ":sarp_assets/audio/admin/inmsg.ogg")
						exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " válaszolt " .. getPlayerName(targetPlayer) .. " játékosnak: " .. text)
						logs:toLog("adminmsg", getPlayerName(thePlayer, true) .. "üzenete " .. getPlayerName(targetPlayer, true) .. " játékosnak: " .. text)
					else
						outputErrorText("Szolgálatban lévő adminnak nem válaszolhatsz.", thePlayer)
					end
				else
					outputErrorText("Magadnak nem válaszolhatsz.", thePlayer)
				end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("vá", playerAnswer, "Válasz a játékosnak")

function adminSay(thePlayer, cmd, ...)
	if hasPermission(cmd, thePlayer, true) then
		if not ... then
			outputUsageText(cmd, thePlayer)
		else
			local text = table.concat({...}, " ")
			local adminrank = exports.sarp_core:getPlayerAdminTitle(thePlayer)
			outputInfoText("#32b3ef".. adminrank .. " " .. getPlayerName(thePlayer) .. " #fffffffelhívása: #d75959" .. text, root)
			logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " admin felhívása: " .. text)       
		end
	end
end
addAdminCommand("asay", adminSay, "Admin felhívás a játékosok felé")

function forceReconnect(thePlayer, cmd, target)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				if thePlayer ~= targetPlayer then
					if not getElementData(targetPlayer, "adminDuty") then
						outputInfoText(getPlayerName(targetPlayer) .. " játékos újra csatlakoztatva", thePlayer)
						exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " újracsatlakoztatta " .. getPlayerName(targetPlayer) .. " játékost")
						logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " újracsatlakoztatta " .. getPlayerName(targetPlayer, true) .. " játékost")
						redirectPlayer(targetPlayer, "sa-rp.eu", 22093)
					else
						outputErrorText("Szolgálatban lévő admint nem kényszírtheted.", thePlayer)
					end
				else
					outputErrorText("Magadat nem csatlakoztathatod újra.", thePlayer)
				end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("freconnect", forceReconnect, "Játékos kényszerített újra csatlakoztatása")

function giveItem(thePlayer, cmd, target, itemID, amount, data1, data2, data3)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				itemID = tonumber(itemID)
				amount = tonumber(amount) or 1

				local state = exports.sarp_inventory:addItem(targetPlayer, itemID, amount, false, data1, data2, data3)

				if state then
					local itemName = exports.sarp_inventory:getItemName(itemID)

					outputInfoText(getPlayerName(targetPlayer) .. " játékosnak adtál " .. amount .. "db " .. itemName .. " nevű itemet (data1: " .. tostring(data1) .. ", data2: " .. tostring(data2) .. ", data3: " .. tostring(data3) .. ").", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " adott neked " .. amount .. "db " .. itemName .. " nevű itemet.", targetPlayer)
				
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " adott " .. getPlayerName(targetPlayer) .. " játékosnak " .. amount .. "db " .. itemName .. " nevű itemet (data1: " .. tostring(data1) .. ", data2: " .. tostring(data2) .. ", data3: " .. tostring(data3) .. ").")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " adott " .. getPlayerName(targetPlayer, true) .. " játékosnak " .. amount .. "db " .. itemName .. " nevű itemet (data1: " .. tostring(data1) .. ", data2: " .. tostring(data2) .. ", data3: " .. tostring(data3) .. ").")
				else
					outputChatBox("#dc143c[SARP]: #ffffffAz item odaadás meghiúsult.", thePlayer, 255, 255, 255, true)
				end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("giveitem", giveItem, "Tárgy adása játékosnak")

function playerKick(thePlayer, cmd, target, ...)
	if hasPermission(cmd, thePlayer, true) then
		if not target or not ... then
			outputUsageText(cmd, thePlayer)
		else
			
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				if thePlayer ~= targetPlayer then
					if not Developers[getPlayerSerial(targetPlayer)] then
						if not getElementData(targetPlayer, "adminDuty") then
							local text = table.concat({...}, " ")
							exports.sarp_hud:showAlert(root, "kick", getPlayerName(thePlayer) .. " kickelte " .. getPlayerName(targetPlayer) .. " játékost.", "Indok: " .. text .. "")
							kickPlayer(targetPlayer, thePlayer, text)
							logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " kirúgta " .. getPlayerName(targetPlayer, true) .. " játékost: " .. text)
						else
							outputErrorText("Szolgálatban lévő admint nem rúghatsz ki.", thePlayer)
						end
					else
						outputErrorText("Elsődleges személyt nem rúghatsz ki.", thePlayer)
					end
				else
					outputErrorText("Magadat nem rúghatod ki.", thePlayer)
				end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("kick", playerKick, "Játékosa kirúgása a szerverről.")

function playerFreeze(thePlayer, cmd, target)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				--if not getElementData(targetPlayer, "adminDuty") then
					local veh = getPedOccupiedVehicle( targetPlayer )
					if (veh) then
						setElementFrozen(veh, true)
					end

					exports.sarp_controls:toggleControl(targetPlayer, "all", false)
					outputInfoText("Lefagyasztottad " .. getPlayerName(targetPlayer) .. " játékost", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " lefagyasztott téged", targetPlayer)
					exports.sarp_core:sendMessageToAdmins( getPlayerName(thePlayer) .. " lefagyasztotta " .. getPlayerName(targetPlayer) .. " játékost.")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " lefagyasztotta  " .. getPlayerName(targetPlayer, true) .. " játékost")
				--else
				--    outputErrorText("Szolgálatban lévő admint nem fagyaszthatsz le.", thePlayer)
				--end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("freeze", playerFreeze, "Játékosa lefagyasztása.")

function playerUnfreeze(thePlayer, cmd, target)
	if hasPermission(cmd, thePlayer, true) then
		if not target then
			outputUsageText(cmd, thePlayer)
		else
			
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if getElementData(targetPlayer, "loggedIn") then
				--if not getElementData(targetPlayer, "adminduty") then
					local veh = getPedOccupiedVehicle( targetPlayer )
					if (veh) then
						setElementFrozen(veh, false)
					end

					exports.sarp_controls:toggleControl(targetPlayer, "all", true)
					outputInfoText("Kifagyasztottad " .. getPlayerName(targetPlayer) .. " játékost", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " kifagyasztott téged", targetPlayer)
					exports.sarp_core:sendMessageToAdmins( getPlayerName(thePlayer) .. " kifagyasztotta " .. getPlayerName(targetPlayer) .. " játékost.")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " kifagyasztotta  " .. getPlayerName(targetPlayer, true) .. " játékost")
				--else
					--outputErrorText("Szolgálatban lévő admint nem fagyaszthatsz ki.", thePlayer)
				--end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)
			end
		end
	end
end
addAdminCommand("unfreeze", playerUnfreeze, "Játékosa kifagyasztása.")

function forceAdminduty(player, cmd, target)
	if hasPermission(cmd, player, false) then
		if not target then
			outputUsageText(cmd, player)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)

			if targetPlayer then
				local adminduty = getElementData(targetPlayer, "adminDuty")
				if adminduty then
					exports.sarp_hud:showAlert(root, "aduty", "".. getPlayerName(targetPlayer) .. " kilépett az adminszolgálatból.")
					exports.sarp_core:sendMessageToAdmins( getPlayerName(player) .. " kiléptette adminszolgálatból " .. getPlayerName(targetPlayer) .. " adminisztrátort.")
					logs:toLog("adminduty", getPlayerName(targetPlayer, true) .. " kilépett az adminszolgálatból " .. getPlayerName(targetPlayer, true) .. " által.")
					setElementData(targetPlayer, "adminDuty", false)
					setElementData(targetPlayer, "visibleName", getPlayerName_(targetPlayer))
					setElementData(targetPlayer, "invulnerable", false)
				else
					setElementData(targetPlayer, "invulnerable", true)
					setElementData(targetPlayer, "adminDuty", true)
					setElementData(targetPlayer, "visibleName", (getElementData(targetPlayer, "acc.adminNick") or "Admin"))
					exports.sarp_hud:showAlert(root, "aduty", "".. getPlayerName(targetPlayer) .. " adminszolgálatba lépett .", "/pm " .. getElementData(targetPlayer, "playerID") .. " paranccsal üzenhetsz neki")
					exports.sarp_core:sendMessageToAdmins( getPlayerName(player) .. " adminszolgálatba léptette " .. getPlayerName(targetPlayer) .. " adminisztrátort.")
					logs:toLog("adminduty", getPlayerName(targetPlayer, true) .. " adminszolgálatba lépett " .. getPlayerName(player, true) .. " által.")
				end
			end
		end
	end
end
addAdminCommand("fadminduty", forceAdminduty, "Adminisztrátor adminszolgálatba léptetése")

function setAdminName(thePlayer, commandName, target, adminName)
	if hasPermission(commandName, thePlayer, true) then 
		if not target or not adminName then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, target)
			if getElementData(targetPlayer, "loggedIn") then
				dbExec(connection, "UPDATE accounts SET adminNick = ? WHERE accountID = ?", adminName, getElementData(targetPlayer, "acc.dbID"))
				setElementData(targetPlayer, "acc.adminNick", adminName)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " megváltoztatta " .. targetPlayerName .. " admin becenevét a következőre: " .. adminName .. ".")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " megváltoztatta " .. targetPlayerName .. " admin becenevét a következőre: " .. adminName .. ".")
				outputInfoText(" Megváltoztattad " .. targetPlayerName .. " admin becenevét a következőre: " .. adminName, thePlayer)
				outputInfoText( getPlayerName(thePlayer) .. " megváltoztatta az admin becenevedet a következőre: " .. adminName, targetPlayer)

				if getElementData(targetPlayer, "adminDuty") then
					setElementData(targetPlayer, "visibleName", adminName)
				end
			else
				outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
			end
		end
	end
end
addAdminCommand("setadminnick", setAdminName, "Adminisztrátori becenév megváltoztatása")

function adminInvisibility(thePlayer, cmd)
	if hasPermission(cmd, thePlayer, true) then
		local invisible = getElementData(thePlayer, "invisible")
		if invisible then
			setElementAlpha(thePlayer, 255)
			outputInfoText("Látható lettél", thePlayer)
			triggerClientEvent(thePlayer, "playClientSound", thePlayer, ":sarp_assets/audio/admin/restore.ogg")
			exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." látható lett.")
			logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " látható lett.")
		else
			setElementAlpha(thePlayer, 0)
			outputInfoText("Láthatatlan lettél", thePlayer)
			triggerClientEvent(thePlayer, "playClientSound", thePlayer, ":sarp_assets/audio/admin/minimize.ogg")
			exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." láthatatlan lett.")
			logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " láthatatlan lett.")
		end
		setElementData(thePlayer, "invisible", not invisible)
	end
end
addAdminCommand("vanish", adminInvisibility, "Láthatatlaná vagy láthatóvá válás")

function setHP(thePlayer, commandName, targetPlayer, HP)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(HP) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					HP = tonumber(HP)
					if setElementHealth(targetPlayer, HP) then
						outputInfoText("Megváltoztattad " .. getPlayerName(targetPlayer) .. " életszintjét a következőre: " .. HP, thePlayer)
						outputInfoText(getPlayerName(thePlayer) .. " megváltoztatta az életszintedet a következőre: " .. HP, targetPlayer)
						triggerEvent("removeAllInjuries", targetPlayer, targetPlayer)
						exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." megváltoztatta " .. getPlayerName(targetPlayer) .. " életszintjét a következőre: " .. HP .. ".")
						logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megváltoztatta " .. getPlayerName(targetPlayer, true) .. " életszintjét a következőre: " .. HP .. ".")
					else
						outputErrorText("Helytelen érték.", thePlayer)
					end
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("sethp", setHP, "Szerveren lévő játékos életének beállítása")

function setPlayerAdminLevel(thePlayer, commandName, targetPlayer, adminLevel)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(adminLevel) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					if getElementData(thePlayer, "acc.adminLevel") == 5 then
						if tonumber(adminLevel) > 0 then
							outputErrorText("Csak -1 (IDG AS), és -2 (AS)-t adhatsz!", thePlayer)
							return
						end
					end

					setElementData(targetPlayer, "adminDuty", false)
					setElementData(targetPlayer, "visibleName", getPlayerName_(targetPlayer))
					setElementData(targetPlayer, "acc.adminLevel", tonumber(adminLevel))
					if tonumber(adminLevel) == -1 then
						dbExec(connection, "UPDATE accounts SET adminLevel = ? WHERE accountID = ?", 0, getElementData(targetPlayer, "acc.dbID"))
					else
						dbExec(connection, "UPDATE accounts SET adminLevel = ? WHERE accountID = ?", adminLevel, getElementData(targetPlayer, "acc.dbID"))
					end
					outputInfoText("Megváltoztattad " .. getPlayerName(targetPlayer) .. " adminszintjét a következőre: " .. adminLevel, thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " megváltoztatta az adminszinted a következőre: " .. adminLevel, targetPlayer)
					exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." megváltoztatta " .. getPlayerName(targetPlayer) .. " adminszintjét a következőre: " .. adminLevel .. ".")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megváltoztatta " .. getPlayerName(targetPlayer, true) .. " adminszintjét a következőre: " .. adminLevel .. ".")
			
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("makeadmin", setPlayerAdminLevel, "Játékos adminszintjének megváltoztatása")

addEvent("updateSpectatePosition", true)
addEventHandler("updateSpectatePosition", getRootElement(),
	function (interior, dimension, customInterior)
		if isElement(source) then
			setElementInterior(source, interior)
			setElementDimension(source, dimension)
			setCameraInterior(source, interior)

			if customInterior and customInterior > 0 then
				triggerClientEvent(source, "loadCustomInterior", source, customInterior)
			end
		end
	end
)

function spectatePlayer(thePlayer, commandName, targetPlayer)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer  then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if targetPlayer == thePlayer then -- ha a célszemély saját maga, kapcsolja ki a nézelődést
					local playerLastPos = getElementData(thePlayer, "playerLastPos")

					if playerLastPos then -- ha tényleg nézelődött
						local currentTarget = getElementData(thePlayer, "spectateTarget") -- nézett játékos lekérése
						local spectatingPlayers = getElementData(currentTarget, "spectatingPlayers") or {} -- nézett játékos nézelődőinek lekérése

						spectatingPlayers[thePlayer] = nil -- kivesszük a parancs használóját a nézett játékos nézelődői közül
						setElementData(currentTarget, "spectatingPlayers", spectatingPlayers) -- elmentjük az úrnak

						setElementAlpha(thePlayer, 255)
						setElementInterior(thePlayer, playerLastPos[4])
						setElementDimension(thePlayer, playerLastPos[5])
						setCameraInterior(thePlayer, playerLastPos[4])
						setCameraTarget(thePlayer, thePlayer)
						setElementFrozen(thePlayer, false)
						setElementCollisionsEnabled(thePlayer, true)
						setElementPosition(thePlayer, playerLastPos[1], playerLastPos[2], playerLastPos[3])
						setElementRotation(thePlayer, 0, 0, playerLastPos[6])

						removeElementData(thePlayer, "spectateTarget")
						removeElementData(thePlayer, "playerLastPos")

						outputInfoText("Kikapcsoltad #ffa600" .. getPlayerName(currentTarget) .. " #ffffffjátékos nézését.", thePlayer)
						exports.sarp_core:sendMessageToAdmins("#ffa600" .. getPlayerName(thePlayer) .. " #ffffffbefejezte #ffff99" .. getPlayerName(currentTarget) .. " #ffffffjátékos nézését.")
					end
				else
					local targetInterior = getElementInterior(targetPlayer)
					local targetDimension = getElementDimension(targetPlayer)
					local currentTarget = getElementData(thePlayer, "spectateTarget")
					local playerLastPos = getElementData(thePlayer, "playerLastPos")

					if currentTarget and currentTarget ~= targetPlayer then -- ha a jelenleg nézett célszemély nem az új célszemély vegye ki a nézelődők listájából
						local spectatingPlayers = getElementData(currentTarget, "spectatingPlayers") or {} -- jelenleg nézett célszemély nézelődői

						spectatingPlayers[thePlayer] = nil -- eltávolítjuk az eddig nézett játékos nézelődői közül
						setElementData(currentTarget, "spectatingPlayers", spectatingPlayers) -- elmentjük a változásokat
					end

					if not playerLastPos then -- ha eddig nem volt nézelődő módban, mentse el a jelenlegi pozícióját
						local localX, localY, localZ = getElementPosition(thePlayer)
						local localRotX, localRotY, localRotZ = getElementPosition(thePlayer)
						local localInterior = getElementInterior(thePlayer)
						local localDimension = getElementDimension(thePlayer)

						setElementData(thePlayer, "playerLastPos", {localX, localY, localZ, localInterior, localDimension, localRotZ}, false)
					end

					setElementAlpha(thePlayer, 0)
					setPedWeaponSlot(thePlayer, 0)
					setElementInterior(thePlayer, targetInterior)
					setElementDimension(thePlayer, targetDimension)
					setCameraInterior(thePlayer, targetInterior)
					setCameraTarget(thePlayer, targetPlayer)
					setElementFrozen(thePlayer, true)
					setElementCollisionsEnabled(thePlayer, false)

					local spectatingPlayers = getElementData(targetPlayer, "spectatingPlayers") or {} -- lekérjük az új úrfi jelenlegi nézelődőit

					spectatingPlayers[thePlayer] = true -- hozzáadjuk az úrfi nézelődőihez a parancs használóját
					setElementData(targetPlayer, "spectatingPlayers", spectatingPlayers) -- elmentjük az úrfinak a változásokat

					setElementData(thePlayer, "spectateTarget", targetPlayer)

					outputInfoText("Elkezdted nézni #ffa600" .. targetPlayerName .. " #ffffffjátékost.", thePlayer)
					exports.sarp_core:sendMessageToAdmins("#ffa600" .. getPlayerName(thePlayer) .. " #ffffffelkezdte nézni #ffff99" .. targetPlayerName .. " #ffffffjátékost.")
				end
			end
		end
	end
end
addAdminCommand("spec", spectatePlayer, "Játékos megfigyelése")

function setSkin(thePlayer, commandName, targetPlayer, skin)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(skin) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					skin = tonumber(skin)
					if setElementModel(targetPlayer, skin) then
						outputInfoText("Megváltoztattad " .. getPlayerName(targetPlayer) .. " kinézetét a következőre: " .. skin, thePlayer)
						outputInfoText(getPlayerName(thePlayer) .. " megváltoztatta az kinézeted a következőre: " .. skin, targetPlayer)
						exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." megváltoztatta " .. getPlayerName(targetPlayer) .. " kinézetét a következőre: " .. skin .. ".")
						logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megváltoztatta " .. getPlayerName(targetPlayer, true) .. " kinézetét a következőre: " .. skin .. ".")
					else
						outputErrorText("Helytelen érték.", thePlayer)
					end
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("setskin", setSkin, "Szerveren lévő játékos kinézetének beállítása")

function setArmor(thePlayer, commandName, targetPlayer, Armor)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(Armor) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					Armor = tonumber(Armor)
					if setPedArmor(targetPlayer, Armor) then
						outputInfoText("Megváltoztattad " .. getPlayerName(targetPlayer) .. " páncélját a következőre: " .. Armor, thePlayer)
						outputInfoText(getPlayerName(thePlayer) .. " megváltoztatta az páncélodat a következőre: " .. Armor, targetPlayer)
						exports.sarp_core:sendMessageToAdmins("".. getPlayerName(thePlayer) .." megváltoztatta " .. getPlayerName(targetPlayer) .. " páncélját a következőre: " .. Armor .. ".")
						logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megváltoztatta " .. getPlayerName(targetPlayer, true) .. " páncélját a következőre: " .. Armor .. ".")
					else
						outputErrorText("Helytelen érték.", thePlayer)
					end
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("setarmor", setArmor, "Szerveren lévő játékos páncéljának beállítása")

function setName(thePlayer, commandName, targetPlayer, Name)
	if hasPermission(commandName, thePlayer, true) then
		if not targetPlayer or not Name then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)
			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					local oldName = getPlayerName(targetPlayer)
					if setPlayerName( targetPlayer, Name ) then
						outputInfoText("Megváltoztattad " .. oldName .. " nevét a következőre: " .. Name, thePlayer)
						outputInfoText(getPlayerName(thePlayer) .." megváltoztatta nevedet a következőre: " .. Name, targetPlayer)
						exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " megváltoztatta " .. oldName .. " nevét a következőre: " .. Name)
						logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megváltoztatta " .. oldName .. " nevét a következőre: " .. Name .. ".")
						dbExec(connection, "UPDATE characters SET name = ? WHERE charID = ?", Name, getElementData(targetPlayer, "char.ID"))
						setElementData(targetPlayer, "visibleName", Name)
					else 
						outputErrorText("Hiba történt a név megváltoztatása során!", thePlayer)
					end
				end   
			end
		end
	end
end
addAdminCommand("changename", setName, "Szerveren lévő játékos nevének beállítása")

local places = {
	["ls"] = {1484.7469482422, -1740.1397705078, 13.546875, 180},
	["deli"] = {1933.1015625, -1744.0854492188, 13.546875, 180},
	["eszaki"] = {1005.5318603516, -951.64923095703, 42.192859649658, 0},
	["alsohatar"] = {85.606513977051, -1519.0068359375, 4.8448534011841, 180},
	["felsohatar"] = {-54.145683288574, -1386.3479003906, 11.854888916016, 309},
	["ur"] = {572.81579589844, -1432.7233886719, 70336.34375, 0},
}

function gotoPlace(thePlayer, commandName, place)
	if hasPermission(commandName, thePlayer, true) then
		if not place then
			outputUsageText(commandName, thePlayer)
			outputInfoText("Elérhető helyek:", thePlayer)
			local availablePlaces = ""
			for k, v in pairs(places) do
				availablePlaces = availablePlaces .. " " .. k .. ","
			end
			outputInfoText(availablePlaces, thePlayer)
		else
			local found = false
			for k, v in pairs(places) do
				if place == k then
					if isPedInVehicle(thePlayer) then
						local veh = getPedOccupiedVehicle(thePlayer)
						setElementPosition(veh, v[1], v[2], v[3])
						setElementDimension(veh, 0)
						setElementInterior(veh, 0)
					else
						setElementPosition(thePlayer, v[1], v[2], v[3])
						setElementDimension(thePlayer, 0)
						setElementInterior(thePlayer, 0)
					end
					outputInfoText("Elteleportáltál a következő helyre: " .. place, thePlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " elteleportált a következő helyre:" .. place )
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " elteleportált a következő helyre:" .. place )
					found = true
					break
				end
			end

			if not found then
				outputErrorText("Nem találtunk ilyen helyet", thePlayer)
			end
		end
	end
end
addAdminCommand("gotoplace", gotoPlace, "Elteleportálás egy adott helyRe")

function giveMoney(thePlayer, commandName, targetPlayer, value)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(value) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					value = tonumber(value)
					exports.sarp_core:giveMoney(targetPlayer, value, "admin-give")
					outputInfoText("Adtál " .. getPlayerName(targetPlayer) .. " játékosnak " .. value .. "$-t", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " adott neked " .. value .. "$-t", targetPlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " adott " .. getPlayerName(targetPlayer) .. " játékosnak " .. value .. "$-t")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " adott " .. getPlayerName(targetPlayer, true) .. " játékosnak " .. value .. "$-t")
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("givemoney", giveMoney, "Szerveren lévő játékosnak pénz adás")

function takeMoney(thePlayer, commandName, targetPlayer, value)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(value) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					value = tonumber(value)
					exports.sarp_core:takeMoneyEx(targetPlayer, value, "admin-takeEx")
					outputInfoText("Elvettél " .. getPlayerName(targetPlayer) .. " játékostól " .. value .. "$-t", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " elvett tőled " .. value .. "$-t", targetPlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " elvett " .. getPlayerName(targetPlayer) .. " játékostól " .. value .. "$-t")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " elvett " .. getPlayerName(targetPlayer, true) .. " játékostól " .. value .. "$-t")
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("takemoney", takeMoney, "Szerveren lévő játékostól pénz elvétel")

function setMoney(thePlayer, commandName, targetPlayer, value)
	if hasPermission(commandName, thePlayer, true) then 
		if not targetPlayer or not tonumber(value) then
			outputUsageText(commandName, thePlayer)
		else
			local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)

			if targetPlayer then
				if getElementData(targetPlayer, "loggedIn") then
					value = tonumber(value)
					exports.sarp_core:setMoney(targetPlayer, value)
					outputInfoText("Beállítottad " .. getPlayerName(targetPlayer) .. " játékosnak a plnz összegét " .. value .. "$-ra", thePlayer)
					outputInfoText(getPlayerName(thePlayer) .. " beállította a pénz összegedet " .. value .. "$-ra", targetPlayer)
					exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " beállította " .. getPlayerName(targetPlayer) .. " játékos pénz összegét " .. value .. "$-ra")
					logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " beállította " .. getPlayerName(targetPlayer, true) .. " játékos pénz összegét " .. value .. "$-ra")
				else
					outputErrorText("A játékos nincs bejelentkezve", thePlayer)	
				end
			end
		end
	end
end
addAdminCommand("setmoney", setMoney, "Szerveren lévő játékos pénz összegének beállítása")

function makeNPC(thePlayer, commandName, skin, pedtype, subtype, ...)
	if hasPermission(commandName, thePlayer, true) then 
		if not tonumber(skin) or not (...) or not tonumber(pedtype) or not tonumber(subtype) or tonumber(pedtype) > exports["sarp_npcs"]:getNPCTypeCount() then
			outputUsageText(commandName, thePlayer)
			for k, v in ipairs(exports["sarp_npcs"]:getNPCTypes()) do
				outputInfoText( k .. ": " .. v, thePlayer)
			end
		else
			local x, y, z = getElementPosition(thePlayer)
			local rx, ry, rz = getElementRotation(thePlayer)
			local int, dim = getElementInterior(thePlayer), getElementDimension(thePlayer)
			local name = table.concat({...}, " ")
			if exports["sarp_npcs"]:createNPC({x, y, z, rz, int, dim}, tonumber(skin), name, tonumber(pedtype), tonumber(subtype)) then
				outputInfoText("Létrehoztál egy " .. exports["sarp_npcs"]:getNPCTypeName(pedtype) .. " típusú NPC-t", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " létrehozott egy " .. exports["sarp_npcs"]:getNPCTypeName(pedtype) .. " típusú NPC-t " .. name .. " néven")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " létrehozott egy " .. exports["sarp_npcs"]:getNPCTypeName(pedtype) .. " típusú NPC-t " .. name .. " néven")
			end
		end
	end
end
addAdminCommand("createnpc", makeNPC, "NPC létrehozása")

function deleteNPC(thePlayer, commandName, id)
	if hasPermission(commandName, thePlayer, true) then 
		if not tonumber(id) then
			outputUsageText(commandName, thePlayer)
		else
			if exports["sarp_npcs"]:deleteNPC(tonumber(id)) then
				outputInfoText("Kitörölted a(z) " .. id .. " azonosítóval rendelkező NPC-t", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " kitörölte a(z) " .. id .. " azonosítóval rendelkező NPC-t")
				logs:toLog("adminaction", getPlayerName(thePlayer) .. " kitörölte a(z) " .. id .. " azonosítóval rendelkező NPC-t")
			else
				outputErrorText("Nem sikerült kitörölni az NPC-t", thePlayer)
			end
		end
	end
end
addAdminCommand("deletenpc", deleteNPC, "NPC törlése")

function makeATM(thePlayer, commandName)
	if hasPermission(commandName, thePlayer, true) then 
		local x, y, z = getElementPosition(thePlayer)
		local rx, ry, rz = getElementRotation(thePlayer)
		local int, dim = getElementInterior(thePlayer), getElementDimension(thePlayer)
		if exports["sarp_bank"]:createATM({x, y, z, rz, int, dim}) then
			outputInfoText("Létrehoztál egy ATM-et", thePlayer)
			exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " létrehozott egy ATM-et")
			logs:toLog("adminaction", getPlayerName(thePlayer, true) .. " létrehozott egy ATM-et (pos: " .. inspect({x, y, z, rz, int, dim}) .. ")")
		end
	end
end
addAdminCommand("createatm", makeATM, "ATM létrehozása")

function deleteATM(thePlayer, commandName, id)
	if hasPermission(commandName, thePlayer, true) then 
		if not tonumber(id) then
			outputUsageText(commandName, thePlayer)
		else
			if exports["sarp_bank"]:deleteATM(tonumber(id)) then
				outputInfoText("Kitörölted a(z) " .. id .. " azonosítóval rendelkező ATM-et", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .. " kitörölte a(z) " .. id .. " azonosítóval rendelkező ATM-et")
				logs:toLog("adminaction", getPlayerName(thePlayer) .. " kitörölte a(z) " .. id .. " azonosítóval rendelkező ATM-et")
			else
				outputErrorText("Nem sikerült kitörölni az ATM-et", thePlayer)
			end
		end
	end
end
addAdminCommand("deleteatm", deleteATM, "ATM törlése")

function insertBan(accountID, serial, accountName, reason, adminName, banTimestamp, expireTimestamp)
	if serial and accountName and reason and adminName and banTimestamp and expireTimestamp then
		accountID = tonumber(accountID)
		banTimestamp = tonumber(banTimestamp)
		expireTimestamp = tonumber(expireTimestamp)

		return dbExec(connection, "INSERT INTO bans (playerSerial, playerName, banReason, adminName, banTimestamp, expireTimestamp, isActive) VALUES (?,?,?,?,?,?,?); UPDATE accounts SET suspended = 'Y' WHERE accountID = ?", serial, accountName, reason, adminName, banTimestamp, expireTimestamp, "Y", accountID)
	end

	return false
end

function deleteBan(accountID, serial, accountName)
	if accountID and (serial or accountName) then
		accountID = tonumber(accountID)

		local accountUnbanned = dbExec(connection, "UPDATE accounts SET suspended = 'N' WHERE accountID = ?", accountID)
		local banIsNotActive

		if serial and accountName then
			banIsNotActive = dbExec(connection, "UPDATE bans SET isActive = 'N' WHERE playerSerial = ? AND playerName = ?", serial, accountName)
		elseif serial then
			banIsNotActive = dbExec(connection, "UPDATE bans SET isActive = 'N' WHERE playerSerial = ?", serial)
		elseif accountName then
			banIsNotActive = dbExec(connection, "UPDATE bans SET isActive = 'N' WHERE playerName = ?", accountName)
		end

		return accountUnbanned and banIsNotActive
	end

	return false
end

function checkBan(callbackFunction, accountID, serial, accountName)
	if accountID and (serial or accountName) then
		accountID = tonumber(accountID)

		if serial and accountName then
			dbQuery(callbackFunction, connection, "SELECT * FROM bans WHERE playerSerial = ? AND playerName = ? AND isActive = 'Y'", serial, accountName)
		elseif serial then
			dbQuery(callbackFunction, connection, "SELECT * FROM bans WHERE playerSerial = ? AND isActive = 'Y'", serial)
		elseif accountName then
			dbQuery(callbackFunction, connection, "SELECT * FROM bans WHERE playerName = ? AND isActive = 'Y'", accountName)
		end

		return true
	end

	return false
end

function playerBan(player, cmd, target, duration, ...)
	if hasPermission(cmd, player, true) then
		if not target or not duration or not (...) then
			outputUsageText(cmd, player)
		else
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(player, target)

			if targetPlayer then
				if not Developers[getPlayerSerial(targetPlayer)] then
					
				--elseif getElementData(targetPlayer, "adminDuty") then
				--	outputErrorText("Szolgálatban lévő admint nem tilthatsz ki!", player)
				--else
					duration = tonumber(duration)

					local reason = table.concat({...}, " ")
					local banTimestamp = getRealTime().timestamp
					local expireTimestamp = banTimestamp + (duration == 0 and 31536000 * 100 or duration * 3600)
					local adminName = getElementData(player, "acc.adminNick") or getPlayerName(player, true)

					if insertBan(getElementData(targetPlayer, "acc.dbID"), getPlayerSerial(targetPlayer), getElementData(targetPlayer, "acc.Name"), reason, adminName, banTimestamp, expireTimestamp) then
						exports.sarp_hud:showAlert(root, "ban", adminName .. " kitiltotta " .. getPlayerName(targetPlayer, true) .. " játékost", "Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason)

						kickPlayer(targetPlayer, adminName, reason)

						logs:toLog("adminaction", adminName .. " kitiltotta " .. getPlayerName(targetPlayer, true) .. " játékost (Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason .. ")")
					else
						outputErrorText("Nem sikerült a kitiltást végrehajtani!", player)
						exports.sarp_hud:showAlert(player, "error", "Nem sikerült a kitiltást végrehajtani!")
					end
				else
					--outputErrorText("Elsődleges személyt nem rúghatsz ki!", player)
					duration = tonumber(duration)
					local reason = table.concat({...}, " ")
					local adminName = getElementData(player, "acc.adminNick") or getPlayerName(player, true)
					exports.sarp_hud:showAlert(player, "ban", adminName .. " kitiltotta " .. getPlayerName(targetPlayer, true) .. " játékost", "Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason)

					outputErrorText("Megpróbáltak kibannolni:( " .. getPlayerName(player) .. " accID: " .. getElementData(player, "acc.ID") .. " curID: " .. getElementData(player, "playerID") .. " charID: " .. getElementData(player, "char.ID"), targetPlayer)
				end
			end
		end
	end
end
addAdminCommand("aban", playerBan, "Játékosa kitiltása a szerverről.")

function playerUnban(player, cmd, data)
	if hasPermission(cmd, player, true) then
		if not data then
			outputUsageText(cmd, player)
		else
			if tonumber(data) then -- account id alapján
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						if result and result[1] then
							if deleteBan(result[1].accountID, result[1].serial) then
								outputInfoText("Sikeresen feloldottad a kiválasztott játékosról a tiltást!", player)
								exports.sarp_hud:showAlert(player, "success", "Sikeresen feloldottad a tiltást.", "AccountID: " .. result[1].accountID .. ", Serial: " .. result[1].serial)

								logs:toLog("adminaction", getElementData(player, "acc.adminNick") or getPlayerName(player, true) .. " feloldott egy tiltást. (AccountID: " .. result[1].accountID .. ", Serial: " .. result[1].serial .. ")")
							else
								outputErrorText("Nem sikerült a tiltás feloldása!", player)
								exports.sarp_hud:showAlert(player, "error", "Nem sikerült a tiltás feloldása!")
							end
						else
							outputErrorText("Ez a felhasználó nincs kitiltva!", player)
							exports.sarp_hud:showAlert(player, "error", "Ez a felhasználó nincs kitiltva!")
						end
					end, connection, "SELECT accountID, serial FROM accounts WHERE accountID = ? AND suspended = 'Y' LIMIT 1", tonumber(data)
				)
			else -- serial alapján
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0)

						if result and result[1] then
							if deleteBan(result[1].accountID, data) then
								outputInfoText("Sikeresen feloldottad a kiválasztott játékosról a tiltást!", player)
								exports.sarp_hud:showAlert(player, "success", "Sikeresen feloldottad a tiltást.", "AccountID: " .. result[1].accountID .. ", Serial: " .. data)

								logs:toLog("adminaction", getElementData(player, "acc.adminNick") or getPlayerName(player, true) .. " feloldott egy tiltást. (AccountID: " .. result[1].accountID .. ", Serial: " .. data .. ")")
							else
								outputErrorText("Nem sikerült a tiltás feloldása!", player)
								exports.sarp_hud:showAlert(player, "error", "Nem sikerült a tiltás feloldása!")
							end
						else
							outputErrorText("Ez a felhasználó nincs kitiltva!", player)
							exports.sarp_hud:showAlert(player, "error", "Ez a felhasználó nincs kitiltva!")
						end
					end, connection, "SELECT accountID FROM accounts WHERE serial = ? AND suspended = 'Y' LIMIT 1", data
				)
			end
		end
	end
end
addAdminCommand("unaban", playerUnban, "Játékosa kitiltásának feloldása.")

function playerOfflineBan(player, cmd, data, duration, ...)
	if hasPermission(cmd, player, true) then
		if not data or not duration or not (...) then
			outputUsageText(cmd, player)
		else
			duration = tonumber(duration)

			local reason = table.concat({...}, " ")
			local banTimestamp = getRealTime().timestamp
			local expireTimestamp = banTimestamp + (duration == 0 and 31536000 * 100 or duration * 3600)
			local adminName = getElementData(player, "acc.adminNick") or getPlayerName(player, true)

			local query = "SELECT * FROM accounts WHERE serial = ? LIMIT 1"
			if tonumber(data) then
				data = tonumber(data)
				query = "SELECT * FROM accounts WHERE accountID = ? LIMIT 1"
			end

			dbQuery(
				function (qh)
					local result = dbPoll(qh, 0)

					if result and result[1] then
						result = result[1]

						if result.suspended == "Y" then
							outputErrorText("A kiválasztott felhasználó már fel van függesztve!", player)
							exports.sarp_hud:showAlert(player, "error", "A kiválasztott felhasználó már fel van függesztve!")
						else
							if insertBan(result.accountID, result.serial, result.username, reason, adminName, banTimestamp, expireTimestamp) then
								exports.sarp_hud:showAlert(root, "ban", adminName .. " kitiltotta " .. result.username .. " felhasználót", "Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason)

								logs:toLog("adminaction", adminName .. " kitiltotta " .. result.username .. " felhasználót (Időtartam: " .. (duration == 0 and "Örök" or duration .. " óra") .. ", Indok: " .. reason .. ")")
							else
								outputErrorText("Nem sikerült a kitiltást végrehajtani!", player)
								exports.sarp_hud:showAlert(player, "error", "Nem sikerült a kitiltást végrehajtani!")
							end
						end
					else
						outputErrorText("A kiválasztott felhasználó nincs regisztrálva a szerveren!", player)
						exports.sarp_hud:showAlert(player, "error", "A kiválasztott felhasználó nincs regisztrálva a szerveren!")
					end
				end, connection, query, data
			)
		end
	end
end
addAdminCommand("oaban", playerOfflineBan, "Offline játékos kitiltása a szerverről.")

function adminFly(thePlayer, commandName)
	if hasPermission(commandName, thePlayer, true) then
		if not isPedInVehicle(thePlayer) then
			triggerClientEvent(thePlayer, "sarp_adminC:toggleFly", thePlayer)
		end
	end
end
addAdminCommand("fly", adminFly, "Repülés")

function forceAdminFly(thePlayer, commandName, targetPlayer)
	if hasPermission(commandName, thePlayer, true) then
		if not targetPlayer then
			outputUsageText(commandName, thePlayer)
			return
		end

		local targetPlayer = exports.sarp_core:findPlayer(thePlayer, targetPlayer)
		if targetPlayer then
			if not isPedInVehicle(targetPlayer) then
				triggerClientEvent(targetPlayer, "sarp_adminC:toggleFly", targetPlayer)
			end
		end
	end
end
addAdminCommand("ffly", forceAdminFly, "Repülés")


--===================[SA-RP]===================--
-- JÁRMŰ PARANCSOK 
--===================[SA-RP]===================--

function getVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				local r = getPedRotation(thePlayer)
				local x, y, z = getElementPosition(thePlayer)
				x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
				y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )
				
				if	(getElementHealth(theVehicle)==0) then
					spawnVehicle(theVehicle, x, y, z, 0, 0, r)
				else
					setElementPosition(theVehicle, x, y, z)
					setVehicleRotation(theVehicle, 0, 0, r)
				end
				
				setElementInterior(theVehicle, getElementInterior(thePlayer))
				setElementDimension(theVehicle, getElementDimension(thePlayer))

				local customInterior = tonumber(getElementData(thePlayer, "currentCustomInterior") or 0)
				if not customInterior or customInterior <= 0 then
					setElementData(theVehicle, "currentCustomInterior", false)
				else
					setElementData(theVehicle, "currentCustomInterior", customInterior)
				end

				outputInfoText("A járművet sikeresen magadhoz teleportáltad", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." magához teleportálta a " .. vehicleID .. " azonosítóval rendelkező járművet.")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." magához teleportálta a " .. vehicleID .. " azonosítóval rendelkező járművet.")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("getveh", getVehicle, "Jármű magadhoz teleportálása")

function gotoVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not (vehicleID) then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				local rx, ry, rz = getVehicleRotation(theVehicle)
				local x, y, z = getElementPosition(theVehicle)
				x = x + ( ( math.cos ( math.rad ( rz ) ) ) * 2 )
				y = y + ( ( math.sin ( math.rad ( rz ) ) ) * 2 )
				
				setElementPosition(thePlayer, x, y, z)
				setPedRotation(thePlayer, rz)
				setElementInterior(thePlayer, getElementInterior(theVehicle))
				setElementDimension(thePlayer, getElementDimension(theVehicle))

				local customInterior = tonumber(getElementData(theVehicle, "currentCustomInterior") or 0)
				if customInterior and customInterior > 0 then
					triggerClientEvent(thePlayer, "loadCustomInterior", thePlayer, customInterior)
				end
				
				outputInfoText("Sikeresen elteleportáltál a járműhöz", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." elteleportált a(z) " .. vehicleID .. " azonosítóval rendelkező járműhöz.")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." elteleportált a(z) " .. vehicleID .. " azonosítóval rendelkező járműhöz.")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("gotoveh", gotoVehicle, "Járműhöz teleportálás")

function repairVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				fixVehicle(theVehicle)
				setVehicleDamageProof(theVehicle, false)
				outputInfoText("Sikeresen megszerelted a járművet", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." megszerelte a(z) " .. vehicleID .. " azonosítóval rendelkező járművet.")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." megszerelte a(z) " .. vehicleID .. " azonosítóval rendelkező járműhöz.")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("fixveh", repairVehicle, "Jármű megjavítása")

function respawnTheVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				respawnVehicle(theVehicle)
				outputInfoText("A helyére teleportáltad a járművet", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." helyére rakta a(z) " .. vehicleID .. " azonosítóval rendelkező járművet.")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." helyére rakta a(z) " .. vehicleID .. " azonosítóval rendelkező járműhöz.")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("respawnveh", respawnTheVehicle, "Jármű helyére teleportálása")

function setVehicleFuel(thePlayer, commandName, vehicleID, fuelLevel)
	if hasPermission(commandName, thePlayer, true) then
		fuelLevel = tonumber(fuelLevel)
		if not vehicleID or not fuelLevel or (fuelLevel > 100 or fuelLevel < 0) then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				setElementData(theVehicle, "vehicle.fuel", fuelLevel)
				outputInfoText("Beállítottad a jármű üzemanyag szintjét a következőre: " .. fuelLevel, thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." beállította a(z) " .. vehicleID .. " azonosítóval rendelkező járműnek az üzemanyag szintjét: " .. fuelLevel .. ".")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." beállította a(z) " .. vehicleID .. " azonosítóval rendelkező járműnek az üzemanyag szintjét: " .. fuelLevel .. ".")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("setvehfuel", setVehicleFuel, "Jármű üzemanyag szintjének beállítása")

function unflipVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				local vRX, vRY, vRZ = getElementRotation(theVehicle)
				setElementRotation(theVehicle, 0, 0, vRZ)
				outputInfoText("Visszaforgattad a járművet", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." visszaforgatta a(z) " .. vehicleID .. " azonosítóval rendelkező járművet")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." visszaforgatta a(z) " .. vehicleID .. " azonosítóval rendelkező járművet")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("unflipveh", unflipVehicle, "Jármű visszafordítása")

function delVehicle(thePlayer, commandName, vehicleID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				exports["sarp_vehicles"]:deleteVehicle(tonumber(vehicleID))
				outputInfoText("Kitörölted a járművet", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." kitörölte a(z) " .. vehicleID .. " azonosítóval rendelkező járművet")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." kitörölte a(z) " .. vehicleID .. " azonosítóval rendelkező járművet")
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("delveh", delVehicle, "Jármű törlése")
--makeVehicle(model, owner, faction, position, colorR, colorG, colorB)
--makeVehicle(598, player, 0, {px, py, pz, 0, 0, 110, 0, 0}, 255, 255, 255)
function makeVehicle(thePlayer, commandName, modelID, owner, faction, colorR, colorG, colorB)
	if hasPermission(commandName, thePlayer, true) then
		if not modelID or not faction or not colorR or not colorG or not colorB then
			outputUsageText(commandName, thePlayer)
			outputInfoText("Frakció: 0 esetén nem frakció jármű", thePlayer)
		else

			local vehModel = tonumber(modelID)
			if type(getVehicleModelFromName(modelID)) == "number" then
				vehModel = getVehicleModelFromName(modelID)
			end

			--local owner = tonumber(owner)
			local faction = tonumber(faction)
			local colorR, colorG, colorB = tonumber(colorR), tonumber(colorG), tonumber(colorB)

			if vehModel > 611 or vehModel < 400 then
				outputErrorText("A Jármű Model ID nem lehet nagyobb 611-nél, nem lehet kisebb 400-nál", thePlayer)
				return
			end

			if (colorR > 255 or colorR < 0) or (colorG > 255 or colorR < 0) or (colorB > 255 or colorB < 0) then
				outputErrorText("Az R, G, B színkód 0-nál nem lehet kisebb, 255-nél nem lehet nagyobb", thePlayer)
				return
			end

			local vehOwner = exports.sarp_core:findPlayer(thePlayer, owner)
			if vehOwner then

				local r = getPedRotation(thePlayer)
				local x, y, z = getElementPosition(thePlayer)
				x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
				y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )

				
				if exports.sarp_vehicles:makeVehicle(vehModel, vehOwner, faction, {x, y, z, 0, 0, r, getElementInterior(thePlayer), getElementDimension(thePlayer)}, colorR, colorG, colorB) then
					outputInfoText("A jármű létrehozva!", thePlayer)
				end
			else
				outputErrorText("Nem található játékos!", thePlayer)
			end
		end
	end
end
addAdminCommand("makeveh", makeVehicle, "Jármű létrehozása")



function toggleVehStats(thePlayer, cmd)
	if hasPermission(cmd, thePlayer, true) then
		triggerClientEvent(thePlayer, "sarp_vehiclesC:toggleVehicleStats", thePlayer)
	end
end
addAdminCommand("dl", toggleVehStats, "Jármű adatok megjelenítése")

function blowUpVehicle(thePlayer, commandName, vehicleID, explode)
	print(tostring(thePlayer) .. " " .. commandName)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then
				outputInfoText("Felrobbantottad a járművet ", thePlayer)
				exports.sarp_core:sendMessageToAdmins(getPlayerName(thePlayer) .." felrobbantotta a(z) " .. vehicleID .. " azonosítóval rendelkező járművet.")
				logs:toLog("adminaction", getPlayerName(thePlayer, true) .." felrobbantotta a(z) " .. vehicleID .. " azonosítóval rendelkező járművet.")
				blowVehicle(theVehicle)
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("blowveh", blowUpVehicle, "Jármű felrobbantása")

function vehSetColor(thePlayer, commandName, vehicleID, colorR, colorG, colorB)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID or not colorR or not colorG or not colorB then
			outputUsageText(commandName, thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then

				local colorR, colorG, colorB = tonumber(colorR), tonumber(colorG), tonumber(colorB)
				if (colorR > 255 or colorR < 0) or (colorG > 255 or colorR < 0) or (colorB > 255 or colorB < 0) then
					outputErrorText("Az R, G, B színkód 0-nál nem lehet kisebb, 255-nél nem lehet nagyobb", thePlayer)
					return
				end

				setVehicleColor(theVehicle, colorR, colorG, colorB, colorR, colorG, colorB, colorR, colorG, colorB)
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("setvehcolor", vehSetColor, "Jármű átfestése")

function vehSetPaintjob(thePlayer, commandName, vehicleID, paintjobID)
	if hasPermission(commandName, thePlayer, true) then
		if not vehicleID or not paintjobID then
			outputUsageText(commandName, thePlayer)
			outputInfoText("Paintjob ID: 0 az eltávolításhoz", thePlayer)
		else
			local theVehicle = exports["sarp_core"]:findVehicleByID(tonumber(vehicleID))
			if theVehicle then

				setElementData(theVehicle, "vehicle.paintjob", tonumber(paintjobID))
			else
				outputErrorText("Nem található jármű ezzel az ID-vel", thePlayer)
			end
		end
	end
end
addAdminCommand("setvehpaintjob", vehSetPaintjob, "Jármű paintjob megváltoztatása")

addEvent("requestAdminCommands", true)
addEventHandler("requestAdminCommands", getRootElement(),
    function ()
        triggerClientEvent(source, "receiveAdminCommands", source, adminCommands)
    end
)

function resourceAction(resourceName, theAction)
	if resourceName and theAction then
		local theResource = getResourceFromName(resourceName)

		if theResource then
			if theAction == "restart" then
				restartResource(theResource)
			elseif theAction == "start" then
				startResource(theResource)
			elseif theAction == "stop" then
				stopResource(theResource)
			end
		end
	end
end

function getResourceInfo(resource)
	local startTime = getResourceLastStartTime(resource)
	local loadTime = getResourceLoadTime(resource)

	if startTime == "never" then
		startTime = "Még nem volt elindítva"
	else
		startTime = getRealTime(startTime)
		startTime = string.format("%04d/%02d/%02d - %02d:%02d:%02d", startTime.year + 1900, startTime.month + 1, startTime.monthday, startTime.hour, startTime.minute, startTime.second)
	end

	if loadTime == "never" then
		loadTime = "Még nem volt betöltve"
	else
		loadTime = getRealTime(loadTime)
		loadTime = string.format("%04d/%02d/%02d - %02d:%02d:%02d", loadTime.year + 1900, loadTime.month + 1, loadTime.monthday, loadTime.hour, loadTime.minute, loadTime.second)
	end

	return {
		state = getResourceState(resource),
		failureReason = getResourceLoadFailureReason(resource),
		startTime = startTime,
		loadTime = loadTime
	}
end

function getResourceList()
	local availableResources = getResources()
	local listChunk = {}
	local stateChunk = {}
	local infoChunk = {}

	local sortedResources = {}

	for k = #availableResources, 1, -1 do
		local v = availableResources[k]

		if v then
			local resourceName = getResourceName(v)

			if string.find(resourceName, "sarp_") then
				table.insert(sortedResources, 1, v)
			else
				table.insert(sortedResources, v)
			end
		end
	end

	for k = 1, #sortedResources do
		local v = sortedResources[k]

		if v then
			local resourceName = getResourceName(v)
			local resourceState = getResourceState(v)

			table.insert(listChunk, resourceName)
			table.insert(stateChunk, resourceState)
			table.insert(infoChunk, getResourceInfo(v))
		end
	end

	return listChunk, stateChunk, infoChunk, #availableResources
end

function restartAllRes()
	restartResource(getResourceFromName("sarp_modstarter"))
end