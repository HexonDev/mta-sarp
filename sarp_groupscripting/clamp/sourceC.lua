local wheelClamps = {}

function createWheelClamp(vehicle)
    if isElement(vehicle) and not wheelClamps[vehicle] then
        local x, y, z = getVehicleComponentPosition(vehicle, "wheel_lf_dummy", "world")
        wheelClamps[vehicle] = createObject(8283, x, y, z, 0, 0, 180)
        setElementCollisionsEnabled(wheelClamps[vehicle], false)
    end
end

function removeWheelClamp(vehicle)
    if isElement(vehicle) and wheelClamps[vehicle] then
        destroyElement(wheelClamps[vehicle])
        wheelClamps[vehicle] = nil
    end
end

addEventHandler("onClientPreRender", root, function()
    for vehicle, object in pairs(wheelClamps) do
        if isElement(vehicle) and isElement(object) then
            local x, y, z = getVehicleComponentPosition(vehicle, "wheel_lf_dummy", "world")
            local rx, ry, rz = getVehicleComponentRotation(vehicle, "wheel_lf_dummy", "world")
            setElementPosition(object, x, y, z)
            setElementRotation(object, 0, 0, rz)
        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    for k, v in pairs(getElementsByType("vehicle", root, true)) do
        if getElementData(v, "vehicle.wheelClamp") then
            createWheelClamp(v)
        end 
    end
end)

addEventHandler("onClientElementStreamIn", root, function()
    if getElementType(source) == "vehicle" then
        if getElementData(source, "vehicle.wheelClamp") then
            createWheelClamp(source)
        end
    end
end)

addEventHandler("onClientElementStreamOut", root, function()
    if getElementType(source) == "vehicle" then
        removeWheelClamp(source)
    end
end)

addEventHandler("onClientElementDestroy", root, function()
    if getElementType(source) == "vehicle" then
        removeWheelClamp(source)
    end
end)

addEventHandler("onClientElementDataChange", root, function(key, oldValue, newValue)
    if getElementType(source) == "vehicle" then
        if key == "vehicle.wheelClamp" then
            if newValue == true then
                if isElementStreamedIn(source) then
                    createWheelClamp(source)
                end
            elseif newValue == false then
                removeWheelClamp(source)
            end
        end
    end
end)

local screenX, screenY = guiGetScreenSize()

local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

function loadFonts()
    fonts = {
		Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
		Roboto13 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(13), false, "antialiased"),
        Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
        Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(16), false, "cleartype"),
        Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
        RobotoL = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL14 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(14), false, "cleartype"),
        RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
        RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL24 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(24), false, "cleartype"),
        RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
        RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
        RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
    }
end

addEventHandler("onClientResourceStart", resourceRoot, function()       
    loadFonts()
   
end)

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

local barW, barH = 251, 10
local barX, barY = (screenX - barW) / 2, screenY - 5 - 46 - barH - 5

local clampTime = 15
local startTick = nil 
local currentAction = true

local clampSound = nil

function startWheelClampingAnimation(action)
    startTick = getTickCount()
    addEventHandler("onClientRender", root, renderWheelClamping)
    triggerServerEvent("sarp_wheelclampS:applyAnimation", localPlayer, true)
    currentAction = action
    if isElement(clampSound) then
        stopSound(clampSound)
        destroyElement(clampSound)
    end
    clampSound = playSound("clamp/clamp.mp3")
end

function renderWheelClamping()
    if startTick then
        dxDrawRectangle(barX, barY, barW, barH, tocolor(31, 31, 31, 240))
        local text = "leszerelése"
        if currentAction then
            text = "felszerelése"
        end
        dxDrawText("Kerékbilincs " .. text .. "...", barX, barY - dxGetFontHeight(1, fonts.Roboto11), barX + 5, barY + 2,tocolor(255,255,255), 1, fonts.Roboto11)

        local currentTick = getTickCount()
        local elapsedTick = currentTick - startTick
        local endTick = startTick + clampTime * 1000
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
            removeEventHandler("onClientRender", root, renderWheelClamping)
            triggerServerEvent("sarp_wheelclampS:applyAnimation", localPlayer, false)
            if isElement(clampSound) then
                stopSound(clampSound)
                destroyElement(clampSound)
            end
        end
    end
end




