local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
            end
        end

        for k, player in pairs(getElementsByType("player")) do
            if getElementData(player, "char.arrested") then
                local info = getElementData(player, "char.arrested")
                loadPlayerJail(player, info)
            end
        end

    end
)

function registerEvent(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end



local arrestedPlayers = {}

addEvent("movePlayerBackToJail", true) -- ha meghal az úr és börtönben van akkor ez az event fut le!
addEventHandler("movePlayerBackToJail", getRootElement(),
    function ()
        if isElement(source) then
            local accountId = getElementData(source, "acc.dbID")

            if accountId then
                local interior = getElementInterior(source)
                local dim = getElementDimension(source)
                local cellId = math.random(#cells[dim])

                if getElementHealth(source) == 0 or isPedDead(source) then
                    local playerSkin = getElementModel(source)

                    spawnPlayer(source, cells[dim][cellId][1], cells[dim][cellId][2], cells[dim][cellId][3], cells[dim][cellId][4], playerSkin, interior, accountId + math.random(100))
                else
                    removePedFromVehicle(source)
                    setElementPosition(source, cells[dim][cellId][1], cells[dim][cellId][2], cells[dim][cellId][3])
                    setElementRotation(source, cells[dim][cellId][4])
                    setElementInterior(source, interior)
                    setElementDimension(source, accountId + math.random(1, 100))
                end

                setCameraTarget(source, source)
            end
        end
    end
)

function arrestPlayer(id, reason, time, bail, bailPrice)
    local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(source, id)
    if exports.sarp_core:inDistance3D(source, targetPlayer, 5) then
        dropPlayerToTheCell(targetPlayer, time, reason, bail, bailPrice, getPlayerName(source):gsub("_", " "))
    else
        exports.sarp_alert:showAlert(source, "error", "A játékos nincs a közeledben")
    end
end
addEvent("sarp_arrestS:arrestPlayer", true)
addEventHandler("sarp_arrestS:arrestPlayer", root, arrestPlayer)

function dropPlayerToTheCell(player, time, reason, bail, bailPrice, arrestedBy)
    local arrestText = time .. "/" .. reason .. "/" .. tostring(bail) .. "/" .. bailPrice .. "/" .. arrestedBy
    arrestedPlayers[player] = {
        ["timer"] = setTimer(unjailPlayer, time * 60000, 1, player),
        ["time"] = time,
        ["reason"] = reason,
        ["bail"] = {bail, bailPrice},
        ["arrestedBy"] = arrestedBy,
    }


    local dim = getElementDimension(player)
    if not cells[dim] then
        dim = defaultCells
    end
    local int = getElementInterior(player)
    if int == 0 then
        int = defaultInt
    end
    local rnd = math.random(1, #cells[dim])

    setElementPosition(player, cells[dim][rnd][1], cells[dim][rnd][2], cells[dim][rnd][3])
    setElementRotation(player, 0, 0, cells[dim][rnd][4])
    setElementDimension(player, dim)
    setElementInterior(player, int)
    setElementData(player, "char.arrested", arrestText)
    removePedFromVehicle(player)
    print(cells[dim][rnd][1] .. " " .. cells[dim][rnd][2] .. " " .. cells[dim][rnd][3] .. " " .. dim .. " " .. int)

    dbExec(connection, "UPDATE characters SET jailed = ? WHERE charID = ?", arrestText, getElementData(player, "char.ID"))
end

function unjailPlayer(player, adminForce)
    if arrestedPlayers[player] then
        local v = arrestedPlayers[player]
        if isTimer(v["timer"]) then
            killTimer(v["timer"])
        end

        outputInfoText("Kiengedtek a börtönből.", player)
        local dim = getElementDimension(player)
        setElementPosition(player, releasePoints[dim][1], releasePoints[dim][2], releasePoints[dim][3])
        setElementRotation(player, 0, 0, releasePoints[dim][4])
        setElementDimension(player, 0)
        setElementInterior(player, 0)
        setElementData(player, "char.arrested", false)
        removeElementData(player, "char.arrested", false)
        dbExec(connection, "UPDATE characters SET jailed = NULL WHERE charID = ?", getElementData(player, "char.ID"))

        arrestedPlayers[player] = nil

        return true
    end
    return false
end

function updateArrestInfo(player)
    if getElementData(player, "loggedIn") then
        if arrestedPlayers[player] then
            local v = arrestedPlayers[player]
            local lastTime = v["time"]
            if isTimer(v["timer"]) then
                lastTime = getTimerDetails(v["timer"])
            end

            local arrestText = math.ceil(lastTime / 60000) .. "/" .. v["reason"] .. "/" .. tostring(v["bail"][1]) .. "/" .. v["bail"][2] .. "/" .. v["arrestedBy"] 
            setElementData(player, "char.arrested", arrestText)
            dbExec(connection, "UPDATE characters SET jailed = ? WHERE charID = ?", arrestText, getElementData(player, "char.ID"))
        end
    end
end
addCommandHandler("updatearrestinfo", updateArrestInfo)

function loadPlayerJail(player, info)
    if info then
        local info = split(info, "/")
        if info and #info >= 5 then
            --local arrestText = time .. "/" .. reason .. "/" .. tostring(bail) .. "/" .. bailPrice .. "/" .. getPlayerName(arrestedBy):gsub("_", " ")
            --dropPlayerToTheCell(player, time, reason, bail, bailPrice, arrestedBy)
            dropPlayerToTheCell(player, info[1], info[2], info[3], info[4], info[5])
        end
    end
end

addEventHandler("onPlayerQuit", root, function()
    if arrestedPlayers[source] then
        updateArrestInfo(source)
    end
end)

addCommandHandler("release", function(player, cmd, targetPlayer)
    if not exports.sarp_groups:isPlayerHavePermission(player, "jail") then
        exports.sarp_alert:showAlert(player, "error", "Nincs engedélyed a parancs használatához")
        return
    end

    if not targetPlayer then
        outputUsageText("/" .. cmd .. " [Játékos ID]", player)
    else
        local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(player, targetPlayer)
        if arrestedPlayers[targetPlayer] then
            unjailPlayer(targetPlayer)
            outputInfoText(getPlayerName(player):gsub("_", " ") .. " kiengedett a börtönből.", targetPlayer)
        else
            exports.sarp_alert:showAlert(player, "error", "Nincs a játékos börtönben")
        end
    end
end)


outputErrorText = function(text, element)
	triggerClientEvent(element, "playClientSound", element, ":sarp_assets/audio/admin/error.ogg")
	assert(type(text) == "string", "Bad argument @ 'outputErrorText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("error") .. text, element, 0, 0, 0, true)
end

outputInfoText = function(text, element)
	assert(type(text) == "string", "Bad argument @ 'outputInfoText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("info") .. text, element, 0, 0, 0, true)
end

outputUsageText = function(text, element)
	assert(type(text) == "string", "Bad argument @ 'outputInfoText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("usage") .. text, element, 0, 0, 0, true)
end