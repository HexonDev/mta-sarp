
addEventHandler("onResourceStart", getResourceRootElement(), function()
    setTimer(function()
        sellerPed = createPed(100, 1479.9931640625, -1740.2568359375, 13.546875, 360)
        setElementData(sellerPed, "ped.dogseller", true)
        --setElementData(trainerPed, "ped.inUse", false)
		setElementData(sellerPed, "ped.name", "Kisállat kereskedő")
    end, 2000, 1)
end)

function buyDog(name, type, price)
    if type and price and name then

        if exports.global:takeMoney(source, price) then
            insertNewDog(source, name, type)
            exports["sarp_alert"]:showAlert(source, "info", "Sikeresen megvárásoltad az új állatodat!")
            loadCharacterDogs(source)
        else
            exports["sarp_alert"]:showAlert(source, "error", "Nincs elég pénzed megvenni", "az új állatodat!")
        end
    end
end
addEvent("buyNewDog", true)
addEventHandler("buyNewDog", root, buyDog)