Drawing = {}
Drawing.postGUI = false

local defaultColor = tocolor(255, 255, 255)
local defaultFont = "default"
local defaultFontScale = 1

local drawColor = defaultColor
local drawFont = defaultFont
local drawFontScale = defaultFontScale

local drawX = 0
local drawY = 0

function Drawing.getGlobalPosition(x, y)
	return x + drawX, y + drawY
end

function Drawing.origin()
	drawX = 0
	drawY = 0
end

function Drawing.translate(x, y)
	drawX = drawX + x
	drawY = drawY + y
end

function Drawing.setColor(color)
	drawColor = color or defaultColor
end

function Drawing.setFont(font)
	drawFont = font or defaultFont
end

function Drawing.setFontScale(scale)
	drawFontScale = scale or defaultFontScale
end

function Drawing.rectangle(x, y, width, height, color)
	dxDrawRectangle(x + drawX, y + drawY, width, height, color or drawColor, Drawing.postGUI, false)
end

function Drawing.line(x1, y1, x2, y2, color, width)
	dxDrawLine(x1 + drawX, y1 + drawY, x2 + drawX, y2 + drawY, color or drawColor, width, Drawing.postGUI)
end

function Drawing.text(x, y, width, height, text, alignX, alignY, clip, wordBreak, colorCoded, ...)
	x = x + drawX
	y = y + drawY
	dxDrawText(text, x, y, x + width, y + height, drawColor, drawFontScale, drawFont, alignX, alignY, clip, wordBreak, Drawing.postGUI, false, colorCoded, ...)
end

function Drawing.image(x, y, width, height, image, floorMode, rotation)
	if floorMode then
		dxDrawImage(math.floor(x + drawX), math.floor(y + drawY), width, height, image, rotation, 0, 0, drawColor, Drawing.postGUI)
	else
		dxDrawImage(x + drawX, y + drawY, width, height, image, rotation, 0, 0, drawColor, Drawing.postGUI)
	end
end

function Drawing.imageSection(x, y, width, height, ux, uy, uw, uh, image)
	dxDrawImageSection(x + drawX, y + drawY, width, height, ux, uy, uw, uh, image, 0, 0, 0, drawColor, Drawing.postGUI)
end

function Drawing.roundedRectangle(x, y, width, height, color, radius)
	radius = radius or 5
	color = color or drawColor

	x = x + drawX
	y = y + drawY

	dxDrawRoundedRectangle(x, y, width, height, color, radius)
end