local currentWeather = 0
local oldWeather = currentWeather

local weatherFreezed = false
local timeFreezed = false

local halfHourTick = 0

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		changeWeather()
		halfHourTick = getTickCount() + 1800000

		setTimer(processMinuteTimer, 1000, 1)
		setTimer(processMinuteTimer, 60000, 0)
	end
)

addEvent("requestWeather", true)
addEventHandler("requestWeather", getRootElement(),
	function ()
		if timeFreezed then
			triggerClientEvent(source, "receiveWeather", source, currentWeather, timeFreezed[1], timeFreezed[2])
		else
			syncTime(source)
		end
	end
)

function processMinuteTimer()
	if getTickCount() >= halfHourTick then
		changeWeather()
		halfHourTick = getTickCount() + 1800000
	end

	syncTime()
end

function syncTime(toPlayer)
	if timeFreezed then
		return
	end

	local realTime = getRealTime()
	local currentHour = realTime.hour
	
	if realTime.month == 0 or realTime.month == 1 or (realTime.month >= 10 and realTime.month <= 12) then
		if currentHour >= 16 or currentHour >= 0 and currentHour <= 5 then
			currentHour = 0
		end
	end
	
	if currentHour >= 24 then
		currentHour = currentHour - 24
	elseif currentHour < 0 then
		currentHour = currentHour + 24
	end
	
	setTime(currentHour, realTime.minute)
	setMinuteDuration(60000)
	setWeather(currentWeather)

	if toPlayer then
		triggerClientEvent(toPlayer, "receiveWeather", toPlayer, currentWeather, currentHour, realTime.minute)
	else
		triggerClientEvent("receiveWeather", getResourceRootElement(), currentWeather, currentHour, realTime.minute)
	end
end

local weatherNames = {
	["Haze"] = "Ködös",
	["Mostly Cloudy"] = "Többnyire felhős",
	["Clear"] = "Tiszta",
	["Cloudy"] = "Felhős",
	["Flurries"] = "Havas",
	["Fog"] = "Ködös",
	["Mostly Sunny"] = "Túlnyomóan napos",
	["Partly Cloudy"] = "Részben felhős",
	["Partly Sunny"] = "Részben napos",
	["Freezing Rain"] = "Ónos esős",
	["Rain"] = "Esős",
	["Sleet"] = "Havas esős",
	["Snow"] = "Havas",
	["Sunny"] = "Napos",
	["Thunderstorms"] = "Zivataros",
	["Thunderstorm"] = "Zivataros",
	["Unknown"] = "Ismeretlen",
	["Overcast"] = "Felhős",
	["Scattered Clouds"] = "Szétszórtan felhős",
	["Light Snow"] = "Enyhén havas",
}

local weatherIDs = {
	["Haze"] = math.random(12,15),
	["Mostly Cloudy"] = 2,
	["Clear"] = 10,
	["Cloudy"] = math.random(0,7),
	["Flurries"] = 32,
	["Fog"] = math.random(0,7),
	["Mostly Sunny"] = math.random(0,7),
	["Partly Cloudy"] = math.random(0,7),
	["Partly Sunny"] = math.random(0,7),
	["Freezing Rain"] = 2,
	["Rain"] = 2,
	["Sleet"] = 2,
	["Snow"] = 4,
	["Sunny"] = 11,
	["Thunderstorms"] = 8,
	["Thunderstorm"] = 8,
	["Unknown"] = 0,
	["Overcast"] = 7,
	["Scattered Clouds"] = 7,
	["Light Snow"] = 4,
}

function changeWeather()
	if weatherFreezed then
		return
	end

	--[[
	if #availableWeathers > 1 then
		while currentWeather == oldWeather do
			currentWeather = availableWeathers[math.random(1, #availableWeathers)]
		end
	end

	oldWeather = currentWeather
	]]

	--http://api.apixu.com/v1/current.json?key=22bde3cbef67499d999174354182712&q=Los_Angeles
	fetchRemote("http://api.apixu.com/v1/current.json?key=22bde3cbef67499d999174354182712&q=Budapest",
		function(data)
			local result = fromJSON(data)
			local temp_c = tonumber(result["current"]["temp_c"])
			local weather = tonumber(result["current"]["condition"]["text"])

			if not weatherNames[weather] then
				weather = "Cloudy"
			end

			if not string.find(weather, "storm") then
				setWeather(weatherIDs[weather])
			else
				setWeather(0)
			end

			setElementData(resourceRoot, "serverWeather", {temp_c, weatherNames[weather]})

			outputDebugString("Időjárás: " .. weatherNames[weather] .. ", Hőmérséklet: " .. temp_c .. " °C")
		end,
	nil, true)
end

function setServerWeather(weatherId, freeze)
	weatherFreezed = freeze
	currentWeather = weatherId or availableWeathers[math.random(1, #availableWeathers)]
	oldWeather = currentWeather

	if timeFreezed then
		triggerClientEvent("receiveWeather", getResourceRootElement(), currentWeather, timeFreezed[1], timeFreezed[2])
	else
		syncTime()
	end
end

function setServerTime(hour, minute, freeze)
	timeFreezed = freeze and {hour, minute} or false

	if freeze then
		triggerClientEvent("receiveWeather", getResourceRootElement(), currentWeather, hour, minute)
	else
		syncTime()
	end
end

exports.sarp_admin:addAdminCommand("settime", 8, "Szerver idő módosítása")
addCommandHandler("settime",
	function (player, command, hour, minute)
		if getElementData(player, "acc.adminLevel") >= 8 then
			if not hour then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [óra (* = valós idő)] [perc]", player, 0, 0, 0, true)
			elseif hour == "*" then
				setServerTime(false, false, false)
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az idő sikeresen visszaállítva a valós időhöz.", player, 0, 0, 0, true)
			else
				hour = tonumber(hour) or 12
				minute = tonumber(minute) or 0

				if hour < 0 or hour > 23 then
					outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az óra nem lehet kisebb mint #ff46460 #ffffffés nem lehet nagyobb mint #ff464623#ffffff.", player, 0, 0, 0, true)
					return
				end

				if minute < 0 and minute > 59 then
					outputChatBox(exports.sarp_core:getServerTag("admin") .. "A perc nem lehet kisebb mint #ff46460 #ffffffés nem lehet nagyobb mint #ff464659#ffffff.", player, 0, 0, 0, true)
					return
				end

				setServerTime(hour, minute, true)
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az idő sikeresen átállítva! #ffa600(" .. string.format("%.2i:%.2i", hour, minute) .. ")", player, 0, 0, 0, true)
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("setweather", 8, "Szerver időjárás módosítása")
addCommandHandler("setweather",
	function (player, command, weatherId)
		if getElementData(player, "acc.adminLevel") >= 8 then
			if not weatherId then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. command .. " [időjárás id (* = random)]", player, 0, 0, 0, true)
			elseif weatherId == "*" then
				setServerWeather(false, false)
			else
				weatherId = tonumber(weatherId) or 0
				setServerWeather(weatherId, true)
				outputChatBox(exports.sarp_core:getServerTag("admin") .. "Az időjárás sikeresen átállítva! #ffa600(" .. weatherId .. ")", player, 0, 0, 0, true)
			end
		end
	end
)