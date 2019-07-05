addEvent("onTireFlatten", true)
addEventHandler("onTireFlatten", getRootElement(),
	function(tireID)
		local frontLeft, rearLeft, frontRight, rearRight = getVehicleWheelStates(source)

		if tireID == 0 then
			setVehicleWheelStates(source, 1, rearLeft, frontRight, rearRight)
		elseif tireID == 1 then
			setVehicleWheelStates(source, frontLeft, 1, frontRight, rearRight)
		elseif tireID == 2 then
			setVehicleWheelStates(source, frontLeft, rearLeft, 1, rearRight)
		elseif tireID == 3 then
			setVehicleWheelStates(source, frontLeft, rearLeft, frontRight, 1)
		end
	end)

addCommandHandler("garagecmd",
	function(player, cmd, id)
		if getElementData(player, "acc.adminLevel") >= 9 then
			id = tonumber(id)
			
			if not isGarageOpen(id) then
				setGarageOpen(id, true)
			else
				setGarageOpen(id, false)
			end
		end
	end)

addEventHandler("onElementModelChange", getRootElement(),
	function()
		if getElementType(source) == "player" then
			setPedAnimation(source)
		end
	end)