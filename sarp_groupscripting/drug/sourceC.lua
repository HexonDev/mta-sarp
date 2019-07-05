--local clickedPed = nil

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if button == "left" and state == "down" then
        if clickedElement then
            if getElementData(clickedElement, "isDrugPed") then
                if exports.sarp_core:inDistance3D(localPlayer, clickedElement, 2) then
                    getInfoFromPed(clickedElement)
                    --clickedPed = clickedElement
                    --print(clickedPed, clickedElement)
                end
            end
        end
    end
end)

local freshPlants = {}

function getInfoFromPed(clickedPed)
    if exports.sarp_core:takeMoney(localPlayer, infoPrice) then
        for k, v in pairs(plants) do
            freshPlants[k] = {}
            if chances[k] then
                for i = 1, math.random(chances[k][1], chances[k][2]) do
                    local drugTable = plants[k][math.random(1, #plants[k])]
                    table.insert(freshPlants[k], drugTable)
                end
            end
        end
        createDrugPoint()
    else
        exports.sarp_chat:sendLocalMessage(clickedPed, "Te most viccelsz?! Na húzzá' innen")
    end
end

local drugBlips = {}
local drugPlants = {}

local selectedPlant = nil

function isInDrugPoint(element)
    if element then
        for k, v in pairs(drugPlants) do
            if isElementWithinColShape(element, k) then
                return true
            end
        end
    end
    return false
end

function createDrugPoint()
    --if #freshPlants > 0 then
        outputConsole(inspect(freshPlants))
        for k, v in pairs(freshPlants) do
            for k2,v2 in pairs(v) do
                local drugCol = createColSphere(v2[1], v2[2], v2[3], 4) --createMarker(v[1], v[2], v[3] - 1, "cylinder", 3)
                setElementData(drugCol, "drugType", k) 
                
                drugBlips[drugCol] = createBlip(v2[1], v2[2], v2[3])
                setElementData(drugBlips[drugCol], "blipIcon", "cp")
                setElementData(drugBlips[drugCol], "blipTooltipText", k .. " ültetvény")
                setElementData(drugBlips[drugCol], "blipColor", tocolor(50, 179, 239))

                drugPlants[drugCol] = createObject(plantObjects[k], v2[1], v2[2], v2[3] - 0.3)
            end
        end
   --end
end

addEventHandler("onClientColShapeHit", resourceRoot, function(element)
    if element == localPlayer and drugPlants[source] then
        selectedPlant = source
        exports.sarp_minigames:startMinigame("buttons", "harvestSuccess", "harvestFailed", 0.15, 0.2, 115, 20)
        triggerServerEvent("sarp_drugS:applyAnimation", localPlayer, true, "take")
    end
end)

addEventHandler("onClientColShapeLeave", resourceRoot, function(element)
    if element == localPlayer then
        selectedPlant = nil
    end
end)

function destroyPlant(plant)
    destroyElement(plant)
    if isElement(drugBlips[plant]) then destroyElement(drugBlips[plant]) end
    if isElement(drugPlants[plant]) then destroyElement(drugPlants[plant]) end
    selectedPlant = nil
    drugPlants[plant] = nil
end



addEvent("harvestSuccess", true)
addEventHandler("harvestSuccess", root, function()
    local drugType = getElementData(selectedPlant, "drugType")
    triggerServerEvent("addItem", localPlayer, localPlayer, itemID["unprocessed"][drugType], 1, false)
    triggerServerEvent("sarp_drugS:applyAnimation", localPlayer)
    destroyPlant(selectedPlant)
end)

addEvent("harvestFailed", true)
addEventHandler("harvestFailed", root, function()
    destroyPlant(selectedPlant)
    triggerServerEvent("sarp_drugS:applyAnimation", localPlayer)
    outputChatBox("Nem sikerült megszerezned a növényt")
end)

local drugMakeZone = {}

function loadDurgMakeCols()
    if drugMakeCols[getElementDimension(localPlayer)] then
        for k, v in pairs( drugMakeCols[getElementDimension(localPlayer)]) do
            drugMakeZone[k] = createColSphere(v[1], v[2], v[3], v[4])
            setElementInterior(drugMakeZone[k], getElementInterior(localPlayer))
            setElementDimension(drugMakeZone[k], getElementDimension(localPlayer))
        end
    end
end
loadDurgMakeCols()

function isInDrugMakeZone(element)
    if element then
        for k, v in pairs(drugMakeZone) do
            if isElementWithinColShape(element, v) then
                return true
            end
        end
    end
    return false
end

local screenX, screenY = guiGetScreenSize()
local startTick = nil
local selectedDrug = nil

function startDrugMaking(type)
    addEventHandler("onClientRender", root, renderDrugMaking)
    setElementData(localPlayer, "drugProcessing", true)
    triggerServerEvent("sarp_drugS:applyAnimation", localPlayer, true, "take")
    setElementFrozen(localPlayer, true)
    startTick = getTickCount()
    selectedDrug = type
end
addEvent("sarp_drugC:startDrugMaking", true)
addEventHandler("sarp_drugC:startDrugMaking", root, startDrugMaking)

function stopDrugMaking(type)
    removeEventHandler("onClientRender", root, renderDrugMaking)
    triggerServerEvent("addItem", localPlayer, localPlayer, itemID["processed"][type], 1, false)
    triggerServerEvent("sarp_drugS:applyAnimation", localPlayer, false)
    setElementFrozen(localPlayer, false)
    startTick = nil
    selectedDrug = nil
    setElementData(localPlayer, "drugProcessing", false)
end
addEvent("sarp_drugC:stopDrugMaking", true)
addEventHandler("sarp_drugC:stopDrugMaking", root, stopDrugMaking)

function renderDrugMaking()
    local barW, barH = 251, 10
    local barX, barY = (screenX - barW) * 0.5, screenY - 5 - 46 - barH - 5

    dxDrawRectangle(barX, barY, barW, barH, tocolor(31, 31, 31, 240))

    if startTick then
        local currentTick = getTickCount()
        local elapsedTick = currentTick - startTick
        local endTick = startTick + drugMakeTime[selectedDrug]
        local duration = endTick - startTick
        local barProgress = elapsedTick / duration
        local barFill = interpolateBetween(
            0, 0, 0,
            1, 0, 0,
            barProgress, "Linear"
        )
        --print(barFill .. " :: " .. barProgress)
        dxDrawRectangle(barX + 2, barY + 2, (barW - 4) * barFill, barH - 4, tocolor(7, 112, 196, 240))  

        if barProgress >= 1 then
            stopDrugMaking(selectedDrug)
        end
    end
end