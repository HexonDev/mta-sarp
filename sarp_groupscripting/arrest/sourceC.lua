local screenX, screenY = guiGetScreenSize()
local UI = exports.sarp_ui
local isVisible = false
local widgets = {}
local Arrest = {}

local panelW, panelH = UI:respc(390), UI:respc(600)



Arrest.Show = function()

    if not exports.sarp_groups:isPlayerHavePermission(localPlayer, "jail") then
        exports.sarp_alert:showAlert("error", "Nincs engedélyed a parancs használatához")
        return
    end

	if isVisible then
		return
    end

    local dim = getElementDimension(localPlayer)
    if dim ~= 0 then
        local px, py, pz = getElementPosition(localPlayer) 
        if not (getDistanceBetweenPoints3D(arrestPoints[dim][1], arrestPoints[dim][2], arrestPoints[dim][3], px, py, pz) <= 7) then
            exports.sarp_alert:showAlert("error", "Nem vagy letartóztatási hely közelében.")
            return
        end
    end

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
		text = "Letartóztatás",
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

  widgets.playerLabel = UI:createCustomLabel({
    x = respc(10),
    y = respc(60),
    width = panelW - respc(20),
    height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Játékos:",
  })
  UI:addChild(widgets.panel, widgets.playerLabel)

  widgets.playerInput = UI:createCustomInput({
    x = respc(10),
    y = respc(105),
    width = panelW - respc(20),
    height = respc(40),
    font = fonts.Roboto14,
    maxLength = respc(48),
    placeholder = "Játékos ID/névrészlet",
  })
  UI:addChild(widgets.panel, widgets.playerInput)

  widgets.reasonLabel = UI:createCustomLabel({
    x = respc(10),
    y = respc(155),
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
    y = respc(195),
    width = panelW - respc(20),
    height = respc(40),
    font = fonts.Roboto14,
    maxLength = respc(48),
    placeholder = "",
  })
  UI:addChild(widgets.panel, widgets.reasonInput)

  --[[widgets.canBailLabel = UI:createCustomLabel({
    x = respc(50),
    y = respc(250),
    width = panelW - respc(20),
    height = respc(40),
		color = tocolor(255, 255, 255),
		font = fonts.Roboto14,
		alignX = "left",
		alignY = "center",
		text = "Óvadék ellenében távozhat ($):",
  })
  UI:addChild(widgets.panel, widgets.canBailLabel)

  widgets.canBailCheckbox = UI:createCustomCheckbox({
      x = respc(10),
      y = respc(250),
      width = respc(30),
      height = respc(30),
      --color = {50, 179, 239},
      rounded = false,
      state = false
  })
  UI:addChild(widgets.panel, widgets.canBailCheckbox)
  --UI:setState(widgets.canGetCheckbox, true)

  widgets.bailInput = UI:createCustomInput({
      x = respc(10),
      y = respc(290),
      width = panelW - respc(20),
      height = respc(40),
      font = fonts.Roboto14,
      maxLength = 10,
      regexp = "^[0-9]",
  })
  UI:addChild(widgets.panel, widgets.bailInput)]]

  widgets.timeLabel = UI:createCustomLabel({
    x = respc(10),
    y = respc(340),
    width = panelW - respc(20),
    height = respc(40),
    color = tocolor(255, 255, 255),
    font = fonts.Roboto14,
    alignX = "left",
    alignY = "center",
    text = "Idő (perc):",
    regexp = "^[0-9]",
  })
  UI:addChild(widgets.panel, widgets.timeLabel)

  widgets.timeInput = UI:createCustomInput({
    x = respc(10),
    y = respc(380),
    width = panelW - respc(20),
    height = respc(40),
    font = fonts.Roboto14,
    maxLength = 5,
    regexp = "^[0-9]",
  })
  UI:addChild(widgets.panel, widgets.timeInput)

  widgets.arrestButton = UI:createCustomButton({
    x = respc(10),
    y = panelH - respc(40) - respc(10),
    width = panelW - respc(20),
    height = respc(40),
    text = "Letartóztatás",
    font = fonts.Roboto14,
    color = {7, 112, 196, 125},
  })
  UI:addChild(widgets.panel, widgets.arrestButton)

end
addCommandHandler("arrest", Arrest.Show)

Arrest.Close = function()
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
            Arrest.Close()
        elseif widget == widgets.arrestButton then
            local int = getElementDimension(localPlayer)
            local px, py, pz = getElementPosition(localPlayer)
            if getDistanceBetweenPoints3D(arrestPoints[int][1], arrestPoints[int][2], arrestPoints[int][3], px, py, pz) <= 7 then
                local player = UI:getText(widgets.playerInput)
                local reason = UI:getText(widgets.reasonInput)
                local bailPrice = 0
                --local canBail = UI:getState(widgets.canBailCheckbox)
                --if canBail then
                --    bailPrice = tonumber(UI:getText(widgets.bailInput))
                --end
                local canBail = false
                local time = tonumber(UI:getText(widgets.timeInput))

                if utf8.len(reason) < 6 then
                    exports.sarp_alert:showAlert("error", "Az indoknak hosszabbnak kell lennie mint 5 karakter.")
                    return
                end

                if canBail then
                    if utf8.len(UI:getText(widgets.bailInput)) <= 0 or tonumber(UI:getText(widgets.bailInput)) <= 0 then
                        exports.sarp_alert:showAlert("error", "Az óvadéknak nagyobbnak kell lennie mint 0.")
                        return
                    end
                end

                if utf8.len(UI:getText(widgets.timeInput)) <= 0 or time <= 0 then
                    exports.sarp_alert:showAlert("error", "Az idő nem lehet 0 vagy negatív szám.")
                    return
                end

                local int = getElementDimension(localPlayer)
                local px, py, pz = getElementPosition(localPlayer) 
            
                triggerServerEvent("sarp_arrestS:arrestPlayer", localPlayer, player, reason, time, canBail, bailPrice)
            else
                exports.sarp_alert:showAlert("error", "Nem vagy letartóztatási hely közelében.")
            end
        end
	end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    --if isVisible then
        if button == "left" and state == "down" then
            if clickedElement and isElement(clickedElement) then
                if getElementData(clickedElement, "ped.type") == 7 then
                    if exports.sarp_core:inDistance3D(getLocalPlayer(), clickedElement, 4) then
                        Arrest.Show()
                    end
                end
            end
        end
    --end
end)
