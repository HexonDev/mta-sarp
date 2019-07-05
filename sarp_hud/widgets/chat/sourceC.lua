local moocChatMaxLines = 10
local moocChatMessages = {}
local moocChatState = true

local blackColor = tocolor(0, 0, 0)
local greyColor = tocolor(205, 205, 205)

local oocCache = {}

function clearChatFunction()
	for i = 1, getChatboxLayout()["chat_lines"] do
		outputChatBox("")
		outputConsole("")
	end
end
addCommandHandler("clearchat", clearChatFunction)
addCommandHandler("cc", clearChatFunction)

function oocClearChatFunction()
	moocChatMessages = {}
	processOOC()
end
addCommandHandler("clearooc", oocClearChatFunction)
addCommandHandler("co", oocClearChatFunction)

addCommandHandler("togooc",
	function ()
		moocChatState = not moocChatState
	end
)

addEvent("onClientRecieveOOCMessage", true)
addEventHandler("onClientRecieveOOCMessage", getRootElement(),
	function (message, playerName)
		if #moocChatMessages >= moocChatMaxLines then
			table.remove(moocChatMessages, moocChatMaxLines)
		end

		local adminDuty = getElementData(source, "adminDuty")
		local color = "#ffffff"

		if not adminDuty then
			message = playerName .. ": (( " .. message .. " ))"
		else
			local adminLevel = getElementData(source, "acc.adminLevel") or 0
			local adminTitle = exports.sarp_core:getPlayerAdminTitleByLevel(adminLevel)
			color = exports.sarp_core:getAdminLevelColor(adminLevel)
			
			message = "[" .. adminTitle .. "] " .. playerName .. ": (( " .. message .. " ))"
		end
		
		table.insert(moocChatMessages, 1, {message, hexToColor(color)})
		outputConsole(message)

		processOOC()
	end
)

function hexToColor(code)
	code = code:gsub("#", "")
	return tocolor(tonumber("0x" .. code:sub(1, 2)), tonumber("0x" .. code:sub(3, 4)), tonumber("0x" .. code:sub(5, 6)))
end

local fontHeight = dxGetFontHeight(1, "default-bold")

function processOOC()
	oocCache = {}

	if #moocChatMessages > 0 then
		for i = 1, #moocChatMessages do
			local str = moocChatMessages[i][1]
			local str2 = string.gsub(str, "#......", "")
			str = string.gsub(str, "\n", "")

			local length = dxGetTextWidth(str, 1, "default-bold", true)
			local breaks = 0
			local textSub = {}

			if length >= widgets.oocchat.sizeX then
				local i, i2 = 1, 1
				local start = 1
				local remainText = ""

				while true do
					local length = dxGetTextWidth(utfSub(str, start, i), 1, "default-bold", true)

					if length >= widgets.oocchat.sizeX then
						breaks = breaks + 1

						if utfSub(str, i - 1, i - 1) == "#" then
							table.insert(textSub, utfSub(str, i2, i - 2) .. "\n")
							i2 = i - 1
							remainText = utfSub(str, i2, #str)
							str = utfSub(str, 1, i - 2) .. "\n" .. utfSub(str, i - 1, #str)
						else
							table.insert(textSub, utfSub(str, i2, i - 1) .. "\n")
							i2 = i
							remainText = utfSub(str, i2, #str)
							str = utfSub(str, 1, i - 1) .. "\n" .. utfSub(str, i, #str)
						end

						start = i
					elseif i + 1 >= #str then
						table.insert(textSub, remainText)
						break
					end

					i = i + 1
				end
			end

			str2 = string.gsub(str, "#......", "")
			table.insert(oocCache, {str, moocChatMessages[i][2], breaks + 1, str2, textSub})
		end
	end
end

local lastOocSizeX = 0
local lastOocSizeY = 0

render.oocchat = function (x, y)
	if moocChatState then
		if lastOocSizeX ~= widgets.oocchat.sizeX or lastOocSizeY ~= widgets.oocchat.sizeY then
			lastOocSizeX = widgets.oocchat.sizeX
			lastOocSizeY = widgets.oocchat.sizeY
			processOOC()
		end

		dxDrawText("OOC Chat (eltüntetéshez /togooc)", x + 1, y + 1, 0, 0, blackColor, 1, "default-bold", "left", "top", false, false, false)
		dxDrawText("OOC Chat (eltüntetéshez /togooc)", x, y, 0, 0, greyColor, 1, "default-bold", "left", "top", false, false, false)

		local y2 = y + widgets.oocchat.sizeY - fontHeight

		--[[
		for i = 1, #moocChatMessages do
			local y3 = y2 - i * 15

			dxDrawText(moocChatMessages[i][1], x + 1, y3 + 1, 0, 0, blackColor, 1, "default-bold", "left", "top", false, false, false, false)
			dxDrawText(moocChatMessages[i][1], x, y3, 0, 0, moocChatMessages[i][2], 1, "default-bold", "left", "top", false, false, false, false)
		end
		]]

		local y3 = y2

		for i = 1, math.min(moocChatMaxLines, #oocCache) do
			--local y3 = y2 - i * 15
			local text, color, line, textWithNoColor, textSub = unpack(oocCache[i])
			local moreLines = 0

			if line - 1 > 0 then
				if i + (line - 1) > moocChatMaxLines then
					local terrain = {}

					for i = 1, math.floor(math.floor(y - y3) / fontHeight) do
						terrain[i] = true
					end

					local newText = ""

					for i = 1, #textSub do
						if not terrain[i] then
							newText = newText .. string.gsub(textSub[i], "\n", "") .. "\n"
						end
					end

					text = newText
					textWithNoColor = string.gsub(text, "#......", "")
					moreLines = true
				end
			end

			if moreLines then
				dxDrawText(textWithNoColor, x + 1, y3 + 1, 0, 0, blackColor, 1, "default-bold", "left", "top", false, false, false, false)
				dxDrawText(text, x, y3, 0, 0, color, 1, "default-bold", "left", "top", false, false, false, false)
			else
				local y3 = y3 + fontHeight * line
				dxDrawText(textWithNoColor, x + 1, y3 + 1, 0, 0, blackColor, 1, "default-bold", "left", "top", false, false, false, false)
				dxDrawText(text, x, y3, 0, 0, color, 1, "default-bold", "left", "top", false, false, false, false)
			end

			if oocCache[i + 1] then
				local text, color, line, textWithNoColor, textSub = unpack(oocCache[i + 1])
				if line >= 2 then
					y3 = y3 - fontHeight * math.max(line, 2)
				else
					y3 = y3 - fontHeight * (math.max(line, 2) - 1)
				end
			end
		end

		return true
	else
		return false
	end
end