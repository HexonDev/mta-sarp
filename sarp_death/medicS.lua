
function registerEvent(event, element, xfunction)
    addEvent(event, true)
    addEventHandler(event, element, xfunction)
end

registerEvent("sarp_medicS:healPlayer", root, function(targetPlayer)
    local targetPlayerName = getPlayerName(targetPlayer):gsub("_", " ")
    healPlayer(targetPlayer)
    setPedAnimation(targetPlayer)
    setCameraTarget(targetPlayer, targetPlayer)

    outputChatBox(exports.sarp_core:getServerTag("info") .. "Sikeresen meggyógyítottad #32b3ef" .. targetPlayerName .. " #ffffffjátékost.", localPlayer, 0, 0, 0, true)
    outputChatBox(exports.sarp_core:getServerTag("info") .. "#32b3ef" .. (getElementData(localPlayer, "acc.adminNick") or "Admin") .. " #ffffffmeggyógyított téged.", targetPlayer, 0, 0, 0, true)
end)

registerEvent("sarp_medicS:reviewPlayer", root, function(targetPlayer)
    local targetPlayerName = getPlayerName(targetPlayer):gsub("_", " ")
    local playerPosX, playerPosY, playerPosZ = getElementPosition(targetPlayer)
    local playerInterior = getElementInterior(targetPlayer)
    local playerDimension = getElementDimension(targetPlayer)
    local playerSkin = getElementModel(targetPlayer)

    spawnPlayer(targetPlayer, playerPosX, playerPosY, playerPosZ, getPedRotation(targetPlayer), playerSkin, playerInterior, playerDimension)
    healPlayer(targetPlayer)
    setPedAnimation(targetPlayer)
    setCameraTarget(targetPlayer, targetPlayer)

    outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen felsegítetted #32b3ef" .. targetPlayerName .. " #ffffffjátékost.", localPlayer, 0, 0, 0, true)
    outputChatBox(exports.sarp_core:getServerTag("admin") .. "#32b3ef" .. (getElementData(localPlayer, "acc.adminNick") or "Admin") .. " #fffffffelsegített téged.", targetPlayer, 0, 0, 0, true)
end)