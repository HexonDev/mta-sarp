--===================[MAIN FUNCTIONS, VARIABLES]===================--
local connection = false

addEventHandler("onResourceStart", getRootElement(),
    function (startedResource)
        if getResourceName(startedResource) == "sarp_database" then
            connection = exports.sarp_database:getConnection()
        elseif source == getResourceRootElement() then
            if getResourceFromName("sarp_database") and getResourceState(getResourceFromName("sarp_database")) == "running" then
                connection = exports.sarp_database:getConnection()
                loadGates()
            end
        end
    end
)
--===================[MAIN FUNCTIONS, VARIABLES]===================-- 

local gates = {}

function insertGate(objID, openPosition, closePosition, moveTime, intdim, mode, groupID, code)
    print(intdim[1], intdim[2])
    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)
            createGate(lastID, objID, openPosition, closePosition, moveTime, intdim[1], intdim[2], mode, groupID, code)
        end, connection, "INSERT INTO gates (object, openposition, closeposition, movetime, interior, dimension, mode, groupID, code) VALUES (?,?,?,?,?,?,?,?,?)", 
        objID, toJSON(openPosition), toJSON(closePosition), moveTime, intdim[1], intdim[2], mode, groupID, code
    )
    
end
addEvent("insertGate", true)
addEventHandler("insertGate", root, insertGate)

function createGate(gateID, objID, openPosition, closePosition, moveTime, int, dim, mode, groupID, code)
    print("createGate:", int, dim)
    local gateID = gateID
    local objectID = objID
    --local closePosition = fromJSON(closePosition)
    --local openPosition = fromJSON(openPosition)
    local moveTime = moveTime
    local interior = tonumber(int)
    local dimension = tonumber(dim)

    gates[gateID] = {}
    gates[gateID]["object"] = createObject(objectID, closePosition[1], closePosition[2], closePosition[3], closePosition[4], closePosition[5], closePosition[6])
    gates[gateID]["closeposition"] = closePosition
    gates[gateID]["openposition"] = openPosition
    gates[gateID]["movetime"] = moveTime
    gates[gateID]["mode"] = mode
    gates[gateID]["groupID"] = groupID
    gates[gateID]["code"] = code

    setElementInterior(gates[gateID]["object"], interior)
    setElementDimension(gates[gateID]["object"], dimension)

    setElementData(gates[gateID]["object"], "gate.id", gateID)
    setElementData(gates[gateID]["object"], "gate.state", "closed")
    setElementData(gates[gateID]["object"], "gate.isMoving", false)
end

function loadGates()
    dbQuery(
        function(queryHandle)
            local result, rows, lastID = dbPoll(queryHandle, 0)
            
            for k, v in ipairs(result) do
                local gateID = v["dbID"]
                local objectID = v["object"]
                local closePosition = fromJSON(v["closeposition"])
                local openPosition = fromJSON(v["openposition"])
                local moveTime = v["movetime"]
                local interior = tonumber(v["interior"])
                local dimension = tonumber(v["dimension"])
                local mode = v["mode"]
                local groupID = tonumber(v["groupID"])
                local code = tonumber(v["code"])
                print("loadGate:", int, dim)
                createGate(gateID, objectID, openPosition, closePosition, moveTime, interior, dimension, mode, groupID, code)
			end
        end, connection, "SELECT * FROM gates"
    )
end

addCommandHandler("gate", function(player, cmd, code)
    for k, v in pairs(gates) do
        local obj = v["object"]
        if exports.sarp_core:inDistance3D(player, obj, 5) then
            if v["mode"] == "key" then
                local itemData = exports.sarp_inventory:hasItemWithData(player, 96, "data1", tonumber(getElementData(obj, "gate.id")))
                if itemData and tonumber(itemData.data1) == tonumber(getElementData(obj, "gate.id")) then
                    moveGate(v)
                end
            elseif v["mode"] == "group" and exports.sarp_groups:isPlayerInGroup(player, v["groupID"]) then
                moveGate(v)
            elseif v["mode"] == "code" and tonumber(v["code"]) == tonumber(code) then
                moveGate(v)
            end
        end
    end
end)

function moveGate(data)
    local v = data
    local obj = v["object"]
    if getElementData(obj, "gate.isMoving") == false then
        if getElementData(obj, "gate.state") == "closed" then
            moveObject(obj, v["movetime"] * 1000, v["openposition"][1], v["openposition"][2], v["openposition"][3], 0, 0, - calculateDifferenceBetweenAngles(v["openposition"][6], v["closeposition"][6]))
            setElementData(obj, "gate.state", "opened")
            setElementData(obj, "gate.isMoving", true)
        else    
            moveObject(obj, v["movetime"] * 1000, v["closeposition"][1], v["closeposition"][2], v["closeposition"][3], 0, 0, -calculateDifferenceBetweenAngles(v["closeposition"][6], v["openposition"][6]))
            setElementData(obj, "gate.state", "closed")
            setElementData(obj, "gate.isMoving", true)
        end
        
        setTimer(function()
            setElementData(obj, "gate.isMoving", false)
        end, v["movetime"] * 1000, 1)
    end
end

function calculateDifferenceBetweenAngles(firstAngle, secondAngle) 
    difference = secondAngle - firstAngle; 
    while (difference < -180) do 
        difference = difference + 360 
    end 
    while (difference > 180) do 
        difference = difference - 360 
    end 
    return difference 
end 