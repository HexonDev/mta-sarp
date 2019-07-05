local phoneState = false

local currentPage = "lockscreen"

local phoneType = 1

local currentWallpaper = 1

local components = {
	[1] = {
		["base"] = {
			startPos = {-116, -5},
			contents = {
				{"image", 0, 0, 512, 512, "base.png"},
				{"wallpaper"}
			}
		},
		["page:lockscreen"] = {
			startPos = {0, 0},
			contents = {
				{"rectangle", 6, 22, 268, 471, tocolor(0, 0, 0, 180)},
				{"image", -116, -5, 512, 512, "cloud.png", 0, tocolor(255, 255, 255, 50)},
				{"rectangle", 10, 332, 268 / 2, 1 / responsiveMultipler, tocolor(255, 255, 255)},
				{"rectangle", 10, 400, 268 / 2, 1 / responsiveMultipler, tocolor(255, 255, 255)},
				{"text", "Érintsd meg a főgombot a feloldáshoz", 6, 426, 274, 466, tocolor(255, 255, 255), 0.85, "Roboto", "center", "center"},
				{"image", -116, -5, 512, 512, "basebtn.png"},
				{"lockscreen"}
			},
			buttons = {
				{131, 466, 18, 18, "unlockPhone"}
			},
		},
		["page:home"] = {
			startPos = {0, 0},
			contents = {
				{"dynamictext", "#currenttime", 6 + 1, 70 + 1, 274 + 1, 466 + 1, tocolor(0, 0, 0), 1, "RobotoLighter40", "center", "top"},
				{"dynamictext", "#currenttime", 6, 70, 274, 466, tocolor(255, 255, 255), 1, "RobotoLighter40", "center", "top"},

				{"image", 15, 435, 48, 48, "buttons/settings.png"},
			},
			buttons = {
				{15, 435, 48, 48, "changePage:settings"}
			}
		},
		["page:settings"] = {
			startPos = {0, 0},
			contents = {
				{"image", -116, -5, 512, 512, "settings_page.png"},
			},
			buttons = {}
		}
	}
}

local pictures = {}
local shaders = {}

local weather = {}

local activeButton = false
local activeInput = false

--[[
bindKey("f2","down",
	function()
		triggerEvent("openPhone", localPlayer)
	end)
]]

addEvent("openPhone", true)
addEventHandler("openPhone", getRootElement(),
	function ()
		phoneState = not phoneState

		commandHandler("changePage:lockscreen")
	end
)

addEventHandler("onClientResourceStart", getRootElement(),
	function (res)
		if res == getThisResource() then
			local sarp_weather = getResourceFromName("sarp_weather")

			if sarp_weather and getResourceState(sarp_weather) == "running" then
				weather = getElementData(getResourceRootElement(sarp_weather), "serverWeather")
			else
				weather = {1, 1}
			end
		else
			local sarp_weather = getResourceFromName("sarp_weather")

			if sarp_weather and getResourceState(sarp_weather) == "running" then
				weather = getElementData(getResourceRootElement(sarp_weather), "serverWeather")
			end
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if dataName == "serverWeather" then
			weather = getElementData(source, "serverWeather")
		end
	end
)

function commandHandler(command)
	command = split(command, ":")

	if command[1] == "changePage" then
		currentPage = command[2]
	elseif command[1] == "unlockPhone" then
		commandHandler("changePage:home")
	end
end

function processPhoneTexture(path, gray)
	local k = path

	if gray then
		k = path .. ":gray"
	end

	if isElement(pictures[k]) then
		return pictures[k]
	elseif not pictures[k] then
		if gray then
			pictures[k] = dxCreateShader("mobile/files/blackwhite.fx")

			if not shaders[k] then
				shaders[k] = dxCreateTexture(path, "argb", false, "clamp")
			end

			dxSetShaderValue(pictures[k], "screenSource", shaders[k])
		else
			pictures[k] = dxCreateTexture(path, "argb", false, "clamp")
		end
	end

	return path
end

local monthNames = {
	[0] = "Január",
	[1] = "Február",
	[2] = "Március",
	[3] = "Április",
	[4] = "Május",
	[5] = "Június",
	[6] = "Július",
	[7] = "Augusztus",
	[8] = "Szeptember",
	[9] = "Október",
	[10] = "November",
	[11] = "December"
}

local dayNames = {
	[0] = "Vasárnap",
	[1] = "Hétfő",
	[2] = "Kedd",
	[3] = "Szerda",
	[4] = "Csütörtök",
	[5] = "Péntek",
	[6] = "Szombat"
}

function replaceDynamicText(text)
	if text == "#currenttime" then
		local time = getRealTime()
		local hour = time["hour"]
		local minute = time["minute"]

		if utf8.len(hour) == 1 then
			hour = 0 .. hour
		end

		if utf8.len(minute) == 1 then
			minute = 0 .. minute
		end

		text = hour .. ":" .. minute
	elseif text == "#currentdate" then
		local time = getRealTime()

		text = utf8.lower(monthNames[time["month"]]:sub(1, 3)) .. " " .. time["monthday"] .. ", " .. dayNames[time["weekday"]]
	end

	return text
end

function drawPhoneComponent(x, y, v)
	if v[1] == "image" then
		dxDrawImage(x + resp(v[2]), y + resp(v[3]), resp(v[4]), resp(v[5]), processPhoneTexture("mobile/files/images/" .. v[6]), v[7], 0, 0, v[8])
	elseif v[1] == "imagesection" then
		dxDrawImageSection(x + resp(v[2]), y + resp(v[3]), resp(v[4]), resp(v[5]), v[6], v[7], resp(v[8]), resp(v[9]), processPhoneTexture("mobile/files/images/" .. v[10]), v[11])
	elseif v[1] == "dynamictext" then
		dxDrawText(replaceDynamicText(v[2]), x + resp(v[3]), y + resp(v[4]), x + resp(v[5]), y + resp(v[6]), v[7], v[8], _G[v[9]], v[10], v[11])
	elseif v[1] == "text" then
		dxDrawText(v[2], x + resp(v[3]), y + resp(v[4]), x + resp(v[5]), y + resp(v[6]), v[7], v[8], _G[v[9]], v[10], v[11])
	elseif v[1] == "rectangle" then
		dxDrawRectangle(x + resp(v[2]), y + resp(v[3]), resp(v[4]), resp(v[5]), v[6])
	elseif v[1] == "lockscreen" then
		drawPhoneComponent(x, y, {"dynamictext", "#currenttime", 12, 338, 0, 338 + 32.5, tocolor(230, 190, 130), 0.6, "RobotoBolder40", "left", "center"})
		drawPhoneComponent(x, y, {"dynamictext", "#currentdate", 24, 338 + 32.5, 24 + 143, 338 + 55, tocolor(230, 190, 130), 0.8, "RobotoRegular", "left", "center"})

		local temp_c = math.floor(weather[1] * 10) / 10
		local tempTextWidth = dxGetTextWidth(temp_c, 1, RobotoBolder40)

		dxDrawText(temp_c, x + resp(10), y + resp(65), x + resp(170), y + resp(165), tocolor(255, 255, 255), 1, RobotoBolder40, "center", "center")
		dxDrawText("°C", x + resp(10) + (resp(160) - tempTextWidth) / 2 + tempTextWidth, y + resp(65), 0, 0, tocolor(255, 255, 255), 0.5, RobotoBolder40, "left", "top")
		dxDrawText(utf8.lower(weather[2]), x + resp(10), y + resp(65), x + resp(170), y + resp(165), tocolor(230, 190, 130), 0.75, RobotoL18, "center", "bottom")
	elseif v[1] == "wallpaper" then
		dxDrawImage(x, y, resp(512), resp(512), processPhoneTexture("mobile/files/images/wallpapers/" .. currentWallpaper .. ".png", currentPage == "lockscreen"))
	end
end

render.phone = function (x, y)
	if phoneState then
		local base = components[phoneType]["base"]
		local contents = base["contents"]

		for k = 1, #contents do
			local v = contents[k]

			if v then
				drawPhoneComponent(x + resp(base["startPos"][1]), y + resp(base["startPos"][2]), v)
			end
		end

		local page = components[phoneType]["page:" .. currentPage]
		local contents = page["contents"]

		for k = 1, #contents do
			local v = contents[k]

			if v then
				drawPhoneComponent(x + resp(page["startPos"][1]), y + resp(page["startPos"][2]), v)
			end
		end

		local page = components[phoneType]["page:" .. currentPage]
		local buttons = page["buttons"]

		activeButton = false

		local cursorX, cursorY = getCursorPosition()

		if cursorX and cursorY then
			cursorX = cursorX * screenX
			cursorY = cursorY * screenY

			for k = 1, #buttons do
				local v = buttons[k]

				if v then
					local x2 = resp(v[1]) + x + resp(page["startPos"][1])
					local y2 = resp(v[2]) + y + resp(page["startPos"][2])

					--dxDrawRectangle(x2, y2, resp(v[3]), resp(v[4]), tocolor(0, 0, 0, 150))
					
					if cursorX >= x2 and cursorX <= x2 + resp(v[3]) and cursorY >= y2 and cursorY <= y2 + resp(v[4]) then
						activeButton = v[5]
					end
				end
			end
		end

		return true
	else
		return false
	end
end

addEventHandler("onClientClick", getRootElement(),
	function (button, state)
		if button == "left" then
			if activeButton then
				if type(activeButton) == "table" then
					activeInput = activeButton
				else
					if state == "up" then
						local selected = split(activeButton, "_")

						commandHandler(selected[1])
					end
				end
			elseif state == "down" then
				activeInput = false
			end
		end
	end
)