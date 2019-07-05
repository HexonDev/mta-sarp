local shaders = {}
local textures = {}

addEventHandler("onClientElementStreamOut", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" then
			local paintjobId = getElementData(source, "vehicle.paintjob") or 0

			if paintjobId > 0 then
				removeVehiclePaintjob(source)
			end
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "vehicle" then
			local paintjobId = getElementData(source, "vehicle.paintjob") or 0

			if paintjobId > 0 then
				setVehiclePaintjob(source, paintjobId)
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for k, v in ipairs(getElementsByType("vehicle", getRootElement(), true)) do
			local paintjobId = getElementData(v, "vehicle.paintjob") or 0

			if paintjobId > 0 then
				setVehiclePaintjob(v, paintjobId)
			end
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue, newValue)
		if dataName == "vehicle.paintjob" then
			if not newValue or newValue == 0 then
				removeVehiclePaintjob(source)
			else
				setVehiclePaintjob(source, newValue)
			end
		end
	end
)

function setVehiclePaintjob(vehicle, paintjobId)
	if isElement(vehicle) then
		if paintjobId then
			local model = getElementModel(vehicle)

			paintjobId = tonumber(paintjobId)

			if paintjobs[model] then
				if paintjobId <= 0 or paintjobId > #paintjobs[model] then
					removeVehiclePaintjob(vehicle)
					return
				end

				if not shaders[vehicle] then
					shaders[vehicle] = dxCreateShader("files/changer.fx", 0, 100, false, "vehicle")
				end

				local k = "files/paintjobs/" .. model .. "/" .. paintjobs[model][paintjobId][2]

				if not textures[k] then
					textures[k] = dxCreateTexture(k, "dxt3")
				end

				if isElement(shaders[vehicle]) and isElement(textures[k]) then
					dxSetShaderValue(shaders[vehicle], "TEXTURE", textures[k])

					engineApplyShaderToWorldTexture(shaders[vehicle], paintjobs[model][paintjobId][1], vehicle)
				end
			end
		end
	end
end

function removeVehiclePaintjob(vehicle)
	if isElement(vehicle) then
		if isElement(shaders[vehicle]) then
			destroyElement(shaders[vehicle])
		end

		shaders[vehicle] = nil
	end
end