
function registerEvent(event, element, xfunction)
    addEvent(event, true)
    addEventHandler(event, element, xfunction)
end

registerEvent("sarp_medicC:playerHeal", root, function(targetPlayer)
    if targetPlayer then
        if not isPedDead(targetPlayer) then
            exports.sarp_minigames:startMinigame("buttons", "healSuccess", "healFailed", 0.15, 0.2, 115, 40)
        else
            outputChatBox(exports.sarp_core:getServerTag("info") .. "A páciens halott.", 0, 0, 0, true)
        end
    end
end)

registerEvent("healSuccess", root, function(player)
    triggerServerEvent("sarp_medicS:healPlayer", player, player)
    --triggerServerEvent("sarp_medicS", player)
end)

registerEvent("healFailed", root, function(player)
    exports.sarp_hud:showAlert("error", "Sikertelen ellátás!", "Nem sikerült az ellátást szakszerűen végrehajtanod")
    --triggerServerEvent("sarp_medicS", player)
end)