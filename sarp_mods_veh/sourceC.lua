pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));addEventHandler("onCoreStarted",root,function(functions) for k,v in ipairs(functions) do _G[v]=nil;end;collectgarbage();pcall(loadstring(base64Decode(exports.sarp_core:getInterfaceElements())));end)

local screenX, screenY = guiGetScreenSize()
local responsiveMultipler = 1

function respc(x)
	return math.ceil(x * responsiveMultipler)
end

local modList = {}
local modContents = {}

local panelState = false

local RobotoFont = false
local RobotoFontLighter = false
local IconsFont = false

local listOffset = 0
local selectedMod = false
local toggableVehs = {}

local lastButtonPress = 0

local downloadNum = 0
local downloadSize = 0
local downloadedSize = 0
local gotInterpolate = 0
local lastCurrent = -1

addEventHandler("onClientResourceStart", getRootElement(),
	function (res)
		if source == getResourceRootElement() then
			responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()
		else
			local sarp_hud = getResourceFromName("sarp_hud")
			if sarp_hud and getResourceState(sarp_hud) == "running" then
				responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()
			end
		end
	end
)

function panelRender()
	local relX, relY = getCursorPosition()

	if relX and relY then
		relX = relX * screenX
		relY = relY * screenY
	end

	buttons = {}

	local sx = respc(1010)
	local sy = respc(400)
	local x = screenX / 2 - sx / 2
	local y = screenY / 2 - sy / 2

	local x2 = x - 10
	local y2 = y - 10
	local sx2 = sx + 20
	local sy2 = sy + 20

	-- ** Háttér
	dxDrawRectangle(x2, y2, sx2, sy2, tocolor(31, 31, 31, 240))

	-- ** Cím
	dxDrawRectangle(x2, y2, sx2, respc(40), tocolor(31, 31, 31, 240))
	dxDrawImage(math.floor(x2 + respc(4)), math.floor(y2 + respc(4)), respc(32), respc(32), ":sarp_hud/files/logo.png", 0, 0, 0, tocolor(50, 179, 239))
	dxDrawText("Jármű modok", x2 + respc(40), y2, 0, y2 + respc(40), tocolor(255, 255, 255), 1, RobotoFontLighter, "left", "center")

	-- ** Kilépés
	local closeTextWidth = dxGetTextWidth("X", 1, RobotoFontLighter)
	local closeTextPosX = x2 + sx2 - closeTextWidth - 5
	local closeColor = tocolor(255, 255, 255)

	if activeButton == "close" then
		closeColor = tocolor(215, 89, 89)
	end

	dxDrawText("X", closeTextPosX, y2, 0, y2 + 30, closeColor, 1, RobotoFontLighter, "left", "center")
	buttons["close"] = {closeTextPosX, y2, closeTextWidth, respc(40)}

	-- ** Oszlop nevek
	local sizeForTableCell = sx / 3

	dxDrawText("Jármű neve", x, y + respc(35), 0, y + respc(70), tocolor(255, 255, 255), 0.75, RobotoFontLighter, "left", "center")
	dxDrawText("Eredeti jármű", x + sizeForTableCell, y + respc(35), 0, y + respc(70), tocolor(255, 255, 255), 0.75, RobotoFontLighter, "left", "center")
	dxDrawText("Állapot", x + sizeForTableCell * 2, y + respc(35), 0, y + respc(70), tocolor(255, 255, 255), 0.75, RobotoFontLighter, "left", "center")
	dxDrawText("Méret", x, y + respc(35), x + sx - respc(5), y + respc(70), tocolor(255, 255, 255), 0.75, RobotoFontLighter, "right", "center")

	-- ** Lista
	local sizeForItem = (sy - respc(80)) / 10

	for k = 1, 9 do
		local v = modList[k + listOffset]
		local y2 = y + respc(40) + sizeForItem * k

		if activeButton == "select:" .. k + listOffset then
			dxDrawRectangle(x - respc(5), y2, sx + respc(10), sizeForItem, tocolor(50, 50, 50, 50))
		elseif k % 2 == 0 then
			dxDrawRectangle(x - respc(5), y2, sx + respc(10), sizeForItem, tocolor(0, 0, 0, 50))
		else
			dxDrawRectangle(x - respc(5), y2, sx + respc(10), sizeForItem, tocolor(0, 0, 0, 80))
		end

		if selectedMod == k + listOffset then
			dxDrawRectangle(x - respc(5), y2, respc(5), sizeForItem, tocolor(50, 179, 239, 180))
			dxDrawRectangle(x, y2, sx, sizeForItem, tocolor(50, 179, 239, 50))
		end

		if v then
			local x2 = x + respc(5)
			local state = "Kikapcsolva"

			if v.state == "notdownloaded" then
				state = "Nincs letöltve"
			elseif v.state == "downloading" then
				state = "Letöltés..."
			elseif v.state == "on" then
				state = "Bekapcsolva"
			end

			dxDrawText(v.customName, x2, y2, 0, y2 + sizeForItem, tocolor(255, 255, 255), 0.7, RobotoFont, "left", "center")
			dxDrawText(v.originalName, x2 + sizeForTableCell, y2, 0, y2 + sizeForItem, tocolor(255, 255, 255), 0.7, RobotoFont, "left", "center")
			dxDrawText(state, x2 + sizeForTableCell * 2, y2, 0, y2 + sizeForItem, tocolor(255, 255, 255), 0.7, RobotoFont, "left", "center")
			dxDrawText(v.size, x2, y2, x + sx - respc(5), y2 + sizeForItem, tocolor(255, 255, 255), 0.7, RobotoFont, "right", "center")

			buttons["select:" .. k + listOffset] = {x - respc(5), y2, sx + respc(10), sizeForItem}
		end
	end

	if #modList > 9 then
		local sizeForScroll = sizeForItem * 9

		dxDrawRectangle(x2 + sx2 - respc(10), y + respc(70), respc(5), sizeForScroll, tocolor(0, 0, 0, 100))

		dxDrawRectangle(x2 + sx2 - respc(10), y + respc(70) + (sizeForScroll / #modList) * math.min(listOffset, #modList - 9), respc(5), (sizeForScroll / #modList) * 9, tocolor(50, 179, 239))
	end

	local downloadAllTextWidth = dxGetTextWidth("Össz. letöltése", 0.6, RobotoFont) + respc(12)
	local deleteAllTextWidth = dxGetTextWidth("Össz. törlése", 0.6, RobotoFont) + respc(12)
	local totalWidth = downloadAllTextWidth + respc(10)

	drawButton("downloadAll", "Össz. letöltése", x, y + sy - respc(30), downloadAllTextWidth, respc(35), 50, 179, 239, 1, RobotoFont, 0.6)
	drawButton("deleteAll", "Össz. törlése", x + totalWidth, y + sy - respc(30), deleteAllTextWidth, respc(35), 200, 50, 50, 1, RobotoFont, 0.6)

	local toggleAllOnTextWidth = dxGetTextWidth("Össz. bekapcsolása", 0.6, RobotoFont) + respc(12)
	local toggleAllOffTextWidth = dxGetTextWidth("Össz. kikapcsolása", 0.6, RobotoFont) + respc(12)

	totalWidth = totalWidth + deleteAllTextWidth + respc(10)
	drawButton("toggleAllOn", "Össz. bekapcsolása", x + totalWidth, y + sy - respc(30), toggleAllOnTextWidth, respc(35), 50, 179, 239, 1, RobotoFont, 0.6)

	totalWidth = totalWidth + toggleAllOnTextWidth + respc(10)
	drawButton("toggleAllOff", "Össz. kikapcsolása", x + totalWidth, y + sy - respc(30), toggleAllOffTextWidth, respc(35), 255, 100, 0, 1, RobotoFont, 0.6)

	if selectedMod then
		local mod = modList[selectedMod]

		if mod then
			if mod.state == "notdownloaded" then
				drawButton("downloadSelected", "Letöltés", x + sx - respc(160), y + sy - respc(30), respc(160), respc(35), 50, 179, 239, 1, RobotoFont, 0.7, "", IconsFont, 0.7)
			elseif mod.state == "downloading" then
			elseif mod.state == "on" then
				drawButton("toggleSelected", "Kikapcsolás", x + sx - respc(330), y + sy - respc(30), respc(160), respc(35), 255, 100, 0, 1, RobotoFont, 0.7, "", IconsFont, 0.7)
				drawButton("deleteSelected", "Törlés", x + sx - respc(160), y + sy - respc(30), respc(160), respc(35), 200, 50, 50, 1, RobotoFont, 0.7, "", IconsFont, 0.7)
			elseif not mod.state or mod.state == "off" then
				drawButton("toggleSelected", "Bekapcsolás", x + sx - respc(330), y + sy - respc(30), respc(160), respc(35), 50, 179, 239, 1, RobotoFont, 0.7, "", IconsFont, 0.7)
				drawButton("deleteSelected", "Törlés", x + sx - respc(160), y + sy - respc(30), respc(160), respc(35), 200, 50, 50, 1, RobotoFont, 0.7, "", IconsFont, 0.7)
			end
		end
	end

	if downloadNum > 0 then
		local current = downloadedSize / downloadSize
		local last = lastCurrent

		if lastCurrent ~= current then
			if not gotInterpolate then
				gotInterpolate = getTickCount()
			else
				local elapsedTime =  getTickCount() - gotInterpolate
				local progress = elapsedTime / 500

				last = interpolateBetween(
					lastCurrent, 0, 0,
					current, 0, 0,
					progress, "OutQuad")

				if progress >= 1 then
					lastCurrent = current
					gotInterpolate = false
				end
			end
		end

		dxDrawText("Letöltés...", x, y + respc(25), 0, 0, tocolor(255, 255, 255), 0.55, RobotoFont, "left", "top")

		local downloadTextWidth = dxGetTextWidth("Letöltés...", 0.55, RobotoFont) + respc(12)
		local sizeText = byte2human(downloadedSize) .. " / " .. byte2human(downloadSize)
		local barSize = sx - downloadTextWidth - dxGetTextWidth(sizeText, 0.55, RobotoFont) - respc(12)

		dxDrawRectangle(x + downloadTextWidth, y + respc(30), barSize, respc(8), tocolor(255, 255, 255, 50))
		dxDrawRectangle(x + downloadTextWidth, y + respc(30), barSize * last, respc(8), tocolor(50, 179, 239))

		dxDrawText(sizeText, x, y + respc(25), x + sx, 0, tocolor(255, 255, 255), 0.55, RobotoFont, "right", "top")
	end

	-- ** Gombok
	activeButton = false

	if relX and relY then
		for k, v in pairs(buttons) do
			if relX >= v[1] and relY >= v[2] and relX <= v[1] + v[3] and relY <= v[2] + v[4] then
				activeButton = k
				break
			end
		end
	end
end

function clickHandler(button, state)
	if button == "left" and state == "down" then
		if activeButton == "close" then
			modsPanelFunc()
		elseif activeButton then
			local selected = split(activeButton, ":")

			if selected[1] == "select" then
				local id = tonumber(selected[2])

				if selectedMod == id then
					selectedMod = false
				else
					selectedMod = id
				end
			elseif selected[1] == "btn" then
				local playerVehicle = getPedOccupiedVehicle(localPlayer)

				if getTickCount() - lastButtonPress < 500 then
					exports.sarp_hud:showInfobox("error", "Ne ilyen gyorsan!")
					return
				else
					lastButtonPress = getTickCount()
				end

				if selected[2] == "downloadAll" then
					downloadNum = 0
					downloadSize = 0
					downloadedSize = 0

					for k, v in pairs(modList) do
						if v.state == "notdownloaded" then
							modList[k].state = "downloading"

							setTimer(
								function()
									if string.find(modContents[v.id], "txd") then
										downloadFile("files/" .. v.id .. ".txd")
									end

									if string.find(modContents[v.id], "dff") then
										downloadFile("files/" .. v.id .. ".dff")
									end
								end,
							1200, 1)

							downloadNum = downloadNum + 1
							downloadSize = downloadSize + v.realSize
						end
					end

					saveToggableVehicles()
				elseif selected[2] == "deleteAll" then
					if isElement(playerVehicle) then
						exports.sarp_hud:showInfobox("error", "Előbb szállj ki a járművedől!")
						return
					end

					for k, v in pairs(modList) do
						engineRestoreModel(v.vehicleModel)

						if fileExists("files/" .. v.id .. ".txd") then
							fileDelete("files/" .. v.id .. ".txd")
						end

						if fileExists("files/" .. v.id .. ".dff") then
							fileDelete("files/" .. v.id .. ".dff")
						end

						modList[k].state = "notdownloaded"
						toggableVehs[tostring(v.vehicleModel)] = nil
					end

					saveToggableVehicles()
				elseif selected[2] == "downloadSelected" then
					downloadNum = 0
					downloadSize = 0
					downloadedSize = 0

					modList[selectedMod].state = "downloading"

					if string.find(modContents[modList[selectedMod].id], "txd") then
						downloadFile("files/" .. modList[selectedMod].id .. ".txd")
					end

					if string.find(modContents[modList[selectedMod].id], "dff") then
						downloadFile("files/" .. modList[selectedMod].id .. ".dff")
					end

					downloadNum = downloadNum + 1
					downloadSize = downloadSize + modList[selectedMod].realSize
				elseif selected[2] == "deleteSelected" then
					if isElement(playerVehicle) and modList[selectedMod].vehicleModel == getElementModel(playerVehicle) then
						exports.sarp_hud:showInfobox("error", "Éppen egy ilyen típusú járműben ülsz!")
						return
					end

					toggableVehs[tostring(modList[selectedMod].vehicleModel)] = nil

					engineRestoreModel(modList[selectedMod].vehicleModel)

					if fileExists("files/" .. modList[selectedMod].id .. ".txd") then
						fileDelete("files/" .. modList[selectedMod].id .. ".txd")
					end

					if fileExists("files/" .. modList[selectedMod].id .. ".dff") then
						fileDelete("files/" .. modList[selectedMod].id .. ".dff")
					end

					modList[selectedMod].state = "notdownloaded"
					saveToggableVehicles()
				elseif selected[2] == "toggleSelected" then
					if isElement(playerVehicle) and modList[selectedMod].vehicleModel == getElementModel(playerVehicle) then
						exports.sarp_hud:showInfobox("error", "Éppen egy ilyen típusú járműben ülsz!")
						return
					end

					if not modList[selectedMod].state or modList[selectedMod].state == "off" then
						modList[selectedMod].state = "off"

						if string.find(modContents[modList[selectedMod].id], "txd") then
							downloadFile("files/" .. modList[selectedMod].id .. ".txd")
						end

						if string.find(modContents[modList[selectedMod].id], "dff") then
							downloadFile("files/" .. modList[selectedMod].id .. ".dff")
						end
					elseif modList[selectedMod].state == "on" then
						modList[selectedMod].state = "off"

						toggableVehs[tostring(modList[selectedMod].vehicleModel)] = nil

						engineRestoreModel(modList[selectedMod].vehicleModel)
					end

					saveToggableVehicles()
				elseif selected[2] == "toggleAllOn" then
					local canToggleAll = true

					for k, v in pairs(modList) do
						if v.state == "notdownloaded" or v.state == "downloading" then
							canToggleAll = false
							break
						end
					end

					if not canToggleAll then
						exports.sarp_hud:showInfobox("error", "Nincs letöltve az összes mód!")
						return
					end

					if isElement(playerVehicle) then
						exports.sarp_hud:showInfobox("error", "Előbb szállj ki a járművedől!")
						return
					end

					for k, v in pairs(modList) do
						modList[k].state = "off"

						if string.find(modContents[v.id], "txd") then
							downloadFile("files/" .. v.id .. ".txd")
						end

						if string.find(modContents[v.id], "dff") then
							downloadFile("files/" .. v.id .. ".dff")
						end
					end

					saveToggableVehicles()
				elseif selected[2] == "toggleAllOff" then
					if isElement(playerVehicle) then
						exports.sarp_hud:showInfobox("error", "Előbb szállj ki a járművedől!")
						return
					end

					for k, v in pairs(modList) do
						if v.state == "on" then
							modList[k].state = "off"
							toggableVehs[tostring(v.vehicleModel)] = nil
							engineRestoreModel(v.vehicleModel)
						end
					end

					saveToggableVehicles()
				end
			end
		end
	end
end

function keyHandler(button, state)
	if state then
		if #modList > 9 then
			if button == "mouse_wheel_down" and listOffset < #modList - 9 then
				listOffset = listOffset + 9
			elseif button == "mouse_wheel_up" and listOffset > 0 then
				listOffset = listOffset - 9
			end
		end
	end
end

function modsPanelFunc()
	if not panelState then
		RobotoFont = dxCreateFont("Roboto.ttf", respc(17.5), false, "antialiased")
		RobotoFontLighter = dxCreateFont("RobotoL.ttf", respc(17.5), false, "antialiased")
		IconsFont = dxCreateFont("Themify.ttf", respc(17.5), false, "antialiased")

		addEventHandler("onClientRender", getRootElement(), panelRender)
		addEventHandler("onClientClick", getRootElement(), clickHandler)
		addEventHandler("onClientKey", getRootElement(), keyHandler)

		selectedMod = false
		panelState = true
	else
		removeEventHandler("onClientRender", getRootElement(), panelRender)
		removeEventHandler("onClientClick", getRootElement(), clickHandler)
		removeEventHandler("onClientKey", getRootElement(), keyHandler)

		if isElement(RobotoFont) then
			destroyElement(RobotoFont)
			RobotoFont = nil
		end

		if isElement(RobotoFontLighter) then
			destroyElement(RobotoFontLighter)
			RobotoFontLighter = nil
		end

		if isElement(IconsFont) then
			destroyElement(IconsFont)
			IconsFont = nil
		end

		panelState = false
	end
end
addCommandHandler("mods", modsPanelFunc)
addCommandHandler("modspanel", modsPanelFunc)
addCommandHandler("modpanel", modsPanelFunc)

addEventHandler("onClientFileDownloadComplete", getResourceRootElement(),
	function (file, success)
		if success then
			local path = file:gsub("files/", ""):gsub(".txd", ""):gsub(".dff", "")

			if availableMods[path] then
				local model = tonumber(availableMods[path][1]) or getVehicleModelFromName(availableMods[path][1])

				if not availableMods[path][3] then -- ha nem kapcsolgatható cserélje le a módot
					if file:find(".txd") then
						engineImportTXD(engineLoadTXD(file), model)
					elseif file:find(".dff") then
						engineReplaceModel(engineLoadDFF(file), model)
					end
				elseif toggableVehs[tostring(model)] and toggableVehs[tostring(model)] == "on" then -- ha resource indításkor a mentett állapot bekapcsolt volt
					if file:find(".txd") then
						engineImportTXD(engineLoadTXD(file), model)
					elseif file:find(".dff") then
						engineReplaceModel(engineLoadDFF(file), model)
					end
				else -- ha kapcsolhatgató
					for k, v in pairs(modList) do
						if v.id == path then
							if v.state == "downloading" then -- ha eddig töltötte
								downloadedSize = downloadedSize + v.realSize

								setTimer(
									function()
										downloadNum = downloadNum - 1
									end,
								1000, 1)

								if v.state ~= "downloading" then
									modList[k].state = "downloading"
								else
									modList[k].state = false
								end
							elseif v.state == "off" then -- ha bekapcsolta a módot betöltjük
								if file:find(".txd") then
									engineImportTXD(engineLoadTXD(file), model)
								elseif file:find(".dff") then
									engineReplaceModel(engineLoadDFF(file), model)
								end

								if string.len(modContents[path]) == 6 then -- dff és txd
									if file:find(".txd") then -- először a txd-t tölti be
										modList[k].state = "off" -- ezért kikapcsolva hagyjuk még az állapotát
									elseif file:find(".dff") then -- amint betöltötte a dff-et
										modList[k].state = "on" -- bekapcsoljuk az állapotát is
									end
								else -- vagy dff vagy txd
									modList[k].state = "on"
								end
							end

							break
						end
					end
				end
			end
		end
	end
)

function byte2human(bytes)
	local threshold = 1000

	if math.abs(bytes) < threshold then
		return bytes .. " B"
	end

	local units = {"kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
	local unitIndex = 0

	repeat
		bytes = bytes / threshold
		unitIndex = unitIndex + 1
	until not (math.abs(bytes) >= threshold and unitIndex < #units)

	return tonumber(string.format("%.2f", bytes)) .. " " .. units[unitIndex]
end

function spairs(t, order)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	if order then
		table.sort(keys,
			function (a, b)
				return order(t, a, b)
			end
		)
	else
		table.sort(keys)
	end

	local i = 0
	return function ()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

addEvent("requestModSizes", true)
addEventHandler("requestModSizes", getRootElement(),
	function (sizes, contents)
		local preTable = {}

		modContents = contents

		for k, v in pairs(availableMods) do
			if not v[3] then -- ha nem kapcsolgatható töltse le mindenképp
				if string.find(contents[k], "txd") then
					downloadFile("files/" .. k .. ".txd")
				end

				if string.find(contents[k], "dff") then
					downloadFile("files/" .. k .. ".dff")
				end
			elseif contents[k] ~= "big" then
				local model = tostring(tonumber(v[1]) or getVehicleModelFromName(v[1]))

				if toggableVehs[model] then
					if toggableVehs[model] == "on" then
						availableMods[k].state = "on"

						if string.find(contents[k], "txd") then
							downloadFile("files/" .. k .. ".txd")
						end

						if string.find(contents[k], "dff") then
							downloadFile("files/" .. k .. ".dff")
						end
					end
				end
			end

			if sizes[k] and contents[k] ~= "big" then
				local model = tonumber(v[1]) or getVehicleModelFromName(v[1])
				local state = v.state or "off"

				if string.find(contents[k], "txd") and not fileExists("files/" .. k .. ".txd") then
					state = "notdownloaded"
				end

				if string.find(contents[k], "dff") and not fileExists("files/" .. k .. ".dff") then
					state = "notdownloaded"
				end

				table.insert(preTable, {
					id = k,
					vehicleModel = model,
					originalName = _getVehicleNameFromModel(model),
					customName = v[2],
					size = byte2human(sizes[k]),
					realSize = sizes[k],
					state = state
				})
			end
		end

		for k, v in spairs(preTable, function (t, a, b) return utf8.lower(t[b].customName) > utf8.lower(t[a].customName) end) do
			table.insert(modList, v)
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		toggableVehs = {}

		if fileExists("save.json") then
			local file = fileOpen("save.json")
			if file then
				local size = fileGetSize(file)
				local bytes = fileRead(file, size)

				fileClose(file)

				toggableVehs = fromJSON(bytes)
			end
		end

		triggerServerEvent("requestModSizes", localPlayer)
	end
)

function saveToggableVehicles()
	local toggableVehs = {}

	for k, v in pairs(modList) do
		if v.state == "on" then
			toggableVehs[v.vehicleModel] = "on"
		else
			toggableVehs[v.vehicleModel] = "off"
		end
	end

	if fileExists("save.json") then
		fileDelete("save.json")
	end

	local file = fileCreate("save.json")
	if file then
		fileWrite(file, toJSON(toggableVehs))
		fileClose(file)
	end
end
addEventHandler("onClientResourceStop", getResourceRootElement(), saveToggableVehicles)