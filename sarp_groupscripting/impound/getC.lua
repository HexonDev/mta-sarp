local screenX, screenY = guiGetScreenSize()
local UI = exports.sarp_ui
local isVisible = false
local widgets = {}
local Get = {}

local activeItem = nil

function getImpoundedVehicles()
    local impoundedVehicles = {}
    local charID = getElementData(localPlayer, "char.ID")
    for k, v in ipairs(getElementsByType("vehicle")) do
        if getElementData(v, "vehicle.owner") == charID and getElementData(v, "vehicle.impound") then
            table.insert(impoundedVehicles, v)
        end
    end

    return impoundedVehicles
end

local function processImpoundedVehicles(id, newData)
    if not isVisible then
		return
	end

    local impoundedVehicles = getImpoundedVehicles()
	local list = {}

    for i = 1, #impoundedVehicles do
        local vehicle = impoundedVehicles[i]

        if getElementData(vehicle, "vehicle.impound") then
            local data = split(getElementData(vehicle, "vehicle.impound"), "/")
            -- reason .. "/" .. price .. "/" .. canGet .. "/" .. impoundedDate .. "/" .. expiredDate .. "/" .. impoundedBy


            if i == id then
                data = newData
            end
    

        
            table.insert(list, {
                getVehiclePlateText(vehicle),
                --data[1],
                --data[2],
                data = {vehicle, data}
            })
        end
	end

	UI:setItems(widgets.vehiclesList, list)
	list = nil
end

local panelW, panelH = UI:respc(390), UI:respc(600)

Get.Show = function()

	if isVisible then
		return
    end

    showCursor(true)

	isVisible = true

	widgets.panel = UI:createCustomPanel({
		x = (screenX - panelW) / 2,
		y = (screenY - panelH) / 2,
		width = panelW,
		height = panelH,
        --rounded = true
        enableAnimation = true
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
		text = "Jármű kiváltás",
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

    widgets.vehiclesList = UI:createCustomList({
		x = 10,
		y = 15 + respc(34.425) + respc(35),
		width = panelW - 20,
		height = respc(35) * 7,
		columnFont = fonts.Roboto14,
		columnFontScale = 0.9,
		itemFontScale = 0.75,
		columns = {
			{text = "Jármű rendszám", size = 0.3, itemAlign = "left", columnAlign = "left"},
            --{text = "Indok", size = 0.4, itemAlign = "left", columnAlign = "left"},
            --{text = "Kiváltási ár ($)", size = 0.3, itemAlign = "right", columnAlign = "right"},
		},
		items = {},
		itemHeight = respc(35),
		visibleItems = 8,
		scrollOffset = 2,
		enableScrollbar = true
	})
    UI:addChild(widgets.panel, widgets.vehiclesList)
    
    processImpoundedVehicles()
end

Get.Close = function()
    if not isVisible then
		return
	end
	isVisible = false

	UI:removeChild(widgets.panel)
	showCursor(false)
end

Get.ShowImpoundData = function(data)
    local vehicle = data[1]
    local info = data[2]

    -- reason .. "/" .. price .. "/" .. canGet .. "/" .. impoundedDate .. "/" .. expiredDate .. "/" .. impoundedBy

    local canGet = "Nem"
    if info[3] == "true" then
        canGet = "Igen"
    end

    local expireTime = getRealTime(info[5])
    local expireDate = string.format("%04d. %02d. %02d. %02d:%02d", expireTime.year + 1900, expireTime.month + 1, expireTime.monthday, expireTime.hour, expireTime.minute) .. "-ig"
    if info[4] == info[5] then
        expireDate = "Határozatlan időre"
    end 

    local impoundedTime = getRealTime(info[4])
    local impoundedDate = string.format("%04d. %02d. %02d. %02d:%02d", impoundedTime.year + 1900, impoundedTime.month + 1, impoundedTime.monthday, impoundedTime.hour, impoundedTime.minute)

    local processedInfo = {}
    processedInfo["Lefoglalás ideje"] = impoundedDate
    processedInfo["Lefoglalva"] = expireDate .. ""
    processedInfo["Kiváltható"] = canGet
    processedInfo["Indok"] = info[1]
    if tonumber(info[2]) > 0 and info[3] then 
        processedInfo["Kiváltási ár ($)"] = info[2]
    end

    local i = 0
    for k, v in pairs(processedInfo) do
    
        widgets["label"] = UI:createCustomLabel({
            x = 10,
            y = respc(375) + (respc(34.425) * i),
            width = 0,
            height = respc(34.425),
            color = tocolor(255, 255, 255),
            font = fonts.Roboto14,
            alignX = "left",
            alignY = "center",
            text = k .. ": " .. v,
        })
        UI:addChild(widgets.panel, widgets["label"])
        i = i + 1
    end

    if info[3] and tonumber(info[2]) > 0 then
        widgets.getButton = UI:createCustomButton({
            x = respc(10),
            y = panelH - respc(40) - respc(10),
            width = panelW - respc(20),
            height = respc(40),
            text = "Kiváltás",
            font = fonts.Roboto14,
            color = {7, 112, 196, 125},
        })
        UI:addChild(widgets.panel, widgets.getButton)
    end

    selectedItem = data
end

addEvent("sarpUI.click", false)
addEventHandler("sarpUI.click", resourceRoot, function (widget, button)
	if button == "left" then
		if widget == widgets.closeButton then
            Get.Close()
        elseif widget == widgets.vehiclesList then
            local hoveredItem = UI:getHoveredItem(widget)

			if hoveredItem then
				local items = UI:getItems(widget)

				UI:setActiveItem(widget, hoveredItem)
				activeItem = hoveredItem
                
				if items[hoveredItem] then
                    Get.ShowImpoundData(items[hoveredItem].data)
                    
				end
            end
        elseif widget == widgets.getButton then
            --print(selectedItem[2][2])
            triggerServerEvent("sarp_impoundS:getVehicle", selectedItem[1], localPlayer, selectedItem[1], tonumber(selectedItem[2][2]))
            Get.Close()
        end
	end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
    --if isVisible then
        if button == "left" and state == "down" then
            if clickedElement and isElement(clickedElement) then
                if getElementData(clickedElement, "ped.type") == 6 then
                    if exports.sarp_core:inDistance3D(getLocalPlayer(), clickedElement, 4) then
                        Get.Show()
                    end
                end
            end
        end
    --end
end)