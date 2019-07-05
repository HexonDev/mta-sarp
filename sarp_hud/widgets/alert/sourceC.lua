local alerts = {}
local maxAlert = 4

local startHeight = respc(42)

render.alert = function (x, y)
	if #alerts > 0 then
		local now = getTickCount()

		if alerts[1] then
			local v = alerts[1]

			if now >= v.fadeOutStart then
				local elapsedTime = now - v.fadeOutStart
				local progress = elapsedTime / 375

				if progress > 1 then
					table.remove(alerts, 1)
				end
			end
		end

		local lastCurrHeight = 0

		for k = #alerts, 1, -1 do
			local v = alerts[k]

			if v then
				local alphaFactor = 0
				local currHeight = startHeight

				if now > v.fadeInStart and now <= v.fadeOutStart then
					local elapsedTime = now - v.fadeInStart
					local progress = elapsedTime / 375

					alphaFactor, currHeight = interpolateBetween(
						0, startHeight, 0,
						1, v.maxHeight, 0,
						progress, "InOutQuad"
					)
				elseif now > v.fadeOutStart then
					local elapsedTime = now - v.fadeOutStart
					local progress = elapsedTime / 375

					alphaFactor, currHeight = interpolateBetween(
						1, v.maxHeight, 0,
						0, startHeight, 0,
						progress, "InOutQuad"
					)
				end

				v.deltaY = currHeight - (startHeight * (1 - alphaFactor))

				local y2 = y + widgets.alert.sizeY - currHeight - lastCurrHeight

				-- ** háttér
				dxDrawRectangle(x, y2, v.maxWidth, currHeight, tocolor(50, 50, 50, 200 * alphaFactor))
				dxDrawRectangle(x + 2, y2 + 2, v.maxWidth - 4, currHeight - 4, tocolor(25, 25, 25, 175 * alphaFactor))

				-- ** töltő csík
				local progress = (now - v.fadeInStart) / (v.fadeOutStart - v.fadeInStart)

				if progress <= 1 then
					dxDrawRectangle(x, y2 + currHeight - resp(2), v.maxWidth * (1 - progress), resp(2), tocolor(v.theColor[1], v.theColor[2], v.theColor[3], 255 * alphaFactor))
				end

				-- ** ikon
				if v.thePicture then
					dxDrawImage(math.floor(x + resp(12)), math.floor(y2 + (currHeight - resp(32)) / 2), resp(32), resp(32), v.thePicture, 0, 0, 0, tocolor(v.theColor[1], v.theColor[2], v.theColor[3], 255 * alphaFactor))
				end

				-- ** szöveg
				for k2 = 1, #v.lines do
					local v2 = v.lines[k2]

					if v2 then
						local y = y2 + (currHeight - (#v.lines * Roboto18H) * 0.75) / 2

						dxDrawText(v2, x + resp(54), y + (Roboto18H * 0.75) * (k2 - 1), 0, 0, tocolor(255, 255, 255, 255 * alphaFactor), 0.75, Roboto18, "left", "top", false, false, false, true)
					end
				end

				lastCurrHeight = lastCurrHeight + v.deltaY + resp(5)
			end
		end

		return true
	end

	return false
end

function showAlert(theType, str, str2, imgPath, color)
	if str then
		if #alerts >= maxAlert then
			if #alerts >= maxAlert + 1 then
				table.remove(alerts, 1)
			end

			alerts[1].fadeOutStart = getTickCount()
		end

		theType = theType or "info"

		local data = {}
		local stringLines = {}
		local line = 1

		data.maxWidth = defaultWidgets.minimap.sizeX
		data.maxHeight = startHeight

		do
			local stringTable = {}
			local text = ""

			if str then
				table.insert(stringTable, str)

				if str2 then
					table.insert(stringTable, str2)
				end
			end

			for k, v in ipairs(stringTable) do
				local words = split(v, " ")
				local color = ""

				if utf8.len(v) > 0 then
					if k == 2 then
						stringLines[line] = text
						line = line + 1
						text = ""
					end

					for j = 1, #words do
						local word = words[j]

						if dxGetTextWidth(text .. word, 0.75, Roboto18, true) > data.maxWidth - resp(54) then
							stringLines[line] = color .. text

							line = line + 1

							for character in utf8.gmatch(text, "#%x%x%x%x%x%x") do
								color = character
							end

							text = ""
						end

						text = text .. word .. " "
					end

					stringLines[line] = color .. text
				end

				data.maxHeight = data.maxHeight + (line - 1) * (Roboto18H * 0.75)
			end
		end

		if line > 1 then
			data.maxHeight = data.maxHeight + resp(8)
		else
			data.maxHeight = startHeight
		end

		data.lines = stringLines
		data.deltaY = 0

		data.fadeInStart = getTickCount()
		data.fadeOutStart = data.fadeInStart + 5000

		if imgPath then
			data.thePicture = imgPath
		else
			data.thePicture = alertTypes[theType][2]
		end

		if color then
			data.theColor = color
		else
			data.theColor = alertTypes[theType][3]
		end

		if isHudElementVisible("alert") then
			playSound(alertTypes[theType][4])
		end

		outputConsole("[" .. alertTypes[theType][1] .. "]: " .. str:gsub("#%x%x%x%x%x%x", ""))

		if str2 then
			outputConsole(" -> " .. str2:gsub("#%x%x%x%x%x%x", ""))
		end

		table.insert(alerts, data)
	end
end
addEvent("showAlertClient", true)
addEventHandler("showAlertClient", getRootElement(), showAlert)