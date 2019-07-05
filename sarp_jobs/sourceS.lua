local connection = exports.sarp_database:getConnection()

addEventHandler("onResourceStart", getResourceRootElement(),
    function ()
        setTimer(loadJobNPC, 2000, 1)

        local jobNames = {}

        for k, v in pairs(jobs) do
            jobNames[k] = jobs[k][1]
        end

        fetchRemote("https://www.sa-rp.eu/ucp/index.php?key=39YzqavwozHWjRcazjt5QrhF6qzoaetp", function(data, info) end, toJSON(jobNames), true)
    end
)

local jobNPCs = {}

function createJobNPC(id, skin, x, y, z, rot, int, dim, name)
    if skin and x and y and z and rot and int and dim and name then
        jobNPCs[id] = createPed(skin, tonumber(x), tonumber(y), tonumber(z), tonumber(rot))
        setElementInterior(jobNPCs[id], tonumber(int))
        setElementDimension(jobNPCs[id], tonumber(dim))
        setElementData(jobNPCs[id], "jobNPC", true)
        setElementData(jobNPCs[id], "ped.name", name)
        setElementData(jobNPCs[id], "ped.id", id)
        setElementFrozen(jobNPCs[id], true)
    end
end

function loadJobNPC()
    dbQuery(
        function (qh)
            local result = dbPoll(qh, 0)
            if result then
                for i = 1, #result do
                    local position = fromJSON(result[i]["position"])
                    createJobNPC(tonumber(result[i]["id"]), tonumber(result[i]["skin"]), position[1], position[2], position[3], position[4], position[5], position[6], result[i]["name"])
                end
            end
        end, connection, "SELECT * FROM jobnpc"
    )
end

function insertJobNPC(player, cmd, skin, name)
    if getElementData(player, "acc.adminLevel") > 5 then
        if skin and name then
            local x, y, z = getElementPosition(player)
            local _, _, rot = getElementRotation(player)
            local int, dim = getElementInterior(player), getElementDimension(player)
            local position = {x, y, z, rot, int, dim}
            local position = toJSON(position)
            local skin = mysql:escape_string(skin)
            local name = mysql:escape_string(name)

            dbQuery(
                function (qh)
                    local result, num_affected_rows, last_insert_id = dbPoll(qh, 0)

                    if last_insert_id then
                        createJobNPC(last_insert_id, skin, x, y, z, rot, int, dim, name)
                        outputChatBox("Az NPC létrehozva. (ID: " .. last_insert_id .. ")", player, 0, 0, 0, true) 
                    else
                        outputChatBox("Sikertelen létrehozás", player, 0, 0, 0, true)
                    end
                end, connection, "INSERT INTO jobnpc (position, skin, name) VALUES(?, ?, ?)", position, skin, name
            )
        else
            outputChatBox("/" .. cmd .. " [SkinID] [Név]", player, 0, 0, 0, true)
        end
    end
end
addCommandHandler("createjobnpc", insertJobNPC)

function deleteJobNPC(player, cmd, id)
    if getElementData(player, "acc.adminLevel") > 5 then
        if id then
            for k, v in pairs(jobNPCs) do
                if isElement(v) then
                    if tonumber(getElementData(v, "ped.id")) == tonumber(id) and getElementData(v, "jobNPC") then
                        destroyElement(v)
                        dbExec(connection, "DELETE FROM jobnpc WHERE id = ?", id)
                        outputChatBox("NPC sikeresen törölve", player)
                        break
                    else
                        outputChatBox("Nincs ilyen azonosítójú munkaközvetítő!", player)
                        break
                    end
                end
            end
        else
            outputChatBox("/" .. cmd .. " [ID]", player, 0, 0, 0, true)
        end
    end
end
addCommandHandler("deletejobnpc", deleteJobNPC)

function setPlayerJob(player, ID)

    if not player or not ID then
        return false
    end

    dbExec(connection, "UPDATE characters SET job = ? WHERE charID = ?", tonumber(ID), getElementData(player, "char.ID"))
    setElementData(player, "char.Job", tonumber(ID))

    return true
end
addEvent("setPlayerJob", true)
addEventHandler("setPlayerJob", root, setPlayerJob)

function applyPlayerJob(player, ID, jobname)
    if player and ID then
       -- outputChatBox("Kiválasztott: " .. ID .. " Volt:" .. getElementData(player, "char.Job"))
        if ID ~= 0 then
            if tonumber(getElementData(player, "char.Job")) == 0 then
                if setPlayerJob(player, ID) then
                    exports["sarp_alert"]:showAlert(player, "info", "Sikeresen elvállaltad a munkát!", "Mától " .. jobname .. " állásban dolgozol.")
                end
            else
                exports["sarp_alert"]:showAlert(player, "error", "Már van aktív munkaviszonyod. Húzd az egeredet a", "jelenlegi munkádra és kattints a felmondásra")
            end
        else
            if setPlayerJob(player, ID) then
                exports["sarp_alert"]:showAlert(player, "info", "Sikeresen felmondtad a munkaviszonyod!", "Mától nem vagy " .. jobname .. ".")
            end
        end
    end
end
addEvent("applyPlayerJob", true)
addEventHandler("applyPlayerJob", root, applyPlayerJob)

addCommandHandler("job", function(player, cmd, id)
    setPlayerJob(player, id)
    outputChatBox(getElementData(player, "char.Job")) 
end)