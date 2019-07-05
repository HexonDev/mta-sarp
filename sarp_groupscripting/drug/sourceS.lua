local infoPed = nil

addEventHandler("onResourceStart", resourceRoot, function()
    spawnInfoPed()
end)

function spawnInfoPed()
    if isElement(infoPed) then
        destroyElement(infoPed)
    end

    local randomPos = math.random(1, #infoPedPosition)
    local x, y, z, rz = unpack(infoPedPosition[randomPos])
    outputChatBox(x .. " " .. y .. " " .. z)
    infoPed = createPed(100, x, y, z, rz)
    setElementFrozen(infoPed, true)
	setElementData(infoPed, "invulnerable", true)
	setElementData(infoPed, "visibleName", "Informátor")
    setElementData(infoPed, "pedNameType", "Drog")
    setElementData(infoPed, "isDrugPed", true)
	setPedAnimation(infoPed, "COP_AMBIENT", "Coplook_think", -1, true, false, false)
end

addEvent("sarp_drugS:applyAnimation", true)
addEventHandler("sarp_drugS:applyAnimation", root, function(state, action)
    if state then 
        if action == "take" then
            setPedAnimation(source, "bomber", "bom_plant_loop", -1, true, false)
        elseif action == "make" then
            setPedAnimation(source, "bomber", "bom_plant_loop", -1, true, false)
        end
    else
        setPedAnimation(source)
    end
end)