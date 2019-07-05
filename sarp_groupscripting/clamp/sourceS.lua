function registerEvent(event, element, func)
    addEvent(event, true)
    addEventHandler(event, element, func)
end

addCommandHandler("addwc", function(player)
    addWheelClamp(getPedOccupiedVehicle(player))
end)

addCommandHandler("remwc", function(player)
    removeWheelClamp(getPedOccupiedVehicle(player))
end)

function addWheelClamp(vehicle)
    if isElement(vehicle) and getElementType(vehicle) == "vehicle" then
        setElementData(vehicle, "vehicle.wheelClamp", true)
    end
end


function removeWheelClamp(vehicle)
    if isElement(vehicle) and getElementType(vehicle) == "vehicle" then
        setElementData(vehicle, "vehicle.wheelClamp", false)
    end
end

registerEvent("sarp_wheelclampS:applyAnimation", root, function(state)
    print(state)
    if state then
        setPedAnimation(source, "bomber", "bom_plant_loop", -1, true, false)
    else
        setPedAnimation(source)
    end
end)