local loadedRoadmarks = {}
local roadmarkSavePath = "savedRoadmarks.json"

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		if not fileExists(roadmarkSavePath) then
			loadedRoadmarks = {}
		else
			local fileHandler = fileOpen(roadmarkSavePath)
			if fileHandler then
				local fileBuffer = fileRead(fileHandler, fileGetSize(fileHandler))
				
				if fileBuffer then
					loadedRoadmarks = fromJSON(fileBuffer)
				end
				
				fileClose(fileHandler)
			end
		end
	end
)

addEventHandler("onResourceStop", getResourceRootElement(),
	function ()
		if fileExists(roadmarkSavePath) then
			fileDelete(roadmarkSavePath)
		end
		
		local fileHandler = fileCreate(roadmarkSavePath)
		if fileHandler then
			fileWrite(fileHandler, toJSON(loadedRoadmarks, true, "tabs"))
			fileClose(fileHandler)
		end
	end
)

addEvent("requestRoadmarksList", true)
addEventHandler("requestRoadmarksList", getRootElement(),
	function ()
		triggerClientEvent(source, "receiveRoadmarksList", source, loadedRoadmarks)
	end
)

addEvent("createRoadmark", true)
addEventHandler("createRoadmark", getRootElement(),
	function (data)
		if data then
			local currentTimestamp = getRealTime().timestamp
			local creatorName = utf8.gsub(getPlayerName(source), "#%x%x%x%x%x%x", "")
			
			local roadmarkID = data.tableId or md5(currentTimestamp .. "-" .. creatorName)
			
			if not data.isStripe then
				loadedRoadmarks[roadmarkID] = {
					textureData = data.textureData,
					scale = data.scale,
					rotation = data.rotation,
					x0 = data.middlePosX,
					y0 = data.middlePosY,
					z0 = data.middlePosZ,
					x1 = data.startPosX,
					y1 = data.startPosY,
					z1 = data.startPosZ,
					x2 = data.endPosX,
					y2 = data.endPosY,
					z2 = data.endPosZ,
					x3 = data.faceTowardX,
					y3 = data.faceTowardY,
					z3 = data.faceTowardZ,
					interior = getElementInterior(source),
					dimension = getElementDimension(source),
					color = data.color or -1,
					creationTime = currentTimestamp,
					playerName = creatorName,
					accountId = getElementData(source, "acc.ID") or "N/A",
					characterId = getElementData(source, "char.ID") or "N/A",
					isProtected = data.isProtected
				}
			else
				loadedRoadmarks[roadmarkID] = {
					x0 = data.normalPosX,
					y0 = data.normalPosY,
					z0 = data.normalPosZ,
					width = data.width,
					height = data.height,
					interior = getElementInterior(source),
					dimension = getElementDimension(source),
					color = data.color or -1,
					creationTime = currentTimestamp,
					playerName = creatorName,
					accountId = getElementData(source, "acc.ID") or "N/A",
					characterId = getElementData(source, "char.ID") or "N/A",
					isProtected = data.isProtected
				}
			end
			
			triggerClientEvent("createRoadmark", getResourceRootElement(), source, loadedRoadmarks[roadmarkID], roadmarkID)
		end
	end
)

addEvent("protectRoadmark", true)
addEventHandler("protectRoadmark", getRootElement(),
	function (id, state)
		if loadedRoadmarks[id] then
			loadedRoadmarks[id].isProtected = state
			triggerClientEvent("protectRoadmark", getResourceRootElement(), id, state)
		end
	end
)

addEvent("deleteRoadmark", true)
addEventHandler("deleteRoadmark", getRootElement(),
	function (id, data)
		if loadedRoadmarks[id] then
			loadedRoadmarks[id] = nil
			triggerClientEvent("deleteRoadmark", getResourceRootElement(), id)
		end
	end
)