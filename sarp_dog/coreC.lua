
local dogSkins = {
	{"dog1", 311},
	{"dog2", 310},
	{"dog3", 309},
	{"dog4", 308},
	{"dog5", 307},
	{"dog6", 306},
	{"dog7", 305},
}

local dogTXD = {}
local dogDFF = {}

addEventHandler("onClientResourceStart", getResourceRootElement(), function()
	loadDogs()
end)

function loadDogs()
	for k, v in ipairs(dogSkins) do
		dogTXD[k] = engineLoadTXD("mods/" .. v[1] .. ".txd")
		engineImportTXD(dogTXD[k], v[2])
		dogDFF[k] = engineLoadDFF("mods/" .. v[1] .. ".dff")
		engineReplaceModel(dogDFF[k], v[2])
	end
end


local dogs = {}

function loadDogsFromServer(table)
    dogs = table
end
addEvent("fillClientDogTable", true)
addEventHandler("fillClientDogTable", root, loadDogsFromServer)

function isDogSpawned(player)
    if player and isElement(player) then
        if dogs[player] then
            return dogs[player]
        end
    end

    return false
end
