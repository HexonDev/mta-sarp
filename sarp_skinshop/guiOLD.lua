local Panel = {}

local UI = exports.sarp_ui
addEventHandler("onInterfaceStarted", root, function ()
	UI = exports.sarp_ui
end)

local widgets = {}

local screenX, screenY = guiGetScreenSize()


local isVisible = false
local currentPanel = "personal"
local activeItem = nil
local oldModel = nil

local FontManager = {}
FontManager = {
	loadedFonts = {},

	addFont = function (name, element)
		FontManager.loadedFonts[name] = element
	end,

	unloadFonts = function ()
		for key, value in pairs(FontManager.loadedFonts) do
			if isElement(value) then
				value:destroy()
			end
		end

		FontManager.loadedFonts = {}
	end,

	loadFonts = function ()
		FontManager.unloadFonts()

		FontManager.addFont("Roboto", exports.sarp_assets:loadFont("Roboto-Regular.ttf", UI:resp(16), false, "cleartype"))
		FontManager.addFont("Roboto11", exports.sarp_assets:loadFont("Roboto-Regular.ttf", UI:resp(11), false, "cleartype"))
		FontManager.addFont("RobotoL16", exports.sarp_assets:loadFont("Roboto-Light.ttf", UI:resp(16), false, "cleartype"))
	end
}

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

addEventHandler("onAssetsLoaded", root, function ()
	FontManager.loadFonts()
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
    FontManager.loadFonts()
    
    setTimer(function()
        createSkinShop(getElementInterior(localPlayer))
    end, 1000, 1)
end)

local currentPage = "main"
local panelW, panelH = UI:respc(300), UI:respc(500)

function Panel.show()

    oldModel = getElementModel(localPlayer)

	if isVisible then
		return
	end

	isVisible = true

	widgets.panel = UI:createCustomPanel({
		x = UI:respc(10),
		y = (screenY - panelH) / 2,
		width = panelW,
		height = panelH,
		rounded = true
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
    

    local currentHeaderText = ""
    if currentPage == "male" then
        currentHeaderText = "(Férfi)"
    elseif currentPage == "female" then 
        currentHeaderText = "(Női)"
    end

	widgets.headerTitle = UI:createCustomLabel({
		x = 10 + UI:respc(30.225),
		y = 5,
		width = 0,
		height = UI:respc(34.425),
		color = tocolor(255, 255, 255),
		font = FontManager.loadedFonts.Roboto,
		alignX = "left",
		alignY = "center",
		text = "Ruházati üzlet " .. currentHeaderText,
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

    if currentPage == "main" then
        widgets.welcomeText = UI:createCustomLabel({
            x = (panelW / 2),
            y = 70,
            width = 0,
            height = UI:respc(34.425),
            color = tocolor(255, 255, 255),
            font = FontManager.loadedFonts.Roboto11,
            alignX = "center",
            alignY = "top",
            text = "Üdvözöllek!\nVálaszd ki, hogy milyen ruhát\nszeretnél magadnak. Amennyiben\na listában kiválasztottad magadnak,\nkattints a [Kiválasztás] gombra,\nés menj a pénztárhoz, majd fizesd ki.\nHa fizetés nélkül távozol, akkor\na ruhát nem kapod meg.",
        })
        UI:addChild(widgets.panel, widgets.welcomeText)

        widgets.maleButton = UI:createCustomButton({
			x = 10,
			y = (panelH - (UI:respc(40) + UI:respc(10)) * 2),
			width = panelW - 20,
			height = UI:respc(40),
			color = {50, 179, 239, 175},
			text = "Férfi ruházat",
			font = FontManager.loadedFonts.RobotoL16,
			rounded = true
		})
        UI:addChild(widgets.panel, widgets.maleButton)
        
        widgets.femaleButton = UI:createCustomButton({
			x = 10,
			y = (panelH - (UI:respc(40) + UI:respc(10)) * 1),
			width = panelW - 20,
			height = UI:respc(40),
			color = {50, 179, 239, 175},
			text = "Női ruházat",
			font = FontManager.loadedFonts.RobotoL16,
			rounded = true
		})
		UI:addChild(widgets.panel, widgets.femaleButton)

    elseif currentPage == "select" then
        widgets.skinList = UI:createCustomList({
            x = 10,
            y = 15 + UI:respc(34.425) + UI:respc(35),
            width = panelW - 20,
            height = UI:respc(35) * 7,
            columnFont = FontManager.loadedFonts.Roboto,
            columnFontScale = 0.9,
            itemFontScale = 0.75,
            columns = {
                {text = "Ruha", size = 0.7, itemAlign = "left", columnAlign = "left"},
                {text = "Ár ($)", size = 0.3, itemAlign = "right", columnAlign = "right"},
            },
            items = {},
            itemHeight = UI:respc(35),
            visibleItems = 8,
            scrollOffset = 2,
            enableScrollbar = true
        })
        UI:addChild(widgets.panel, widgets.skinList)

    end
    showCursor(true)
end

function Panel.hide()
	if not isVisible then
		return
	end
    isVisible = false

    setElementModel(localPlayer, oldModel)

	UI:removeChild(widgets.panel)
	showCursor(false)
end

addCommandHandler("sp", function()
    Panel.show()
end)

local function processSkinList(sex, id, newData)
	if not isVisible then
		return
	end

	local list = {}

    for k, v in pairs(availableSkins[sex]) do
        --local data = v

        --if i == id then
        --    data = newData
        --end

        table.insert(list, {
            v[1],
            v[2],
            data = {k, v}
        })
    end

	UI:setItems(widgets.skinList, list)
	list = nil
end

local function createSelectButton()

    if widgets.selectButton then
        UI:removeChild(widgets.panel, widgets.selectButton)
    end

    widgets.selectButton = UI:createCustomButton({
        x = 10,
        y = (panelH - (UI:respc(40) + UI:respc(10)) * 1),
        width = panelW - 20,
        height = UI:respc(40),
        color = {50, 179, 239, 175},
        text = "Kiválaszt",
        font = FontManager.loadedFonts.RobotoL16,
        rounded = true
    })
    UI:addChild(widgets.panel, widgets.selectButton)
end

addEvent("sarpUI.click", false)
addEventHandler("sarpUI.click", resourceRoot, function (widget, button)
	if button == "left" then
		if widget == widgets.closeButton then
            changePanel("main")
            activeItem = nil
			Panel.hide()
        elseif widget == widgets.maleButton then
            changePanel("select")
			processSkinList("male")
        elseif widget == widgets.femaleButton then
            changePanel("select")
            processSkinList("female")
        elseif widget == widgets.skinList then
            local hoveredItem = UI:getHoveredItem(widget)

            if hoveredItem then
                local items = UI:getItems(widget)

				UI:setActiveItem(widget, hoveredItem)
                activeItem = items[hoveredItem].data
                
                --outputChatBox(activeItem[1] .. " " .. activeItem[2][1] .. " " .. activeItem[2][2])

                setElementModel(localPlayer, activeItem[1])

                createSelectButton()
            end
        elseif widget == widgets.selectButton then
            exports.sarp_alert:showAlert("warning", "Kiválasztottad a ruhádat. Most menj és fizesd ki.", "Ha nem fizeted ki, akkor nem kapod meg a ruhádat.")
            Panel.hide()
		end
	end
end)


function changePanel(panel)
    Panel.hide()
	currentPage = panel
	Panel.show()
end

local shopAssistant = {}
local shopMarker = {}

function createSkinShop(interiorID)
    local myInterior = getElementInterior(localPlayer)
    if myInterior == interiorID then
        for k, v in ipairs(shopAssistants[myInterior]) do
            local aX, aY, aZ, aR, aSkin, aName = v[1], v[2], v[3], v[4], v[5], v[6]
            shopAssistant[k] = createPed(aSkin, aX, aY, aZ, aR)
            setElementModel(shopAssistant[k], aSkin)
            setElementData(shopAssistant[k], "invulnerable", true)
            setElementData(shopAssistant[k], "visibleName", aName)
            setElementData(shopAssistant[k], "pedNameType", "Eladó")

            setElementInterior(shopAssistant[k], myInterior)
            setElementFrozen(shopAssistant[k], true)
            setElementDimension(shopAssistant[k], getElementDimension(localPlayer))

            setPedAnimation(shopAssistant[k], "int_shop", "shop_loop", -1, true, false, false, false)
        end

        for k, v in ipairs(shopMarkers[myInterior]) do
            local mX, mY, mZ = v[1], v[2], v[3]
            shopMarker[k] = createMarker(mX, mY, mZ - 1, "cylinder", 1, 50, 179, 239, 175)

            setElementInterior(shopMarker[k], myInterior)
            setElementDimension(shopMarker[k], getElementDimension(localPlayer))
        end
    end
end

addEventHandler("onClientInteriorChange", root, function(interior)
    if availableShopInteriors[interior] then
        createSkinShop(interior)
    end
end)

addEventHandler("onClientMarkerHit", root, function(hitPlayer)
    --for k, v in pairs(availableShopInteriors) do
    --    if k == getElementInterior(localPlayer) then
            if hitPlayer == localPlayer then
                for i = 1, #shopMarker do 
                    local data = shopMarker[i]
                    if data == source then
                        Panel.show()
                    end
                end
            end
    --    end
    --end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if state == "down" then
        if clickedElement then

            for i = 1, #shopAssistant do 
                local data = shopAssistant[i]
                if data == clickedElement then
                    if activeItem then
                        triggerServerEvent("sarp_skinshopS:buySkin", localPlayer, activeItem[1], activeItem[2][2], localPlayer)
                    else
                        exports.sarp_alert:showAlert("error", "Nem választottál magadnak ruházatot")
                    end
                end
            end
        end
    end
end)

--[[

function updateInfo(success, balance, number)	
	if success then
		changePanel("manage")
	else
		outputChatBox("Nem sikerült belépni")
	end
end
registerEvent("sarp_bankC:updateInfo", root, updateInfo)

function updateBalance()
    UI:setText(widgets.bankBalance, "Egyenleg: " .. getElementData(localPlayer, "char.bankmoney") .. "$")
end
registerEvent("sarp_bankC:updateBalance", root, updateBalance)


addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if clickedElement then
        if getElementData(clickedElement, "atm.id") then
            if exports.sarp_core:inDistance3D(localPlayer, clickedElement, 1) then
                Panel.show()
            end
        end
    end
end)]]