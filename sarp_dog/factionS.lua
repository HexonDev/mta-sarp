
local dogsTable = getAllDogs()
local searchablePlayer = {}
local dogTimers = {}

--// POLICE DOG

function debugSearch(player, cmd, targetPlayer)
    if dogsTable[player] then
        local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(player, targetPlayer)
        dogSmellingItem(dogsTable[player], targetPlayer, "narcotics")
    end
end
addCommandHandler("cse", debugSearch)

local items = {
    ["narcotics"] = {30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43}, 
    ["weapons"] = {}
}


function dogSmellingItem(dog, target, itemtype)
    local targetsPX, targetsPY, targetsPZ = getElementPosition(target)
    local dogPX, dogPY, dogPZ = getElementPosition(dog)
    local distance = getDistanceBetweenPoints3D(dogPX, dogPY, dogPZ, targetsPX, targetsPY, targetsPZ)
    if distance <= 50 then
        local task = {"walkFollowElement", target, 1}
        --local task = {"walkToPos", targetsPX, targetsPY, targetsPZ, 1}
        if exports.npc_hlc:setNPCTask(dog, task) then
            setTimer(function()
                --outputChatBox("Szerintem oda értem, és én szagolni kezdek")
                --if distance <= 1.2 then
                    --exports.global:sendLocalDoAction(getElementData(dog, "dog.owner"), "A kutya szimatol...")
                    sendLocalDogAction(dog, "me", "szimatol...")
                    setTimer(function()
                        local foundedItem = false
                        for k, v in ipairs(items[itemtype]) do 
                            if exports.global:hasItem(target, v) then
                                triggerClientEvent(getElementData(dog, "dog.owner"), "dogPlaySound", dog, "barking")
                                foundedItem = true
                                break
                            end
                        end

                        if not foundedItem then
                            sendLocalDogAction(dog, "do", "Nem talált semmit.")
                            stayHere(dog)
                        end
                    end, math.random(1000, 5000), 1)
                    
                --end
            end, distance * 1000, 1)
        end
    end
end
