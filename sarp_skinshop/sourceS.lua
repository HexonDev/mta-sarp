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

addEvent("sarp_skinshopS:buySkin", true)
addEventHandler("sarp_skinshopS:buySkin", root, function(skin, price, player)
    if skin and price and getElementType(source) == "player" then
        if exports.sarp_core:takeMoney(source, price) then
            dbQuery(
                function(queryHandle, player, skinID)
                    setElementModel(player, skin)
                    exports.sarp_alert:showAlert("info", "Sikeresen megvásároltad a ruházatot.")
                    dbFree(queryHandle)
                end, {source, skin}, connection, "UPDATE characters SET skin = ? WHERE id = ?", skin, getElementData(source, "char.ID")
            )
        else
            exports.sarp_alert:showAlert("error", "Nincs elég pénzed a vásárláshoz.")
        end
    end
end)