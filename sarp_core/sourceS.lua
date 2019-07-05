local maxPlayers = tonumber(getServerConfigSetting("maxplayers"))
local disallowedIdNumbers = {}

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		setMapName("San Andreas")
		setGameType("SA-RP")
		setMaxPlayers(maxPlayers)
		setElementData(resourceRoot, "server.maxPlayers", maxPlayers)

		local players = getElementsByType("player")

		for k = 1, #players do
			local v = players[k]

			if isElement(v) then
				disallowedIdNumbers[k] = v
				setElementData(v, "playerID", k)
				setPlayerNametagShowing(v, false)
			end
		end
	end
)

addEventHandler("onPlayerJoin", getRootElement(),
	function ()
		local freeID = false

		for i = 1, maxPlayers do
			if not disallowedIdNumbers[i] then
				freeID = i
				break
			end
		end

		if freeID and isElement(source) then
			disallowedIdNumbers[freeID] = source
			setElementData(source, "playerID", freeID)
			setPlayerNametagShowing(source, false)
		end
	end
)

addEventHandler("onPlayerQuit", getRootElement(),
	function ()
		local playerID = getElementData(source, "playerID")

		if playerID then
			disallowedIdNumbers[playerID] = nil
		end
	end
)

function sendMessageToAdmins(message, lvl)
	lvl = lvl or 1

	local players = getElementsByType("player")

	for k = 1, #players do
		local v = players[k]

		if isElement(v) then
			local adminLevel = getElementData(v, "acc.adminLevel") or 0

			if adminLevel ~= 0 and adminLevel >= lvl then
				outputChatBox("#d75959>> Adminisztráció: #ffffff" .. tostring(message), v, 255, 255, 255, true)
			end
		end
	end
end

function outputErrorText(text, element)
	if text and isElement(element) then
		outputChatBox("#dc143c>> SARP: #ffffff" .. text, element, 0, 0, 0, true)

		triggerClientEvent(element, "playClientSound", element, ":sarp_assets/audio/admin/error.ogg")
	end
end

function outputInfoText(text, element)
	if text and isElement(element) then
		outputChatBox("#4aabd0>> SARP: #ffffff" .. text, element, 0, 0, 0, true)
	end
end

addCommandHandler("id",
	function (sourcePlayer, commandName, targetPlayer)
		if not targetPlayer then
			outputChatBox("#32b3ef>> Használat: #ffffff/" .. commandName .. " [Játékos név / ID]", sourcePlayer, 0, 0, 0, true)
		else
			local targetPlayer, targetPlayerName = findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				outputChatBox("#ffff99>> #ffa600" .. targetPlayerName .. " #ffffffjátékos azonosítója: #ffff99" .. getElementData(targetPlayer, "playerID"), sourcePlayer, 0, 0, 0, true)
			end
		end
	end
)

addCommandHandler("level",
	function (sourcePlayer, commandName, targetPlayer)
		if not targetPlayer then
			outputChatBox("#32b3ef>> Használat: #ffffff/" .. commandName .. " [Játékos név / ID]", sourcePlayer, 0, 0, 0, true)
		else
			local targetPlayer, targetPlayerName = findPlayer(sourcePlayer, targetPlayer)

			if targetPlayer then
				outputChatBox("#ffff99>> #ffa600" .. targetPlayerName .. " #ffffffjátékos szintje: #ffff99" .. getLevel(targetPlayer), sourcePlayer, 0, 0, 0, true)
			end
		end
	end
)

function playSoundForElement(element, path)
	triggerClientEvent(element, "playClientSound", element, path)
end