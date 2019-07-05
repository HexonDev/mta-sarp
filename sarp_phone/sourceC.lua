local screenX, screenY = guiGetScreenSize()

local responsiveMultipler = 1--exports.sarp_hud:getResponsiveMultipler()

local function respc(x)
	return math.ceil(x * responsiveMultipler)
end

local function resp(x)
	return x * responsiveMultipler
end

local phoneWidth = respc(280)
local phoneHeight = respc(512)

local phonePosX = screenX - phoneWidth - resp(12)
local phonePosY = screenY / 2 - phoneHeight / 2

local forceState = true
local phoneState = false

local currentPage = "lockscreen"

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

local textures = {}
local weatherData = {}

local buttons = {}
local activeButton = false

local fakeInputs = {}
local activeFakeInput = false

local apps = {
	{"settings.png", "changepage:settings", "Beállítások"},
	{"contacts.png", "changepage:contacts", "Névjegyzék"},
	{"phone.png", "changepage:phone", "Tárcsázó"},
	--{"sms.png", "changepage:messages", "Üzenetek"}
}

local setNum = 11
local offsetSet = 0
local settings = {
	{"wallpaper_icon.png", "changepage:changewallpaper", "Háttérkép beállítása"},
}

local wallpapersNum = 5
local offsetWallpaper = 0
local selectedWallpaper = 1
local currentWallpaper = 1
local randomWallpaperMode = false

local myPhoneNum = false

local contacts = {}
local contactsEx = {}
local offsetContact = 0
local contactNum = 8
local selectedContact = false

addEventHandler("onClientResourceStart", getRootElement(),
	function(res)
		local weather = getResourceFromName("sarp_weather")

		if weather and getResourceState(weather) == "running" then
			weatherData = getElementData(getResourceRootElement(weather), "serverWeather")
		end

		if res == getThisResource() then
			triggerEvent("requestChangePhoneStartPos", localPlayer)
		end
	end)

addEventHandler("onClientElementDataChange", getRootElement(),
	function(data)
		if data == "serverWeather" then
			weatherData = getElementData(source, "serverWeather")
		end
	end)

local RobotoFont = false
local RobotoFontLighter = false

function createFonts()
	RobotoFont = dxCreateFont(":sarp_assets/fonts/Roboto-Regular.ttf", resp(15), false, "antialiased")
	RobotoFontLighter = dxCreateFont(":sarp_assets/fonts/Roboto-Light.ttf", resp(40), false, "cleartype")
end

function destroyFonts()
	if isElement(RobotoFont) then
		destroyElement(RobotoFont)
		RobotoFont = nil
	end

	if isElement(RobotoFontLighter) then
		destroyElement(RobotoFontLighter)
		RobotoFontLighter = nil
	end
end

addEvent("openPhone", true)
addEventHandler("openPhone", getRootElement(),
	function(dbID, phoneNumber, datas, balance)
		if phoneState and (currentPage == "talking" or currentPage == "incoming") then
			return
		end

		phoneState = not phoneState

		myPhoneNum = phoneNumber

		if randomWallpaperMode then
			math.randomseed(getTickCount() + math.random(getTickCount()))

			currentWallpaper = math.random(wallpapersNum)
		end

		selectedWallpaper = currentWallpaper

		if not selectedWallpaper or selectedWallpaper < 0 or selectedWallpaper > wallpapersNum then
			selectedWallpaper = 1
		end

		commandHandler("changepage:lockscreen")

		if phoneState then
			createFonts()

			addEventHandler("onClientRender", getRootElement(), renderThePhone)
			addEventHandler("onClientClick", getRootElement(), onPhoneClick)
			addEventHandler("onClientKey", getRootElement(), onPhoneKey)
			addEventHandler("onClientCharacter", getRootElement(), processFakeInput)
		else
			removeEventHandler("onClientRender", getRootElement(), renderThePhone)
			removeEventHandler("onClientClick", getRootElement(), onPhoneClick)
			removeEventHandler("onClientKey", getRootElement(), onPhoneKey)
			removeEventHandler("onClientCharacter", getRootElement(), processFakeInput)

			destroyFonts()
		end
	end)

function processPhoneShowHide(state)
	forceState = state
end

function changePhoneStartPos(x, y)
	phonePosX, phonePosY = x, y
end

function drawTaskbar()
	if currentPage == "lockscreen" then
		dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/taskbar.png"))
	else
		dxDrawImage(phonePosX + resp(-32), phonePosY, resp(280), resp(512), processPhoneTexture("files/taskbar.png"))
		dxDrawText(replaceDynamicText("#currenttime"), phonePosX, phonePosY + resp(33), phonePosX + resp(265), 0, tocolor(255, 255, 255), 0.5, RobotoFont, "right", "top")
	end
end

function drawBaseButtons()
	dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/mainbuttons.png"))

	buttons["changepage:home"] = {phonePosX + resp(140) - resp(12), phonePosY + resp(469) - resp(12), resp(24), resp(24)}
end

function renderThePhone()
	if phoneState and forceState then
		buttons = {}

		-- ** Alap
		dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/base.png"))

		-- ** Háttérkép
		dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/wallpapers/" .. currentWallpaper .. ".png"))

		-- ** Zárképernyő
		if currentPage == "lockscreen" then
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(0, 0, 0, 180))

			dxDrawText("Érintsd meg a kijelzőt a feloldáshoz", phonePosX, phonePosY + resp(360), phonePosX + resp(280), 0, tocolor(255, 255, 255), 0.6, RobotoFont, "center", "top")

			drawTaskbar()

			dxDrawText(replaceDynamicText("#currenttime"), phonePosX + resp(30), phonePosY + resp(380), 0, 0, tocolor(255, 255, 255), 1, RobotoFontLighter, "left", "top")
			dxDrawText(replaceDynamicText("#currentdate"), phonePosX + resp(30), phonePosY + resp(450), 0, 0, tocolor(180, 180, 180), 0.625, RobotoFont, "left", "top")

			buttons["unlockphone"] = {phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452)}
		-- ** Főképernyő
		elseif currentPage == "home" then
			drawTaskbar()
			drawBaseButtons()

			-- elválasztó
			dxDrawRectangle(phonePosX + resp(179), phonePosY + resp(83), 1, resp(67), tocolor(200, 200, 200))

			-- idő/dátum/pozíció
			dxDrawText(replaceDynamicText("#currenttime"), 0, phonePosY + resp(71), phonePosX + resp(168), 0, tocolor(255, 255, 255), 0.85, RobotoFontLighter, "right", "top")

			dxDrawText(replaceDynamicText("#currentdatefull"), 0, phonePosY + resp(125), phonePosX + resp(168), 0, tocolor(255, 255, 255), 0.53, RobotoFont, "right", "top")

			local mapMarkerSize = resp(14)

			dxDrawImage(math.floor(phonePosX + resp(168) - mapMarkerSize), math.floor(phonePosY + resp(140)), mapMarkerSize, mapMarkerSize, processPhoneTexture("files/mapmarker.png"))

			dxDrawText(replaceDynamicText("#currentcity"), 0, phonePosY + resp(140), phonePosX + resp(168) - mapMarkerSize, 0, tocolor(255, 255, 255), 0.53, RobotoFont, "right", "top")

			-- hőmérséklet/időjárás
			dxDrawImage(math.floor(phonePosX + resp(193)), math.floor(phonePosY + resp(85)), resp(26), resp(26), processPhoneTexture("files/cloud.png"))

			dxDrawText(math.floor(weatherData[1] * 10) / 10 .. "°", phonePosX + resp(191), phonePosY + resp(108), 0, 0, tocolor(255, 255, 255), 0.48, RobotoFontLighter, "left", "top")

			dxDrawText(utf8.lower(weatherData[2]), phonePosX + resp(191), phonePosY + resp(140), 0, 0, tocolor(255, 255, 255), 0.53, RobotoFont, "left", "top")

			-- applikációk
			local firstPosX = phonePosX + resp(27)
			local appStartPosX, appStartPosY = firstPosX, phonePosY + resp(380)

			for i=1,#apps do
				if i % 5 == 0 then
					appStartPosX = firstPosX
					appStartPosY = appStartPosY - resp(65)
				end

				dxDrawImage(math.floor(appStartPosX), math.floor(appStartPosY), resp(36), resp(36), processPhoneTexture("files/apps/" .. apps[i][1]))

				dxDrawText(apps[i][3], appStartPosX, appStartPosY + resp(40), appStartPosX + resp(36), 0, tocolor(255, 255, 255), 0.45, RobotoFont, "center", "top")

				buttons[apps[i][2]] = {appStartPosX, appStartPosY, resp(36), resp(36)}

				appStartPosX = appStartPosX + resp(64)
			end
		-- ** Beállítások
		elseif currentPage == "settings" then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(15, 15, 15, 240))

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- cím
			dxDrawText("Beállítások", phonePosX + resp(21), phonePosY + resp(52), 0, 0, tocolor(255, 255, 255), 0.4, RobotoFontLighter, "left", "top")

			-- elválasztó
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(80), resp(260), resp(2), tocolor(50, 50, 50))

			-- menü elemek
			local oneSize = (resp(432) - resp(25) - resp(32)) / setNum

			for i=1,setNum do
				local x = phonePosX + resp(10)
				local y = phonePosY + resp(82) + (i-1) * oneSize

				if i % 2 == 0 then
					dxDrawRectangle(x, y, resp(260), oneSize, tocolor(0, 0, 0, 25))
				else
					dxDrawRectangle(x, y, resp(260), oneSize, tocolor(0, 0, 0, 50))
				end

				local set = settings[i + offsetSet]

				if set then
					local pictureSize = oneSize * 0.75

					dxDrawImage(math.floor(x + oneSize / 2 - pictureSize / 2), math.floor(y + oneSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/" .. set[1]), 0, 0, 0, tocolor(0, 170, 255))
				
					dxDrawText(set[3], x + oneSize, y, x + resp(260), y + oneSize, tocolor(255, 255, 255), 0.6, RobotoFont, "left", "center")

					if activeButton == set[2] then
						dxDrawImage(math.floor(x + resp(260) - pictureSize), math.floor(y + oneSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(0, 170, 255))
					else
						dxDrawImage(math.floor(x + resp(260) - pictureSize), math.floor(y + oneSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(255, 255, 255, 50))
					end
				
					buttons[set[2]] = {x, y, resp(260), oneSize}
				end
			end
		-- ** Háttérkép beállítása
		elseif currentPage == "changewallpaper" then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(15, 15, 15, 240))

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- cím
			dxDrawText("Háttérkép beállítása", phonePosX + resp(21), phonePosY + resp(52), 0, 0, tocolor(255, 255, 255), 0.4, RobotoFontLighter, "left", "top")

			-- elválasztó
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(80), resp(260), resp(2), tocolor(50, 50, 50))

			-- change wallpaper
			local y =  phonePosY + resp(82)

			dxDrawRectangle(phonePosX + resp(10),y, resp(260), respc(40), tocolor(0, 0, 0, 25))

			dxDrawText("Háttérkép kiválasztása", phonePosX + resp(20), y, 0, y + respc(40), tocolor(255, 255, 255), 0.6, RobotoFont, "left", "center")

			if activeButton == "changepage:selectwallpaper" then
				dxDrawImage(math.floor(phonePosX + resp(270) - respc(30)), math.floor(y + respc(40) / 2 - respc(30) / 2), respc(30), respc(30), processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(0, 170, 255))
			else
				dxDrawImage(math.floor(phonePosX + resp(270) - respc(30)), math.floor(y + respc(40) / 2 - respc(30) / 2), respc(30), respc(30), processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(255, 255, 255, 50))
			end

			buttons["changepage:selectwallpaper"] = {phonePosX + resp(10), y, resp(260), respc(40)}

			-- random wallpaper
			y = y + respc(40)

			dxDrawRectangle(phonePosX + resp(10), y, resp(260), respc(40), tocolor(0, 0, 0, 50))

			dxDrawText("Háttérkép véletlenszerű cseréje", phonePosX + resp(20), y, 0, y + respc(40), tocolor(255, 255, 255), 0.575, RobotoFont, "left", "center")
		
			drawButtonSlider("randomwallpaper", randomWallpaperMode, phonePosX + resp(265) - resp(64), y + respc(40) / 2 - resp(28) / 2, resp(28), {75, 75, 75}, {75, 75, 75}, {0, 170, 255})
		-- ** Háttérkép kiválasztása
		elseif currentPage == "selectwallpaper" then
			-- háttérkép
			if selectedWallpaper ~= currentWallpaper then
				dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/wallpapers/" .. selectedWallpaper .. ".png"))
			end

			drawBaseButtons()

			-- fade effekt
			dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/fade.png"))

			-- cím
			dxDrawText("Háttérkép beállítása", phonePosX, phonePosY + resp(40), phonePosX + resp(280), 0, tocolor(255, 255, 255), 0.75, RobotoFont, "center", "top")

			-- mégsem
			if activeButton == "closeSelectWallpaper" then
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(40)), resp(20), resp(20), processPhoneTexture("files/x.png"), 0, 0, 0, tocolor(215, 89, 89))
			else
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(40)), resp(20), resp(20), processPhoneTexture("files/x.png"))
			end
			buttons["closeSelectWallpaper"] = {phonePosX + resp(20) - resp(5), phonePosY + resp(40) - resp(5), resp(30), resp(30)}

			-- mentés
			if activeButton == "saveSelectWallpaper" then
				dxDrawImage(math.floor(phonePosX + resp(240)), math.floor(phonePosY + resp(40)), resp(20), resp(20), processPhoneTexture("files/check.png"), 0, 0, 0, tocolor(0, 170, 255))
			else
				dxDrawImage(math.floor(phonePosX + resp(240)), math.floor(phonePosY + resp(40)), resp(20), resp(20), processPhoneTexture("files/check.png"))
			end
			buttons["saveSelectWallpaper"] = {phonePosX + resp(240) - resp(5), phonePosY + resp(40) - resp(5), resp(30), resp(30)}

			-- képek
			local oneSize = (resp(260) - resp(10) - resp(10) * 4) / 4

			for i=1,4 do
				local wp = i + offsetWallpaper

				if wp then
					local x = phonePosX + resp(10) + (i-1) * oneSize + i * resp(10)
					local y = phonePosY + resp(427) - oneSize

					dxDrawImageSection(x, y, oneSize, oneSize, 280 / 2 - 128 / 2, 512 / 2 - 128 / 2, 128, 128, processPhoneTexture("files/wallpapers/" .. wp .. ".png"))

					if activeButton == "viewWallpaper:" .. i + offsetWallpaper then
						dxDrawRectangle(x, y, oneSize, oneSize, tocolor(0, 0, 0, 125))
					end

					if selectedWallpaper == wp then
						dxDrawRectangle(x - resp(2), y - resp(2), oneSize + resp(4), resp(2), tocolor(0, 170, 255)) -- teteje
						dxDrawRectangle(x - resp(2), y + oneSize, oneSize + resp(4), resp(2), tocolor(0, 170, 255)) -- alja
						dxDrawRectangle(x - resp(2), y, resp(2), oneSize, tocolor(0, 170, 255)) -- bal
						dxDrawRectangle(x + oneSize, y, resp(2), oneSize, tocolor(0, 170, 255)) -- jobb
					else
						dxDrawRectangle(x - resp(2), y - resp(2), oneSize + resp(4), resp(2), tocolor(75, 75, 75)) -- teteje
						dxDrawRectangle(x - resp(2), y + oneSize, oneSize + resp(4), resp(2), tocolor(75, 75, 75)) -- alja
						dxDrawRectangle(x - resp(2), y, resp(2), oneSize, tocolor(75, 75, 75)) -- bal
						dxDrawRectangle(x + oneSize, y, resp(2), oneSize, tocolor(75, 75, 75)) -- jobb

						buttons["viewWallpaper:" .. i + offsetWallpaper] = {x, y, oneSize, oneSize}
					end
				end
			end

			-- infó
			dxDrawText("A lapozáshoz használd a görgőt", phonePosX, phonePosY + resp(340), phonePosX + resp(280), 0, tocolor(255, 255, 255), 0.6, RobotoFont, "center", "top")
		-- ** Névjegyzék
		elseif currentPage == "contacts" then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(15, 15, 15, 240))

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- cím
			dxDrawText("Névjegyek", phonePosX + resp(21), phonePosY + resp(52), 0, 0, tocolor(255, 255, 255), 0.4, RobotoFontLighter, "left", "top")

			-- elválasztó
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(80), resp(260), resp(2), tocolor(50, 50, 50))

			-- új névjegy hozzáadása
			if activeButton == "changepage:addcontact" then
				dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/addcontacthover.png"))
			else
				dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/addcontact.png"))
			end
			buttons["changepage:addcontact"] = {phonePosX + resp(111), phonePosY + resp(423), resp(55), resp(28)}

			-- menü elemek
			local oneSize = (resp(432) - resp(32) - resp(60)) / contactNum
			local pictureSize = oneSize * 0.75

			if #contacts < 1 then
				dxDrawText("Nincsenek hozzáadott névjegyeid.", phonePosX + resp(25), phonePosY + resp(85), 0, 0, tocolor(150, 150, 150, 150), 0.6, RobotoFont, "left", "top")
			else
				for i=1,contactNum do
					local x = phonePosX + resp(10)
					local y = phonePosY + resp(80) + (i-1) * oneSize

					local contact = contacts[i + offsetContact]

					if contact then
						if i + offsetContact ~= contactNum + offsetContact then
							dxDrawRectangle(x + resp(10), y + oneSize, resp(240), 1, tocolor(50, 50, 50))
						end

						dxDrawRectangle(x + resp(15), y + oneSize / 2 - pictureSize / 2, pictureSize, pictureSize, contact[3])
						
						dxDrawText(utf8.upper(utf8.sub(contact[1], 1, 1)), x + resp(15), y + oneSize / 2 - pictureSize / 2, x + resp(15) + pictureSize, y + oneSize / 2 + pictureSize / 2, tocolor(255, 255, 255), 0.75, RobotoFont, "center", "center")

						if activeButton == "selectcontact:" .. i then
							dxDrawText(contact[1], x + resp(15) + pictureSize + resp(5), y, x + resp(255) - pictureSize, y + oneSize, tocolor(0, 170, 255), 0.6, RobotoFont, "left", "center", true)
						else
							dxDrawText(contact[1], x + resp(15) + pictureSize + resp(5), y, x + resp(255) - pictureSize, y + oneSize, tocolor(255, 255, 255), 0.6, RobotoFont, "left", "center", true)
						end
						
						if activeButton == "deletecontact:" .. i then
							dxDrawImage(math.floor(x + resp(250) - pictureSize), math.floor(y + oneSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/x.png"), 0, 0, 0, tocolor(215, 89, 89))
						else
							dxDrawImage(math.floor(x + resp(250) - pictureSize), math.floor(y + oneSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/x.png"), 0, 0, 0, tocolor(150, 150, 150, 150))
							
							buttons["selectcontact:" .. i] = {x + resp(10), y, resp(250) - pictureSize, oneSize}
						end

						buttons["deletecontact:" .. i] = {x + resp(250) - pictureSize, y + oneSize / 2 - pictureSize / 2, pictureSize, pictureSize}
					end
				end
			end

			if #contacts > contactNum then
				local totalSize = oneSize * contactNum

				dxDrawRectangle(phonePosX + resp(260), phonePosY + resp(80), respc(5), totalSize, tocolor(25, 25, 25))

				dxDrawRectangle(phonePosX + resp(260), phonePosY + resp(80) + (totalSize / #contacts) * offsetContact, respc(5), (totalSize / #contacts) * contactNum, tocolor(50, 179, 239))
			end
		-- ** Új névjegy
		elseif currentPage == "addcontact" then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(15, 15, 15, 240))

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- cím
			dxDrawText("Új névjegy", phonePosX, phonePosY + resp(52), phonePosX + resp(280), 0, tocolor(255, 255, 255), 0.375, RobotoFontLighter, "center", "top")

			-- mégsem
			if activeButton == "changepage:contacts" then
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/x.png"), 0, 0, 0, tocolor(215, 89, 89))
			else
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/x.png"))
			end
			buttons["changepage:contacts"] = {phonePosX + resp(20) - resp(5), phonePosY + resp(57) - resp(5), resp(30), resp(30)}

			-- mentés
			if activeButton == "addcontact" then
				dxDrawImage(math.floor(phonePosX + resp(240)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/check.png"), 0, 0, 0, tocolor(0, 170, 255))
			else
				dxDrawImage(math.floor(phonePosX + resp(240)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/check.png"))
			end
			buttons["addcontact"] = {phonePosX + resp(240) - resp(5), phonePosY + resp(57) - resp(5), resp(30), resp(30)}

			-- név mező
			drawFakeInput("addContactName", "normal|40", "Név", phonePosX + resp(20), phonePosY + resp(100), resp(240), resp(40), false, tocolor(255, 255, 255), 0.75, RobotoFont, tocolor(100, 100, 100))

			if getActiveFakeInput() == "addContactName" then
				dxDrawRectangle(phonePosX + resp(20), phonePosY + resp(100) + resp(40), resp(240), resp(2), tocolor(0, 170, 255, 125))
			else
				dxDrawRectangle(phonePosX + resp(20), phonePosY + resp(100) + resp(40), resp(240), resp(2), tocolor(80, 80, 80, 80))
			end

			-- telefonszám mező
			drawFakeInput("addContactNum", "num-only|16", "Telefonszám", phonePosX + resp(20), phonePosY + resp(180), resp(240), resp(40), false, tocolor(255, 255, 255), 0.75, RobotoFont, tocolor(100, 100, 100))

			if getActiveFakeInput() == "addContactNum" then
				dxDrawRectangle(phonePosX + resp(20), phonePosY + resp(180) + resp(40), resp(240), resp(2), tocolor(0, 170, 255, 125))
			else
				dxDrawRectangle(phonePosX + resp(20), phonePosY + resp(180) + resp(40), resp(240), resp(2), tocolor(80, 80, 80, 80))
			end
		-- ** Névjegy megtekintése
		elseif currentPage == "viewcontact" and selectedContact and contacts[selectedContact] then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452) / 2, contacts[selectedContact][3]) -- teteje

			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30) + resp(452) / 2, resp(260), resp(452) / 2, tocolor(15, 15, 15, 240)) -- alja

			dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/fade.png"))

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- cím
			dxDrawText(contacts[selectedContact][1] .. "\n" .. contacts[selectedContact][2], phonePosX + resp(22), phonePosY + resp(201), phonePosX + resp(248), phonePosY + resp(266), tocolor(255, 255, 255), 0.375, RobotoFontLighter, "left", "top", true)

			-- vissza gomb
			if activeButton == "changepage:contacts" then
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/arrow2.png"), 0, 0, 0, tocolor(0, 170, 255))
			else
				dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(phonePosY + resp(57)), resp(20), resp(20), processPhoneTexture("files/arrow2.png"))
			end
			buttons["changepage:contacts"] = {phonePosX + resp(20) - resp(5), phonePosY + resp(57) - resp(5), resp(30), resp(30)}

			-- tárcsázás
			local y = phonePosY + resp(452) / 2 + resp(45)
			local holderSize = resp(40)
			local pictureSize = holderSize * 0.6

			dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(y + holderSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/phone_icon.png"), 0, 0, 0, tocolor(180, 180, 180, 180))

			dxDrawText("Tárcsázás", phonePosX + resp(30) + pictureSize, y, 0, y + holderSize, tocolor(255, 255, 255), 0.6, RobotoFont, "left", "center")

			dxDrawRectangle(phonePosX + resp(20), y + holderSize, resp(240), 1, tocolor(50, 50, 50))

			dxDrawImage(math.floor(phonePosX + resp(270) - respc(30)), math.floor(y + holderSize / 2 - resp(24) / 2), respc(24), respc(24), processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(255, 255, 255, 50))
			
			-- sms
			y = y + holderSize

			dxDrawImage(math.floor(phonePosX + resp(20)), math.floor(y + holderSize / 2 - pictureSize / 2), pictureSize, pictureSize, processPhoneTexture("files/comment_icon.png"), 0, 0, 0, tocolor(180, 180, 180, 180))

			dxDrawText("Üzenet küldés", phonePosX + resp(30) + pictureSize, y, 0, y + holderSize, tocolor(255, 255, 255), 0.6, RobotoFont, "left", "center")

			dxDrawRectangle(phonePosX + resp(20), y + holderSize, resp(240), 1, tocolor(50, 50, 50))

			dxDrawImage(math.floor(phonePosX + resp(270) - respc(30)), math.floor(y + holderSize / 2 - resp(24) / 2), respc(24), respc(24), processPhoneTexture("files/arrow.png"), 0, 0, 0, tocolor(255, 255, 255, 50))
		-- ** Tárcsázó
		elseif currentPage == "phone" then
			-- háttér
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(452), tocolor(15, 15, 15, 240))

			-- input
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(30), resp(260), resp(70), tocolor(25, 25, 25))
			drawFakeInput("callPhoneNum", "num-only|16|", false, phonePosX + resp(20), phonePosY + resp(50), resp(240), resp(50), false, tocolor(255, 255, 255), 1, RobotoFont, false, "center")
			activeFakeInput = "callPhoneNum|num-only|16"

			drawTaskbar()
			dxDrawRectangle(phonePosX + resp(10), phonePosY + resp(457), resp(260), resp(25), tocolor(25, 25, 25, 75))
			drawBaseButtons()

			-- hívás gomb
			dxDrawImage(phonePosX, phonePosY, resp(280), resp(512), processPhoneTexture("files/call.png"), 0, 0, 0, tocolor(77, 163, 50))
			buttons["dialNumber"] = {phonePosX + resp(118), phonePosY + resp(408), resp(44), resp(44)}

			-- számgombok
			for i=0,11 do
				if i ~= 9 then
					local x = phonePosX + resp(54) + (resp(44) + resp(20)) * (i % 3)
					local y = phonePosY + resp(210) + (resp(44) + resp(5)) * math.floor(i / 3)

					local num = i == 10 and "0" or tostring(1 + i)
					local colorOfHover = tocolor(0, 170, 255)

					if i == 11 then
						num = "X"
						colorOfHover = tocolor(215, 89, 89)
					end

					if activeButton == "injectFakeInput:callPhoneNum|num-only|16:" .. num then
						dxDrawImage(math.floor(x), math.floor(y), resp(44), resp(44), processPhoneTexture("files/numcircle.png"), 0, 0, 0, colorOfHover)

						dxDrawText(num, x, y, x + resp(44), y + resp(44), colorOfHover, 1, RobotoFont, "center", "center")
					else
						dxDrawImage(math.floor(x), math.floor(y), resp(44), resp(44), processPhoneTexture("files/numcircle.png"), 0, 0, 0, tocolor(150, 150, 150, 150))

						dxDrawText(num, x, y, x + resp(44), y + resp(44), tocolor(255, 255, 255), 1, RobotoFont, "center", "center")
					end

					buttons["injectFakeInput:callPhoneNum|num-only|16:" .. num] = {x, y, resp(44), resp(44)}
				end
			end
		end

		local cursorX, cursorY = getCursorPosition()

		activeButton = false

		if cursorX and cursorY then
			cursorX = cursorX * screenX
			cursorY = cursorY * screenY

			for k, v in pairs(buttons) do
				--dxDrawRectangle(v[1], v[2], v[3], v[4], tocolor(127, 0, 0, 127))

				if cursorX >= v[1] and cursorX <= v[1] + v[3] and cursorY >= v[2] and cursorY <= v[2] + v[4] then
					activeButton = k
				end
			end
		end
	end
end

function getFitFontScale(text, scale, font, maxwidth)
	local scaleex = scale

	if dxGetTextWidth(text, scaleex, font) > maxwidth then
		while dxGetTextWidth(text, scaleex, font) > maxwidth do
			scaleex = scaleex - 0.01
		end
	end

	return scaleex
end

function drawFakeInput(name, properties, label, x, y, sx, sy, bgColor, textColor, fontScale, font, labelColor, alignX)
	if not fakeInputs[name] then
		fakeInputs[name] = ""
	end

	if bgColor then
		dxDrawRectangle(x, y, sx, sy, bgColor)
	end

	local activeInput = getActiveFakeInput()

	alignX = alignX or "left"

	local scale = fontScale

	if utf8.len(fakeInputs[name]) > 0 then
		scale = getFitFontScale(fakeInputs[name], fontScale, font, sx - resp(20))

		dxDrawText(fakeInputs[name], x + resp(10), y, x + sx - resp(10), y + sy, textColor, scale, font, alignX, "center", true)
	elseif label and activeInput ~= name then
		scale = getFitFontScale(label, fontScale, font, sx - resp(20))

		dxDrawText(label, x + resp(10), y, x + sx - resp(10), y + sy, labelColor or textColor, scale, font, alignX, "center", true)
	end

	if activeInput == name and alignX == "left" then
		dxDrawRectangle(x + resp(10) + dxGetTextWidth(fakeInputs[name], scale, font) + resp(2), y + resp(5), resp(2), sy - resp(10), textColor)
	end

	buttons["setInput:" .. name .. "|" .. properties] = {x, y, sx, sy}
end

function replaceDynamicText(text)
	if text == "#currenttime" then
		local time = getRealTime()

		text = string.format("%02d:%02d", time.hour, time.minute)
	elseif text == "#currentdate" then
		local time = getRealTime()

		text = utf8.lower(monthNames[time.month]:sub(1, 4)) .. " " .. time.monthday .. ", " .. dayNames[time.weekday]:sub(1, 3)
	elseif text == "#currentdatefull" then
		local time = getRealTime()

		text = utf8.lower(monthNames[time.month]) .. " " .. time.monthday .. "., " .. dayNames[time.weekday]
	elseif text == "#currentcity" then
		local x, y, z = getElementPosition(localPlayer)

		return getZoneNameEx(x, y, z, true)
	end

	return text
end

function processPhoneTexture(path)
	if isElement(textures[path]) then
		return textures[path]
	elseif not textures[path] then
		textures[path] = dxCreateTexture(path, "argb", true, "clamp")
	end

	return textures[path]
end

function commandHandler(command)
	command = split(command, ":")

	if command[1] == "changepage" then
		currentPage = command[2]

		activeFakeInput = false
		fakeInputs = {}

		if currentPage == "changewallpaper" then
			selectedWallpaper = currentWallpaper
		end
	elseif command[1] == "unlockphone" then
		commandHandler("changepage:home")
	elseif command[1] == "viewWallpaper" then
		local id = tonumber(command[2])

		selectedWallpaper = id
	elseif command[1] == "closeSelectWallpaper" then
		commandHandler("changepage:changewallpaper")
	elseif command[1] == "saveSelectWallpaper" then
		randomWallpaperMode = false

		currentWallpaper = selectedWallpaper

		commandHandler("changepage:home")
	elseif command[1] == "randomwallpaper" then
		randomWallpaperMode = not randomWallpaperMode

		if randomWallpaperMode then
			math.randomseed(getTickCount() + math.random(getTickCount()))

			currentWallpaper = math.random(wallpapersNum)
		end

		selectedWallpaper = currentWallpaper
	elseif command[1] == "addcontact" then
		if utf8.len(fakeInputs.addContactName) > 0 and utf8.len(fakeInputs.addContactNum) > 0 then
			if contactsEx[tonumber(fakeInputs.addContactNum)] then
				exports.sarp_hud:showInfobox("error", "A kiválasztott telefonszámhoz már társítva van egy névjegy!")
				return
			end

			table.insert(contacts, {fakeInputs.addContactName, tonumber(fakeInputs.addContactNum), tocolor(pastelcolor(fakeInputs.addContactName))})
			table.sort(contacts, function(a, b) return a[1] < b[1] end)

			contactsEx = {}

			for i=1,#contacts do
				if contacts[i] then
					contactsEx[contacts[i][2]] = contacts[i][1]
				end
			end

			commandHandler("changepage:contacts")
		end
	elseif command[1] == "deletecontact" then
		local id = tonumber(command[2])

		if contacts[id + offsetContact] then
			local newcontacts = {}

			for i=1,#contacts do
				if contacts[i] and i ~= id + offsetContact then
					table.insert(newcontacts, contacts[i])
				end
			end

			contacts = newcontacts
			contactsEx = {}

			for i=1,#contacts do
				if contacts[i] then
					contactsEx[contacts[i][2]] = contacts[i][1]
				end
			end

			if #contacts > contactNum then
				if offsetContact > #contacts - contactNum then
					offsetContact = #contacts - contactNum
				end
			else
				offsetContact = 0
			end
		end
	elseif command[1] == "selectcontact" then
		local id = tonumber(command[2])

		if contacts[id + offsetContact] then
			selectedContact = id + offsetContact

			commandHandler("changepage:viewcontact")
		end
	elseif command[1] == "injectFakeInput" then
		if utf8.lower(command[3]) == "x" then
			processFakeInput("backspace", command[2])
		else
			processFakeInput(command[3], command[2])
		end
	end
end

function onPhoneClick(button, state)
	if button == "left" then
		if activeButton then
			if string.find(activeButton, "setInput") then
				if state == "down" then
					activeFakeInput = activeButton:gsub("setInput:", "")
				end
			else
				local button = split(activeButton, "_")
				local btnstate = "down"

				if button[2] == "[up]" then
					btnstate = "up"
				end

				if button[3] == "[isButtonDown]" then
					return
				end

				if state == btnstate then
					commandHandler(button[1])
				end
			end
		elseif state == "down" then
			activeFakeInput = false
		end
	end
end

function onPhoneKey(key, state)
	local theInput, inputType, maxChar = getActiveFakeInput()

	if theInput and key ~= "escape" then
		cancelEvent()
	end

	if state then
		if key == "backspace" then
			processFakeInput("backspace")
		end

		if key == "enter" or key == "num_enter" then
			processFakeInput("enter")
		end
	end

	if currentPage == "selectwallpaper" then
		if key == "mouse_wheel_down" then
			if offsetWallpaper < wallpapersNum - 4 then
				offsetWallpaper = offsetWallpaper + 1
			end
		elseif key == "mouse_wheel_up" then
			if offsetWallpaper > 0 then
				offsetWallpaper = offsetWallpaper - 1
			end
		end
	elseif currentPage == "contacts" then
		if key == "mouse_wheel_down" then
			if offsetContact < #contacts - contactNum then
				offsetContact = offsetContact + 1
			end
		elseif key == "mouse_wheel_up" then
			if offsetContact > 0 then
				offsetContact = offsetContact - 1
			end
		end
	end
end

function getActiveFakeInput(forcedInput)
	if forcedInput then
		local input = split(forcedInput, "|")

		return input[1], input[2], tonumber(input[3]), input[4]
	elseif activeFakeInput then
		local input = split(activeFakeInput, "|")

		return input[1], input[2], tonumber(input[3]), input[4]
	end
end

function processFakeInput(key, forcedInput)
	local theInput, inputType, maxChar = getActiveFakeInput(type(forcedInput) == "string" and forcedInput or false)

	if theInput then
		if not fakeInputs[theInput] then
			fakeInputs[theInput] = ""
		end

		if key == "enter" then

		elseif key == "backspace" then
			fakeInputs[theInput] = utf8.sub(fakeInputs[theInput], 1, -2)
		else
			if maxChar > utf8.len(fakeInputs[theInput]) then
				if inputType == "num-only" then
					if tonumber(key) then
						fakeInputs[theInput] = fakeInputs[theInput] .. key
					end
				else
					fakeInputs[theInput] = fakeInputs[theInput] .. key
				end
			end
		end
	end
end

function pastelcolor(str)
	local baseRed, baseGreen, baseBlue = 128, 128, 128
	local seed = 0

	for character in utf8.gmatch(str, ".") do
		seed = seed + utf8.byte(character)
	end
	
	local rand1 = math.abs(math.sin(seed) * 10000) % 256

	seed = seed + seed

	local rand2 = math.abs(math.sin(seed) * 10000) % 256

	seed = seed + seed

	local rand3 = math.abs(math.sin(seed) * 10000) % 256

	return math.ceil(rand1 + baseRed) / 2, math.ceil(rand2 + baseGreen) / 2, math.ceil(rand3 + baseBlue) / 2
end

function drawButtonSlider(key, state, x, y, h, bgColor, offColor, onColor)
	local buttonColor

	if state then
		buttonColor = {onColor[1], onColor[2], onColor[3], 0}
	else
		buttonColor = {offColor[1], offColor[2], offColor[3], 255}
	end

	local alphaDifference = 255 - buttonColor[4]

	buttons[key] = {x, y, resp(64), resp(32)}

	y = y + (h - resp(32)) / 2

	dxDrawImage(x, y, resp(64), resp(32), processPhoneTexture("files/off.png"), 0, 0, 0, tocolor(bgColor[1], bgColor[2], bgColor[3], 255 - alphaDifference))

	dxDrawImage(x, y, resp(64), resp(32), processPhoneTexture("files/on.png"), 0, 0, 0, tocolor(buttonColor[1], buttonColor[2], buttonColor[3], 0 + alphaDifference))

	if not state then
		dxDrawImage(x + (state and 32 or 0), y, resp(64), resp(32), processPhoneTexture("files/circle.png"), 0, 0, 0, tocolor(bgColor[1], bgColor[2], bgColor[3], 255))
	else
		dxDrawImage(x + (state and 32 or 0), y, resp(64), resp(32), processPhoneTexture("files/circle.png"), 0, 0, 0, tocolor(255, 255, 255, 255))
	end
end

local unknownZones = {
	["San Fierro Bay"] = true,
	["Gant Bridge"] = true,
	["Las Venturas"] = true,
	["Bone County"] = true,
	["Tierra Robada"] = true,
}

function getZoneNameEx(x, y, z, cities)
	local zoneName = getZoneName(x, y, z, cities)
	local cityName = zoneName

	if not cities then
		cityName = getZoneName(x, y, z, true)
	end

	if unknownZones[zoneName] or unknownZones[cityName] then
		return "Ismeretlen"
	end

	if zoneName == "Unknown" or cityName == "Unknown" then
		return "Ismeretlen"
	end

	return zoneName
end