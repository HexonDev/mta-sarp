local screenX, screenY = guiGetScreenSize()

local bloodLevel = 100

local bringBackAnimTick = 0
local inAnim = false
local endAnimTimer = false

local animTime = 300000 -- 5 perc
local preDeathTime = 300000 -- 5 perc

local bloodEffect = false
local cameraShake = false
local cameraShakeTick = false
local screenFadeEffect = false

local screenSource = false

local Roboto = false

local deathTypes = {
	[19] = "robbanás",
	[37] = "égés",
	[49] = "autóbaleset",
	[50] = "autóbaleset",
	[51] = "robbanás",
	[52] = "elütötték",
	[53] = "fulladás",
	[54] = "esés",
	[55] = "unknown",
	[56] = "verekedés",
	[57] = "fegyver",
	[59] = "tank",
	[63] = "robbanás",
	[0] = "verekedés"
}

local weaponNames = {
	Rammed = "autóbaleset",
	shovel = "Csákány",
	["colt 45"] = "CZ-75",
	silenced = "Hangtompítós CZ-75",
	deagle = "H&K USP 45",
	rifle = "Springfield M-1903",
	sniper = "Távcsöves Springfield M-1903"
}

local preDeathStart = false
local preDeathTimer = false
local deathFadeEffect = false
local deathCutscene = false

local bodyParts = {
	myself_inner = {
		[3] = "törzsben",
		[4] = "medencében",
		[5] = "bal kézben",
		[6] = "jobb kézben",
		[7] = "bal lábban",
		[8] = "jobb lábban",
		[9] = "fejben"
	},
	myself_outer = {
		[3] = "törzsön",
		[4] = "medencén",
		[5] = "bal kézen",
		[6] = "jobb kézen",
		[7] = "bal lábon",
		[8] = "jobb lábon",
		[9] = "fejen"
	},
	himself = {
		[3] = "törzsén",
		[4] = "medencéjén",
		[5] = "bal kézén",
		[6] = "jobb kézén",
		[7] = "bal lábán",
		[8] = "jobb lábán",
		[9] = "fején"
	},
	getout = {
		[3] = "törzséből",
		[4] = "medencéjéből",
		[5] = "bal kezéből",
		[6] = "jobb kezéből",
		[7] = "bal lábából",
		[8] = "jobb lábából",
		[9] = "fejéből"
	}
}

local coffinModel = 3898

local txd = engineLoadTXD("files/coffin.txd")
engineImportTXD(txd, coffinModel)

local dff = engineLoadDFF("files/coffin.dff")
engineReplaceModel(dff, coffinModel, true)

local col = engineLoadCOL("files/coffin.col")
engineReplaceCOL(col, coffinModel)

local tombstoneInfo = {}

local deathSound = false
local deathShader = false

local farewellTexts = {
	[1] = {
		"A múltba visszanézve valami fáj, valakit keresünk, aki nincs már.",
		"Nélküled szomorú az élet, és még most sem hisszük el,",
		"hogy többé nem látunk Téged."
	},
	[2] = {
		"Elcsitult a szív, mely értünk dobogott,",
		"számunkra Te sosem leszel halott,",
		"örökké élni fogsz, akár a csillagok."
	},
	[3] = {
		"Elfeledni téged nem lehet,",
		"csak megtanulni élni nélküled."
	},
	[4] = {
		"Pihenj Te drága szív,",
		"mely megszűntél dobogni!",
		"Szerető jóságod nem tudjuk feledni."
	},
	[5] = {
		"Az Ő szíve pihen, a miénk vérzik,",
		"A fájdalmat csak az élők érzik."
	},
	[6] = {
		"Szenvedésed után a halál nyugalom,",
		"De Nélküled élni örökös fájdalom."
	},
	[7] = {
		"Nekem nincs már holnap,",
		"Ennyi volt az élet,",
		"Sirassatok csendben,",
		"Szívetekben élek!"
	},
	[8] = {
		"Küzdöttél, de már nem lehet,",
		"Most átölel a csend és a szeretet."
	},
	[9] = {
		"Jól csak a szívével lát az ember.",
		"Ami igazán lényeges az a szemnek láthatatlan."
	},
	[10] = {
		"S mert halhatunk bármelyik percben,",
		"S célunk mégis az örökkévalóság,",
		"Minden igaz ember ezért hős",
		"S az emberszívben van a legtöbb jóság."
	}
}

local ceremonySentence = false
local ceremonyDuration = 0
local ceremonyCharacterSpeed = 80

for i = 1, #farewellTexts do
	for j = 1, #farewellTexts[i] do
		ceremonyDuration = ceremonyDuration + utf8.len(farewellTexts[i][j]) * ceremonyCharacterSpeed * 1.25
	end
end

local inAnimTime = false
local lastAnimSecond = -1

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		if inAnim then
			setElementFrozen(localPlayer, false)
			exports.sarp_controls:toggleControl({"all"}, true)
			--exports.sarp_hud:toggleHUD(true)

			triggerServerEvent("bringBackInjureAnim", localPlayer, true)
		end

		setElementData(localPlayer, "bloodLevel", 100)

		if inAnimTime then
			setElementData(localPlayer, "inAnimTime", {getTickCount() - inAnimTime, inAnim})
		else
			setElementData(localPlayer, "inAnimTime", {0, false})
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if source == localPlayer then
			if dataName == "bloodLevel" then
				bloodLevel = getElementData(localPlayer, "bloodLevel") or 100

				if bloodLevel > 20 then
					cameraShake = false
					setGameSpeed(1)
				end
			elseif dataName == "isPlayerDeath" or dataName == "bloodLevel" then
				if not getElementData(localPlayer, "isPlayerDeath") and (preDeathStart or deathCutscene) then
					setCameraTarget(localPlayer)

					bloodLevel = 100
					cameraShake = false
					preDeathStart = false
					deathFadeEffect = false
					ceremonySentence = false

					setGameSpeed(1)
					exports.sarp_hud:toggleHUD(true)
					showChat(true)

					if isElement(deathSound) then
						destroyElement(deathSound)
						deathSound = nil
					end

					if isElement(deathShader) then
						destroyElement(deathShader)
						deathShader = nil
					end

					if isTimer(preDeathTimer) then
						killTimer(preDeathTimer)
						preDeathTimer = nil
					end

					if isElement(screenSource) then
						destroyElement(screenSource)
						screenSource = nil
					end

					if isElement(Roboto) then
						destroyElement(Roboto)
						Roboto = nil
					end

					destroyDeathCutscene()
				end
			elseif dataName == "loggedIn" and getElementData(localPlayer, "loggedIn") and getElementData(localPlayer, "isPlayerDeath") then
				if not screenSource then
					screenSource = dxCreateScreenSource(screenX, screenY)
				end

				setGameSpeed(1)
				cameraShake = false
				deathFadeEffect = {getTickCount(), 0, 255}

				exports.sarp_hud:toggleHUD(false)
				showChat(false)

				if getElementData(localPlayer, "player.Cuffed") then
					exports.sarp_controls:toggleControl({"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, true)
				end

				setElementData(localPlayer, "isPlayerDeath", true)
				setElementData(localPlayer, "player.Cuffed", false)
				setElementData(localPlayer, "player.Grabbed", false)
				setElementData(localPlayer, "player.Tazed", false)
				setElementData(localPlayer, "player.seatBelt", false)

				if isTimer(preDeathTimer) then
					killTimer(preDeathTimer)
					preDeathTimer = nil
				end

				preDeathTimer = setTimer(
					function ()
						deathSound = playSound("files/death.mp3")
						Roboto = dxCreateFont("files/Roboto.ttf", 24, false, "antialiased")

						preDeathStart = false

						startDeathCutscene()

						deathFadeEffect = {getTickCount(), 255, 0}
					end,
				5000, 1)
			end
		end
	end
)

addEventHandler("onClientPlayerWasted", localPlayer,
	function (killer, weapon, bodyPart)
		if source == localPlayer then
			local adminJail = getElementData(source, "acc.adminJailTime") or 0
			local inJail = getElementData(source, "char.arrested")

			if adminJail > 0 or inJail then
				triggerServerEvent("reSpawnInJail", source)
				return
			end

			local deathReason = "ismeretlen"
			local customDeath = getElementData(source, "customDeath")

			if customDeath then
				deathReason = customDeath
				setElementData(source, "customDeath", false)
			elseif tonumber(weapon) then
				deathReason = deathTypes[weapon]

				if not deathReason then
					local weaponName = getWeaponNameFromID(weapon)

					if weaponNames[weaponName] then
						weaponName = weaponNames[weaponName]

						if weaponName == "autóbaleset" then
							deathReason = "autóbaleset"
						else
							deathReason = "fegyver (" .. weaponName .. ")"
						end
					else
						deathReason = "fegyver (" .. weaponName .. ")"
					end
				elseif deathReason == "unknown" then
					deathReason = "ismeretlen"
				end
			end

			if bodyPart == 9 then
				deathReason = deathReason .. " [fejlövés]"
			end

			setElementData(source, "deathReason", deathReason)

			if not screenSource then
				screenSource = dxCreateScreenSource(screenX, screenY)
			end

			if isElement(deathSound) then
				destroyElement(deathSound)
			end

			if isElement(deathShader) then
				destroyElement(deathShader)
			end

			deathSound = playSound("files/deathup.mp3")
			deathShader = dxCreateShader("files/blackwhite.fx")
			dxSetShaderValue(deathShader, "screenSource", screenSource)

			setGameSpeed(1)
			cameraShake = false
			preDeathStart = getTickCount()

			exports.sarp_hud:toggleHUD(false)
			showChat(false)

			if getElementData(localPlayer, "player.Cuffed") then
				exports.sarp_controls:toggleControl({"jump", "crouch", "walk", "aim_weapon", "fire", "enter_passenger"}, true)
			end

			setElementData(localPlayer, "isPlayerDeath", true)
			setElementData(localPlayer, "player.Cuffed", false)
			setElementData(localPlayer, "player.Grabbed", false)
			setElementData(localPlayer, "player.Tazed", false)
			setElementData(localPlayer, "player.seatBelt", false)

			if isTimer(preDeathTimer) then
				killTimer(preDeathTimer)
				preDeathTimer = nil
			end

			preDeathTimer = setTimer(
				function ()
					deathFadeEffect = {getTickCount(), 0, 255}

					preDeathTimer = setTimer(
						function ()
							deathSound = playSound("files/death.mp3")
							Roboto = dxCreateFont("files/Roboto.ttf", 24, false, "antialiased")

							preDeathStart = false

							startDeathCutscene()

							deathFadeEffect = {getTickCount(), 255, 0}
						end,
					5000, 1)
				end,
			34000, 1)
		end
	end
)

local haveBulletInLegs = false

setTimer(
	function ()
		haveBulletInLegs = false

		if (getElementData(localPlayer, "acc.adminJail") or 0) ~= 0 then
			return
		end
	
		if getElementData(localPlayer, "adminDuty") then
			return
		end

		if getElementData(localPlayer, "isPlayerDeath") then
			return
		end

		if getElementHealth(localPlayer) > 20 then
			local bulletDamages = getElementData(localPlayer, "bulletDamages") or {}
			local bloodLoss = 0

			bloodLevel = getElementData(localPlayer, "bloodLevel") or 100

			local canFall = false

			for k, v in pairs(bulletDamages) do
				local damage = split(k, ";")

				if damage[1] == "stitch-hole" then -- összevart golyó helye
				elseif damage[1] == "stitch-cut" then -- összevart vágás
				elseif damage[1] == "punch" then -- ütések
				elseif damage[1] == "cut" then -- vágás
					bloodLoss = bloodLoss + math.random(7, 20) / 10
				elseif tonumber(damage[1]) >= 25 and tonumber(damage[1]) <= 27 then -- sörétek
					bloodLoss = bloodLoss + math.random(7, 20) / 10

					if damage[2] == "7" or damage[2] == "8" then
						canFall = true
					else
						canFall = false
					end
				else -- golyók
					bloodLoss = bloodLoss + math.random(7, 20) / 10
					
					if damage[2] == "7" or damage[2] == "8" then
						canFall = true
					else
						canFall = false
					end
				end
			end

			if getElementData(localPlayer, "usingBandage") then
				bloodLoss = bloodLoss * 0.6
			end

			if bloodLoss > 0 then
				bloodLevel = bloodLevel - bloodLoss

				if bloodLevel <= 0 then
					setElementData(localPlayer, "customDeath", "elvérzett")
					setElementHealth(localPlayer, 20)
					setGameSpeed(1)
					bloodLevel = 0
				elseif bloodLevel > 0 and bloodLevel <= 40 then
					if math.random(10) <= 5 then
						if not cameraShake then
							exports.sarp_hud:showInfobox("warning", "Az alacsony vérszinted miatt elkezdtél szédülni!")

							cameraShake = {0, 0, 0, false, 0, 0}

							setGameSpeed(0.75 + (40 - bloodLevel) * 0.75 / 100)

							playSound("files/heavybreathing.wav")
						end

						cameraShake[1] = 40 - bloodLevel
					end
				end

				if bloodLevel > 0 and canFall then
					haveBulletInLegs = canFall
				end

				setElementData(localPlayer, "bloodLevel", bloodLevel)

				if not bloodEffect or bloodEffect and getTickCount() - bloodEffect[1] >= 5000 then
					bloodEffect = {getTickCount(), bloodLevel / 100}
				end
			elseif bloodLevel < 100 then
				setElementData(localPlayer, "bloodLevel", 100)
				setElementData(localPlayer, "usingBandage", false)
			end
		end
	end,
10000, 0)

function dxDrawBorderText(text, x, y, sx, sy, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded)
	dxDrawText(text, x - 1, y - 1, sx - 1, sy - 1, tocolor(0, 0, 0), scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x - 1, y + 1, sx - 1, sy + 1, tocolor(0, 0, 0), scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x + 1, y - 1, sx + 1, sy - 1, tocolor(0, 0, 0), scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x + 1, y + 1, sx + 1, sy + 1, tocolor(0, 0, 0), scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
	dxDrawText(text, x, y, sx, sy, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, true)
end

function endAnim()
	triggerServerEvent("killPlayerAnimTimer", localPlayer)

	endAnimTimer = false
	cameraShake = false

	if isElement(screenSource) then
		destroyElement(screenSource)
	end
	screenSource = nil

	if isTimer(preDeathTimer) then
		killTimer(preDeathTimer)
		preDeathTimer = nil
	end

	preDeathTimer = setTimer(
		function ()
			screenFadeEffect = {getTickCount(), 255, 0}

			preDeathTimer = setTimer(
				function ()
					screenFadeEffect = false
				end,
			3000, 1)
		end,
	1500, 1)
end

function destroyDeathCutscene(ceremonyEnd)
	if deathCutscene then
		processRipTombstone(nil)

		if isElement(deathCutscene.vehicleDriver) then
			destroyElement(deathCutscene.vehicleDriver)
			deathCutscene.vehicleDriver = nil
		end

		if isElement(deathCutscene.baseVehicle) then
			destroyElement(deathCutscene.baseVehicle)
			deathCutscene.baseVehicle = nil
		end

		for k, v in pairs(deathCutscene.mournerPeds) do
			if isElement(deathCutscene.mournerPeds[k]) then
				destroyElement(deathCutscene.mournerPeds[k])
			end
		end

		if isElement(deathCutscene.theCoffin) then
			destroyElement(deathCutscene.theCoffin)
			deathCutscene.theCoffin = nil
		end

		if isElement(deathCutscene.theFlowerOfCoffin) then
			destroyElement(deathCutscene.theFlowerOfCoffin)
			deathCutscene.theFlowerOfCoffin = nil
		end

		for k, v in pairs(deathCutscene.objectElements) do
			if isElement(deathCutscene.objectElements[k]) then
				destroyElement(deathCutscene.objectElements[k])
			end
		end

		if isElement(deathCutscene.hospitalPed) then
			destroyElement(deathCutscene.hospitalPed)
			deathCutscene.hospitalPed = nil
		end
	end

	if not ceremonyEnd then
		deathCutscene = nil
	end
end

function startDeathCutscene(ceremonyEnd)
	local playerId = getElementData(localPlayer, "playerID")

	if not ceremonyEnd then
		destroyDeathCutscene()
	end

	if playerId then
		setElementPosition(localPlayer, 0, 0, 0)
		setElementDimension(localPlayer, playerId)
		setElementInterior(localPlayer, 0)
		setCameraInterior(0)

		if not ceremonyEnd then
			local vehicleElement = createVehicle(442, 2034.892578125, -1423.3518066406, 16.536323547363, 0, 0, 180, "-R.I.P.-")
			setElementInterior(vehicleElement, 0)
			setElementDimension(vehicleElement, playerId)
			setVehicleColor(vehicleElement, 0, 0, 0, 0, 0, 0)

			local pedElement = createPed(255, 0, 0, 0, 0)
			setElementInterior(pedElement, 0)
			setElementDimension(pedElement, playerId)
			warpPedIntoVehicle(pedElement, vehicleElement)

			deathCutscene = {}
			deathCutscene.baseVehicle = vehicleElement
			deathCutscene.vehicleDriver = pedElement
			deathCutscene.mournerPeds = {}
			deathCutscene.objectElements = {}

			local mournerPed = createPed(17, 912.5732421875, -1069.8638916016, 24.400218963623, 95)
			setElementInterior(mournerPed, 0)
			setElementDimension(mournerPed, playerId)
			setPedAnimation(mournerPed, "SWORD", "sword_IDLE")
			table.insert(deathCutscene.mournerPeds, mournerPed)

			local mournerPed = createPed(125, 912.32958984375, -1067.998046875, 24.488353729248, 95)
			setElementInterior(mournerPed, 0)
			setElementDimension(mournerPed, playerId)
			setPedAnimation(mournerPed, "SWORD", "sword_IDLE")
			table.insert(deathCutscene.mournerPeds, mournerPed)

			local mournerPed = createPed(117, 910.01214599609, -1067.998046875, 24.491737365723, 270)
			setElementInterior(mournerPed, 0)
			setElementDimension(mournerPed, playerId)
			setPedAnimation(mournerPed, "SWORD", "sword_IDLE")
			table.insert(deathCutscene.mournerPeds, mournerPed)

			local mournerPed = createPed(186, 910.01214599609, -1069.8638916016, 24.491737365723, 270)
			setElementInterior(mournerPed, 0)
			setElementDimension(mournerPed, playerId)
			setPedAnimation(mournerPed, "SWORD", "sword_IDLE")
			table.insert(deathCutscene.mournerPeds, mournerPed)

			local mournerPed = createPed(math.random(190, 195), 2039.4725341797, -1415.0229492188, 17.170774459839, 145)
			setElementInterior(mournerPed, 0)
			setElementDimension(mournerPed, playerId)
			setPedAnimation(mournerPed, "graveyard", "mrnm_loop")
			deathCutscene.hospitalPed = mournerPed

			local objectElement = createObject(coffinModel, 911.375, -1069.1975097656, 23.25, 0, 0, -85)
			setElementInterior(objectElement, 0)
			setElementDimension(objectElement, playerId)
			deathCutscene.theCoffin = objectElement

			local flowerObject = createObject(325, 0, 0, 0)
			setElementInterior(flowerObject, 0)
			setElementDimension(flowerObject, playerId)
			attachElements(flowerObject, objectElement, 0, 0, 0.5, 0, 90, 180)
			deathCutscene.theFlowerOfCoffin = flowerObject

			local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(deathCutscene.theCoffin)
			maxZ = maxZ - 0.25

			deathCutscene.coffinBounds = {
				[1] = {maxX, maxY - 0.1, maxZ},
				[2] = {minX, maxY - 0.1, maxZ},
				[3] = {minX, minY + 0.05, maxZ},
				[4] = {maxX, minY + 0.05, maxZ},
			}

			setCameraMatrix(2043.6573486328, -1431.5511474609, 23.625, 2043.0211181641, -1430.9112548828, 23.193984985352)

			deathCutscene.vehicleStart = getTickCount() + 5000
		else
			local objectElement = createObject(11223, 911.375, -1069, 22.9, 0, 0, 90)
			setElementInterior(objectElement, 0)
			setElementDimension(objectElement, playerId)
			setObjectScale(objectElement, 0.225, 0.1)
			setElementCollisionsEnabled(objectElement, false)
			table.insert(deathCutscene.objectElements, objectElement)

			local objectElement = createObject(5777, 911.2, -1066.75, 24, 0, 0, 270)
			setElementInterior(objectElement, 0)
			setElementDimension(objectElement, playerId)
			table.insert(deathCutscene.objectElements, objectElement)

			local characterName = getElementData(localPlayer, "char.Name"):gsub("_", " ")
			local characterAge = getElementData(localPlayer, "char.Age") or 0
			local currentYear = getRealTime().year + 1900

			processRipTombstone(characterName .. "\n" .. currentYear - characterAge .. " - " .. currentYear)
		end
	end
end

function elementOffset(element, offX, offY, offZ)
	local matrix = getElementMatrix(element)
	local posX = offX * matrix[1][1] + offY * matrix[2][1] + offZ * matrix[3][1] + matrix[4][1]
	local posY = offX * matrix[1][2] + offY * matrix[2][2] + offZ * matrix[3][2] + matrix[4][2]
	local posZ = offX * matrix[1][3] + offY * matrix[2][3] + offZ * matrix[3][3] + matrix[4][3]

	return posX, posY, posZ
end

function processRipTombstone(text)
	if isElement(tombstoneInfo.renderTarget) then
		destroyElement(tombstoneInfo.renderTarget)
	end

	tombstoneInfo.renderTarget = nil

	if text then
		tombstoneInfo.text = text
		tombstoneInfo.renderTarget = dxCreateRenderTarget(256, 128, true)

		if isElement(tombstoneInfo.renderTarget) then
			dxSetRenderTarget(tombstoneInfo.renderTarget)

			dxDrawImage(256 / 2 - 32 / 2, 0, 32, 32, "files/cross.png", 0, 0, 0, tocolor(0, 0, 0, 200))

			dxDrawText(text, 0, 32, 256, 128, tocolor(0, 0, 0, 200), 1, 1.25, "beckett", "center", "center")

			dxSetRenderTarget()
		end
	end
end

addEventHandler("onClientRestore", getRootElement(),
	function ()
		if tombstoneInfo.renderTarget then
			processRipTombstone(tombstoneInfo.text)
		end
	end
)

local lastFallAnim = 0

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		if tombstoneInfo.renderTarget and isElement(tombstoneInfo.renderTarget) then
			local x, y, z = 911.2, -1066.975, 23.9
			local x2, y2, z2 = 0, -1, 0.25

			dxDrawMaterialLine3D(x, y, z + 0.5, x, y, z, tombstoneInfo.renderTarget, 1.25, tocolor(255, 255, 255), x + x2, y + y2, z + z2)
		end

		if deathCutscene then
			local currentTick = getTickCount()

			if isElement(screenSource) then
				dxUpdateScreenSource(screenSource)
			end

			dxDrawImage(0, 0, screenX, screenY, deathShader)

			if deathCutscene.vehicleStart and currentTick >= deathCutscene.vehicleStart then
				local elapsedTime = currentTick - deathCutscene.vehicleStart

				if isElement(deathCutscene.vehicleDriver) then
					setPedControlState(deathCutscene.vehicleDriver, "accelerate", true)
				end

				if elapsedTime >= 2500 then
					deathCutscene.vehicleStart = false

					setPedControlState(deathCutscene.vehicleDriver, "accelerate", false)

					deathFadeEffect = {getTickCount(), 0, 255}

					removePedFromVehicle(deathCutscene.vehicleDriver)
					setElementPosition(deathCutscene.vehicleDriver, 911.46508789063, -1071.0933837891, 24.345584869385)
					setElementRotation(deathCutscene.vehicleDriver, 0, 0, 0)
					setElementModel(deathCutscene.vehicleDriver, 68)
					setPedAnimation(deathCutscene.vehicleDriver, "GRAVEYARD", "prst_loopa", -1, true, false, false)

					setElementPosition(deathCutscene.baseVehicle, 915.98956298828, -1068.3989257813, 23.981510162354)
					setElementRotation(deathCutscene.baseVehicle, 0, 0, 0)
					setVehicleEngineState(deathCutscene.baseVehicle, false)
					setVehicleDoorOpenRatio(deathCutscene.baseVehicle, 1, 1)

					deathCutscene.ceremonyStart = getTickCount() + 5000

					ceremonySentence = {deathCutscene.ceremonyStart + 5000, farewellTexts[1], 1, 1}
				end
			elseif deathCutscene.ceremonyStart and currentTick >= deathCutscene.ceremonyStart then
				local elapsedTime = currentTick - deathCutscene.ceremonyStart

				setCameraMatrix(907.24078369141, -1065.1546630859, 28.628499984741, 907.83337402344, -1065.7069091797, 28.042135238647)

				if not deathFadeEffect or deathFadeEffect[3] == 255 then
					deathFadeEffect = {getTickCount(), 255, 0}
				end

				for i = 1, 4 do
					if isElement(deathCutscene.mournerPeds[i]) then
						local boneX, boneY, boneZ = getPedBonePosition(deathCutscene.mournerPeds[i], 25)
						local coffinX, coffinY, coffinZ = elementOffset(deathCutscene.theCoffin, unpack(deathCutscene.coffinBounds[i]))

						dxDrawLine3D(boneX, boneY, boneZ, coffinX, coffinY, coffinZ, tocolor(75, 37.5, 0), 2)
					end
				end

				if elapsedTime >= ceremonyDuration then
					local progress = (elapsedTime - ceremonyDuration) / 10000
					local deltaZ = interpolateBetween(
						23.25, 0, 0,
						21.75, 0, 0,
						progress, "Linear")

					local coffinX, coffinY, coffinZ = getElementPosition(deathCutscene.theCoffin)

					setElementPosition(deathCutscene.theCoffin, coffinX, coffinY, deltaZ)

					if progress >= 1 then
						for i = 1, 4 do
							if isElement(deathCutscene.mournerPeds[i]) then
								setPedAnimation(deathCutscene.mournerPeds[i], "GRAVEYARD", "mrnM_loop", -1, true, false, false)
							end
						end

						setPedAnimation(deathCutscene.vehicleDriver, "GRAVEYARD", "mrnM_loop", -1, true, false, false)

						deathCutscene.ceremonyStart = false
						deathCutscene.ceremonyEnd = getTickCount() + 5000

						deathFadeEffect = {getTickCount(), 0, 255}
					end
				end
			elseif deathCutscene.ceremonyEnd and currentTick >= deathCutscene.ceremonyEnd then
				local elapsedTime = currentTick - deathCutscene.ceremonyEnd
				local progress = elapsedTime / 5000
				
				if not deathFadeEffect or deathFadeEffect[3] == 255 then
					deathFadeEffect = {getTickCount(), 255, 0}
					destroyDeathCutscene(true)
					startDeathCutscene(true)
				end

				local camX, camY, camZ = interpolateBetween(
					907.24078369141, -1065.1546630859, 28.628499984741,
					912.37310791016, -1071.5478515625, 25.02440071106,
					progress, "OutQuad")

				local lookX, lookY, lookZ = interpolateBetween(
					907.83337402344, -1065.7069091797, 28.042135238647,
					911.88677978516, -1070.6947021484, 24.835758209229,
					progress, "OutQuad")

				setCameraMatrix(camX, camY, camZ, lookX, lookY, lookZ)

				if elapsedTime >= 10000 then
					deathCutscene.ceremonyEnd = false
					deathFadeEffect = {getTickCount(), 0, 255, true}

					if isTimer(preDeathTimer) then
						killTimer(preDeathTimer)
						preDeathTimer = nil
					end

					preDeathTimer = setTimer(
						function ()
							triggerServerEvent("spawnToHospital", localPlayer)
						end,
					5000, 1)
				end 
			end

			dxDrawRectangle(0, 0, screenX, screenY / 7, tocolor(0, 0, 0))
			dxDrawRectangle(0, screenY - screenY / 7, screenX, screenY / 7, tocolor(0, 0, 0))
			dxDrawImage(0, screenY / 7, screenX, screenY - screenY / 3.5, "files/vin.png", 0, 0, 0, tocolor(0, 0, 0))

			local pictureSize = screenY / 7 - 20

			dxDrawImage(math.floor((screenX - pictureSize) / 2), math.floor(0 + (screenY / 7 - pictureSize) / 2), pictureSize, pictureSize, "files/cross.png")

			if ceremonySentence and currentTick >= ceremonySentence[1] then
				if ceremonySentence[3] <= #ceremonySentence[2] then
					local currentText = ceremonySentence[2][ceremonySentence[3]]
					local textLength = utf8.len(currentText) 

					local elapsedTime = currentTick - ceremonySentence[1]
					local characterSubProgress = elapsedTime / (textLength * ceremonyCharacterSpeed)

					if characterSubProgress > 0 then
						local text = ""

						for i = 1, #ceremonySentence[2] do
							if ceremonySentence[3] > i then
								text = text .. ceremonySentence[2][i] .. "\n"
							end
						end

						local textPos = interpolateBetween(
							0, 0, 0,
							textLength, 0, 0,
							characterSubProgress, "Linear"
						)

						dxDrawText(text .. utf8.sub(currentText, 1, math.floor(textPos)), 32, screenY - screenY / 7, screenX, screenY, tocolor(255, 255, 255), 0.5, Roboto, "left", "center")

						if characterSubProgress > 1.25 then
							if ceremonySentence[3] ~= #ceremonySentence[2] then
								ceremonySentence[3] = ceremonySentence[3] + 1
								ceremonySentence[1] = getTickCount()
							elseif ceremonySentence[4] < #farewellTexts then
								ceremonySentence[4] = ceremonySentence[4] + 1
								ceremonySentence[2] = farewellTexts[ceremonySentence[4]]
								ceremonySentence[3] = 1
								ceremonySentence[1] = getTickCount()
							else
								ceremonySentence = false
							end
						end
					end
				end
			end
		end

		if bloodLevel < 100 and not isPedInVehicle(localPlayer) and math.random(100) <= 10 then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

			fxAddBlood(playerPosX, playerPosY, playerPosZ - 3, 0, 0, 3, math.random(5))
		end

		if haveBulletInLegs and not isPedInVehicle(localPlayer) and getElementHealth(localPlayer) > 20 then
			if getTickCount() >= lastFallAnim then
				if not getElementData(localPlayer, "player.Cuffed") and not getElementData(localPlayer, "player.Grabbed") then
					local vx, vy, vz = getElementVelocity(localPlayer)
					local speed = getDistanceBetweenPoints3D(0, 0, 0, vx, vy, vz)

					if speed > 0.0475 then
						lastFallAnim = getTickCount() + math.random(1250, 7500)

						triggerServerEvent("fallAnimByBulletDamage", localPlayer)
					end
				end
			end
		end

		if cameraShake then
			if not screenSource then
				screenSource = dxCreateScreenSource(screenX, screenY)
				dxSetTextureEdge(screenSource, "mirror")
			end

			if isElement(screenSource) then
				dxUpdateScreenSource(screenSource)
			end

			if not cameraShakeTick then
				cameraShakeTick = getTickCount()
			end

			local elapsedTime = getTickCount() - cameraShakeTick
			
			if elapsedTime > 3000 then
				cameraShake[2] = cameraShake[5]
				cameraShake[3] = cameraShake[6]
				cameraShake[4] = not cameraShake[4]

				elapsedTime = 0
				cameraShakeTick = getTickCount()
			end

			local progress = elapsedTime / 3000

			if not cameraShake[4] then
				cameraShake[5], cameraShake[6] = interpolateBetween(
					cameraShake[2], cameraShake[3], 0,
					cameraShake[1], cameraShake[1], 0,
					progress, "OutQuad")
			else
				cameraShake[5], cameraShake[6] = interpolateBetween(
					cameraShake[2], cameraShake[3], 0,
					0, 0, 0,
					progress, "OutQuad")
			end

			dxDrawImageSection(0, 0, screenX, screenY, cameraShake[5], cameraShake[6], screenX, screenY, screenSource, 0, 0, 0, tocolor(255, 255, 255))
			dxDrawImageSection(0, 0, screenX, screenY, -cameraShake[5], -cameraShake[6], screenX, screenY, screenSource, 0, 0, 0, tocolor(255, 255, 255, 100))
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local currentTick = getTickCount()

		if bloodEffect then
			local elapsedTime = currentTick - bloodEffect[1]
			local progress = elapsedTime / 750

			local alpha = interpolateBetween(
				0, 0, 0,
				150 * bloodEffect[2] + 55, 0, 0,
				progress, "InOutQuad")

			if progress - 2 > 0 then
				alpha = interpolateBetween(
					150 * bloodEffect[2] + 55, 0, 0,
					0, 0, 0,
					progress - 2, "InOutQuad")
			end

			if progress > 3 then
				bloodEffect = false
			end

			dxDrawImage(0, 0, screenX, screenY, "files/vin.png", 0, 0, 0, tocolor(100, 20, 40, alpha))
		end

		if screenFadeEffect then
			local progress = (currentTick - screenFadeEffect[1]) / 3000
			local alpha = interpolateBetween(
				screenFadeEffect[2], 0, 0,
				screenFadeEffect[3], 0, 0,
				progress, "Linear")

			dxDrawRectangle(0, 0, screenX, screenY, tocolor(0, 0, 0, alpha))
		end

		local currentHealth = getElementHealth(localPlayer)

		if currentHealth <= 20 and currentHealth > 0 then
			local block, animation = getPedAnimation(localPlayer)

			if isPedInVehicle(localPlayer) then
				if ((block and string.lower(block)) ~= "ped" or (animation and string.lower(animation)) ~= "car_dead_lhs") and currentTick - bringBackAnimTick > 500 then
					setPedAnimation(localPlayer, "ped", "car_dead_lhs", -1, false, false, false)

					triggerServerEvent("bringBackInjureAnim", localPlayer)

					bringBackAnimTick = currentTick
				end
			elseif ((block and string.lower(block)) ~= "wuzi" or (animation and string.lower(animation)) ~= "cs_dead_guy") and currentTick - bringBackAnimTick > 500 then
				setPedAnimation(localPlayer, "wuzi", "cs_dead_guy", -1, false, false, false)

				triggerServerEvent("bringBackInjureAnim", localPlayer)

				bringBackAnimTick = currentTick
			end

			if not inAnim then
				inAnim = true
				cameraShake = false

				if isElement(screenSource) then
					destroyElement(screenSource)
				end
				screenSource = nil

				setElementFrozen(localPlayer, true)
				exports.sarp_controls:toggleControl({"all"}, false)
				--exports.sarp_hud:toggleHUD(false)

				local lastnimTime = getElementData(localPlayer, "inAnimTime") or {}

				inAnimTime = getTickCount() - (lastnimTime[1] or 0)
				lastAnimSecond = -1

				if isTimer(endAnimTimer) then
					killTimer(endAnimTimer)
				end

				endAnimTimer = setTimer(endAnim, animTime + preDeathTime, 1)

				screenFadeEffect = {getTickCount(), 0, 255}
			end

			if not Roboto then
				Roboto = dxCreateFont("files/Roboto.ttf", 24, false, "antialiased")
			end

			if endAnimTimer then
				local timeLeft = getTimerDetails(endAnimTimer)
				local preDeath = false

				if timeLeft then
					if timeLeft <= (animTime + preDeathTime) / 2 then
						preDeath = true
					end

					timeLeft = timeLeft / 1000
				else
					timeLeft = 0
				end

				local minute = timeLeft / 60 % 60
				local second = timeLeft % 60
				local deathText = ""

				if lastAnimSecond ~= second then
					lastAnimSecond = second

					setElementData(localPlayer, "inAnimTime", {getTickCount() - inAnimTime, preDeath})
				end

				if preDeath then
					if minute > 0 then
						deathText = "A halál beálltáig " .. string.format("%02d másodperc.", second)
					else
						deathText = "A halál beálltáig " .. string.format("%02d perc és %02d másodperc.", minute, second)
					end
				else
					deathText = "Eszméletlen vagy. (" .. string.format("%02d:%02d", minute, second) .. ")"
				end

				dxDrawBorderText(deathText, 0, screenY - 125, screenX, 0, tocolor(215, 89, 89), 0.75, Roboto, "center", "top")
			end
		elseif inAnim then
			inAnim = false
			screenFadeEffect = false
			inAnimTime = false

			setElementFrozen(localPlayer, false)
			exports.sarp_controls:toggleControl({"all"}, true)
			--exports.sarp_hud:toggleHUD(true)

			if isTimer(endAnimTimer) then
				killTimer(endAnimTimer)
			end
			endAnimTimer = false

			if isElement(Roboto) then
				destroyElement(Roboto)
			end
			Roboto = false

			triggerServerEvent("bringBackInjureAnim", localPlayer, true)
		end

		if preDeathStart then
			local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
			local elapsedTime = currentTick - preDeathStart
			local progress = elapsedTime / 39000
			local z = 0

			if playerPosZ >= 10000 or getElementInterior(localPlayer) ~= 0 then
				z = interpolateBetween(
					1.5, 0, 0,
					3.5, 0, 0,
					progress, "Linear")
			else
				z = interpolateBetween(
					5, 0, 0,
					60, 0, 0,
					progress, "Linear")
			end

			setCameraMatrix(playerPosX, playerPosY, playerPosZ + z, playerPosX, playerPosY, playerPosZ)

			local alpha = 0
			local alpha2 = 255

			if elapsedTime > 1070 and elapsedTime <= 3200 then
				local progress = (elapsedTime - 1070) / 750

				if progress > 1 then
					progress = 1
				end

				progress = 1 - math.abs(0.5 - progress) * 2

				alpha = 100 * progress
				alpha2 = 255 * progress
			elseif elapsedTime > 3200 then
				local progress = (elapsedTime - 3200) / 250

				if progress > 1 then
					progress = 1
				end
				
				alpha = 200 * (1 - math.abs(0.5 - progress) * 2) + 55
				alpha2 = 0
			end

			if isElement(screenSource) then
				dxUpdateScreenSource(screenSource)
			end

			dxDrawImage(0, 0, screenX, screenY, deathShader)
			dxDrawImage(0, 0, screenX, screenY, screenSource, 0, 0, 0, tocolor(255, 255, 255, alpha2))

			dxDrawImage(0, 0, screenX, screenY, "files/vin.png", 0, 0, 0, tocolor(0, 0, 0))
			dxDrawImage(0, 0, screenX, screenY, "files/vin.png", 0, 0, 0, tocolor(200, 50, 50, alpha))
		end

		if deathFadeEffect then
			local progress = (currentTick - deathFadeEffect[1]) / 5000

			local alpha = interpolateBetween(
				deathFadeEffect[2], 0, 0,
				deathFadeEffect[3], 0, 0,
				progress, "Linear")

			if deathFadeEffect[2] <= 0 and progress > 1 then
				deathFadeEffect = false
			end

			if deathFadeEffect and deathFadeEffect[4] and deathSound then
				if progress > 1 then
					progress = 1
				end

				setSoundVolume(deathSound, 1 - progress)
			end

			dxDrawRectangle(0, 0, screenX, screenY, tocolor(0, 0, 0, alpha))
		end
	end, true, "low-5"
)

local lastTryTick = 0
local tryToHelpUpPerson = false
local tryToHealPerson = false

addEvent("tryToHelpUpPerson", true)
addEventHandler("tryToHelpUpPerson", getRootElement(),
	function(sourcePlayer)
		if getTickCount() - lastTryTick >= 1000 then
			lastTryTick = getTickCount()

			if getElementHealth(sourcePlayer) <= 20 and getElementHealth(sourcePlayer) > 0 then
				tryToHelpUpPerson = sourcePlayer

				-- van defi -> sokkolás
				if exports.sarp_inventory:hasItem(107) then

				-- nincs defi -> mellkas kompresszió
				else

				end
			else
				exports.sarp_hud:showAlert("error", "A kiválasztott játékos nem halott vagy már nem lehet megmenteni!")
			end
		end
	end)

addCommandHandler("healmyself",
	function()
		if getElementData(localPlayer, "acc.adminLevel") >= 9 then
			triggerEvent("tryToHealPerson", localPlayer, localPlayer)
		end
	end)

addEvent("tryToHealPerson", true)
addEventHandler("tryToHealPerson", getRootElement(),
	function(sourcePlayer)
		if getTickCount() - lastTryTick >= 1000 then
			lastTryTick = getTickCount()

			local bulletDamages = getElementData(sourcePlayer, "bulletDamages") or {}
			local damages = 0

			for k, v in pairs(bulletDamages) do
				damages = damages + 1
			end

			if damages > 0 then
				--[[
				for k, v in pairs(bulletDamages) do
					local data = split(k, ";")
					local damageType = data[1]
					local bodyPart = tonumber(data[2])

					if damageType == "stitch-hole" then
					elseif damageType == "stitch-cut" then
					elseif damageType == "punch" then
					elseif damageType == "cut" then
						exports.sarp_hud:showAlert("error", "Addig nem gyógyíthatod meg amíg vágás van a testén!")
						return
					elseif tonumber(damageType) >= 25 and tonumber(damageType) <= 27 then
						exports.sarp_hud:showAlert("error", "Addig nem gyógyíthatod meg amíg sörétek vannak a testében!")
						return
					else
						exports.sarp_hud:showAlert("error", "Addig nem gyógyíthatod meg amíg golyó vannak a testében!")
						return
					end
				end

				if (getElementData(sourcePlayer, "bloodLevel") or 100) ~= 100 then
					exports.sarp_hud:showAlert("error", "Addig nem gyógyíthatod meg amíg nem állítod el a vérzést!")
					return
				end
				]]

				-- van eset táska
				if exports.sarp_inventory:hasItem(108) then
					
				else
					exports.sarp_hud:showAlert("error", "Nincs nálad eset táska, ezért nem tudod ellátni a sérültet!")
				end
			else
				exports.sarp_hud:showAlert("error", "A kiválasztott játékos nincs megsérülve!")
			end
		end
	end)

addEvent("examinePlayerBody", true)
addEventHandler("examinePlayerBody", getRootElement(),
	function (sourcePlayer)
		local currentDamages = getElementData(sourcePlayer, "bulletDamages") or {}
		local damagesForDraw = {}

		for k, v in pairs(currentDamages) do
			local data = split(k, ";")
			local damageType = data[1]
			local bodyPart = tonumber(data[2])

			if damageType == "stitch-hole" then
				table.insert(damagesForDraw, "Összevart golyó helye a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "stitch-cut" then
				table.insert(damagesForDraw, "Összevart vágás a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "punch" then
				table.insert(damagesForDraw, "Ütések a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "cut" then
				table.insert(damagesForDraw, v .. " vágás a " .. bodyParts.myself_outer[bodyPart])
			elseif tonumber(damageType) >= 25 and tonumber(damageType) <= 27 then
				table.insert(damagesForDraw, "Sörétek a " .. bodyParts.myself_inner[bodyPart])
			else
				table.insert(damagesForDraw, v .. " golyó a " .. bodyParts.myself_inner[bodyPart])
			end
		end

		if (getElementData(sourcePlayer, "bloodLevel") or 100) ~= 100 then
			table.insert(damagesForDraw, "Vérzés")
		end

		if #damagesForDraw > 0 then
			outputChatBox("#ffff99>> " .. getPlayerName(sourcePlayer):gsub("_", " ") .. " sérülései:", 0, 0, 0, true)

			for k, v in ipairs(damagesForDraw) do
				outputChatBox("    >> #ffff99" .. v, 255, 255, 255, true)
			end
		else
			outputChatBox("#ffff99>> " .. getPlayerName(sourcePlayer):gsub("_", " ") .. " sérülései: #ffffffNem található sérülés.", 0, 0, 0, true)
		end
	end
)

addCommandHandler("sérüléseim",
	function ()
		local currentDamages = getElementData(localPlayer, "bulletDamages") or {}
		local damagesForDraw = {}

		for k, v in pairs(currentDamages) do
			local data = split(k, ";")
			local damageType = data[1]
			local bodyPart = tonumber(data[2])

			if damageType == "stitch-hole" then
				table.insert(damagesForDraw, "Összevart golyó helye a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "stitch-cut" then
				table.insert(damagesForDraw, "Összevart vágás a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "punch" then
				table.insert(damagesForDraw, "Ütések a " .. bodyParts.myself_outer[bodyPart])
			elseif damageType == "cut" then
				table.insert(damagesForDraw, v .. " vágás a " .. bodyParts.myself_outer[bodyPart])
			elseif tonumber(damageType) >= 25 and tonumber(damageType) <= 27 then
				table.insert(damagesForDraw, "Sörétek a " .. bodyParts.myself_inner[bodyPart])
			else
				table.insert(damagesForDraw, v .. " golyó a " .. bodyParts.myself_inner[bodyPart])
			end
		end

		if #damagesForDraw > 0 then
			for k, v in ipairs(damagesForDraw) do
				outputChatBox("#ffff99>> Sérüléseim: #ffffff" .. v, 0, 0, 0, true)
			end
		else
			outputChatBox("#ffff99>> Sérüléseim: #ffffffNem található sérülés.", 0, 0, 0, true)
		end
	end
)