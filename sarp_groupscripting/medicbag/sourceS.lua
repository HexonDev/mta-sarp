local medicbags = {}

function createMedicbag(player, cmd)

    if medicbags[player] then
        outputChatBox("Van már táska a kezedben, vagy rakt", player)
        return
    end

    medicbags[player] = createObject(3089, 0, 0, 0)
    exports.sarp_boneattach:attachElementToBone(medicbags[player], player, 12, 0, -0.03, 0.3, 30 , 180, 0)
    setElementCollisionsEnabled(medicbags[player], false)
end
addCommandHandler("cm", createMedicbag)

function dropMedicbag(player, pos)
    if medicbags[player] then
        local oX, oY, oZ = pos[1], pos[2], pos[3]
        
        if isElement(medicbags[player]) then
            exports.sarp_boneattach:detachElementFromBone(medicbags[player])
            setElementPosition(medicbags[player], oX, oY, oZ)
            setElementRotation(medicbags[player], 0, 0, pos[4] - 90)
        end

    end
end
addEvent("sarp_medicbagS:dropMedicbag", true)
addEventHandler("sarp_medicbagS:dropMedicbag", root, dropMedicbag)

addCommandHandler("db", function(player)
    if isElement(medicbags[player]) then
        triggerClientEvent(player, "sarp_medicbagS:calculateMedicbag", player)
    else
        outputChatBox("Nincs táska a kezedben", player)
    end
end)

function pickupMedicbag(player, medicbag)
    if isElement(medicbag) then
        exports.sarp_boneattach:attachElementToBone(medicbag, player, 12, 0, -0.03, 0.3, 30 , 180, 0)
    end
end

function destroyMedicbag(player)
    if isElement(medicbags[player]) then
        exports.sarp_boneattach:detachElementFromBone(medicbags[player])
        destroyElement(medicbags[player])
    end
end
addCommandHandler("dm", destroyMedicbag)

addEventHandler("onPlayerClick", root, function(mouseButton, buttonState, clickedElement)
    if mouseButton == "left" and buttonState == "down" then
        if clickedElement == medicbags[source] then
            pickupMedicbag(source, medicbags[source])
        end
    end
end)