local screenWidth, screenHeight = guiGetScreenSize()
local blackColor = tocolor(0, 0, 0)
local roundTexture = dxCreateTexture(":sarp_assets/images/round.png", "argb", true, "clamp")

function reMap(value, low1, high1, low2, high2)
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

local responsiveMultiplier = reMap(screenWidth, 1024, 1920, 0.75, 1)

function getResponsiveMultiplier()
	return responsiveMultiplier
end

function resp(value)
	return value * responsiveMultiplier
end

function respc(value)
	return math.ceil(value * responsiveMultiplier)
end

function getMousePosition()
	local cx, cy = getCursorPosition()

	if tonumber(cx) and tonumber(cy) then
		cx = cx * screenWidth
		cy = cy * screenHeight
	else
		cx, cy = -10, -10
	end

	return cx, cy
end

function isCursorWithinArea(x, y, w, h, cx, cy)
	return (cx >= x and cy >= y and cx <= x + w and cy <= y + h)
end

function capitalizeString(str)
	return (str:gsub("^%l", string.upper))
end

function clampColor(color)
	if color > 255 then
		color = 255
	elseif color < 0 then
		color = 0
	end
	return color
end

function colorMul(color, mul)
	return clampColor(color[1] * mul), clampColor(color[2] * mul), clampColor(color[3] * mul)
end

function colorDarken(color, amount, alpha)
	local r, g, b = colorMul(color, 1 - amount / 100)
	return tocolor(r, g, b, alpha)
end

function colorLighten(color, amount, alpha)
	local r, g, b = colorMul(color, 1 + amount / 100)
	return tocolor(r, g, b, alpha)
end

function toRGBA(color)
	color = tonumber(color)
	local r = bitExtract(color, 16, 8)
	local g = bitExtract(color, 8, 8)
	local b = bitExtract(color, 0, 8)
	local a = bitExtract(color, 24, 8)
	return r, g, b, a
end

function dxDrawBorderedText(text, x, y, w, h, color, ...)
	local textWithoutHEX = string.gsub(text, "#%x%x%x%x%x%x", "")
	dxDrawText(textWithoutHEX, x - 1, y - 1, w - 1, h - 1, blackColor, ...)
	dxDrawText(textWithoutHEX, x - 1, y + 1, w - 1, h + 1, blackColor, ...)
	dxDrawText(textWithoutHEX, x + 1, y - 1, w + 1, h - 1, blackColor, ...)
	dxDrawText(textWithoutHEX, x + 1, y + 1, w + 1, h + 1, blackColor, ...)
	dxDrawText(text, x, y, w, h, color, ...)
end

function dxDrawRoundedRectangle(x, y, w, h, color, radius, postGUI, subPixelPositioning)
	radius = radius or 10
	color = color or tocolor(0, 0, 0, 200)
	
	dxDrawImage(x, y, radius, radius, roundTexture, 0, 0, 0, color, postGUI)
	dxDrawImage(x, y + h - radius, radius, radius, roundTexture, 270, 0, 0, color, postGUI)
	dxDrawImage(x + w - radius, y, radius, radius, roundTexture, 90, 0, 0, color, postGUI)
	dxDrawImage(x + w - radius, y + h - radius, radius, radius, roundTexture, 180, 0, 0, color, postGUI)
	
	dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
	dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI, subPixelPositioning)
	dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
end