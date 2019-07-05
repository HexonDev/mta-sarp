local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

registerEvent("sarp_miningS:startMining", root, function()
    setPedAnimation(source, "baseball", "bat_4", -1, false)
    local x, y, z = getElementPosition(source)
    triggerClientEvent(root, "sarp_miningC:playMiningSound", source)
    --print("Meghív")
end)

registerEvent("sarp_miningS:stopMining", root, function()
    setPedAnimation(source)
end)

registerEvent("sarp_miningS:giveOre", root, function(itemID)
    exports.sarp_inventory:addItem(source, itemID, 1, false)
    local itemName = exports.sarp_inventory:getItemName(itemID)
    exports.sarp_hud:showAlert(source, "info", "A felvett " .. itemName .. " bekerült az inventorydba")
end)


registerEvent("sarp_miningS:takeOres", root, function()
    local collectedMoney = 0
    for k, v in pairs(ores) do
        local itemID = v[4]
        local item = exports.sarp_inventory:hasItem(source, itemID)
        if item then
            local itemName = exports.sarp_inventory:getItemName(itemID)
            local itemCount = exports.sarp_inventory:countItemsByItemID(source, itemID, true)

            for i = 1, itemCount do
                local money = math.random(v[3][1], v[3][2])
                exports.sarp_core:giveMoney(source, money)
                collectedMoney = collectedMoney + money
            end
            triggerEvent("takeItem", source, source, "itemId", itemID, false)
        end
    end
    exports.sarp_alert:showAlert(source, "info", "Sikeresen leadtad az érceidet", "Összessen " .. collectedMoney .. "$-t kaptál értük")
end)