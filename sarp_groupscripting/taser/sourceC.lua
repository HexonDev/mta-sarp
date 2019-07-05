local tazerModel = 2044

local playerTazerObject = {}
local playerTazerShader = {}

local emptyTexture = dxCreateTexture("files/empty.png")

local tazerShootEffect = {}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		local txd = engineLoadTXD("files/taser.txd")
		engineImportTXD(txd, tazerModel)

		local dff = engineLoadDFF("files/taser.dff")
		engineReplaceModel(dff, tazerModel)

		setElementData(localPlayer, "tazerState", false)
		setElementData(localPlayer, "player.Tazed", false)
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName)
		if dataName == "tazerState" then
			if isElement(playerTazerObject[source]) then
				destroyElement(playerTazerObject[source])
			end

			if isElement(playerTazerShader[source]) then
				destroyElement(playerTazerShader[source])
			end

			if getElementData(source, dataName) then
				local playerInterior = getElementInterior(source)
				local playerDimension = getElementDimension(source)
				local tazerObject = createObject(tazerModel, 0, 0, 0)

				if isElement(tazerObject) then
					setElementInterior(tazerObject, playerInterior)
					setElementDimension(tazerObject, playerDimension)
					setElementCollisionsEnabled(tazerObject, false)
					setObjectScale(tazerObject, 0.75)

					exports.sarp_boneattach:attachElementToBone(tazerObject, source, 12, 0, 0, 0, 0, -90, 0)

					playerTazerObject[source] = tazerObject
					playerTazerShader[source] = dxCreateShader("files/texturechanger.fx", 0, 0, false, "ped")
					
					if isElement(playerTazerShader[source]) then
						dxSetShaderValue(playerTazerShader[source], "gTexture", emptyTexture)
						
						for k, v in ipairs(engineGetModelTextureNames("348")) do
							engineApplyShaderToWorldTexture(playerTazerShader[source], v, source)
						end
					end
				end
			end
		end
	end
)

addEventHandler("onClientPlayerQuit", getRootElement(),
	function ()
		if isElement(playerTazerObject[source]) then
			destroyElement(playerTazerObject[source])
		end
	end
)

addEventHandler("onClientPlayerWasted", getRootElement(),
	function ()
		if isElement(playerTazerObject[source]) then
			destroyElement(playerTazerObject[source])
		end
	end
)

addEventHandler("onClientPlayerWeaponFire", getRootElement(),
	function (weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement)
		if weapon == 24 and getElementData(source, "tazerState") then
			if isElement(hitElement) then
				if getElementType(hitElement) == "player" and not getPedOccupiedVehicle(hitElement) then
					if not getElementData(hitElement, "player.Tazed") and not getElementData(hitElement, "adminDuty") and not getElementData(source, "adminDuty") then
						local playerPosX, playerPosY, playerPosZ = getElementPosition(source)
						local targetPosX, targetPosY, targetPosZ = getElementPosition(hitElement)

						tazerShootEffect[hitElement] = {
							tazedBy = source,
							startTick = getTickCount(),
							effectElement = createEffect("prt_spark_2", targetPosX, targetPosY, targetPosZ)
						}

						local playerInterior = getElementInterior(source)
						local playerDimension = getElementDimension(source)
						local sound = playSound3D("files/taser.ogg", playerPosX, playerPosY, playerPosZ)

						setElementInterior(sound, playerInterior)
						setElementDimension(sound, playerDimension)
					end
				end
			end

			if source == localPlayer then
				setElementData(localPlayer, "tazerReloadNeeded", true)
				exports.sarp_controls:toggleControl({"fire", "vehicle_fire"}, false)
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		local currentTick = getTickCount()

		for k, v in pairs(tazerShootEffect) do
			if isElement(v.tazedBy) and isElement(k) then
				local officerPosX, officerPosY, officerPosZ = getPedBonePosition(v.tazedBy, 26)
				local targetPosX, targetPosY, targetPosZ = getPedBonePosition(k, 3)

				local elapsedTime = currentTick - v.startTick
				local progress = elapsedTime / 750

				local linePosX, linePosY, linePosZ = interpolateBetween(
					officerPosX, officerPosY, officerPosZ,
					targetPosX, targetPosY, targetPosZ,
					progress, "Linear"
				)

				dxDrawLine3D(officerPosX, officerPosY, officerPosZ, linePosX, linePosY, linePosZ, tocolor(100, 100, 100, 100), 0.5, false)
				dxDrawLine3D(officerPosX, officerPosY + 0.02, officerPosZ, linePosX, linePosY + 0.02, linePosZ, tocolor(100, 100, 100, 100), 0.5, false)

				if elapsedTime >= 300 and isElement(v.effectElement) then
					destroyElement(v.effectElement)
				end

				if elapsedTime >= 2390 then
					tazerShootEffect[k] = nil
				end
			else
				tazerShootEffect[k] = nil
			end
		end
	end
)