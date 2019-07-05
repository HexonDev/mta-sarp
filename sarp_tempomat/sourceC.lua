local cruiseSpeed = false

addEventHandler("onClientVehicleExit", getRootElement(),
	function (player)
		if player == localPlayer and cruiseSpeed then
			endTempomat()

			setElementData(source, "tempomatSpeed", false)
		end
	end
)

addEventHandler("onClientPreRender", getRootElement(),
	function ()
		if cruiseSpeed then
			local vehicle = getPedOccupiedVehicle(localPlayer)

			if not getElementData(vehicle, "vehicle.engine") then
				endTempomat()
			end

			if vehicle and getPedOccupiedVehicleSeat(localPlayer) == 0 then
				local speed = getVehicleSpeed(vehicle)

				if speed < cruiseSpeed then
					local delta = (cruiseSpeed - speed) / 10

					if delta > 1 then
						delta = 1
					end

					setAnalogControlState("accelerate", delta)
				else
					setAnalogControlState("accelerate", 0)
				end
			end
		end
	end
)

addEventHandler("onClientVehicleCollision", getRootElement(),
	function (hitElement, force)
		if cruiseSpeed and source == getPedOccupiedVehicle(localPlayer) and force >= 75 then
			endTempomat()
		end
	end
)

function getVehicleSpeed(vehicle)
	local velocityX, velocityY, velocityZ = getElementVelocity(vehicle)
	return getDistanceBetweenPoints3D(0, 0, 0, velocityX, velocityY, velocityZ) * 187.5
end

function endTempomat()
	cruiseSpeed = false

	exports.sarp_controls:toggleControl({"accelerate", "brake_reverse"}, true)

	unbindKey("brake_reverse", "down", endTempomat)
	unbindKey("accelerate", "down", endTempomat)
	unbindKey("num_add", "down", "increaseTempomatSpeed")
	unbindKey("num_sub", "down", "decreaseTempomatSpeed")

	setAnalogControlState("accelerate", 0)

	local vehicle = getPedOccupiedVehicle(localPlayer)

	if vehicle then
		setElementData(vehicle, "tempomatSpeed", false)
	end
end

addCommandHandler("tempomat",
	function ()
		local vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and getPedOccupiedVehicleSeat(localPlayer) == 0 and getElementData(vehicle, "vehicle.engine") then
			if cruiseSpeed then
				endTempomat()
				return
			end

			local speed = getVehicleSpeed(vehicle)

			if speed > 5 then
				cruiseSpeed = speed

				exports.sarp_controls:toggleControl({"accelerate", "brake_reverse"}, false)

				bindKey("brake_reverse", "down", endTempomat)
				bindKey("accelerate", "down", endTempomat)
				bindKey("num_add", "down", "increaseTempomatSpeed")
				bindKey("num_sub", "down", "decreaseTempomatSpeed")

				setElementData(vehicle, "tempomatSpeed", cruiseSpeed)
			end
		end
	end
)
bindKey("c", "up", "tempomat")

addCommandHandler("increaseTempomatSpeed",
	function ()
		local vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and cruiseSpeed <= 300 then
			cruiseSpeed = cruiseSpeed + 2

			setElementData(vehicle, "tempomatSpeed", cruiseSpeed)
		end
	end
)

addCommandHandler("decreaseTempomatSpeed",
	function ()
		local vehicle = getPedOccupiedVehicle(localPlayer)

		if vehicle and cruiseSpeed > 6 then
			cruiseSpeed = cruiseSpeed - 2
			
			setElementData(vehicle, "tempomatSpeed", cruiseSpeed)
		end
	end
)