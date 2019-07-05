local screenX, screenY = guiGetScreenSize()
local responsiveMultipler = exports.sarp_hud:getResponsiveMultipler()

function respc(value)
	return math.ceil(value * responsiveMultipler)
end

local loadScreenStarted = false
local loadScreenFadeOut = false
local currentText = 1
local interpolateSpeedSet = {}
local loadScreenSpeed = 0
local sizeForLoadingBar = 0
local backgroundSound = false
local executableEvent = false
local executableEventArgs = false
local lastChatState = isChatVisible()
local circleSize = respc(64)
local circleSize2 = respc(128)
local logoAlpha = 0
local logoInterpolationStart = false

function loadFonts()
	local fonts = {
		RobotoFont = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(17.5), false, "antialiased"),
		RobotoFont2 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(22), false, "antialiased")
	}

	for k,v in pairs(fonts) do
		_G[k] = v
		_G[k .. "Size"] = dxGetFontHeight(1, _G[k])
	end
end

local logoNodes = {
	[1] = {
		[1] = {
			{129, 0, 18, 64},
			{18, 64, 18, 194},
			{18, 194, 129, 256}
		},
		[2] = {
			{129, 40, 56, 83},
			{56, 83, 56, 115},
			{56, 115, 129, 155}
		},
		[3] = {
			{129, 196, 70, 163},
			{70, 163, 70, 140},
			{70, 140, 56, 140},
			{56, 140, 56, 173},
			{56, 173, 129, 213}
		},
		[4] = {
			{129, 59, 70, 92},
			{70, 92, 70, 106},
			{70, 106, 135, 143},
			{135, 143, 129, 155}
		}
	},
	[2] = {
		[1] = {
			{129, 0, 239, 64},
			{239, 64, 239, 194},
			{239, 194, 129, 256}
		},
		[2] = {
			{129, 40, 201, 83},
			{201, 83, 201, 115},
			{201, 115, 187, 115},
			{187, 115, 187, 92},
			{187, 92, 129, 59}
		},
		[3] = {
			{129, 99, 122, 112},
			{122, 112, 187, 149},
			{187, 149, 187, 163},
			{187, 163, 129, 196}
		},
		[4] = {
			{129, 99, 201, 141},
			{201, 141, 201, 172},
			{201, 172, 129, 213}
		}
	}
}

addEventHandler("onAssetsLoaded", getRootElement(),
	function ()
		loadFonts()
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		loadFonts()
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		for k, v in pairs(getElementsByType("sound")) do
			destroyElement(v)
		end
	end
)

addCommandHandler("loadscreen",
	function ()
		exports.sarp_loader:showTheLoadScreen(15000, {"Karakter inicilizálása", "Karakter adatok betöltése", "Felhasználói felület betöltése", "Szinkronizációk folyamatban"})
	end
)

function showTheLoadScreen(speed, texts, event, ...)
	if loadScreenStarted then
		removeEventHandler("onClientRender", getRootElement(), renderTheLoadingScreen)
		showChat(false)
	else
		lastChatState = isChatVisible()
		showChat(false)
	end

	if isElement(backgroundSound) then
		stopSound(backgroundSound)
		backgroundSound = nil
	end
	
	local tickCount = getTickCount()

	currentText = 1
	interpolateSpeedSet = {}
	sizeForLoadingBar = 0

	for i = 1, #texts do
		interpolateSpeedSet[i] = {
			texts[i],
			tickCount + speed / (#texts - 1) * i,
			tickCount + speed / (#texts - 1) * (i - 1),
			circleSize + respc(300)
		}

		if i < #texts then
			sizeForLoadingBar = sizeForLoadingBar + interpolateSpeedSet[i][4]
		else
			sizeForLoadingBar = sizeForLoadingBar + circleSize
		end

		if i == 1 then
			interpolateSpeedSet[i][5] = tickCount
		end
	end

	logoInterpolationStart = false
	logoAlpha = 0
	
	loadScreenStarted = tickCount
	loadScreenFadeOut = tickCount + speed
	loadScreenSpeed = speed
	
	executableEvent = event
	executableEventArgs = {...}

	backgroundSound = playSound(":sarp_assets/audio/loader/loading.ogg", true)
	setSoundVolume(backgroundSound, 0.2)

	addEventHandler("onClientRender", getRootElement(), renderTheLoadingScreen, true, "low-9999999999999")
end
addEvent("showTheLoadScreen", true)
addEventHandler("showTheLoadScreen", getRootElement(), showTheLoadScreen)

function renderTheLoadingScreen()
	if not loadScreenStarted then
		return
	end

	local tickCount = getTickCount()
	local loadingProgress = (tickCount - loadScreenStarted) / loadScreenSpeed
	local alpha = 1

	if loadingProgress > 1 and tickCount >= loadScreenFadeOut then
		local progress = (tickCount - loadScreenFadeOut) / 480

		alpha = interpolateBetween(
			1, 0, 0,
			0, 0, 0,
			progress, "InOutQuad")

		if isElement(backgroundSound) then
			setSoundVolume(backgroundSound, (1 - progress) * 0.2)
		end

		if progress > 1 then
			alpha = 0
		end

		loadingProgress = 1
	end

	dxDrawRectangle(0, 0, screenX, screenY, tocolor(16, 16, 16, 255 * alpha))

	local x = screenX / 2 - sizeForLoadingBar / 2
	local y = screenY / 2 - respc(384) / 2

	drawLogoAnimation(screenX / 2 - 256 / 2, y - 128, alpha)
	--dxDrawImage(screenX / 2 - 256 / 2, y - 128, 256, 256, "files/logo.png", 0, 0, 0, tocolor(50, 179, 239, 255 * alpha))
	y = y + 164

	dxDrawText("Betöltés folyamatban... " .. math.floor(loadingProgress * 100) .. "%", 0, y, screenX, screenY, tocolor(255, 255, 255, 255 * alpha), 1, RobotoFont2, "center", "top")
	y = y + RobotoFont2Size * 2

	if interpolateSpeedSet[currentText] then
		if tickCount > interpolateSpeedSet[currentText][2] then
			if interpolateSpeedSet[currentText + 1] then
				currentText = currentText + 1

				interpolateSpeedSet[currentText][5] = getTickCount()
			end
		end
	end

	for k = 1, #interpolateSpeedSet do
		local v = interpolateSpeedSet[k]
		local x2 = x + v[4] * (k - 1)

		if currentText >= k then
			local segmentAlpha = 0

			if v[5] and tonumber(v[5]) then
				local progress = (tickCount - v[5]) / 500
				local alpha2 = interpolateBetween(
					0, 0, 0,
					255, 0, 0,
					progress, "OutQuad")

				if progress < 1 then
					dxDrawImage(x2, y, circleSize, circleSize, "files/circle.png", 0, 0, 0, tocolor(75, 75, 75, (255 - alpha2) * alpha))
				end

				segmentAlpha = alpha2

				if progress > 1 then
					v[5] = true
				end
			elseif v[5] then
				segmentAlpha = 255
			end

			dxDrawImage(x2, y, circleSize, circleSize, "files/circle.png", 0, 0, 0, tocolor(50, 179, 239, segmentAlpha * alpha))
			dxDrawImage(x2 - (circleSize2 - circleSize) / 2, y - (circleSize2 - circleSize) / 2, circleSize2, circleSize2, "files/circle_glow.png", 0, 0, 0, tocolor(50, 179, 239, segmentAlpha * alpha))
			dxDrawImage(x2 - (circleSize2 - circleSize) / 2, y - (circleSize2 - circleSize) / 2, circleSize2, circleSize2, "files/circle_check.png", 0, 0, 0, tocolor(255, 255, 255, segmentAlpha * alpha))

			if k < #interpolateSpeedSet then
				if currentText == k then
					local elapsedTime = tickCount - interpolateSpeedSet[currentText][3]
					local progress = elapsedTime / (interpolateSpeedSet[currentText][2] - interpolateSpeedSet[currentText][3])
					local barSizeX = interpolateBetween(
						0, 0, 0,
						v[4] - circleSize + respc(16), 0, 0,
						progress, "Linear")

					dxDrawRectangle(x2 + circleSize - respc(8), y + (circleSize - respc(5)) / 2, v[4] - circleSize + respc(16), respc(5), tocolor(75, 75, 75, 255 * alpha))
					dxDrawRectangle(x2 + circleSize - respc(8), y + (circleSize - respc(5)) / 2, barSizeX, respc(5), tocolor(50, 179, 239, 255 * alpha))
				else
					dxDrawRectangle(x2 + circleSize - respc(8), y + (circleSize - respc(5)) / 2, v[4] - circleSize + respc(16), respc(5), tocolor(50, 179, 239, 255 * alpha))
				end
			end
		else
			dxDrawImage(x2, y, circleSize, circleSize, "files/circle.png", 0, 0, 0, tocolor(75, 75, 75, 255 * alpha))

			if k < #interpolateSpeedSet then
				dxDrawRectangle(x2 + circleSize - respc(8), y + (circleSize - respc(5)) / 2, v[4] - circleSize + respc(16), respc(5), tocolor(75, 75, 75, 255 * alpha))
			end
		end

		dxDrawText(v[1], x2, y + circleSize, x2 + circleSize, y + circleSize*2, tocolor(255, 255, 255, 255 * alpha), 0.75, RobotoFont, "center", "center")
	end

	if alpha <= 0 then
		loadScreenStarted = false

		if isElement(backgroundSound) then
			stopSound(backgroundSound)
			backgroundSound = nil
		end
		
		if executableEvent then
			triggerEvent(executableEvent, localPlayer, unpack(executableEventArgs))
		end
		
		removeEventHandler("onClientRender", getRootElement(), renderTheLoadingScreen)

		showChat(lastChatState)
	end
end

function drawLogoAnimation(x, y, a)
	if not logoAlpha then
		logoAlpha = 0
	end

	if logoAlpha < 245 then
		for i = 1, #logoNodes do
			for j = 1, #logoNodes[i] do
				local mainNode = logoNodes[i][j]

				if not mainNode[1][5] and not mainNode[1][6] then
					mainNode[1][5] = getTickCount()
				end

				for k = 1, #mainNode do
					local node = mainNode[k]

					if node[5] and getTickCount() >= node[5] then
						local elapsedTime = getTickCount() - node[5]
						local duration = (loadScreenSpeed - 375) / #mainNode
						local progress = elapsedTime / duration

						local x2, y2 = interpolateBetween(
							node[1], node[2], 0,
							node[3], node[4], 0,
							progress, "Linear"
						)

						dxDrawLine(x + node[1], y + node[2], x + x2, y + y2, tocolor(50, 179, 239, 255 * a), 1)

						if progress >= 1 then
							if mainNode[k+1] then
								mainNode[k+1][5] = getTickCount()
							end

							if j == 3 and k == #mainNode then
								if not logoInterpolationStart then
									logoInterpolationStart = getTickCount()
								end
							end

							node[5] = false
							node[6] = true
						end
					elseif node[6] then
						dxDrawLine(x + node[1], y + node[2], x + node[3], y + node[4], tocolor(50, 179, 239, 255 * a), 1)
					end
				end
			end
		end
	end

	if logoInterpolationStart and getTickCount() >= logoInterpolationStart then
		local elapsedTime = getTickCount() - logoInterpolationStart
		local progress = elapsedTime / 750

		logoAlpha = interpolateBetween(
			0, 0, 0,
			255, 0, 0,
			progress, "Linear")
	end

	dxDrawImage(x, y, 256, 256, "files/logo.png", 0, 0, 0, tocolor(50, 179, 239, logoAlpha * a))
end