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

local dogSkin = 9
local followDistance = 2
local dogs = {}

function loadCharacterDogs(element)
	dbQuery(
		function (qh)
			local result = dbPoll(qh, 0)
			if result then
				local characterDogs = {}

				for i = 1, #result do
					characterDogs[i] = {}
					characterDogs[i]["id"] = result[i]["id"]
					characterDogs[i]["name"] = result[i]["name"]
					characterDogs[i]["type"] = result[i]["type"]
					characterDogs[i]["alive"] = result[i]["alive"]
					characterDogs[i]["owner"] = result[i]["owner"]
					characterDogs[i]["qualification"] = result[i]["qualification"]
				end

				setElementData(element, "dogs", characterDogs)
			end
		end, connection, "SELECT * FROM dogs WHERE owner = ?", getElementData(element, "char.ID")
	)
end

function insertNewDog(owner, name, type)
	if name and owner and type and isElement(owner) then
		local qualification = {}
		local qualification = toJSON(qualification)

		dbQuery(
			function (qh)
				local result, num_affected_rows, last_insert_id = dbPoll(qh, 0)

				outputDebugString("Kutya beszúrva az adatbázisba: " .. last_insert_id)
			end, connection, "INSERT INTO dogs (name, owner, qualification, type) VALUES(?, ?, ?, ?)", name, getElementData(owner, "char.ID"), qualification, type
		)
	end
end


function spawnDog(owner, id)
	if id and owner and isElement(owner) then
		local dogDataTable = getElementData(owner, "dogs") 
		id = tonumber(id)
		local ox, oy, oz = getElementPosition(owner)
		dogs[owner] = createPed(9, ox + 2, oy, oz)
		if exports.npc_hlc:enableHLCForNPC(dogs[owner]) then
			setElementData(dogs[owner], "dog.id", dogDataTable[id]["id"])
			setElementData(dogs[owner], "dog.name", dogDataTable[id]["name"])
			setElementData(dogs[owner], "dog.type", dogDataTable[id]["type"])
			setElementModel(dogs[owner], dogDataTable[id]["type"])
			setElementData(dogs[owner], "dog.alive", dogDataTable[id]["alive"])
			setElementData(dogs[owner], "dog.owner", dogDataTable[id]["owner"])
			setElementData(dogs[owner], "dog.qualification", dogDataTable[id]["qualification"])
			followTarget(dogs[owner], owner)

			triggerClientEvent(owner, "fillClientDogTable", owner, dogs)
		end
	end
end

function despawnDog(owner)
	local dog = isDogSpawned(owner)
	if dog then
		destroyElement(dog)
		dogs[owner] = nil
		triggerClientEvent(owner, "fillClientDogTable", owner, dogs)
	end
end

function followTarget(dog, target)
	if dog and target then
		local task = {"walkFollowElement", target, followDistance}
		exports.npc_hlc:setNPCTask(dog, task)
		setPedAnimation(dog, false)
	end
end
addEvent("followTarget", true)
addEventHandler("followTarget", root, followTarget)

function attackTarget(dog, target)
	if dog and target then
		local task = {"killPed", target, 1, followDistance}
		setPedAnimation(dog, false)
		exports.npc_hlc:setNPCTask(dog, {"killPed", target, 1, followDistance})
		--if exports.npc_hlc:onNPCTaskDone(task) then
			-- Nem tudom még, nem válaszol
		--end
	end
end
addEvent("attackTarget", true)
addEventHandler("attackTarget", root, attackTarget)

function stayHere(dog)
	if dog then
		
		exports.npc_hlc:clearNPCTasks(dog)
	end
end
addEvent("stayHere", true)
addEventHandler("stayHere", root, stayHere)

function dogLie(dog)
	if dog then
		exports.npc_hlc:clearNPCTasks(dog)
		setTimer(function()
			setPedAnimation(dog, "FOOD", "FF_Sit_Look", -1, true)
		end, 500, 1)
	end
end
addEvent("dogLie", true)
addEventHandler("dogLie", root, dogLie)

function sendLocalDogAction(element, type, message)
	if not isElement(element) then
		return
	end

	if type == "me" then
		exports.global:sendLocalText(element, " ***(Állat) " ..  string.gsub(getElementData(element, "dog.name"), "_", " ").. ( message:sub( 1, 1 ) == "'" and "" or " " ) .. message, 194, 162, 218)
	elseif type == "do" then
		exports.global:sendLocalText(element, " *(Állat) " .. message .. "* ((" .. getElementData(element, "dog.name"):gsub("_", " ") .. "))", 255, 51, 102)
	end
end
addEvent("sendLocalDogAction", true)
addEventHandler("sendLocalDogAction", root, sendLocalDogAction)

function getAllDogs()
	return dogs or false
end

function getCurrentDogSkin()
	return dogSkin
end

function dogCommands(player, cmd, arg, id)
	if not arg then
		outputChatBox("/" .. cmd .. " [keress|jarmu]", source, 0, 0, 0, true)
		return
	end


	if arg == "keress" then
		if target then
			local target, targetName = exports.global:findPlayerByPartialNick(player, id)
			--dogSmellingItem(getElementData)
		end
	elseif arg == "jarmu" then
		if dogs[player] and isElement(dogs[player]) then
			if isPedInVehicle(player) then
				local veh = getPedOccupiedVehicle(player)
				warpPedIntoVehicle(dogs[player], veh, 1)   
			end
		end
	end
end
addCommandHandler("kutya", dogCommands)

function adebug(source, cmd, id)
	loadCharacterDogs(source)
	--createNewDog(source, id)
end
addCommandHandler("cdog", adebug)

function isDogSpawned(player)
	if player and isElement(player) then
		if dogs[player] then
			return dogs[player]
		end
	end

	return false
end

addEventHandler("onVehicleEnter", root, function(player, seat)
	if isElement(dogs[player]) then
		local occupants = getVehicleOccupants(source)
		local freeSeats = {}
		for k, v in pairs(occupants) do
			freeSeats[k] = true
		end

		for k = 0, 4 do
			if not freeSeats[k] then
				warpPedIntoVehicle(dogs[player], source, k)
				--outputChatBox(k .. " helyre beültettem a kutyát")
				break
			end
		end
	end
end)

addEventHandler("onVehicleExit", root, function(player)
	if isElement(dogs[player]) then
		removePedFromVehicle(dogs[player])
		local vehX, vehY, vehZ = getElementPosition(source)
		setElementPosition(dogs[player], vehX + 2, vehY, vehZ, true)
		--outputChatBox("A kutya kiszállítva")
	end
end)
