
local crosshairs = {}
local shader = false
local currentCrosshair = nil

addEventHandler("onClientResourceStart", root, function()
    shader = dxCreateShader("texreplace.fx")

    addCrosshair("crosshairs/1.png")
    addCrosshair("crosshairs/2.png")
    addCrosshair("crosshairs/3.png")
    addCrosshair("crosshairs/4.png")
end)

function changeCrosshair(id)
    if not shader then
        return
    end

    if not id then
        return
    end

    local crosshairPath = crosshairs[id]
    local texture = dxCreateTexture(crosshairPath)

    engineApplyShaderToWorldTexture(shader, "siteM16")
    dxSetShaderValue(shader, "gTexture", texture)
    currentCrosshair = id
end

function resetCrosshair()
    engineRemoveShaderFromWorldTexture(shader, "siteM16")
    currentCrosshair = nil
end

function addCrosshair(path)
    table.insert(crosshairs, path)
end

function getCrosshairs()
    return #crosshairs, crosshairs
end

addCommandHandler("cc", function(cmd, id)
    if not id then
        resetCrosshair()
    else
        changeCrosshair(tonumber(id))
    end
end)
--[[
local screenX, screenY = guiGetScreenSize()

addEventHandler("onClientRender", root, function()
    local crosshairNum, crosshair = getCrosshairs()
    if currentCrosshair then
        dxDrawImage(screenX / 2, screenY / 2, 64, 64, crosshair[currentCrosshair])
    end
    dxDrawText(crosshairNum, screenX / 2, screenY / 2, screenX / 2, screenY / 2, tocolor(255, 255, 255, 255))
end)
--]]