
--===================[MAIN FUNCTIONS, VARIABLES]===================--
local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
                loadAllNPC()
            end
        end
    end
)
--===================[MAIN FUNCTIONS, VARIABLES]===================-- 

local logs = exports.sarp_logs
local alert = exports.sarp_alert
local core = exports.sarp_core

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

local loadedNPCs = {}

local pedTypes = {
    [1] = "Munkaügyi NPC", -- 
    [2] = "Banki ügyintéző NPC", -- 
    [3] = "Jármű kereskedő", --
    [4] = "Okmány hivatal",
    [5] = "Vizsgabiztos (Altíptus: 1: elmélet, 2: gyakorlat)", -- Altípus: 1 - Elméleti, 2 - Gyakorlati
    [6] = "Jármű kiadó",
}

function getNPCTypeName(pedType)
    assert(type(pedType) == "number", "Bad argument @ 'getNPCTypeName' [expected number at argument 1, got "..type(pedType) .. "]")
    if pedTypes[pedType] then
        return pedTypes[pedType]
    end
    return "Ismeretlen"
end

function getNPCTypeCount()
    return #pedTypes
end

function getNPCTypes()
    return pedTypes
end

function createNPC(position, skin, name, pedtype, subtype)
    assert(type(position) == "table", "Bad argument @ 'createNPC' [expected table at argument 1, got "..type(position) .. "]")
    assert(type(skin) == "number", "Bad argument @ 'createNPC' [expected number at argument 2, got "..type(skin) .. "]")
    assert(type(name) == "string", "Bad argument @ 'createNPC' [expected string at argument 3, got "..type(name) .. "]")
    assert(type(pedtype) == "number", "Bad argument @ 'createNPC' [expected number at argument 4, got "..type(pedtype) .. "]")
    assert(type(subtype) == "number", "Bad argument @ 'createNPC' [expected number at argument 5, got "..type(subtype) .. "]")

    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)
            
            local ped = createPed(skin, position[1], position[2], position[3], position[4])

            if isElement(ped) then
                setElementInterior(ped, position[5])
                setElementDimension(ped, position[6])
                setElementFrozen(ped, true)
                setElementData(ped, "ped.name", name .. " (" .. lastID .. ")")
                setElementData(ped, "ped.type", tonumber(pedtype))
                setElementData(ped, "ped.subtype", subtype) 
                setElementData(ped, "invulnerable", true)

                loadedNPCs[lastID] = ped
            end
        end, connection, "INSERT INTO npcs (position, skin, name, type, subtype) VALUES (?, ?, ?, ?, ?)", toJSON(position), skin, name, pedtype, subtype
    )
end

function deleteNPC(id)
    assert(type(id) == "number", "Bad argument @ 'deleteNPC' [expected number at argument 1, got "..type(id) .. "]")

    if loadedNPCs[id] then
        if dbExec(connection, "DELETE FROM npcs WHERE id = ?", id) then
            destroyElement(loadedNPCs[id])
            return true
        end
    end

    return false
end

function loadAllNPC()
    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)
            
            for k, v in pairs(result) do
                local position = fromJSON(v["position"])
                local ped = createPed(tonumber(v["skin"]), tonumber(position[1]), tonumber(position[2]), tonumber(position[3]), tonumber(position[4]))
                
                if isElement(ped) then
                    setElementInterior(ped, tonumber(position[5]))
                    setElementDimension(ped, tonumber(position[6]))
                    setElementFrozen(ped, true)
                    setElementData(ped, "ped.name", v["name"] .. " (" .. v["id"] .. ")")
                    setElementData(ped, "ped.type", v["type"])
                    setElementData(ped, "ped.subtype", v["subtype"]) 
                    setElementData(ped, "invulnerable", true)

                    loadedNPCs[v["id"]] = ped
                end
            end
        end, connection, "SELECT * FROM npcs"
    )
end
