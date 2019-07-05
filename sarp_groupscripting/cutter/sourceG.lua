hydraulicCutter = 8251

doorComponents = {
    ["door_rf_dummy"] = 3,
    ["door_lf_dummy"] = 2,
    ["door_rr_dummy"] = 5,
    ["door_lr_dummy"] = 4,
}

cuttingStates = {
    [1] = 2,
    [2] = 4, 
}

function registerEvent(event, element, func)
    addEvent(event, true)
    addEventHandler(event, element, func)
end