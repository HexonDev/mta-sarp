
local showPanel

addEventHandler("onClientClick", root, function(button, state, aX, aY, wX, wY, wZ, element)
    if state == "down" then
        if element and isElement(element) then
            if getElementData(element, "ped.dogtrainer") then
                if getElementData(element, "ped.inUse") then
                    outputChatBox("Már éppen egy kutyát tanít... Várd meg míg végez.")
                    return
                end



            end
        end
    end
end)