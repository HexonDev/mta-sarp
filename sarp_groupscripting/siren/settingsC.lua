local screenX, screenY = guiGetScreenSize()
local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()
local widgets = {}
local isVisible = false
local gpsState = false
fonts = {}

local Settings = {}

local SettableValues = {
    {"sound:1", "Hangjelzés 1", "N/A"},
    {"sound:2", "Hangjelzés 2", "N/A"},
    {"sound:3", "Hangjelzés 3", "N/A"},
    {"light:1", "Fényjelzés 1", "N/A"},
    {"light:2", "Fényjelzés 2", "N/A"},
    {"light:3", "Fényjelzés 3", "N/A"},
}

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

function loadFonts()
    fonts = {
        Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
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
        LEDCalculator = exports.sarp_assets:loadFont("LEDCalculator.ttf", respc(18), false, "antialiased"),
    }
end

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
	loadFonts()
end)

local statusCodes = {
	[1] = "Inaktív",
	[2] = "Elérhető",
	[3] = "Erősítés"
}

Settings.Show = function()
    local panelW, panelH = UI:respc(400), UI:respc(300)

	if isVisible then
		return
	end

	isVisible = true

	widgets.panel = UI:createCustomPanel({
		x = (screenX - panelW) / 2,
		y = (screenY - panelH) / 2,
		width = panelW,
		height = panelH,
		--rounded = true
	})
	UI:addChild(widgets.panel)

	widgets.logo = UI:createImage({
		x = 5,
		y = 5,
		width = UI:respc(403 * 0.075),
		height = UI:respc(459 * 0.075),
		texture = ":sarp_assets/images/sarplogo_big.png",
		color = tocolor(50, 179, 239),
		floorMode = true
	})
    UI:addChild(widgets.panel, widgets.logo)

	widgets.headerTitle = UI:createCustomLabel({
		x = 10 + UI:respc(30.225),
		y = 5,
		width = 0,
		height = UI:respc(34.425),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Vezérlő beállítások",
	})
	UI:addChild(widgets.panel, widgets.headerTitle)

	widgets.closeButton = UI:createCustomImageButton({
		x = panelW - UI:respc(24) - 10,
		y = 5 + (UI:respc(34.425) - UI:respc(24)) / 2,
		width = UI:respc(24),
		height = UI:respc(24),
		hoverColor = tocolor(215, 89, 89),
		texture = ":sarp_assets/images/cross_x.png"
	})
    UI:addChild(widgets.panel, widgets.closeButton)
    
    -----------------------------------------------------------

    widgets.unitInput = UI:createCustomInput({
        x = respc(10),
        y = respc(60),
        width = panelW - respc(20),
        height = respc(40),
        font = fonts.Roboto14,
        placeholder = "Egység",
        maxLength = 18,
    })
    UI:addChild(widgets.panel, widgets.unitInput)

    statusState = getElementData(getPedOccupiedVehicle(localPlayer), "siren.status") or 0 

    widgets.visibleButton = UI:createCustomButton({
        x = respc(10),
        y = respc(110),
        width = panelW - respc(20),
        height = respc(40),
        text = "Státusz: " .. statusCodes[statusState],
        font = fonts.Roboto14,
        color = {7, 112, 196, 125},
        --rounded = true
    })
    UI:addChild(widgets.panel, widgets.visibleButton)

    widgets.saveButton = UI:createCustomButton({
        x = respc(10),
        y = panelH - respc(40) - respc(10),
        width = panelW - respc(20),
        height = respc(40),
        text = "Mentés",
        font = fonts.Roboto14,
        color = {7, 112, 196, 125},
        --rounded = true
    })
    UI:addChild(widgets.panel, widgets.saveButton)


    local veh = getPedOccupiedVehicle(localPlayer)

    if getElementData(veh, "siren.unit") and getElementData(veh, "siren.unit") ~= "" then
        UI:setText(widgets.unitInput, getElementData(veh, "siren.unit"))
    else
        UI:setText(widgets.unitInput, "Ismeretlen")
    end
end
addEvent("sarp_sirenC:showSettings", true)
addEventHandler("sarp_sirenC:showSettings", root, Settings.Show)

Settings.Close = function()
    if not isVisible then
		return
	end
	isVisible = false

	UI:removeChild(widgets.panel)
	showCursor(false)
end

--[[
local selectMode = false

Settings.ChangeKey = function(controlID, key)
    local data = SettableValues[controlID]
    data[3] = key 
    UI:setText(widgets[data[1] .. ":button"], tostring(utf8.upper(key)))
    selectMode = false
end

Settings.LoadConfig = function()
    
end

Settings.ProcessConfig = function()
    for i = 1, #SettableValues do
        local v = SettableValues[i]
        local k = v[1]
        if v[3] ~= "N/A" then
            bindKey(v[3], "down", processKey, k, i)
        end
    end
end

function processKey(key)
  
end
]]

addEvent("sarpUI.click", false)
addEventHandler("sarpUI.click", resourceRoot, function (widget, button)
	if button == "left" then
		if widget == widgets.closeButton then
            Settings.Close()
        elseif widget == widgets.saveButton then
            if isPedInVehicle(localPlayer) then
                local vehicle = getPedOccupiedVehicle(localPlayer)
                local unit = UI:getText(widgets.unitInput)

                setElementData(vehicle, "siren.unit", unit)
                --setElementData(vehicle, "siren.gps", gpsState)

                --triggerServerEvent("sarp_sirenS:toggleGPS", localPlayer, gpsState)
            end
        elseif widget == widgets.visibleButton then
            if isPedInVehicle(localPlayer) then
                statusState = getElementData(getPedOccupiedVehicle(localPlayer), "siren.status") or 0 
                statusState = statusState + 1
                if statusState > 3 then
                    statusState = 1
                end

                UI:setText(widgets.visibleButton, "Státusz: " .. statusCodes[statusState])
                print(statusState)
                setElementData(getPedOccupiedVehicle(localPlayer), "siren.status", statusState)
            end
        end
	end
end)

addEventHandler("onClientCharacter", root, function(char)
    if selectMode then
        --if press and button ~= "mouse1" and button ~= "mouse2" and button ~= "mouse3" and button ~= "mouse_wheel_up" and button ~= "mouse_wheel_down" then
            local v = SettableValues[selectMode]
            Settings.ChangeKey(selectMode, char)
        --end
    end
end)

addEventHandler("onClientVehicleStartExit", root, function(player)
    Settings.Close()
end)

