--===================[MAIN FUNCTIONS, VARIABLES]===================--
local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
                loadAllATM()
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

loadedATMs = {}

function createATM(position)
    assert(type(position) == "table", "Bad argument @ 'createNPC' [expected table at argument 1, got "..type(position) .. "]")

    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)

            local atm = createObject(2942, position[1], position[2], position[3] - 0.35, 0, 0, position[4])

            if isElement(atm) then
                setElementInterior(atm, position[5])
                setElementDimension(atm, position[6])
                setElementFrozen(atm, true)
                setElementData(atm, "atm.id", lastID)
                loadedATMs[lastID] = atm
                
            end
        end, connection, "INSERT INTO atm (position) VALUES (?)", toJSON(position)
    )
end

function deleteATM(id)
    assert(type(id) == "number", "Bad argument @ 'deleteNPC' [expected number at argument 1, got "..type(id) .. "]")

    if loadedATMs[id] then
        if dbExec(connection, "DELETE FROM atm WHERE id = ?", id) then
            destroyElement(loadedATMs[id])
            return true
        end
    end

    return false
end

function loadAllATM()
    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)
            
            for k, v in pairs(result) do
                local position = fromJSON(v["position"])
                local atm = createObject(2942, position[1], position[2], position[3] - 0.35, 0, 0, position[4])
                
                if isElement(atm) then
                    setElementInterior(atm, position[5])
                    setElementDimension(atm, position[6])
                    setElementFrozen(atm, true)
                    setElementData(atm, "atm.id", lastID)
                    loadedATMs[lastID] = atm
                end
            end
        end, connection, "SELECT * FROM atm"
    )
end

