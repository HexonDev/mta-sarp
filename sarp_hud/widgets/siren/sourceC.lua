local panelSizeX = respc(350)
local panelSizeY = respc(164)

local panelPosX = screenX / 2 - panelSizeX / 2
local panelPosY = screenY - panelSizeY - 86

function getSirenPanelPosition()
	return panelPosX, panelPosY
end

function setSirenPanelPosition(x, y)
	panelPosX, panelPosY = x, y
end

local buttons = {}
local activeButton = false

local allowedVehicles = {}
local activeControls = {
	sound = false,
	light = false,
	strobe = false
}

local controlPictures = {
	light = "lights",
	strobe = "lights",
	sound = "sound"
}

local currentUnitNumber = "Ismeretlen"
local currentStateOfGPS = false
local canUseSirenPanel = false

local draggingPanel = false

addEventHandler("onClientResourceStart", getRootElement(),
	function(startedRes)
		if startedRes == getThisResource() then
			local groupscripting = getResourceFromName("sarp_groupscripting")

			if groupscripting and getResourceState(groupscripting) == "running" then
				allowedVehicles = exports.sarp_groupscripting:getAllowedVehicles()
			end

			if occupiedVehicle then
				currentUnitNumber = getElementData(occupiedVehicle, "siren.unit") or "Ismeretlen"
				currentStateOfGPS = getElementData(occupiedVehicle, "siren.gps")
				canUseSirenPanel = getElementData(occupiedVehicle, "vehicle.sirenPanel")
			end
		elseif getResourceName(startedRes) == "sarp_groupscripting" then
			allowedVehicles = exports.sarp_groupscripting:getAllowedVehicles()
		end
	end)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if occupiedVehicle and source == occupiedVehicle and (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) then
			if dataName == "siren.unit" then
				currentUnitNumber = getElementData(occupiedVehicle, "siren.unit") or "Ismeretlen"
			elseif dataName == "siren.status" then
				currentStateOfGPS = getElementData(occupiedVehicle, "siren.status")
			elseif dataName == "vehicle.siren" then
				activeControls = getElementData(source, "vehicle.siren") or {sound = false, light = false, strobe = false}
			elseif dataName == "vehicle.sirenPanel" then
				canUseSirenPanel = getElementData(occupiedVehicle, "vehicle.sirenPanel")
			end
		end
	end
)

addEventHandler("onClientPlayerVehicleEnter", getRootElement(),
	function (vehicle, seat)
		if source == localPlayer and (seat == 0 or seat == 1) then
			currentUnitNumber = getElementData(vehicle, "siren.unit") or "Ismeretlen"
			currentStateOfGPS = getElementData(vehicle, "siren.status")
			activeControls = getElementData(vehicle, "vehicle.siren") or {sound = false, light = false, strobe = false}
			canUseSirenPanel = getElementData(vehicle, "vehicle.sirenPanel")
		end
	end
)

function drawControlButton(type, id)
	if activeControls[type] == id then
		dxDrawImage(panelPosX + respc(51) * (id - 1), panelPosY, panelSizeX, panelSizeY, "widgets/siren/files/" .. controlPictures[type] .. "_on.png")
	elseif activeControls[type] ~= id then
		dxDrawImage(panelPosX + respc(51) * (id - 1), panelPosY, panelSizeX, panelSizeY, "widgets/siren/files/" .. controlPictures[type] .. "_off.png")
	end
end

local statusCodes = {
	[1] = "Inaktív",
	[2] = "Elérhető",
	[3] = "Erősítés"
}

addEventHandler("onClientRender", getRootElement(),
	function ()
		if occupiedVehicle and isElement(occupiedVehicle) and (getPedOccupiedVehicleSeat(localPlayer) == 0 or getPedOccupiedVehicleSeat(localPlayer) == 1) then
			local vehicleModel = getElementModel(occupiedVehicle)

			if allowedVehicles[vehicleModel] or canUseSirenPanel then
				local absX, absY = getCursorPosition()

				buttons = {}

				if isCursorShowing() then
					absX = absX * screenX
					absY = absY * screenY

					if getKeyState("mouse1") then
						if absX >= panelPosX and absX <= panelPosX + panelSizeX and absY >= panelPosY and absY <= panelPosY + panelSizeY and not activeButton and not draggingPanel then
							draggingPanel = {absX, absY, panelPosX, panelPosY}
						end

						if draggingPanel then
							panelPosX = absX - draggingPanel[1] + draggingPanel[3]
							panelPosY = absY - draggingPanel[2] + draggingPanel[4]
						end
					elseif draggingPanel then
						draggingPanel = false
					end
				else
					absX, absY = -1, -1

					if draggingPanel then
						draggingPanel = false
					end
				end

				dxDrawImage(panelPosX, panelPosY, panelSizeX, panelSizeY, "widgets/siren/files/panel.png")

				drawControlButton("light", 1)
				drawControlButton("light", 2)
				drawControlButton("strobe", 3)

				drawControlButton("sound", 1)
				drawControlButton("sound", 2)
				drawControlButton("sound", 3)

				dxDrawImage(panelPosX, panelPosY, panelSizeX, panelSizeY, "widgets/siren/files/settings.png")

				dxDrawText("Egység: " .. currentUnitNumber, panelPosX + respc(180), panelPosY + respc(38), 0, 0, tocolor(0, 0, 0, 200), 1, LEDCalculator8)
				dxDrawText("Státusz: " .. statusCodes[currentStateOfGPS], panelPosX + respc(180), panelPosY + respc(38) + LEDCalculator8H, 0, 0, tocolor(0, 0, 0, 200), 1, LEDCalculator8)

				buttons["sound:1"] = {panelPosX + respc(30), panelPosY + respc(30), respc(32.63), respc(32.50)}
				buttons["sound:2"] = {panelPosX + respc(81), panelPosY + respc(30), respc(32.63), respc(32.50)}
				buttons["sound:3"] = {panelPosX + respc(129), panelPosY + respc(30), respc(32.63), respc(32.50)}

				buttons["lights:1"] = {panelPosX + respc(30), panelPosY + respc(77), respc(32.63), respc(32.50)}
				buttons["lights:2"] = {panelPosX + respc(81), panelPosY + respc(77), respc(32.63), respc(32.50)}
				buttons["lights:3"] = {panelPosX + respc(129), panelPosY + respc(77), respc(32.63), respc(32.50)}

				buttons["settings"] = {panelPosX + respc(30), panelPosY + respc(118), respc(135), respc(19)}

				activeButton = false

				if isCursorShowing() and not renderData.editorActive then
					for k, v in pairs(buttons) do
						if absX >= v[1] and absX <= v[1] + v[3] and absY >= v[2] and absY <= v[2] + v[4] then
							activeButton = k
							break
						end
					end
				end
			end
		end
	end
)

addEventHandler("onClientClick", getRootElement(),
	function (button, state)
		if state == "down" then
			if activeButton and occupiedVehicle then
				local selected = split(activeButton, ":")

				if activeButton == "settings" then
					triggerEvent("sarp_sirenC:showSettings", localPlayer)
				elseif selected[1] == "sound" then
					local soundID = tonumber(selected[2])

					if activeControls.sound == soundID then
						activeControls.sound = false
						triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, false)
					else
						activeControls.sound = soundID
						triggerServerEvent("sarp_sirenS:toggleSirenSound", localPlayer, soundID)
					end
				elseif selected[1] == "lights" then
					local lightID = tonumber(selected[2])

					if activeControls.light == lightID or activeControls.strobe == lightID then
						if lightID == 3 then
							activeControls.strobe = false
							setElementData(occupiedVehicle, "vehicle.siren", activeControls)
							return
						end

						activeControls.light = false
						triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, false)
					else
						if lightID == 3 then
							activeControls.strobe = lightID
							setElementData(occupiedVehicle, "vehicle.siren", activeControls)
							return
						end

						activeControls.light = lightID
						triggerServerEvent("sarp_sirenS:toggleSirenLights", localPlayer, lightID)
					end
				end

				setElementData(occupiedVehicle, "vehicle.siren", activeControls)
			end
		end
	end
)