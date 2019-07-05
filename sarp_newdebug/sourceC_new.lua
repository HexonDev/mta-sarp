local screenWidth, screenHeight = guiGetScreenSize()

local consoleSheet = createBrowser(screenWidth, screenHeight, true, true)

local consoleHistory = 55
local consoleMessages = 0

local consoleWidth = screenWidth / 2
local consoleHeight = 300
local consoleX = (screenWidth - consoleWidth) / 2
local consoleY = screenHeight - consoleHeight - 75

local isConsoleActive = false

local tempLineBreaks = {}
local debugLines = {}
local visibleLines = 20

local clearLinesProcess = false

addEventHandler("onClientBrowserCreated", getRootElement(),
	function ()
		if source == consoleSheet then
			loadBrowserURL(consoleSheet, "http://mta/local/files/index.html")
		end
	end
)

addEventHandler("onClientBrowserDocumentReady", getRootElement(),
	function ()
		if source == consoleSheet then
			executeBrowserJavascript(consoleSheet, "document.getElementById(\"innercontents\").style.fontSize=\"" .. 97 .. "%\"; document.getElementById(\"innercontents\").style.left=\"" .. math.floor(consoleX) .. "px\"; document.getElementById(\"innercontents\").style.top=\"" .. math.floor(consoleY) .. "px\"; document.getElementById(\"innercontents\").style.width=\"" .. math.floor(consoleWidth) .. "px\"; document.getElementById(\"innercontents\").style.height=\"" .. math.floor(consoleHeight) .. "px\"; document.getElementById(\"innercontents\").scrollTop = document.getElementById(\"innercontents\").scrollHeight; var element=document.getElementById(\"innercontents\"),temp=document.createElement(element.nodeName);temp.setAttribute(\"style\",\"opacity:0;margin:0px;padding:0px;font-family:\"+element.style.fontFamily+\";font-size:\"+element.style.fontSize),temp.innerHTML=\"test\",temp=element.parentNode.appendChild(temp);var ret=temp.clientHeight;temp.parentNode.removeChild(temp); document.title = ret;")
			setTimer(getVisibleLines, 500, 1)
		end
	end
)

function getVisibleLines()
	visibleLines = tonumber(getBrowserTitle(consoleSheet)) or 20

	tempLineBreaks = {}

	for i = 1, visibleLines do
		table.insert(tempLineBreaks, "<br/>")
	end
end

addCommandHandler("debugon",
	function ()
		if getElementData(localPlayer, "acc.adminLevel") >= 9 then
			if not isConsoleActive then
				isConsoleActive = true
				addEventHandler("onClientRender", getRootElement(), renderTheDebugConsole, true, "low")
				outputChatBox("Debugscript on")
			end
		end
	end
)

addCommandHandler("debugoff",
	function ()
		if isConsoleActive then
			isConsoleActive = false
			removeEventHandler("onClientRender", getRootElement(), renderTheDebugConsole)
			outputChatBox("Debugscript off")
		end
	end
)

addCommandHandler("cd",
	function ()
		if isConsoleActive then
			clearLinesProcess = true

			debugLines = {}
			consoleMessages = 0
			executeBrowserJavascript(consoleSheet, "document.getElementById(\"innercontents\").innerHTML = \"" .. table.concat(tempLineBreaks, "") .. "\"")

			clearLinesProcess = false
		end
	end
)

function renderTheDebugConsole()
	dxDrawImage(0, 0, screenWidth, screenHeight, consoleSheet)
end

addEventHandler("onClientDebugMessage", getRootElement(),
	function (message, level, file, line, r, g, b)
		if isConsoleActive then
			if level == 1 then
				level = "#d75959[fa-exclamation-circle] "
			elseif level == 2 then
				level = "#FF9600[fa-exclamation-triangle] "
			elseif level == 3 then
				level = "#32b3ef[fa-info-circle] "
			else
				level = string.format("#%02x%02x%02x", r, g, b) .. "[fa-terminal] "
			end

			level = "[caret-left]b style='color: inherit;'[caret-right]" .. level .. "[caret-left][per]b[caret-right]"
			
			if file and line then
				addDebugLine(level .. file .. ":" .. line .. ", " .. message)
			else
				addDebugLine(level .. message)
			end
		end
	end
)

addEvent("addDebugLine", true)
function addDebugLine(message)
	if isConsoleActive then
		if clearLinesProcess then
			return
		end

		local currentTick = getTickCount()
		local processTable = true

		for line = 1, #debugLines do
			if debugLines[line][2] == message then
				local nextTick = currentTick

				if debugLines[line][1] > 20 then
					nextTick = nextTick + 375
				end

				if currentTick >= debugLines[line][3] then
					debugLines[line] = {debugLines[line][1] + 1, debugLines[line][2], nextTick}
					processTable = false
					break
				end

				return
			end
		end
		
		if processTable then
			table.insert(debugLines, {1, message, currentTick})

			if #debugLines >= visibleLines then
				table.remove(debugLines, 1)
			end
		end

		consoleMessages = 0
		executeBrowserJavascript(consoleSheet, "document.getElementById(\"innercontents\").innerHTML = \"" .. table.concat(tempLineBreaks, "") .. "\"")

		for i = 1, #debugLines do
			if debugLines[i] then
				local debugMessage = escapeHTML(debugLines[i][1] .. "x " .. debugLines[i][2])
				debugMessage = utf8.gsub(debugMessage, "#%x%x%x%x%x%x", "</font><font style='color: %1;'>")
				debugMessage = utf8.gsub(debugMessage, "%[(fa%-(.-))%]", "<i class='fa %1' style='color: inherit; vertical-align: middle;'></i>")

				consoleMessages = consoleMessages + 1
				executeBrowserJavascript(consoleSheet, "document.getElementById(\"innercontents\").innerHTML=document.getElementById(\"innercontents\").innerHTML+\"" .. debugMessage .. "<br />\"; document.getElementById(\"innercontents\").scrollTop = document.getElementById(\"innercontents\").scrollHeight;")

				if consoleMessages > consoleHistory then
					consoleMessages = consoleHistory
					executeBrowserJavascript(consoleSheet, "var lines=document.getElementById(\"innercontents\").innerHTML.split(\"<br>\"); lines.splice(0,1); document.getElementById(\"innercontents\").innerHTML = lines.join(\"<br />\");")
				end
			end
		end
	end
end
addEventHandler("addDebugLine", getRootElement(), addDebugLine)

function escapeHTML(html)
	html = utf8.gsub(html, "&", "&amp;")
	html = utf8.gsub(html, "<", "&lt;")
	html = utf8.gsub(html, ">", "&gt;")
	html = utf8.gsub(html, "\"", "&quot;")
	html = utf8.gsub(html, "'", "&#39;")
	html = utf8.gsub(html, "/", "&#x2F;")
	html = utf8.gsub(html, "\\", "&#x2F;")

	html = utf8.gsub(html, "%[caret%-left]", "<")
	html = utf8.gsub(html, "%[caret%-right]", ">")
	html = utf8.gsub(html, "%[per]", "/")

	return html
end