--[[

CREATE TABLE IF NOT EXISTS `billiard` (
	`tableId` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	`posX` float NOT NULL,
	`posY` float NOT NULL,
	`posZ` float NOT NULL,
	`rotZ` float NOT NULL,
	`interior` int(11) NOT NULL,
	`dimension` int(11) NOT NULL
);

]]

local connection = false

local poolData = {}

local numberForBalls = {1, 9, 10, 2, 8, 3, 11, 12, 4, 13, 5, 14, 6, 15, 7, 16}

local modelForBalls = {3002, 3100, 3101, 3102, 3103, 3104, 3105, 3106, 2995, 2996, 2997, 2998, 2999, 3000, 3001, 3003}

local offsetForBalls = {
	{-0.37142857142857, 0},
	{-0.44285714285714, -0.035},
	{-0.44285714285714, 0.0375},
	{-0.51428571428571, -0.07},
	{-0.51428571428571, 0},
	{-0.51428571428571, 0.075},
	{-0.58571428571429, -0.1},
	{-0.58571428571429, -0.035},
	{-0.58571428571429, 0.0375},
	{-0.58571428571429, 0.1},
	{-0.65714285714286, -0.15},
	{-0.65714285714286, -0.07},
	{-0.65714285714286, 0},
	{-0.65714285714286, 0.075},
	{-0.65714285714286, 0.15},
	{0.5, 0}
}

local gameFieldPos = {
	0.0083254146575743, 0.013325414657574, -1.1166745853424 * 0.875,
	-0.65667458534243 * 0.79, 1.1333254146576 * 0.875, 0.68332541465757 * 0.79,
	0.47832541465757, 0.013325414657574, 0.94332541465758
}

exports.sarp_admin:addAdminCommand("deletebilliard", 7, "Biliárd asztal törlése")
addCommandHandler("deletebilliard",
	function (player, command, tableId)
		if getElementData(player, "acc.adminLevel") >= 7 then
			if not tonumber(tableId) then
				outputChatBox("#32b3ef>> Használat: #ffffff/" .. command .. " [Id]", player, 255, 255, 255, true)
			else
				tableId = tonumber(tableId)

				if poolData[tableId] then
					triggerClientEvent("syncTheTable", resourceRoot, tableId, true)
					
					if isElement(poolData[tableId].objectElement) then
						destroyElement(poolData[tableId].objectElement)
					end

					poolData[tableId] = nil

					dbExec(connection, "DELETE FROM billiard WHERE tableId = ?", tableId)

					outputChatBox("#32b3ef>> Adminisztráció: #ffffffA kiválasztott biliárd asztal sikeresen #ff4646törlésre került#ffffff.", player, 255, 255, 255, true)
				else
					outputChatBox("#cdcdcd>> Adminisztráció: #ff4646A kiválasztott biliárd asztal nem található!", player, 255, 255, 255, true)
				end
			end
		end
	end
)

function addTableHistory(tableId, data)
	if not poolData[tableId].history then
		poolData[tableId].history = {}
	end

	local actions = {}
	local total = #poolData[tableId].history

	if total > 15 then
		total = 15
	end

	table.insert(actions, data)

	for i = 1, total do
		table.insert(actions, poolData[tableId].history[i])
	end

	poolData[tableId].history = actions
end

addEvent("syncActions", true)
addEventHandler("syncActions", getRootElement(),
	function (tableId, actions)
		if isElement(source) then
			if poolData[tableId] then
				poolData[tableId].history = actions

				triggerClientEvent("syncActions", source, tableId, poolData[tableId].history)
			end
		end
	end
)

addEvent("syncPoolBalls", true)
addEventHandler("syncPoolBalls", getRootElement(),
	function (tableId, curBalls, dropBalls)
		if isElement(source) then
			if poolData[tableId] then
				local inHole = {}
				local newgame = false

				for k, v in ipairs(curBalls) do
					-- lyukban van
					if v[5] then
						-- szerver oldali frissítés
						if not poolData[tableId].balls.curPos[k][6] then
							poolData[tableId].balls.curPos[k][6] = true

							table.insert(inHole, {v[5], v[7]})

							addTableHistory(tableId, v[6])
						end

						-- ha a fekete (8-as) golyó esett le -> játék vége
						if v[7] == 8 then
							newgame = true
						end
					end
				end

				-- új játék, golyók visszahelyezése alapértelmezett pozícióba
				if newgame then
					addTableHistory(tableId, "newgame")

					for k, v in ipairs(curBalls) do
						curBalls[k][1] = poolData[tableId].balls.defPos[k][2]
						curBalls[k][2] = poolData[tableId].balls.defPos[k][3]
						curBalls[k][3] = poolData[tableId].balls.defPos[k][4]
						curBalls[k][4] = false
						curBalls[k][5] = nil
					end

					dropBalls = {}
				else
					addTableHistory(tableId, "roundend")
				end

				-- szerver oldali golyók pozíciójánák frissítése
				for k, v in ipairs(curBalls) do
					poolData[tableId].balls.curPos[k][2] = v[1]
					poolData[tableId].balls.curPos[k][3] = v[2]
					poolData[tableId].balls.curPos[k][4] = v[3]
					poolData[tableId].balls.curPos[k][5] = v[4]
				end

				poolData[tableId].balls.ingame = curBalls
				poolData[tableId].balls.dropped = dropBalls
				
				triggerClientEvent("syncPoolBalls", source, tableId, curBalls, dropBalls, poolData[tableId].history, inHole)
			end
		end
	end
)

addEvent("forceABall", true)
addEventHandler("forceABall", getRootElement(),
	function (tableId, ballId, ballForce, animType)
		if isElement(source) then
			if poolData[tableId] then
				if #poolData[tableId].history == 0 then
					addTableHistory(tableId, "newgame")

					triggerClientEvent("syncActions", source, tableId, poolData[tableId].history)
				end

				setPedAnimation(source, "pool", "pool_" .. animType .. "_shot", 1500, false, false, true, false)
				
				setTimer(
					function(player, tableId, ball, force)
						triggerClientEvent("forceABall", player, tableId, ball, force)

						setPedAnimation(player)
					end,
				500, 1, source, tableId, ballId, ballForce)
			end
		end
	end
)

addEvent("setPoolAnimation", true)
addEventHandler("setPoolAnimation", getRootElement(),
	function (anim, state)
		if isElement(source) then
			if state then
				setPedAnimation(source, "pool", anim, -1, false, false, true)
			else
				setPedAnimation(source)
			end
		end
	end
)

addEvent("givePoolStick", true)
addEventHandler("givePoolStick", getRootElement(),
	function (give, stopAnim)
		if isElement(source) then
			if give then
				giveWeapon(source, 7, 1, true)
				exports.sarp_controls:toggleControl(source, {"fire"}, false)
			else
				takeAllWeapons(source)
				exports.sarp_controls:toggleControl(source, {"fire"}, true)
			end

			if stopAnim then
				setPedAnimation(source)
			end
		end
	end
)

addEventHandler("onPlayerSpawn", getRootElement(),
	function ()
		triggerEvent("syncTheTables", source)
	end
)

addEvent("syncTheTables", true)
addEventHandler("syncTheTables", getRootElement(),
	function ()
		if isElement(source) then
			for k, v in pairs(poolData) do
				triggerClientEvent(source, "syncTheTable", source, k, v.objectElement, v.balls.curPos, v.areaPos, v.history)
			end
		end
	end
)

addEvent("syncTheTable", true)
addEventHandler("syncTheTable", getRootElement(),
	function (tableId)
		if isElement(source) then
			if tableId then
				triggerClientEvent(source, "syncTheTable", source, tableId, poolData[tableId].objectElement, poolData[tableId].balls.curPos, poolData[tableId].areaPos, poolData[tableId].history)
			end
		end
	end
)

function rotateAround(angle, x, y)
	angle = math.rad(angle)

	return x * math.cos(angle) - y * math.sin(angle),
		x * math.sin(angle) + y * math.cos(angle)
end

function deepcopy(t)
	if type(t) ~= "table" then return t end
	local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = deepcopy(v)
		else
			target[k] = v
		end
	end
	setmetatable(target, meta)
	return target
end

function createPoolTable(data, sync)
	local objectElement = createObject(2964, data.posX, data.posY, data.posZ, 0, 0, data.rotZ)

	setElementInterior(objectElement, data.interior)
	setElementDimension(objectElement, data.dimension)

	if isElement(objectElement) then
		local tableId = data.tableId

		poolData[tableId] = {}
		poolData[tableId].objectElement = objectElement
		
		poolData[tableId].balls = {}
		poolData[tableId].balls.defPos = {}
		poolData[tableId].balls.curPos = {}
		poolData[tableId].balls.ingame = {}
		poolData[tableId].balls.dropped = {}

		for k, v in ipairs(offsetForBalls) do
			local x, y = rotateAround(data.rotZ, v[1], v[2])
			local data = {
				modelForBalls[numberForBalls[k]],	-- model
				data.posX + x,						-- x
				data.posY + y,						-- y
				data.posZ + gameFieldPos[9],		-- z
				false,								-- frozen
				false								-- inhole
			}

			poolData[tableId].balls.defPos[k] = deepcopy(data)
			poolData[tableId].balls.curPos[k] = deepcopy(data)
		end

		local x, y = rotateAround(data.rotZ, gameFieldPos[5], gameFieldPos[6])
		local x2, y2 = rotateAround(data.rotZ, gameFieldPos[3], gameFieldPos[6])
		local x3, y3 = rotateAround(data.rotZ, gameFieldPos[3], gameFieldPos[4])
		local x4, y4 = rotateAround(data.rotZ, gameFieldPos[5], gameFieldPos[4])

		poolData[tableId].areaPos = {}
		poolData[tableId].areaPos[1] = {data.posX + x, data.posY + y, data.posX + x2, data.posY + y2, data.posZ + gameFieldPos[9]}
		poolData[tableId].areaPos[2] = {data.posX + x2, data.posY + y2, data.posX + x3, data.posY + y3, data.posZ + gameFieldPos[9]}
		poolData[tableId].areaPos[3] = {data.posX + x3, data.posY + y3, data.posX + x4, data.posY + y4, data.posZ + gameFieldPos[9]}
		poolData[tableId].areaPos[4] = {data.posX + x4, data.posY + y4, data.posX + x, data.posY + y, data.posZ + gameFieldPos[9]}

		poolData[tableId].history = {}

		setElementData(objectElement, "poolTableId", tableId)

		if sync then
			triggerClientEvent("syncTheTable", resourceRoot, tableId, objectElement, poolData[tableId].balls.curPos, poolData[tableId].areaPos, poolData[tableId].history)
		end
	end
end

addEventHandler("onResourceStart", getRootElement(),
	function (startedResource)
		if getResourceName(startedResource) == "sarp_database" then
			connection = exports.sarp_database:getConnection()
		elseif source == getResourceRootElement() then
			local sarp_database = getResourceFromName("sarp_database")

			if sarp_database and getResourceState(sarp_database) == "running" then
				connection = exports.sarp_database:getConnection()
			end

			if connection then
				dbQuery(loadBilliards, connection, "SELECT * FROM billiard")
			end
		end
	end
)

function loadBilliards(qh)
	local result = dbPoll(qh, 0)

	if result then
		for k, v in pairs(result) do
			createPoolTable(v)
		end
	end
end

addEvent("placeThePoolTable", true)
addEventHandler("placeThePoolTable", getRootElement(),
	function (data)
		if isElement(source) then
			if data then
				dbQuery(
					function (qh)
						local result = dbPoll(qh, 0, true)[2][1][1]

						if result then
							createPoolTable(result, true)
						end
					end, connection, "INSERT INTO billiard (posX, posY, posZ, rotZ, interior, dimension) VALUES (?,?,?,?,?,?); SELECT * FROM billiard ORDER BY tableId DESC LIMIT 1", unpack(data)
				)
			end
		end
	end
)