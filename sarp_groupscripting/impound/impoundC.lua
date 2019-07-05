local screenX, screenY = guiGetScreenSize()
local UI = exports.sarp_ui
local isVisible = false
local widgets = {}
local Impound = {}

Impound.Show = function()
    if not exports.sarp_groups:isPlayerHavePermission(localPlayer, "impoundVehicle") then
        exports.sarp_alert:showAlert("error", "Nincs engedélyed a parancs használatához")
        return
    end

    local panelW, panelH = UI:respc(600), UI:respc(500)
    --print("asd")
	if isVisible then
		return
    end
    --print("asd2")
    showCursor(true)

	isVisible = true

	widgets.panel = UI:createCustomPanel({
		x = (screenX - panelW) / 2,
		y = (screenY - panelH) / 2,
		width = panelW,
		height = panelH,
        --rounded = true
        --enableAnimation = true
	})
	UI:addChild(widgets.panel)

	widgets.logo = UI:createImage({
		x = 5,
		y = 5,
		width = respc(403 * 0.075),
		height = respc(459 * 0.075),
		texture = ":sarp_assets/images/sarplogo_big.png",
		color = tocolor(50, 179, 239),
		floorMode = true
	})
    UI:addChild(widgets.panel, widgets.logo)

	widgets.headerTitle = UI:createCustomLabel({
		x = 10 + respc(30.225),
		y = 5,
		width = 0,
		height = respc(34.425),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Lefoglalás",
	})
	UI:addChild(widgets.panel, widgets.headerTitle)

	widgets.closeButton = UI:createCustomImageButton({
		x = panelW - respc(24) - 10,
		y = 5 + (respc(34.425) - respc(24)) / 2,
		width = respc(24),
		height = respc(24),
		hoverColor = tocolor(215, 89, 89),
		texture = ":sarp_assets/images/cross_x.png"
	})
    UI:addChild(widgets.panel, widgets.closeButton)

    --[-----------------------------------------------------]--

    widgets.reasonLabel = UI:createCustomLabel({
        x = respc(10),
        y = respc(60),
        width = panelW - respc(20),
        height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Indok:",
    })
    UI:addChild(widgets.panel, widgets.reasonLabel)

    widgets.reasonInput = UI:createCustomInput({
        x = respc(10),
        y = respc(105),
        width = panelW - respc(20),
        height = respc(40),
        font = fonts.Roboto14,
        maxLength = respc(48),
    })
    UI:addChild(widgets.panel, widgets.reasonInput)

    widgets.priceLabel = UI:createCustomLabel({
        x = respc(10),
        y = respc(150),
        width = panelW - respc(20),
        height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Kiváltási ár ($):",
    })
    UI:addChild(widgets.panel, widgets.priceLabel)

    widgets.priceInput = UI:createCustomInput({
        x = respc(10),
        y = respc(195),
        width = panelW - respc(20),
        height = respc(40),
        font = fonts.Roboto14,
        maxLength = respc(48),
        regexp = "^[0-9]",
    })
    UI:addChild(widgets.panel, widgets.priceInput)

    widgets.canGetLabel = UI:createCustomLabel({
        x = respc(50),
        y = respc(250),
        width = panelW - respc(20),
        height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Kiváltható",
    })
    UI:addChild(widgets.panel, widgets.canGetLabel)

    widgets.canGetCheckbox = UI:createCustomCheckbox({
        x = respc(10),
        y = respc(250),
        width = respc(30),
        height = respc(30),
        --color = {50, 179, 239},
        rounded = false,
        state = true
    })
    UI:addChild(widgets.panel, widgets.canGetCheckbox)
    UI:setState(widgets.canGetCheckbox, true)

    widgets.timeLabel = UI:createCustomLabel({
        x = respc(10),
        y = respc(290),
        width = panelW - respc(20),
        height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Idő (nap, 0 a határozatlan időhöz):",
    })
    UI:addChild(widgets.panel, widgets.timeLabel)

    widgets.timeInput = UI:createCustomInput({
        x = respc(10),
        y = respc(330),
        width = panelW - respc(20),
        height = respc(40),
        font = fonts.Roboto14,
        maxLength = 3,
        regexp = "^[0-9]",
    })
    UI:addChild(widgets.panel, widgets.timeInput)

    widgets.impoundButton = UI:createCustomButton({
        x = respc(10),
        y = panelH - respc(40) - respc(10),
        width = panelW - respc(20),
        height = respc(40),
        text = "Lefoglalás",
        font = fonts.Roboto14,
        color = {7, 112, 196, 125},
    })
    UI:addChild(widgets.panel, widgets.impoundButton)
end

addCommandHandler("lefoglal", Impound.Show)

Impound.Close = function()
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
            Impound.Close()
        elseif widget == widgets.impoundButton then
            --reason, price, canGet, time
            if isPedInVehicle(localPlayer) then
                local reason = UI:getText(widgets.reasonInput)
                local price = 0
                local canGet = UI:getState(widgets.canGetCheckbox)
                if canGet then
                    price = tonumber(UI:getText(widgets.priceInput))
                end
                local time = tonumber(UI:getText(widgets.timeInput))

                if utf8.len(reason) < 6 then
                    exports.sarp_alert:showAlert("error", "Az indoknak hosszabbnak kell lennie mint 5 karakter.")
                    return
                end

                if canGet then
                    if utf8.len(UI:getText(widgets.priceInput)) <= 0 or tonumber(UI:getText(widgets.priceInput)) <= 0 then
                        exports.sarp_alert:showAlert("error", "A kiváltási árnak nagyobbnak kell lennie mint 0.")
                        return
                    end
                end

                if utf8.len(UI:getText(widgets.timeInput)) <= 0 or time < 0 then
                    exports.sarp_alert:showAlert("error", "Az idő csak 0 és pozitív szám lehet.")
                    return
                end

                local impoundedDate = getRealTime().timestamp
                local expireDate = getRealTime().timestamp + (86400 * time)
                local impoundedBy = getElementData(localPlayer, "char.ID")

                --outputChatBox(reason .. " :: " .. price .. " :: " .. tostring(canGet) .. " :: " .. time .. " :: " .. impoundedDate .. " :: " .. expireDate .. " :: " .. impoundedBy .. " :: ")
                triggerServerEvent("sarp_impoundS:impoundVehicle", getPedOccupiedVehicle(localPlayer), localPlayer, getPedOccupiedVehicle(localPlayer), reason, price, canGet, impoundedDate, expireDate, impoundedBy)
                Impound.Close()
            end
        end
	end
end)