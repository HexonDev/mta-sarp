local screenX, screenY = guiGetScreenSize()

local lastPlayerDamageTick = 0
local lastVehicleDamageTick = 0
local vehiclePlayerHealthLoss = {}

local vinetta = dxCreateTexture("files/vin.png")
local splatterStart = 0
local splatters = {}

addEventHandler("onClientPlayerDamage", getLocalPlayer(),
	function (attacker, weapon, bodypart, loss)
		if getElementData(source, "invulnerable") then
			cancelEvent()
			return
		end

		if getTickCount() - lastPlayerDamageTick >= 1000 then
			lastPlayerDamageTick = getTickCount()
			splatterStart = false

			for i = 1, #splatters + 1 do
				if not splatters[i] then
					splatters[i] = getTickCount() + math.abs(loss) * math.random(50, 150)

					break
				end
			end
		end

		if source == localPlayer and isElement(attacker) then
			if getElementType(attacker) == "player" then
				if getElementData(attacker, "tazerState") then
					if weapon == 24 then
						if not getElementData(source, "player.Tazed") and not getElementData(source, "adminDuty") and not getElementData(attacker, "adminDuty") then
							triggerServerEvent("onTazerShoot", attacker, source)
						end

						cancelEvent()
					end
				elseif bodypart == 9 and not getElementData(attacker, "tazerState") then
					triggerServerEvent("processHeadShot", localPlayer, attacker, weapon)
					cancelEvent()
				end
			elseif getElementType(attacker) == "ped" and getElementData(attacker, "hitDamage") then
				setElementHealth(localPlayer, getElementHealth(localPlayer) - getElementData(attacker, "hitDamage"))
				cancelEvent()
			end
		end
	end
)

addEventHandler("onClientVehicleDamage", getRootElement(),
	function (attacker, weapon, loss)
		if not weapon and getTickCount() >= lastVehicleDamageTick + 2000 and source == getPedOccupiedVehicle(localPlayer) then
			local vehicleModel = getElementModel(source)
			local damageMultipler = vehiclePlayerHealthLoss[vehicleModel] or 1
			
			local damagedPlayers = {}
			local occupantCount = 0

			for k, v in pairs(getVehicleOccupants(source)) do
				if not getElementData(v, "adminDuty") then
					if getElementData(v, "player.seatBelt") then
						damagedPlayers[v] = math.floor(loss * 0.3) * 0.5 * damageMultipler
					else
						damagedPlayers[v] = math.floor(loss * 0.3) * damageMultipler
					end

					if damagedPlayers[v] == 0 then
						damagedPlayers[v] = nil
					else
						occupantCount = occupantCount + 1
					end
				end
			end

			if occupantCount > 0 then
				triggerServerEvent("vehicleDamage", localPlayer, damagedPlayers)
			end

			lastVehicleDamageTick = getTickCount()
		end
	end, true, "high+99999"
)

addEvent("addBloodToScreenByCarDamage", true)
addEventHandler("addBloodToScreenByCarDamage", getRootElement(),
	function (damagedPlayers)
		local loss = damagedPlayers[localPlayer] or 5

		if loss > 2 and getTickCount() - lastPlayerDamageTick >= 1000 then
			lastPlayerDamageTick = getTickCount()
			splatterStart = false

			for i = 1, #splatters + 1 do
				if not splatters[i] then
					splatters[i] = getTickCount() + math.abs(loss) * math.random(50, 150)

					break
				end
			end
		end
	end
)

addEventHandler("onClientHUDRender", getRootElement(),
	function ()
		if #splatters >= 1 then
			if not splatterStart then
				splatterStart = getTickCount()
			end

			for k = 1, #splatters do
				if splatters[k] then
					v = splatters[k]

					local progress = 0

					if getTickCount() >= v then
						local elapsedTime = getTickCount() - v
						progress = elapsedTime / 1000

						if progress >= 1 then
							splatters[k] = nil

							if #splatters < 1 then
								splatterStart = false
							end
						end
					end

					if v then
						local alpha = interpolateBetween(
							128, 0, 0,
							0, 0, 0,
							progress, "Linear")

						dxDrawImage(0, 0, screenX, screenY, vinetta, 0, 0, 0, tocolor(200, 50, 50, alpha))
					end
				end
			end
		end
	end, true, "high+999999999"
)

addEventHandler("onClientPedDamage", getRootElement(),
	function ()
		if getElementData(source, "invulnerable") then
			cancelEvent()
		end
	end
)

addEventHandler("onClientPlayerStealthKill", getRootElement(),
	function (targetPlayer)
		cancelEvent()
	end
)