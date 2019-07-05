local acmds = {}

connection = false

logs = exports.sarp_logs

protectedSerials = {
	["38637680563E8AF8B85FEDC807B24083"] = true, -- jayceon
	["575B9706754CE444F42A12FEC29BA3A1"] = true, -- hexon
	["A7AFFD556B71B092D01258018AFC2993"] = true, -- marlon
}

function addAdminCommand(command, level, description, forceResourceName)
	if not acmds[command] then
		local resourceName = forceResourceName or "sarp_admin"

		if not forceResourceName and sourceResource then
			resourceName = getResourceName(sourceResource)
		end

		acmds[command] = {level, description, resourceName}
	end
end

addEvent("requestAdminCommands", true)
addEventHandler("requestAdminCommands", getRootElement(),
	function()
		if isElement(source) then
			triggerClientEvent(source, "receiveAdminCommands", source, acmds)
		end
	end)

addEventHandler("onResourceStop", getRootElement(),
	function(stoppedResource)
		if stoppedResource == getThisResource() then
			local array = {}
			local count = 0

			for k, v in pairs(acmds) do
				if v[3] ~= "sarp_admin" then
					array[k] = v
					count = count + 1
				end
			end

			if count > 0 then
				setElementData(getResourceRootElement(getResourceFromName("sarp_modstarter")), "adminCommandsCache", array, false)
			end
		else
			local resname = getResourceName(stoppedResource)

			for k, v in pairs(acmds) do
				if v[3] == resname then
					acmds[k] = nil
				end
			end
		end
	end)

addEventHandler("onResourceStart", getResourceRootElement(),
	function(startedResource)
		connection = exports.sarp_database:getConnection()

		local theRes = getResourceRootElement(getResourceFromName("sarp_modstarter"))

		if theRes then
			local cache = getElementData(theRes, "adminCommandsCache")

			if cache then
				for k, v in pairs(cache) do
					if not acmds[k] then
						addAdminCommand(k, v[1], v[2], v[3])
					end
				end

				removeElementData(theRes, "adminCommandsCache")
			end
		end
	end)



addEventHandler("onPlayerChangeNick", getRootElement(),
	function(oldNick, newNick, changedByUser)
		if changedByUser then
			cancelEvent()
		end
	end)

function outputUsageText(commandName, string, playerSource)
	if isElement(playerSource) then
		outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " " .. string, playerSource, 0, 0, 0, true)
	end
end

function outputErrorText(string, playerSource)
	if isElement(playerSource) then
		outputChatBox(exports.sarp_core:getServerTag("error") .. string, playerSource, 0, 0, 0, true)

		exports.sarp_core:playSoundForElement(playerSource, ":sarp_assets/audio/admin/error.ogg")
	end
end

function outputInfoText(string, playerSource)
	if isElement(playerSource) then
		outputChatBox(exports.sarp_core:getServerTag("info") .. string, playerSource, 0, 0, 0, true)
	end
end

function outputAdminText(string, playerSource)
	if isElement(playerSource) then
		outputChatBox(exports.sarp_core:getServerTag("admin") .. string, playerSource, 0, 0, 0, true)
	end
end

function getPlayerAdminNick(playerSource)
	if isElement(playerSource) then
		return getElementData(playerSource, "acc.adminNick") or "Admin"
	end
end

function getPlayerCharacterName(playerSource)
	if isElement(playerSource) then
		return (getElementData(playerSource, "char.Name"):gsub("_", " "))
	end
end

function getPlayerVisibleName(playerSource)
	if isElement(playerSource) then
		return (getElementData(playerSource, "visibleName"):gsub("_", " "))
	end
end

function havePermission(playerSource, command, forceDuty, helperLevel)
	if isElement(playerSource) then
		if getElementData(playerSource, "acc.adminLevel") >= 9 then
			return true
		end

		if helperLevel and getElementData(playerSource, "acc.helperLevel") >= helperLevel then
			if forceDuty and helperLevel == 2 and not getElementData(playerSource, "helperDuty") then
				outputErrorText("Csak adminsegéd szolgálatban használhatod az adminsegéd parancsokat! (/asduty)", playerSource)
				return false
			end

			return true
		end

		if getElementData(playerSource, "acc.adminLevel") >= acmds[command][1] and getElementData(playerSource, "acc.adminLevel") ~= 0 then
			if forceDuty then
				if not getElementData(playerSource, "adminDuty") then
					outputErrorText("Csak adminszolgálatban használhatod az admin parancsokat!", playerSource)

					return false
				else
					return true
				end
			else
				return true
			end
		end
	end

	return false
end

local dutyTime = {}

addEventHandler("onResourceStop", getRootElement(),
	function(res)
		exports.sarp_core:sendMessageToAdmins("Resource sikeresen leállítva. #d75959(" .. getResourceName(res) .. ")", 8)

		if res == getThisResource() then
			for k, v in pairs(dutyTime) do
				if isElement(k) then
					dbExec(connection, "UPDATE accounts SET adminDutyTime = adminDutyTime + ? WHERE accountID = ?", getTickCount() - v, getElementData(k, "acc.dbID"))
				end
			end
		end
	end)

addEventHandler("onResourceStart", getRootElement(),
	function(res)
		exports.sarp_core:sendMessageToAdmins("Resource sikeresen elindítva. #32b3ef(" .. getResourceName(res) .. ")", 8)
	end)

addEventHandler("onElementDataChange", getRootElement(),
	function(data, oldval, newval)
		if data == "adminDuty" then
			if getElementData(source, "adminDuty") then
				dutyTime[source] = getTickCount()
			elseif dutyTime[source] then
				dbExec(connection, "UPDATE accounts SET adminDutyTime = adminDutyTime + ? WHERE accountID = ?", getTickCount() - dutyTime[source], getElementData(source, "acc.dbID"))
				dutyTime[source] = nil
			end
		end
	end)

addEventHandler("onPlayerQuit", getRootElement(),
	function()
		if dutyTime[source] then
			dbExec(connection, "UPDATE accounts SET adminDutyTime = adminDutyTime + ? WHERE accountID = ?", getTickCount() - dutyTime[source], getElementData(source, "acc.dbID"))
			dutyTime[source] = nil
		end
	end)