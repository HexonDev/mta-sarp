addEvent("sarp_serviceS:startService", true)
addEventHandler("sarp_serviceS:startService", root, function(vehicle, component)
    setPedAnimation(source, "bomber", "bom_plant_loop", -1, true, false)

    triggerClientEvent(source, "sarp_serviceC:startService", vehicle, component)
    print(component)

    local x, y, z = getElementPosition(source)

    triggerClientEvent(root, "repairSound", source, x, y, z, true)
end)

addEvent("sarp_serviceS:repairComponent", true)
addEventHandler("sarp_serviceS:repairComponent", root, function(vehicle, component)
    setPedAnimation(source)
    triggerClientEvent(root, "repairSound", source, nil, nil, nil, false)
    if panels[component] then
        setVehiclePanelState(vehicle, panels[component], 0)
        return
    end
    
    if doors[component] then
        setVehicleDoorState(vehicle, doors[component], 0)
        return
    end

    if component == "engine" then
        setElementHealth(vehicle, 1000)
        return
    end

    if component == "left_light" then
        setVehicleLightState(vehicle, 0, 0)
        return
    end

    if component == "right_light" then
        setVehicleLightState(vehicle, 1, 0)
        return
    end

    if component == "oil" then
        setElementData(vehicle, "lastOilChange", 0)
        return
    end

    --wheels["wheel_lf_dummy"], wheels["wheel_lb_dummy"], wheels["wheel_rf_dummy"], wheels["wheel_rb_dummy"] = getVehicleWheelStates(selectedVehicle)
    if component == "wheel_rf_dummy" then
        setVehicleWheelStates(vehicle, -1, -1, 0, -1)
    elseif component == "wheel_lf_dummy" then
        setVehicleWheelStates(vehicle, 0, -1, -1, -1)
    elseif component == "wheel_rb_dummy" then
        setVehicleWheelStates(vehicle, -1, -1, -1, 0)
    elseif component == "wheel_lb_dummy" then
        setVehicleWheelStates(vehicle, -1, 0, -1, -1)
    end


end)
