local Panel = {}

local UI = exports.sarp_ui
addEventHandler("onInterfaceStarted", root, function ()
	UI = exports.sarp_ui
end)

local widgets = {}

local screenX, screenY = guiGetScreenSize()


local isVisible = false
local currentPanel = "manage"


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
end)

function Panel.show()

	local panelW, panelH = UI:respc(500), UI:respc(200)

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
    

	local headerText = "Banki bejelentkezés"
	if currentPanel == "manage" then
		headerText = "Számla kezelés"
	elseif currentPanel == "transfer" then
		headerText = "Pénz utalás"
	elseif currentPanel == "deposit" then
		headerText = "Pénz letét"
	elseif currentPanel == "withdraw" then
		headerText = "Pénz kivétel"
	elseif currentPanel == "change" then
		headerText = "PIN megváltozatása"
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
		text = headerText,
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

	if currentPanel == "login" then
		
		widgets.passwordInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(90),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "PIN kód",
			masked = true,
			maxLength = 4,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.passwordInput)

		widgets.nextButton = UI:createCustomButton({
			x = UI:respc(100),
			y = UI:respc(150),
			width = UI:respc(300),
			height = UI:respc(40),
			text = "Tovább",
            font = FontManager.loadedFonts.RobotoL16,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.nextButton)
	elseif currentPanel == "withdraw" then
		widgets.withdrawInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(90),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "Összeg",
			maxLength = 7,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.withdrawInput)

		widgets.outButton = UI:createCustomButton({
			x = UI:respc(100),
			y = UI:respc(150),
			width = UI:respc(300),
			height = UI:respc(40),
			text = "Tovább",
            font = FontManager.loadedFonts.RobotoL16,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.outButton)

	elseif currentPanel == "deposit" then
		widgets.depositInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(90),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "Összeg",
			maxLength = 7,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.depositInput)

		widgets.inButton = UI:createCustomButton({
			x = UI:respc(100),
			y = UI:respc(150),
			width = UI:respc(300),
			height = UI:respc(40),
			text = "Tovább",
            font = FontManager.loadedFonts.RobotoL16,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.inButton)

	elseif currentPanel == "change" then
		widgets.changeInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(90),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "Új PIN kód",
			maxLength = 4,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.changeInput)

		widgets.changeButton = UI:createCustomButton({
			x = UI:respc(100),
			y = UI:respc(150),
			width = UI:respc(300),
			height = UI:respc(40),
			text = "Tovább",
            font = FontManager.loadedFonts.RobotoL16,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.changeButton)

	elseif currentPanel == "transfer" then
		widgets.banknumberInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(70),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "Bankszámla szám",
			maxLength = 12,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.banknumberInput)

		widgets.amountInput = UI:createCustomInput({
			x = UI:respc(50),
			y = UI:respc(70 + 30 + 10),
			width = UI:respc(400),
			height = UI:respc(30),
			font = FontManager.loadedFonts.Roboto,
			placeholder = "Összeg",
			maxLength = 7,
			regexp = "^[0-9]",
		})
		UI:addChild(widgets.panel, widgets.amountInput)

		widgets.moneytransferButton = UI:createCustomButton({
			x = UI:respc(100),
			y = UI:respc(150),
			width = UI:respc(300),
			height = UI:respc(40),
			--color = button[3],
			text = "Tovább",
            font = FontManager.loadedFonts.RobotoL16,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.moneytransferButton)

	elseif currentPanel == "manage" then
		widgets.withdrawButton = UI:createCustomButton({
			x = UI:respc(75),
			y = UI:respc(70),
			width = UI:respc(160),
			height = UI:respc(40),
			text = "Pénz kivétel",
            font = FontManager.loadedFonts.Roboto11,
            color = {7, 112, 196, 125},
			--rounded = true
		})
		UI:addChild(widgets.panel, widgets.withdrawButton)

		--[[widgets.transferButton = UI:createCustomButton({
			x = UI:respc(75),
			y = UI:respc(120),
			width = UI:respc(160),
			height = UI:respc(40),
			text = "Pénz utalás",
			font = FontManager.loadedFonts.Roboto11,
			rounded = true
		})
		UI:addChild(widgets.panel, widgets.transferButton)]]--

		widgets.depositButton = UI:createCustomButton({
			x = UI:respc(75 + 160 + 40),
			y = UI:respc(70),
			width = UI:respc(160),
			height = UI:respc(40),
			text = "Pénz letétel",
            font = FontManager.loadedFonts.Roboto11,
            color = {7, 112, 196, 125},
			--rounded = true
		})
        UI:addChild(widgets.panel, widgets.depositButton)
        
        widgets.bankBalance = UI:createCustomLabel({
            x = panelW / 2,
            y = UI:respc(150),
            width = 0,
            height = UI:respc(34),
            color = tocolor(255, 255, 255),
            font = FontManager.loadedFonts.Roboto,
            alignX = "center",
            alignY = "center",
            text = "Egyenleg: " .. getElementData(localPlayer, "char.bankMoney") .. "$",
        })
        UI:addChild(widgets.panel, widgets.bankBalance)

		--[[widgets.pinButton = UI:createCustomButton({
			x = UI:respc(75 + 160 + 40),
			y = UI:respc(120),
			width = UI:respc(160),
			height = UI:respc(40),
			text = "PIN megváltoztatása",
			font = FontManager.loadedFonts.Roboto11,
			rounded = true
		})
		UI:addChild(widgets.panel, widgets.pinButton)]]--

	end

end

function Panel.hide()
	if not isVisible then
		return
	end
	isVisible = false

	UI:removeChild(widgets.panel)
	showCursor(false)
end

addEvent("sarpUI.click", false)
addEventHandler("sarpUI.click", resourceRoot, function (widget, button)
	if button == "left" then
		if widget == widgets.closeButton then
			changePanel("manage")
			Panel.hide()
		elseif widget == widgets.nextButton then

			triggerServerEvent("sarp_bankS:loadPlayerBankAccount", root, localPlayer, tonumber(UI:getText(widgets.passwordInput)))
		elseif widget == widgets.withdrawButton then
			changePanel("withdraw")
		elseif widget == widgets.depositButton then
			changePanel("deposit")
		--elseif widget == widgets.pinButton then
	    --	changePanel("change")
		--elseif widget == widgets.transferButton then
		--	changePanel("transfer")
		elseif widget == widgets.outButton then
			local num = tonumber(UI:getText(widgets.withdrawInput)) or 0
			if num > 0 then
                triggerServerEvent("sarp_bankS:takePlayerBankMoney", localPlayer, localPlayer, num)
                UI:setText(widgets.bankBalance, "Egyenleg: " .. getElementData(localPlayer, "char.bankMoney") .. "$")
			else
				exports.sarp_hud:showAlert("error", "Az összegnek nagyobbnak kell", "lennie, mint 0")
			end
			changePanel("manage")
		elseif widget == widgets.inButton then
			local num = tonumber(UI:getText(widgets.depositInput)) or 0
			if num > 0 then
                triggerServerEvent("sarp_bankS:givePlayerBankMoney", localPlayer, localPlayer, num)
                UI:setText(widgets.bankBalance, "Egyenleg: " .. getElementData(localPlayer, "char.bankMoney") .. "$")
			else
                exports.sarp_hud:showAlert("error", "Az összegnek nagyobbnak kell", "lennie, mint 0")
			end
			changePanel("manage")
		elseif widget == widgets.changeButton then
			local num = tonumber(UI:getText(widgets.changeInput)) or 0
			if num > 0 and string.len(UI:getText(widgets.changeInput)) == 4 then
			else
				--outputChatBox("Az PIN kódnak nagyobbnak kell lennie mint 0, és 4 számjegynek kell lennie.")
			end
			changePanel("manage")
		elseif widget == widgets.moneytransferButton then
			local num = tonumber(UI:getText(widgets.amountInput)) or 0
			local num2 = tonumber(UI:getText(widgets.banknumberInput)) or 0
			if string.len(UI:getText(widgets.banknumberInput)) == 12 then
				if num > 0 then

				else
					--outputChatBox("Az összegnek kódnak nagyobbnak kell lennie mint 0.")
				end
			else
				--outputChatBox("A számlaszámnak 12 számjegynek kell lennie.")
			end
			changePanel("manage")
		end
	end
end)

function changePanel(panel)
    Panel.hide()
	currentPanel = panel
	Panel.show()
end

function updateInfo(success, balance, number)	
	if success then
		changePanel("manage")
	else
		outputChatBox("Nem sikerült belépni")
	end
end
registerEvent("sarp_bankC:updateInfo", root, updateInfo)

function updateBalance()
    UI:setText(widgets.bankBalance, "Egyenleg: " .. getElementData(localPlayer, "char.bankMoney") .. "$")
end
registerEvent("sarp_bankC:updateBalance", root, updateBalance)


addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    if button == "right" and state == "up" and clickedElement then
        if getElementType(clickedElement) == "object" and getElementData(clickedElement, "atm.id") then
            if exports.sarp_core:inDistance3D(localPlayer, clickedElement, 1) then
                Panel.show()
            end
        end
    end
end)