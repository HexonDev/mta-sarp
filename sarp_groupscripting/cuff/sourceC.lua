local cuffModel = 2812

local leftHandCuff = {}
local rightHandCuff = {}

local cuffData = {}
local cuffAnim = {}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		setElementData(localPlayer, "player.Cuffed", false)
		setElementData(localPlayer, "player.Grabbed", false)
		setElementData(localPlayer, "grabbingPlayer", false)

		local TXD = engineLoadTXD("files/cuff.txd")
		if TXD then
			local DFF = engineLoadDFF("files/cuff.dff")
			if DFF then
				engineImportTXD(TXD, cuffModel)
				engineReplaceModel(DFF, cuffModel)
			end
		end

		setTimer(
			function()
				engineLoadIFP("files/standing_cuffed_back.ifp", "cuff_standing")
				engineLoadIFP("files/standing_cuffed.ifp", "cuff_standing2")
				engineLoadIFP("files/walking_cuffed.ifp", "cuff_walking")
			end,
		2000, 1)
	end
)

addEventHandler("onClientResourceStop", getResourceRootElement(),
	function ()
		if getElementData(localPlayer, "player.Cuffed") or getElementData(localPlayer, "cuffAnimation") then
			setPedAnimation(localPlayer)
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if dataName == "player.Cuffed" then
			local cuffed = getElementData(source, "player.Cuffed")
			local grabbed = getElementData(source, "player.Grabbed") or 1

			if isElement(leftHandCuff[source]) then
				destroyElement(leftHandCuff[source])
			end

			if isElement(rightHandCuff[source]) then
				destroyElement(rightHandCuff[source])
			end

			cuffData[source] = cuffed and grabbed or nil

			if cuffed then
				setPedAnimation(source, "cuff_standing", "standing", -1, true, false)

				cuffAnim[source] = 0

				leftHandCuff[source] = createObject(cuffModel, 0, 0, 0)
				setElementDoubleSided(leftHandCuff[source], true)
				exports.sarp_boneattach:attachElementToBone(leftHandCuff[source], source, 11, 0, 0, 0, 90, -45, 0)

				rightHandCuff[source] = createObject(cuffModel, 0, 0, 0)
				setElementDoubleSided(rightHandCuff[source], true)
				exports.sarp_boneattach:attachElementToBone(rightHandCuff[source], source, 12, 0, 0, 0, 90, -45, 0)

				local playerPosX, playerPosY, playerPosZ = getElementPosition(source)
				local soundEffect = playSound3D("files/handcuff.ogg", playerPosX, playerPosY, playerPosZ)
				setElementInterior(soundEffect, getElementInterior(source))
				setElementDimension(soundEffect, getElementDimension(source))
				setSoundMaxDistance(soundEffect, 5)
			else
				setPedAnimation(source)
				cuffData[source] = nil
				cuffAnim[source] = nil
			end
		elseif dataName == "player.Grabbed" then
			local cuffed = getElementData(source, "player.Cuffed")
			local grabbed = getElementData(source, "player.Grabbed")

			if grabbed then
				cuffData[source] = grabbed
			else
				cuffData[source] = cuffed and 1 or nil
			end
		elseif dataName == "cuffAnimation" then
			local dataValue = getElementData(source, "cuffAnimation")
			
			if dataValue == 1 then
				setPedAnimation(source, "cuff_standing2", "standing", -1, true, false)
			elseif dataValue == 2 then
				setPedAnimation(source, "cuff_walking", "walking", -1, true, true)
			elseif dataValue == 3 then
				setPedAnimation(source, "cuff_standing", "standing", -1, true, false)
			else
				setPedAnimation(source)
			end

			if dataValue then
				cuffAnim[source] = dataValue
			else
				cuffAnim[source] = nil
			end
		end
	end
)

addEventHandler("onClientRender", getRootElement(),
	function ()
		for k, v in pairs(cuffData) do
			if isElementStreamedIn(k) and isElement(leftHandCuff[k]) and isElement(rightHandCuff[k]) then
				local playerInterior = getElementInterior(k)
				local playerDimension = getElementDimension(k)

				if getElementDimension(leftHandCuff[k]) ~= playerDimension then
					setElementInterior(leftHandCuff[k], playerInterior)
					setElementInterior(rightHandCuff[k], playerInterior)
					setElementDimension(leftHandCuff[k], playerDimension)
					setElementDimension(rightHandCuff[k], playerDimension)
				end

				local leftCuffPosX, leftCuffPosY, leftCuffPosZ = getElementPosition(leftHandCuff[k])
				local rightCuffPosX, rightCuffPosY, rightCuffPosZ = getElementPosition(rightHandCuff[k])

				dxDrawLine3D(leftCuffPosX, leftCuffPosY, leftCuffPosZ, rightCuffPosX, rightCuffPosY, rightCuffPosZ, tocolor(75, 75, 75))

				if isElement(v) then
					local bonePosX, bonePosY, bonePosZ = getPedBonePosition(v, 25)

					dxDrawLine3D(leftCuffPosX, leftCuffPosY, leftCuffPosZ, bonePosX, bonePosY, bonePosZ, tocolor(10, 10, 10))
				end
			end
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		for k, v in pairs(cuffData) do
			if isElementStreamedIn(k) and isElement(v) then
				if not isPedInVehicle(v) then
					local sourcePosX, sourcePosY, sourcePosZ = getElementPosition(k)
					local targetPosX, targetPosY, targetPosZ = getElementPosition(v)

					local deltaX = targetPosX - sourcePosX
					local deltaY = targetPosY - sourcePosY
					local distance = deltaX * deltaX + deltaY * deltaY

					if distance >= 2 then
						local sourceRotX, sourceRotY, sourceRotZ = getElementRotation(k)

						setElementRotation(k, sourceRotX, sourceRotY, -math.deg(math.atan2(deltaX, deltaY)), "default", true)

						if cuffAnim[source] ~= 2 then
							cuffAnim[source] = 2
							setElementData(k, "cuffAnimation", 2)
						end
					elseif cuffAnim[source] ~= 1 then
						cuffAnim[source] = 1
						setElementData(k, "cuffAnimation", 1)
					end
				end
			end
		end
	end
)