
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
    end
)

function givePlayerAchievement(player, achId)
    if player or isElement(player) or achId or not achievements[achId] then
        if not connection then
            return
        end


        if not getElementData(player, "char.ID") then
            return
        end
        if hasPlayerAchievement(player, achId) then
            --outputDebugString("Nem adtam oda a " .. achId .. " azonosítójú teljesítményt")
            return
        end

       
        local queryHandler = dbExec ( connection, "INSERT INTO achievements (achievementid, characterid) VALUES (?,?)", achId, getElementData ( player, "char.ID" ) )
        local playerAchievements = getElementData(player, "achievements") or {}
        if playerAchievements then
            local achievementName = achievements[achId][1]
            local achievementImage = achievements[achId][2]
            local achievementExp = achievements[achId][3]
            local achievementDesc = achievements[achId][4]

            table.insert(playerAchievements, {achievementName, achievementImage, achievementExp, achievementDesc, achId})
			
            setElementData(player, "achievements", playerAchievements)
            givePlayerXP(player, achievements[achId][3])
            triggerClientEvent(player, "showAchivementPanel", player, achId)
            loadPlayerAchievements(player)
        end
    end
end

function hasPlayerAchievement(player, achId)
    if player and isElement(player) then
        local playerAchievements = getElementData(player, "achievements") or {}
       
	    local achivementFound = false
        for i = 1, #playerAchievements do
			if playerAchievements[i] and tonumber(playerAchievements[i][5]) == tonumber(achId) then
				achivementFound = true
				break
			end
		end
		
		if achivementFound then
			--outputDebugString("A " .. getPlayerName(player) .. "-nek már megvan ez a teljesítmény")
        else
			--outputDebugString("A " .. getPlayerName(player) .. "-nek nincs meg ez a teljesítmény")
        end
		
		return achivementFound
    end
end

function loadPlayerAchievements(player)
    --outputDebugString("Meghívás: LoadPlayerAchievements")
    if player and isElement(player) then
        if not connection then
            return
        end

        if not getElementData(player, "char.ID") then
            return
        end

        local queryHandler = dbQuery(connection, "SELECT * FROM achievements WHERE characterid = ?", getElementData(player, "char.ID"))
        if queryHandler then
            local result, rows, lastid = dbPoll(queryHandler, -1)

            if result == false then
                return
            end

            local playerAchievements = {}
            --outputDebugString(getPlayerName(player) .. " achievementjei: " .. rows)
            for k, v in ipairs(result) do
                local achievementID = v["achievementid"]
                local achievementName = achievements[achievementID][1]
                local achievementImage = achievements[achievementID][2]
                local achievementExp = achievements[achievementID][3]
                local achievementDesc = achievements[achievementID][4]

                table.insert(playerAchievements, {achievementName, achievementImage, achievementExp, achievementDesc, achievementID})
            end
            setElementData(player, "achievements", playerAchievements)

            dbFree(queryHandler)
        end
    end
end


function givePlayerXP(player, value)
    if player and isElement(player) then
        if not value or type(value) ~= "number" then
            return
        end

        if not getElementData(player, "char.ID") then
            return
        end

        local oldXP = getElementData(player, "xp") or 0
        setPlayerXP(player, oldXP + value)

    end
end

function takePlayerXP(player, value)
    if player and isElement(player) then
        if not value or type(value) ~= "number" then
            return
        end

        if not getElementData(player, "char.ID") then
            return
        end

        local oldXP = getElementData(player, "xp") or 0
        setPlayerXP(player, oldXP - value)

    end
end

function setPlayerXP(player, value)
    if player and isElement(player) then
        if not value or type(value) ~= "number" then
            return
        end

        if not getElementData(player, "char.ID") then
            return
        end

        local exec = dbExec(connection, "UPDATE characters SET xp = ? WHERE id = ? ", value, getElementData(player, "char.ID"))
        if exec then
            --outputDebugString(getPlayerName(player) .. " XP-je beállítva " .. value .. " értékre")
            setElementData(player, "xp", value)
        end
    end
end

function getPlayerLevel(player)
    if player and isElement(player) then
        local XP = getElementData(player, "xp") or 0
        local level = 1
        for k, v in ipairs(levels) do
            if v <= XP then
                level = k
            end
        end

        return level
    end
end

function getAllAchievements()
	return achievements
end

addEventHandler("onResourceStart", getResourceRootElement(), function()
    for k, v in ipairs(getElementsByType("player")) do
        if isElement(v) then
            if getElementData(v, "loggedin") == 1 then
                loadPlayerAchievements(v)
            end
        end
    end
end)

addCommandHandler( "rach", function(player)
        givePlayerAchievement(player, math.random(1, #achievements))
end)

addCommandHandler( "allach", function(player)
    for i = 1, #achievements do
        givePlayerAchievement(player, i)
    end
end)