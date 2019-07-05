local screenX, screenY = guiGetScreenSize()

buttons = {}
activeButton = false

function dxDrawMetroButton(key, label, x, y, w, h, activeColor, icon, labelFont, iconFont, labelScale, iconScale)
	local buttonColor

	if activeButton == key then -- !!!
		buttonColor = {processColorSwitchEffect(key, {activeColor[1], activeColor[2], activeColor[3], 175})}
	else
		buttonColor = {processColorSwitchEffect(key, {activeColor[1], activeColor[2], activeColor[3], 125})}
	end

	local alphaDifference = 175 - buttonColor[4]
	local alphaMultipler = 1 -- majd a későbbiek folyamán szükség lesz rá, addig csak 1.

	dxDrawRectangle(x, y, w, h, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], (175 - alphaDifference) * alphaMultipler))
	dxDrawInnerBorder(2, x, y, w, h, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], (125 + alphaDifference) * alphaMultipler))

	labelFont = labelFont or RobotoL14 -- írd át az alapértelmezett szöveg fontra | respc(14)-es legyen
	labelScale = labelScale or 1

	if icon then
		iconFont = iconFont or Themify18 -- írd át az alapértelmezett ikon fontra | respc(18)-as legyen
		iconScale = iconScale or 0.75

		local iconWidth = dxGetTextWidth(icon, iconScale, iconFont) + respc(5) -- respc(5) - írd át ha szükséges
		local textWidth = dxGetTextWidth(label, labelScale, labelFont)
		local totalWidth = iconWidth + textWidth

		local x2 = x + (w - totalWidth) / 2

		dxDrawText(icon, x2, y, 0, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), iconScale, iconFont, "left", "center")
		dxDrawText(label, x2 + iconWidth, y, 0, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), labelScale, labelFont, "left", "center")
	else
		dxDrawText(label, x, y, x + w, y + h, tocolor(255, 255, 255, 255 * alphaMultipler), labelScale, labelFont, "center", "center")
	end
	
	buttons[key] = {x, y, w, h} -- !!!
end

function dxDrawInnerBorder(thickness, x, y, w, h, color)
	thickness = thickness or 2

	dxDrawLine(x, y, x + w, y, color, thickness)
	dxDrawLine(x, y + h, x + w, y + h, color, thickness)
	dxDrawLine(x, y, x, y + h, color, thickness)
	dxDrawLine(x + w, y, x + w, y + h, color, thickness)
end

local colorSwitch = {}

colorSwitch.storedColors = {}
colorSwitch.lastColors = {}
colorSwitch.startInterpolation = {}
colorSwitch.lastColorConcat = {}

function processColorSwitchEffect(key, color, duration, type)
	if not colorSwitch.storedColors[key] then
		if not color[4] then
			color[4] = 255
		end

		colorSwitch.storedColors[key] = color
		colorSwitch.lastColors[key] = color

		colorSwitch.lastColorConcat[key] = table.concat(color)
	end

	duration = duration or 500
	type = type or "Linear"

	if colorSwitch.lastColorConcat[key] ~= table.concat(color) then
		colorSwitch.lastColorConcat[key] = table.concat(color)
		colorSwitch.lastColors[key] = color
		colorSwitch.startInterpolation[key] = getTickCount()
	end

	if colorSwitch.startInterpolation[key] then
		local progress = (getTickCount() - colorSwitch.startInterpolation[key]) / duration

		local r, g, b = interpolateBetween(
			colorSwitch.storedColors[key][1], colorSwitch.storedColors[key][2], colorSwitch.storedColors[key][3],
			color[1], color[2], color[3],
			progress, type
		)

		local a = interpolateBetween(colorSwitch.storedColors[key][4], 0, 0, color[4], 0, 0, progress, type)

		colorSwitch.storedColors[key][1] = r
		colorSwitch.storedColors[key][2] = g
		colorSwitch.storedColors[key][3] = b
		colorSwitch.storedColors[key][4] = a

		if progress >= 1 then
			colorSwitch.startInterpolation[key] = false
		end
	end

	return colorSwitch.storedColors[key][1], colorSwitch.storedColors[key][2], colorSwitch.storedColors[key][3], colorSwitch.storedColors[key][4]
end

registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

function activeButtonChecker()
	local cx, cy = getCursorPosition() -- lekérjük a relatív kurzor pozíciót

	if tonumber(cx) and tonumber(cy) then -- ha számot kapunk, tehát a kurzor elő van hozva
		cx, cy = cx * screenX, cy * screenY -- átalakítjuk abszolút értékekre
		cursorX, cursorY = cx, cy -- eltároljuk a változóba a kurzor abszolút pozícióit

		activeButton = false -- ha nem találna szarságot akkor nincs kijelölve semmi, tehát false

		for k, v in pairs(buttons) do -- végigmegyünk a létrehozott gombokon
			if cx >= v[1] and cy >= v[2] and cx <= v[1] + v[3] and cy <= v[2] + v[4] then -- benne van-e a boxban
				activeButton = k -- eltároljuk az aktív kijelölt gombot
				break -- megállítjuk a loopot
			end
		end
	else -- ha nincs előhozva a kurzor
		activeButton = false -- nincs kijelölve semmi
		cursorX, cursorY = -10, -10 -- kurzor a képernyőn kívülre, hogy a render ne érzékelje
	end
end

function table.empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function cursorInBox(x, y, w, h)
	if x and y and w and h then
		if isCursorShowing() then
			if not isMTAWindowActive() then
				local cursorX, cursorY = getCursorPosition()
				
				cursorX, cursorY = cursorX * screenX, cursorY * screenY
				
				if cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
					return true
				end
			end
		end
	end
	
	return false
end
