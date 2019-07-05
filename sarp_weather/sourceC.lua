local dynamicSkySettings = {
	modelID = 15057,
	sunPreRotation = {25, 0, 0},
	moonPreRotation = {0, 0, 0},
	moonShine = 1,
	modelScale = {0.125, 0.125, 0.125},
	bottomCloudSpread = 700,
	enableIngameClouds = false,
	enableCloudTextures = true,
	enableHorizonBlending = true,
	stratosFade = {70000, 10000},
}

local shaderTable = {}
local textureTable = {}
local modelTable = {}
local tempParam = {}
local moonPhase = 0

local oldWeather = -1 
local windVelocity = {
	[1] = 0.05,
	[3] = 0.1,
	[4] = 0.125,
	[5] = 0.075,
	[7] = 0.3,
	[10] = 0.025,
	[12] = 0.125,
	[14] = 0.03,
	[15] = 0.17,
	[18] = 0.05
}
local removeWeather = {9}
local alphaInWater = 1

local timeHMS = {0, 0, 0}
local minuteStartTickCount
local minuteEndTickCount

local PI = math.pi / 180

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		startDynamicSky()

		setCloudsEnabled(false)
		setBlurLevel(0)

		resetFogDistance()
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		stopDynamicSky()
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		if not dynamicSkyEnabled then
			return
		end
		
		local hour, minute = getTime()
		local seconds = 0
		
		if minute ~= timeHMS[2] then
			local gameSpeed = math.clamp(0.01, getGameSpeed(), 10)

			minuteStartTickCount = getTickCount()
			minuteEndTickCount = minuteStartTickCount + 1000 / gameSpeed
		end
		
		if minuteStartTickCount then
			local minFraction = math.unlerpclamped(minuteStartTickCount, getTickCount(), minuteEndTickCount)

			seconds = math.min(59, math.floor(minFraction * 60))
		end
		
		timeHMS = {hour, minute, seconds}
	end
)

addEvent("receiveWeather", true)
addEventHandler("receiveWeather", getRootElement(),
	function (weatherId, hour, minute)
		if getElementData(localPlayer, "loggedIn") then
			setWeather(weatherId)
			setTime(hour, minute)
		else
			resetSkyGradient()
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if source == localPlayer and dataName == "loggedIn" and getElementData(source, dataName) then
			triggerServerEvent("requestWeather", localPlayer)
		end
	end
)

addEventHandler("onClientDimensionChange", getRootElement(),
	function (newDimension, oldDimension)
		setElementDimension(modelTable.object, newDimension)
	end
)

function startDynamicSky()
	if dynamicSkyEnabled then
		return
	end
	
	shaderTable.skyboxTropos = dxCreateShader("files/shaders/clouds.fx", 2, 0, false, "object")
	shaderTable.skyboxStratos = dxCreateShader("files/shaders/top.fx", 2, 0, false, "object")
	shaderTable.skyboxBottom = dxCreateShader("files/shaders/bottom.fx", 3, 0, false, "object")
	shaderTable.clear = dxCreateShader("files/shaders/clear.fx", 3, 0, false, "world")
	textureTable.cloud = dxCreateTexture("files/textures/clouds.dds", "dxt5")
	textureTable.normal = dxCreateTexture("files/textures/clouds_normal.jpg", "dxt5")
	textureTable.skybox = dxCreateTexture("files/textures/stars.dds", "dxt5")
	moonPhase = getCurrentMoonPhase()
	textureTable.moon = dxCreateTexture("files/textures/moon/" .. toInteger(20 - toInteger(moonPhase * 20)) .. ".png")
	
	effectParts = {
		textureTable.cloud,
		textureTable.normal,
		textureTable.skybox,
		textureTable.moon,
		shaderTable.skyboxTropos,
		shaderTable.skyboxStratos,
		shaderTable.skyboxBottom,
		shaderTable.clear
	}

	bAllValid = true
	
	for _, part in ipairs(effectParts) do
		bAllValid = part and bAllValid
	end
	
	if not bAllValid then 
		return
	end

	dxSetShaderValue(shaderTable.skyboxTropos, "gAlphaMult", 1)
	dxSetShaderValue(shaderTable.skyboxTropos, "gHorizonBlending", dynamicSkySettings.enableHorizonBlending)
	dxSetShaderValue(shaderTable.skyboxTropos, "sClouds", textureTable.cloud)
	dxSetShaderValue(shaderTable.skyboxTropos, "sNormal", textureTable.normal) 
	dxSetShaderValue(shaderTable.skyboxTropos, "sCubeTex", textureTable.skybox)
	dxSetShaderValue(shaderTable.skyboxTropos, "sMoon", textureTable.moon)
	dxSetShaderValue(shaderTable.skyboxTropos, "gStratosFade", dynamicSkySettings.stratosFade)
	dxSetShaderValue(shaderTable.skyboxTropos, "gScale", dynamicSkySettings.modelScale)
	dxSetShaderValue(shaderTable.skyboxTropos, "gBottCloudSpread", dynamicSkySettings.bottomCloudSpread)
	
	dxSetShaderValue(shaderTable.skyboxStratos, "gAlphaMult", 1)
	dxSetShaderValue(shaderTable.skyboxStratos, "gHorizonBlending", dynamicSkySettings.enableHorizonBlending)
	dxSetShaderValue(shaderTable.skyboxStratos, "sCubeTex", textureTable.skybox)
	dxSetShaderValue(shaderTable.skyboxStratos, "sMoon", textureTable.moon)
	dxSetShaderValue(shaderTable.skyboxStratos, "gStratosFade", dynamicSkySettings.stratosFade)
	dxSetShaderValue(shaderTable.skyboxStratos, "gScale", dynamicSkySettings.modelScale)
	dxSetShaderValue(shaderTable.skyboxStratos, "gBottCloudSpread", dynamicSkySettings.bottomCloudSpread)
	
	dxSetShaderValue(shaderTable.skyboxBottom, "gAlphaMult", 1)
	dxSetShaderValue(shaderTable.skyboxBottom, "gHorizonBlending", dynamicSkySettings.enableHorizonBlending)
	dxSetShaderValue(shaderTable.skyboxBottom, "sClouds", textureTable.cloud)
	dxSetShaderValue(shaderTable.skyboxBottom, "gStratosFade", dynamicSkySettings.stratosFade[1], dynamicSkySettings.stratosFade[2])
	dxSetShaderValue(shaderTable.skyboxBottom, "gScale", dynamicSkySettings.modelScale)
	dxSetShaderValue(shaderTable.skyboxBottom, "gBottCloudSpread", dynamicSkySettings.bottomCloudSpread)
	
	engineApplyShaderToWorldTexture(shaderTable.skyboxStratos, "skybox_tex")
	engineApplyShaderToWorldTexture(shaderTable.skyboxBottom, "skybox_tex_bottom")
	engineApplyShaderToWorldTexture(shaderTable.clear, "coronamoon")

	if not dynamicSkySettings.enableCloudTextures then
		engineApplyShaderToWorldTexture(shaderTable.clear, "cloudmasked")
	end

	tempParam[1] = getSunSize()
	tempParam[2] = getMoonSize()
	tempParam[3] = getCloudsEnabled()
	setSunSize(0)
	setMoonSize(0)
    setCloudsEnabled(dynamicSkySettings.enableIngameClouds)
	
	modelTable.txd = engineLoadTXD("files/models/cloud.txd")
	engineImportTXD(modelTable.txd, dynamicSkySettings.modelID)
	
	modelTable.dff = engineLoadDFF("files/models/cloud.dff", dynamicSkySettings.modelID)
	engineReplaceModel(modelTable.dff, dynamicSkySettings.modelID, true)

	local playerX, playerY, playerZ = getElementPosition(localPlayer)

	modelTable.object = createObject(dynamicSkySettings.modelID, playerX, playerY, playerZ, 0, 0, 0, true)
	setObjectScale(modelTable.object, 8)
	setElementAlpha(modelTable.object, 1)

	shaderTable.isSwitched = false

	addEventHandler("onClientPreRender", getRootElement(), onPreRender)
	
	dynamicSkyEnabled = true
end

function stopDynamicSky()
	if not dynamicSkyEnabled then
		return
	end
	
	removeEventHandler("onClientPreRender", getRootElement(), onPreRender)
	
	if isElement(shaderTable.skyboxBottom) then
		engineRemoveShaderFromWorldTexture(shaderTable.skyboxBottom, "skybox_tex_bottom")
	end
	
	if isElement(shaderTable.skyboxStratos) then
		engineRemoveShaderFromWorldTexture(shaderTable.skyboxStratos, "skybox_tex")
	end
	
	if isElement(shaderTable.skyboxTropos) then
		engineRemoveShaderFromWorldTexture(shaderTable.skyboxTropos, "skybox_tex")
	end
	
	if isElement(shaderTable.clear) then
		engineRemoveShaderFromWorldTexture(shaderTable.clear, "*")
	end	
	
	for k, v in ipairs(effectParts) do
		destroyElement(v)
	end
	
	destroyElement(modelTable.object)
	modelTable.object = nil

	engineRestoreModel(dynamicSkySettings.modelID)

	destroyElement(modelTable.txd)
	destroyElement(modelTable.dff)
	modelTable.txd = nil
	modelTable.dff = nil

	dynamicSkyEnabled = false

	setSunSize(tempParam[1])
	setMoonSize(tempParam[2])
	setCloudsEnabled(tempParam[3])
end

function switchShaders()
	if dynamicSkyEnabled then 
		local cameraX, cameraY, cameraZ = getCameraMatrix()
		
		if cameraZ > dynamicSkySettings.stratosFade[2] then
			if shaderTable.isSwitched then
				engineRemoveShaderFromWorldTexture(shaderTable.skyboxTropos, "skybox_tex")
				engineApplyShaderToWorldTexture(shaderTable.skyboxStratos, "skybox_tex")
				shaderTable.isSwitched = false
			end
		else
			if not shaderTable.isSwitched then
				engineRemoveShaderFromWorldTexture(shaderTable.skyboxStratos, "skybox_tex")
				engineApplyShaderToWorldTexture(shaderTable.skyboxTropos, "skybox_tex")
				shaderTable.isSwitched = true
			end
		end
	end
end

function onPreRender()
	renderSphere()
	renderTime()
	switchShaders()
end

function renderSphere()
	if dynamicSkyEnabled then
		local cameraX, cameraY, cameraZ = getCameraMatrix()

		setElementPosition(modelTable.object, cameraX, cameraY, cameraZ, false)
	end
end

function renderTime()
	if not dynamicSkyEnabled then
		return
	end
	
	local hour, minute, seconds = getTimeHMS()
	local timeAspect = (((hour * 60) + minute) + (seconds / 60)) / 1440

	local gRotateX = math.rad(dynamicSkySettings.sunPreRotation[1])
	local gRotateY = math.rad((timeAspect * 360) + dynamicSkySettings.sunPreRotation[2])
	local gRotateZ = math.rad(dynamicSkySettings.sunPreRotation[3])

	dxSetShaderValue(shaderTable.skyboxTropos, "gRotate", gRotateX, gRotateY, gRotateZ)
	dxSetShaderValue(shaderTable.skyboxStratos, "gRotate", gRotateX, gRotateY, gRotateZ)

	local mRotateX = math.rad(dynamicSkySettings.sunPreRotation[1] + dynamicSkySettings.moonPreRotation[1])
	local mRotateY = math.rad(((moonPhase + timeAspect) * 360) + dynamicSkySettings.sunPreRotation[2] + dynamicSkySettings.moonPreRotation[2])
	local mRotateZ = math.rad(dynamicSkySettings.sunPreRotation[3] + dynamicSkySettings.moonPreRotation[3])

	dxSetShaderValue(shaderTable.skyboxTropos, "mRotate", mRotateX, mRotateY, mRotateZ)
	dxSetShaderValue(shaderTable.skyboxStratos, "mRotate", mRotateX, mRotateY, mRotateZ)

	local mMoonLightInt = math.sin(math.pi * moonPhase) * dynamicSkySettings.moonShine

	dxSetShaderValue(shaderTable.skyboxTropos, "mMoonLightInt", mMoonLightInt)
	dxSetShaderValue(shaderTable.skyboxStratos, "mMoonLightInt", mMoonLightInt)
	
	local cameraX, cameraY, cameraZ = getCameraMatrix()
	local waterLevel = getWaterLevel(cameraX, cameraY, cameraZ)
	
	if waterLevel then
		if cameraZ - 0.65 < waterLevel then
			dxSetShaderValue(shaderTable.skyboxTropos, "gIsInWater", true)
			dxSetShaderValue(shaderTable.skyboxBottom, "gIsInWater", true)
			dxSetShaderValue(shaderTable.skyboxStratos, "gIsInWater", true)
		end
	end
	
	if not waterLevel or (cameraZ - 0.65 > waterLevel) then
		dxSetShaderValue(shaderTable.skyboxTropos, "gIsInWater", false)
		dxSetShaderValue(shaderTable.skyboxBottom, "gIsInWater", false)
		dxSetShaderValue(shaderTable.skyboxStratos, "gIsInWater", false)
	end
	
	local thisWeather = getWeather()
	
	for i = 1, #removeWeather do
		if thisWeather == removeWeather[i] then 
			dxSetShaderValue(shaderTable.skyboxTropos, "gAlphaMult", 0)
			dxSetShaderValue(shaderTable.skyboxBottom, "gAlphaMult", 0)
			dxSetShaderValue(shaderTable.skyboxStratos, "gAlphaMult", 0)
		end
	end
	
	if thisWeather ~= oldWeather then
		local velocity = 0.1
		
		if windVelocity[thisWeather] then
			velocity = windVelocity[thisWeather]
		end
		
		dxSetShaderValue(shaderTable.skyboxTropos, "gCloudSpeed", velocity * 0.15)
		dxSetShaderValue(shaderTable.skyboxBottom, "gCloudSpeed", velocity * 0.15)
	end
	
	local r1, g1, b1, r2, g2, b2 = getSunColor()
	local gSunColorR, gSunColorG, gSunColorB = r1 / 255, g1 / 255, b1 / 255
	local gSunColorR2, gSunColorG2, gSunColorB2 = r2 / 255, g2 / 255, b2 / 255
	
	dxSetShaderValue(shaderTable.skyboxTropos, "gSunColor", gSunColorR, gSunColorG, gSunColorB, gSunColorR2, gSunColorG2, gSunColorB2)
	dxSetShaderValue(shaderTable.skyboxStratos, "gSunColor", gSunColorR, gSunColorG, gSunColorB, gSunColorR2, gSunColorG2, gSunColorB2)
	
	if hour == 0 and minute == 0 and seconds == 0 then
		dawn_aspect = 0.001
	end
	
	if hour <= 6 and not (hour == 0 and seconds == 0 and minute == 0) then
		dawn_aspect = ((hour * 60 + minute + seconds / 60)) / 360
	end
	
	if hour > 6 and hour < 20 then
		dawn_aspect = 1
	end
 
	if hour >= 20  then
		dawn_aspect = -6 * ((((hour - 20) * 60) + minute + seconds / 60) / 1440) + 1
	end
	
	dxSetShaderValue(shaderTable.skyboxTropos, "gDayTime", dawn_aspect)
	dxSetShaderValue(shaderTable.skyboxBottom, "gDayTime", dawn_aspect)
	dxSetShaderValue(shaderTable.skyboxStratos, "gDayTime", dawn_aspect)
	
	oldWeather = thisWeather
end

function getTimeHMS()
	return unpack(timeHMS)
end

function math.unlerp(from, pos, to)
	if to == from then
		return 1
	end
	
	return (pos - from) / (to - from)
end

function math.clamp(low, value, high)
	return math.max(low, math.min(value, high))
end

function math.unlerpclamped(from, pos, to)
	return math.clamp(0, math.unlerp(from, pos, to), 1)
end

function toInteger(number)
    local numberToString = tostring(number)
	
    local integer = numberToString:find("%.")
	
    if integer then
        return tonumber(numberToString:sub(1, integer - 1))
    else
        return number
    end
end

function getRadius(x)
    local b = x / 360
	
    local a = 360 * (b - toInteger(b))
	
    if a < 0 then 
		a = a + 360
	end
	
    return a
end

function getPhase(year, month, monthday, hour, minute, second)
	local A, b, phi1, phi2, jdp, tzd, elm, ams, aml, asd
	
	if month > 2 then
		month = month
		year = year
	end
	
	if month <= 2 then
		month = month + 12
		year = year - 1
	end

	local A = toInteger(year / 100)
	local b = 2 - A + toInteger(A / 4)

	jdp = toInteger(365.25 * (year + 4716)) + toInteger(30.6001 * (month + 1)) + monthday + b + ((hour + minute / 60 + second / 3600) / 24) - 1524.5
	jdp = jdp
	tzd = (jdp - 2451545) / 36525
	elm = getRadius(297.8502042 + 445267.1115168 * tzd - (0.00163 * tzd * tzd) + tzd * tzd * tzd / 545868 - (tzd * tzd * tzd * tzd) / 113065000)
	ams = getRadius(357.5291092 + 35999.0502909 * tzd - 0.0001536 * tzd * tzd + tzd * tzd * tzd / 24490000)
	aml = getRadius(134.9634114 + 477198.8676313 * tzd - 0.008997 * tzd * tzd + tzd * tzd * tzd / 69699 - (tzd * tzd * tzd * tzd) / 14712000)
	asd = 180 - elm - (6.289 * math.sin(PI * aml)) +
		(2.1 * math.sin(PI * ((ams)))) -
		(1.274 * math.sin(PI * ((2 * elm) - aml))) -
		(0.658 * math.sin(PI * (2 * elm))) -
		(0.214 * math.sin(PI * (2 * aml))) -
		(0.11 * math.sin(PI * elm))
	phi1 = ((1 + math.cos(PI * (asd))) / 2)

	tzd = (jdp + (0.5 / 24) - 2451545) / 36525
	elm = getRadius(297.8502042 + 445267.1115168 * tzd - (0.00163 * tzd * tzd) + (tzd * tzd * tzd) / 545868 - (tzd * tzd * tzd * tzd) / 113065000)
	ams = getRadius(357.5291092 + 35999.0502909 * tzd - (0.0001536 * tzd * tzd) + (tzd * tzd * tzd) / 24490000)
	aml = getRadius(134.9634114 + 477198.8676313 * tzd - (0.008997 * tzd * tzd) + (tzd * tzd * tzd) / 69699 - (tzd * tzd * tzd * tzd) / 14712000)
	asd = 180 - elm - (6.289 * math.sin(PI * ((aml)))) +
		(2.1 * math.sin(PI * ams)) -
		(1.274 * math.sin(PI * ((2 * elm) - aml))) -
		(0.658 * math.sin(PI * (2 * elm))) -
		(0.214 * math.sin(PI * (2 * aml))) -
		(0.11 * math.sin(PI * elm))
	phi2 = ((1 + math.cos(PI * (asd))) / 2)

	if phi2 - phi1 < 0 then 
		phi1 = -phi1
	end
	
	return phi1
end

function getCurrentMoonPhase()
	local getTime = getRealTime()
	local moonPhase = getPhase(getTime.year + 1900, getTime.month + 1, getTime.monthday, getTime.hour, getTime.minute, getTime.second)
	
	if moonPhase >= 0 then 
		return 1 - moonPhase / 2
	else
		if moonPhase < 0 then 
			return 1 - (2 + moonPhase) / 2
		end 
	end
end