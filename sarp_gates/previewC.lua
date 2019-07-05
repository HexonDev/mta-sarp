local previewObject = nil
local editorMode = nil
local editorState = nil
local fastMode = false

local nearbyMode = false

local gateData = {
    objectID = 980,
    open = {},
    close = {},
	time = 5,
	mode = nil,
	group = 0,
	code = 0,
    ["int-dim"] = {},
}


-- /nearbygates
exports.sarp_admin:addAdminCommand("neargbygates", 5, "Kapu információk megjelenítése")
addCommandHandler("nearbygates", function()
	nearbyMode = not nearbyMode
end)

addEventHandler("onClientRender", root, function()
	for k, v in pairs(getElementsByType("object", root)) do
		local x, y, z = getElementPosition(v)
		local px, py, pz = getElementPosition(localPlayer)

		if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= 5 then
			local sx, sy = getScreenFromWorldPosition(x, y, z)

			if sx and sy then
				dxDrawText("Kapu ID: " .. getElementData(v, "gate.id"), sx, sy, sx, sy, tocolor(255, 255, 255, 255), 1)
			end
		end
	end
end)

-- /creategate KapuID mód(0,1,2) frakcióID(1 esetén) kód(2 esetén)

exports.sarp_admin:addAdminCommand("creategate", 5, "Kapu létrehozása")
addCommandHandler("creategate", function(commandName, gateModel, time, mode, codeOrID)
	if getElementData(localPlayer, "acc.adminLevel") >= 5 then
		if not tonumber(gateModel) or not tonumber(time) then
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Model ID] [Mozgási idő] ([Mód])", 0, 0, 0, true)
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "Model ID: /gatelist a model ID-k megtekintéséhez", 0, 0, 0, true)
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "Mozgási idő: Másodpercben", 0, 0, 0, true)
			outputChatBox(exports.sarp_core:getServerTag("usage") .. "Mód: group, code", 0, 0, 0, true)
		else
			if mode == "group" then
				if not codeOrID or not tonumber(codeOrID) then
					outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Model ID] [Mozgási idő] [Mód] [Frakció ID]", 0, 0, 0, true)
				else
					gateData.group = codeOrID
				end
			elseif mode == "code" then
				if not codeOrID or not tonumber(codeOrID) then
					outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. commandName .. " [Model ID] [Mozgási idő] [Mód] [Kód (0-9)]", 0, 0, 0, true)
				else
					gateData.code = codeOrID
				end
			else
				print("Kulcsos")
			end

			local currentMode = mode or "key"

			gateData.mode = currentMode
			gateData.time = time

			createPreviewGate(tonumber(gateModel)) 
		end
	end
end)


function createPreviewGate(objID) 
    if not editorMode then
        local pX, pY, pZ = getElementPosition(localPlayer)
		local prX, prY, prZ = getElementRotation(localPlayer)
		local pInt = getElementInterior(localPlayer)
        local pDim = getElementDimension(localPlayer)
        
        editorMode = true
        editorState = 1

        outputChatBox(exports.sarp_core:getServerTag("info") .. "Helyezd el a kaput zárt pozicióban", 0, 0, 0, true)

        if isElement(previewObject) then
            destroyElement(previewObject)
        end

        gateData.objectID = objID

        previewObject = createObject(objID, pX, pY, pZ, 0, 0, prZ)
        setElementCollisionsEnabled(previewObject, false)
		setElementAlpha(previewObject, 170)
		setElementInterior(previewObject, pInt)
		setElementDimension(previewObject, pDim)
    end
end


addEventHandler("onClientPreRender", root, function()
	if editorMode then
		local gX, gY, gZ = getElementPosition(previewObject)
		local grX, grY, grZ = getElementRotation(previewObject)
		
		moveValue = 0.01
		
		if fastMode then
			moveValue = 0.1
		else
			moveValue = 0.01
		end
		
		if getKeyState("num_4") then
			setElementPosition(previewObject, gX + moveValue, gY, gZ)
		elseif getKeyState("num_6") then
			setElementPosition(previewObject, gX - moveValue, gY, gZ)
		elseif getKeyState("num_8") then
			setElementPosition(previewObject, gX, gY + moveValue, gZ)
		elseif getKeyState("num_2") then
			setElementPosition(previewObject, gX, gY - moveValue, gZ)
		elseif getKeyState("num_7") then
			setElementRotation(previewObject, grX, grY, grZ + moveValue)
		elseif getKeyState("num_1") then
			setElementRotation(previewObject, grX, grY, grZ - moveValue)
		elseif getKeyState("num_9") then
			setElementPosition(previewObject, gX, gY, gZ + moveValue)
		elseif getKeyState("num_3") then
			
			setElementPosition(previewObject, gX, gY, gZ - moveValue)	
		end
	end
end)

addEventHandler("onClientKey", root, function(button, press)
	if editorMode then
		if (button == "lshift") and (press) then
			cancelEvent()
			
			if fastMode then
				outputChatBox(exports.sarp_core:getServerTag("info") .. "Gyors pozicionálás kikapcsolva", 0, 0, 0, true)
			else
				outputChatBox(exports.sarp_core:getServerTag("info") .. "Gyors pozicionálás bekapcsolva", 0, 0, 0, true)
			end
			fastMode = not fastMode
		elseif (button == "enter") and (press) then
			cancelEvent()
			if (editorState == 1) then
				
				local gX, gY, gZ = getElementPosition(previewObject)
				local grX, grY, grZ = getElementRotation(previewObject)
				
				gateData["close"] = {gX, gY, gZ, grX, grY, grZ}
				gateData["int-dim"] = {getElementInterior(previewObject), getElementDimension(previewObject)}
				
				editorState = 2
				
				outputChatBox(exports.sarp_core:getServerTag("info") .. "Most állítsd be a nyitási poziciót!", 0, 0, 0, true)
				
				
			elseif(editorState == 2) then
				
				local gX, gY, gZ = getElementPosition(previewObject)
				local grX, grY, grZ = getElementRotation(previewObject)
				
				gateData["open"] = {gX, gY, gZ, grX, grY, grZ}
				gateData["int-dim"] = {getElementInterior(previewObject), getElementDimension(previewObject)}
				
				outputChatBox(calculateDifferenceBetweenAngles(gateData["open"][6], gateData["close"][6]))
				triggerServerEvent("insertGate", localPlayer, gateData["objectID"], gateData["open"], gateData["close"], gateData["time"], gateData["int-dim"], gateData["mode"], gateData["group"], gateData["code"])
				destroyPreviewGate()
			end
		elseif (button == "num_1") and (press) then
			cancelEvent()
		elseif (button == "backspace") and (press) then
			destroyPreviewGate()
			outputChatBox(exports.sarp_core:getServerTag("info") .. "Létrehozás vissza vonva", 0, 0, 0, true)
		end
		
		
	end
end)

function destroyPreviewGate()
	if isElement(previewObject) then
		destroyElement(previewObject)
	end
	gateData = {
		objectID = 980,
		open = {},
		close = {},
		time = 5,
		mode = nil,
		group = 0,
		code = 0,
		["int-dim"] = {},
	}
	
	editorMode = false
	editorState = 1
end

function calculateDifferenceBetweenAngles(firstAngle, secondAngle) 
    difference = secondAngle - firstAngle; 
    while (difference < -180) do 
        difference = difference + 360 
    end 
    while (difference > 180) do 
        difference = difference - 360 
    end 
    return difference 
end 