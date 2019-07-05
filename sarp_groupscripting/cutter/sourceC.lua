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


local buttons = {}
local activeButton = nil
local currentVehicle = nil

local cuttingState = 0

local imageW, imageH = 50, 50

addEventHandler("onClientRender", root, function()

    for k, v in pairs(getElementsByType("vehicle", root, true)) do
        if getElementData(v, "vehicle.crashed") then
            local pX, pY, pZ = getElementPosition(localPlayer)
            local vX, vY, vZ = getElementPosition(v)

            if getDistanceBetweenPoints3D(pX, pY, pZ, vX, vY, vZ) <= 7 then
                local iX, iY = getScreenFromWorldPosition(vX, vY, vZ + 1.7)
                if iX then
                    dxDrawImage(iX, iY, imageW, imageH, "cutter/crashed.png", 0, 0, 0, tocolor(255, 182, 0))
                end
            end

            if getElementData(localPlayer, "player.hasCutter") then
                for component, state in pairs(getVehicleComponents(v)) do
                    if doorComponents[component] then
                        if getVehicleDoorState(v, doorComponents[component]) ~= 4 then
                            local cX, cY, cZ = getVehicleComponentPosition(v, component, "world") 
                            if getDistanceBetweenPoints3D(pX, pY, pZ, cX, cY, cZ) <= 2 then
                                local sX, sY = getScreenFromWorldPosition(cX, cY, cZ)
                                local cameraX, cameraY, cameraZ = getCameraMatrix()
                                if sX then
                                    if isLineOfSightClear(cameraX, cameraY, cameraZ, cX, cY, cZ, true, false, false, true, false, true, false) then
                                        --dxDrawText(component, sX, sY, sX, sY, tocolor(255, 255, 255), 1, fonts.Roboto11)
                                        dxDrawRectangle(sX - (imageW / 2), sY - (imageH / 2), imageW, imageH, tocolor(100, 100, 100))
                                        buttons[component] = {sX - (imageW / 2), sY - (imageH / 2), imageW, imageH, v}
                                                    
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end


    local cx, cy = getCursorPosition() -- lekérjük a relatív kurzor pozíciót

	if tonumber(cx) and tonumber(cy) then -- ha számot kapunk, tehát a kurzor elő van hozva
		cx, cy = cx * screenX, cy * screenY -- átalakítjuk abszolút értékekre
		cursorX, cursorY = cx, cy -- eltároljuk a változóba a kurzor abszolút pozícióit

		activeButton = false -- ha nem találna szarságot akkor nincs kijelölve semmi, tehát false

		for k, v in pairs(buttons) do -- végigmegyünk a létrehozott gombokon
			if cx >= v[1] and cy >= v[2] and cx <= v[1] + v[3] and cy <= v[2] + v[4] then -- benne van-e a boxban
				activeButton = k -- eltároljuk az aktív kijelölt gombot
				break -- megállítjuk a loopot
			end
		end
	else -- ha nincs előhozva a kurzor
		activeButton = false -- nincs kijelölve semmi
		cursorX, cursorY = -10, -10 -- kurzor a képernyőn kívülre, hogy a render ne érzékelje
    end

end)

local selectedVehicle = nil
local selectedComponent = nil

addEventHandler("onClientClick", root, function(button, state)
    if button == "left" and state == "down" then
        if doorComponents[activeButton] then
            local pX, pY, pZ = getElementPosition(localPlayer)
            local cX, cY, cZ = getVehicleComponentPosition(buttons[activeButton][5], activeButton, "world") 
            if getDistanceBetweenPoints3D(pX, pY, pZ, cX, cY, cZ) <= 1 then
                exports.sarp_minigames:startMinigame("balance", "removeDoorSuccess", "removeDoorFailed", 0.5, 10000)
                triggerServerEvent("sarp_cutterS:applyAnimation", localPlayer, true)
                triggerServerEvent("sarp_cutterS:playSoundEffect", localPlayer, pX, pY, pZ, true)
                selectedVehicle = buttons[activeButton][5] 
                selectedComponent = activeButton
            end
        end
    end
end)

addEvent("removeDoorSuccess", true)
addEventHandler("removeDoorSuccess", getRootElement(), function()
    local vehicle = selectedVehicle
    print(vehicle)
    if getVehicleDoorState(vehicle, doorComponents[selectedComponent]) == 2 then
        cuttingState = 1
    end
    
    cuttingState = cuttingState + 1
    --setVehicleDoorState(vehicle, doorComponents[activeButton], cuttingStates[cuttingState])
    triggerServerEvent("sarp_cutterS:removeDoor", localPlayer, vehicle, doorComponents[selectedComponent], cuttingState)
    triggerServerEvent("sarp_cutterS:applyAnimation", localPlayer, false)
    triggerServerEvent("sarp_cutterS:playSoundEffect", localPlayer, nil, nil, nil, false)

    if cuttingState >= 2 then 
        cuttingState = 0
    end

    selectedVehicle = nil
    selectedComponent = nil
end)

addEvent("removeDoorFailed", true)
addEventHandler("removeDoorFailed", getRootElement(), function()
    exports.sarp_hud:showAlert("error", "Nem sikerült megfelelően levágni a kijelölt pontot")
    triggerServerEvent("sarp_cutterS:applyAnimation", localPlayer, false)
    triggerServerEvent("sarp_cutterS:playSoundEffect", localPlayer, nil, nil, nil, false)
end)

local sound = nil

addEvent("sarp_cutterC:playSoundEffect", true)
addEventHandler("sarp_cutterC:playSoundEffect", getRootElement(), function(x, y, z, state)
    if not state then
        if isElement(sound) then
            stopSound(sound)
            return
        end
    end

    sound = playSound3D("cutter/scissors.ogg", x, y, z, true)
    setSoundMaxDistance(sound, 20)
    setSoundMinDistance(sound, 5)
end)