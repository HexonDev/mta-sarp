screenX, screenY = guiGetScreenSize()
UI = exports.sarp_ui
responsiveMultipler = UI:getResponsiveMultiplier()
fonts = {}

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

registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
    loadFonts()

end)