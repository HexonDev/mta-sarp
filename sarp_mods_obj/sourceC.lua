function loadModel(name, model, key)
	local file = fileOpen(name)
	local size = fileGetSize(file)
	local bytes = fileRead(file, size)

	fileClose(file)

	local sections = splitEx(bytes, ";")

	for k, v in pairs(sections) do
		processData = sections[k]

		local isTXD = string.find(processData, "isTxd")
		local isDFF = string.find(processData, "isDff")
		local isCOL = string.find(processData, "isCol")

		processData = string.gsub(processData, "isTxd", "")
		processData = string.gsub(processData, "isDff", "")
		processData = string.gsub(processData, "isCol", "")

		processData = teaDecode(processData, key)
		processData = base64Decode(processData)

		if isTXD then
			engineImportTXD(engineLoadTXD(processData), model)
		elseif isDFF then
			engineReplaceModel(engineLoadDFF(processData), model)
		elseif isCOL then
			engineReplaceCOL(engineLoadCOL(processData), model)
		end
	end
end

addEvent("decodeAndLoadModels", true)
addEventHandler("decodeAndLoadModels", getRootElement(),
	function (key)
		for k, v in pairs(availableModels) do
			if fileExists("files/" .. k .. ".sarp") then
				setTimer(
					function(key)
						loadModel("files/" .. k .. ".sarp", v, key)
					end,
				1000, 1, key)
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		triggerServerEvent("requestDecodeKey", localPlayer, localPlayer)
	end
)