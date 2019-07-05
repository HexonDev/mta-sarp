local screenX, screenY = guiGetScreenSize()

local panelPosX = (screenX - screenX / 2) / 2
local panelPosY = 0
local panelHeight = 0
local debugscriptActive = false
local debugLines = {}

local Roboto = false
local RobotoHeight = false

exports.sarp_admin:addAdminCommand("cd", 9, "Debugscript ürítése")
addCommandHandler("cd",
	function ()
		debugLines = {}
	end
)

exports.sarp_admin:addAdminCommand("debugon", 9, "Debugscript bekapcsolása")
addCommandHandler("debugon",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 9 then
			if not debugscriptActive then
				Roboto = dxCreateFont(":sarp_assets/fonts/Roboto-Regular.ttf", 14, false, "antialiased")
				RobotoHeight = dxGetFontHeight(0.75, Roboto)

				panelPosY = screenY - 20 - (36 + 30) - RobotoHeight * 20
				panelHeight = RobotoHeight * 20
				
				debugscriptActive = true
				addEventHandler("onClientRender", getRootElement(), renderTheNewDebug, true, "low-99999999999999999")
				outputChatBox("Debugscript on")
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("debugoff", 9, "Debugscript kikapcsolása")
addCommandHandler("debugoff",
	function ()
		if debugscriptActive then
			if isElement(Roboto) then
				destroyElement(Roboto)
			end
			Roboto = nil

			debugscriptActive = false
			removeEventHandler("onClientRender", getRootElement(), renderTheNewDebug)
			outputChatBox("Debugscript off")
		end
	end
)

addEventHandler("onClientDebugMessage", getRootElement(),
	function (message, level, file, line, r, g, b)
		if debugscriptActive then
			local color
			if level == 1 then
				level = "[ERROR] "
				color = tocolor(215, 89, 89)
			elseif level == 2 then
				level = "[WARNING] "
				color = tocolor(255, 150, 0)
			elseif level == 3 then
				level = "[INFO] "
				color = tocolor(50, 179, 239)
			else
				level = "[INFO] "
				color = tocolor(r, g, b)
			end

			local time = getRealTime()
			local timeStr = "[" .. string.format("%02d:%02d:%02d", time.hour, time.minute, time.second) .. "]"
		
			if file and line then
				addDebugLine(level .. file .. ":" .. line .. ", " .. message, color, timeStr)
			else
				addDebugLine(level .. message, color, timeStr)
			end
		end
	end
)

addEvent("addDebugLine", true)
function addDebugLine(message, color, timeStr)
	if debugscriptActive then
		local lines = {}

		for i = 1, #debugLines do
			if debugLines[i][2] == message then
				debugLines[i] = {debugLines[i][1] + 1, debugLines[i][2], debugLines[i][3], timeStr}
				return
			end
		end
		
		for i = 1, 20 do
			if debugLines[i] then
				lines[i + 1] = debugLines[i]
			end
		end
		
		debugLines = lines
		debugLines[1] = {1, message, color, timeStr}
		
		if #debugLines >= 20 then
			debugLines[#debugLines] = nil
		end
	end
end
addEventHandler("addDebugLine", getRootElement(), addDebugLine)

function dxDrawBorderText(text, x, y, w, h, color, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded)
	text = text:gsub("#......", "")
	dxDrawText(text, x - 1, y - 1, w - 1, h - 1, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x - 1, y + 1, w - 1, h + 1, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x + 1, y - 1, w + 1, h - 1, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x + 1, y + 1, w + 1, h + 1, borderColor, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x, y, w, h, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
end

function renderTheNewDebug()
	if debugscriptActive then
		for k = 1, 20 do
			if debugLines[k] then
				v = debugLines[k]

				local y = panelPosY + panelHeight - RobotoHeight * (k - 1)
				local textWidth = dxGetTextWidth(v[4] .. " " .. v[1] .. "x", 0.75, Roboto)

				dxDrawBorderText(v[4] .. " " .. v[1] .. "x", panelPosX, y, 0, 0, tocolor(255, 255, 255), tocolor(0, 0, 0, 200), 0.75, Roboto, "left", "top")
				dxDrawBorderText(v[2], panelPosX + textWidth + 5, y, 0, 0, v[3], tocolor(0, 0, 0, 200), 0.75, Roboto, "left", "top")
			end
		end
	end
end