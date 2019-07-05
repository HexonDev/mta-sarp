
local Detain = {}

Detain.TargetPlayer = nil
Detain.TargetVehicle = nil
Detain.Active = false

Detain.ClickHandler = function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if Detain.Active then
        print('1')
        if Detain.TargetPlayer then
            print("Nincs targetPlayer")
            if button == "left" and state == "down" then
                print("2")
                if exports.sarp_core:inDistance3D(localPlayer, clickedElement, 10) then
                    print("3")
                    if clickedElement ~= localPlayer then
                        print("4")
                        
                        if getElementType(clickedElement) == "vehicle" then
                            Detain.TargetVehicle = clickedElement
                            
                            if isElement(Detain.TargetVehicle) then
                                triggerServerEvent("sarp_detainS:detainPlayer", localPlayer, Detain.TargetVehicle, Detain.TargetPlayer)
                                removeEventHandler("onClientClick", root, Detain.ClickHandler)
                                Detain.Active = not Detain.Active
                            end
                        end
                    end
                end
            end
        end
    end
end

addEvent("sarp_detainC:detainMode", true)
addEventHandler("sarp_detainC:detainMode", root, function(target)
    Detain.Active = not Detain.Active

    if not isElement(target) then
        return
    end
    Detain.TargetPlayer = target

    if Detain.Active then
        outputInfoText("Válaszd ki a cél járművet")
        addEventHandler("onClientClick", root, Detain.ClickHandler)
    end
end)

addCommandHandler("berak", function()
    Detain.Active = not Detain.Active

    if Detain.Active then
        outputInfoText("Berakás mód bekapcsolva")
        addEventHandler("onClientClick", root, Detain.ClickHandler)
    else
        outputInfoText("Berakás mód kikapcsolva")
        removeEventHandler("onClientClick", root, Detain.ClickHandler)
    end
end)

outputErrorText = function(text, element)
    triggerEvent("playClientSound", element, ":sarp_assets/audio/admin/error.ogg")
	assert(type(text) == "string", "Bad argument @ 'outputErrorText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sapr_core:getServerTag("error") .. text, 0, 0, 0, true)
end

outputInfoText = function(text, element)
	assert(type(text) == "string", "Bad argument @ 'outputInfoText' [expected string at argument 1, got "..type(text).."]")
	outputChatBox(exports.sarp_core:getServerTag("info") .. text, 0, 0, 0, true)
end