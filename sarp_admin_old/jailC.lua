local screenX, screenY = guiGetScreenSize()

local jailColShape = createColSphere(154.14526367188, -1951.6461181641, 47.875 + 1, 3.5)

local jailProcessTimer = false

local adminJailTime = false
local adminJailData = false

local haveJailEvents = false

local loggedIn = false

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		jailProcessTimer = setTimer(jailProcess, 60000, 0)

		adminJailTime = getElementData(localPlayer, "acc.adminJailTime") or 0
		adminJailData = getElementData(localPlayer, "acc.adminJail") or 0
		loggedIn = getElementData(localPlayer, "loggedIn")

		if adminJailData ~= 0 and not haveJailEvents then
			haveJailEvents = true
			addEventHandler("onClientRender", getRootElement(), renderJail)
		end
	end
)

addEventHandler("onClientElementDataChange", getRootElement(),
	function (dataName, oldValue)
		if source == localPlayer then
			if dataName == "acc.adminJail" then
				adminJailData = getElementData(localPlayer, "acc.adminJail") or 0
				adminJailTime = getElementData(localPlayer, "acc.adminJailTime") or 0

				if adminJailData ~= 0 then
					if not haveJailEvents then
						haveJailEvents = true
						addEventHandler("onClientRender", getRootElement(), renderJail)
					end
				elseif haveJailEvents then
					haveJailEvents = false
					removeEventHandler("onClientRender", getRootElement(), renderJail)
				end
			elseif dataName == "loggedIn" then
				if not isTimer(jailProcessTimer) then
					jailProcessTimer = setTimer(jailProcess, 60000, 0)
				end

				adminJailData = getElementData(localPlayer, "acc.adminJail") or 0
				adminJailTime = getElementData(localPlayer, "acc.adminJailTime") or 0
				loggedIn = getElementData(localPlayer, "loggedIn")

				if adminJailData ~= 0 and not haveJailEvents then
					haveJailEvents = true
					addEventHandler("onClientRender", getRootElement(), renderJail)
				end
			elseif dataName == "acc.adminJailTime" and tonumber(getElementData(localPlayer, "acc.adminJailTime")) then
				adminJailTime = getElementData(localPlayer, "acc.adminJailTime")
			end
		end
	end
)

addEventHandler("onClientElementColShapeLeave", getRootElement(),
	function (theShape)
		if theShape == jailColShape and source == localPlayer then
			local adminJail = getElementData(localPlayer, "acc.adminJail") or 0

			if adminJail ~= 0 then
				setElementPosition(source, getElementPosition(theShape))
			end
		end
	end
)

function jailProcess()
	if getElementData(localPlayer, "loggedIn") then
		local adminJail = getElementData(localPlayer, "acc.adminJail") or 0
		local jailTime = getElementData(localPlayer, "acc.adminJailTime") or 0

		if adminJail ~= 0 then
			if not isElementWithinColShape(localPlayer, jailColShape) then
				setElementPosition(localPlayer, getElementPosition(jailColShape))
			end

			if not haveJailEvents then
				haveJailEvents = true
				addEventHandler("onClientRender", getRootElement(), renderJail)
			end

			if jailTime - 1 <= 0 then
				fadeCamera(false, 1)
				setTimer(
					function ()
						setElementData(localPlayer, "acc.adminJail", 0)
						
						setElementPosition(localPlayer, 1478.8834228516, -1739.0384521484, 13.546875)
				 		setElementInterior(localPlayer, 0)
				 		setElementDimension(localPlayer, 0)

				 		triggerServerEvent("getPlayerOutOfJail", localPlayer)

						fadeCamera(true, 1)
					end,
				1000, 1)
			else
				setElementData(localPlayer, "acc.adminJailTime", jailTime - 1)
			end
		end
	end
end

local logoTexture = dxCreateTexture(":sarp_accounts/files/logo.png")
local logoSize = 128 * (1 / 75)

function renderJail()
	if not loggedIn then
		return
	end
	
	dxDrawText("Hátralévő idő: #32b3ef" .. adminJailTime .. " perc", 0, screenY - 128, screenX, screenY - 64, tocolor(255, 255, 255), 1, dxFont, "center", "center", false, false, false, true)
	
	dxDrawMaterialLine3D(154.2, -1951.9 + logoSize / 2, 46.875, 154.2, -1951.9 - logoSize / 2, 46.875, logoTexture, logoSize, tocolor(50, 179, 239), 154.2, -1951.9, 46.875 + 10)
end

addCommandHandler("jailinfo",
	function ()
		local jailData = getElementData(localPlayer, "acc.adminJail") or 0

		if jailData ~= 0 then
			local datas = split(jailData, "/")

			outputChatBox("#ff4646[ SARP - AdminJail ]#ffffff Jail információk:", 255, 255, 255, true)
			outputChatBox(" - Indok: #ffff99" .. datas[2], 255, 255, 255, true)
			outputChatBox(" - Időtartam: #ffff99" .. datas[3] .. " perc", 255, 255, 255, true)
			outputChatBox(" - Hátralévő idő: #ffff99" .. adminJailTime .. " perc", 255, 255, 255, true)
			outputChatBox(" - Admin: #ffff99" .. datas[4], 255, 255, 255, true)
			outputChatBox(" - Időpont: #ffff99" .. exports.sarp_core:formatDate("Y/m/d h:i:s", "'", tostring(datas[1])), 255, 255, 255, true)
		else
			exports.sarp_hud:showAlert("error", "Nem vagy adminbörtönben!")
		end
	end
)