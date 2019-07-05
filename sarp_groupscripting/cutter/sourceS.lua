
local cutters = {}

addEvent("sarp_cutterS:giveCutter", true)
addEventHandler("sarp_cutterS:giveCutter", root, function()
    print("asd1")
    setElementData(source, "player.hasCutter", true)
    setPedWalkingStyle(source, 68)
    exports.sarp_controls:toggleControl(source, {"jump", "crouch", "aim_weapon", "enter_passenger", "enter_exit", "fire", "action"}, false)

    cutters[source] = createObject(hydraulicCutter, getElementPosition(source))
    setElementCollisionsEnabled(cutters[source], false)
    print(cutters[source]) 
    exports.sarp_boneattach:attachElementToBone(cutters[source], source, 12, 0, 0, 0, 0, -95, 0)
end)

addEvent("sarp_cutterS:takeCutter", true)
addEventHandler("sarp_cutterS:takeCutter", root, function()
    print("asd2")
    setElementData(source, "player.hasCutter", false)
    setPedWalkingStyle(source, 118)

    if isElement(cutters[source]) then
        destroyElement(cutters[source])
    end

    exports.sarp_controls:toggleControl(source, {"jump", "crouch", "aim_weapon", "enter_passenger", "enter_exit", "fire", "action"}, true)
end)

registerEvent("sarp_cutterS:removeDoor", root, function(vehicle, component, state)
    print("Kapott adatok:", vehicle, component, state)
    if state == 1 then
        setVehicleDoorState(vehicle, component, 2)
    else
        setVehicleDoorState(vehicle, component, 4)
        
    end
    --setVehicleDoorState()
end)

registerEvent("sarp_cutterS:applyAnimation", root, function(state)
    --setPedAnimation(source, "chainsaw", "csaw_part",)
    if state then
        setPedAnimation(source, "chainsaw", "csaw_part", -1, true, false, false)
    else
        setPedAnimation(source)
    end
end)

addEvent("sarp_cutterS:playSoundEffect", true)
addEventHandler("sarp_cutterS:playSoundEffect", getRootElement(), function(x, y, z, state)
    triggerClientEvent(root, "sarp_cutterC:playSoundEffect", source, x, y, z, state)
end)