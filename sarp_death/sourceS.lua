addEvent("fallAnimByBulletDamage", true)
addEventHandler("fallAnimByBulletDamage", getRootElement(),
	function ()
		if isElement(source) then
			setPedAnimation(source, "PED", "FALL_collapse", 2000, false, true, true, false)
		end
	end
)

exports.sarp_admin:addAdminCommand("afelsegit", 1, "Játékos felsegítése a halálból")
addCommandHandler("afelsegit",
	function (localPlayer, cmd, target)
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if not target then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Játékos név / ID]", localPlayer, 0, 0, 0, true)
			else
				local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(localPlayer, target)

				if targetPlayer then
					if getElementHealth(targetPlayer) <= 20 or isPedDead(targetPlayer) then
						local playerPosX, playerPosY, playerPosZ = getElementPosition(targetPlayer)
						local playerInterior = getElementInterior(targetPlayer)
						local playerDimension = getElementDimension(targetPlayer)
						local playerSkin = getElementModel(targetPlayer)

						spawnPlayer(targetPlayer, playerPosX, playerPosY, playerPosZ, getPedRotation(targetPlayer), playerSkin, playerInterior, playerDimension)
						healPlayer(targetPlayer)
						setPedAnimation(targetPlayer)
						setCameraTarget(targetPlayer, targetPlayer)

						outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen felsegítetted #32b3ef" .. targetPlayerName .. " #ffffffjátékost.", localPlayer, 0, 0, 0, true)
						outputChatBox(exports.sarp_core:getServerTag("admin") .. "#32b3ef" .. (getElementData(localPlayer, "acc.adminNick") or "Admin") .. " #fffffffelsegített téged.", targetPlayer, 0, 0, 0, true)
					else
						outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott játékos nem ájult és/vagy nincs meghalva.", localPlayer, 0, 0, 0, true)
					end
				end
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("agyogyit", 1, "Játékos meggyógyítása")
addCommandHandler("agyogyit",
	function (localPlayer, cmd, target)
		if getElementData(localPlayer, "acc.adminLevel") >= 1 then
			if not target then
				outputChatBox(exports.sarp_core:getServerTag("usage") .. "/" .. cmd .. " [Játékos név / ID]", localPlayer, 0, 0, 0, true)
			else
				local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(localPlayer, target)

				if targetPlayer then
					if isPedDead(targetPlayer) then
						outputChatBox(exports.sarp_core:getServerTag("admin") .. "A kiválasztott játékos halott! A felélesztéshez használd az #ffa600/afelsegit #ffffffparancsot.", localPlayer, 0, 0, 0, true)
					else
						healPlayer(targetPlayer)
						setPedAnimation(targetPlayer)
						setCameraTarget(targetPlayer, targetPlayer)

						outputChatBox(exports.sarp_core:getServerTag("admin") .. "Sikeresen meggyógyítottad #32b3ef" .. targetPlayerName .. " #ffffffjátékost.", localPlayer, 0, 0, 0, true)
						outputChatBox(exports.sarp_core:getServerTag("admin") .. "#32b3ef" .. (getElementData(localPlayer, "acc.adminNick") or "Admin") .. " #ffffffmeggyógyított téged.", targetPlayer, 0, 0, 0, true)
					end
				end
			end
		end
	end
)

function healPlayer(playerElement)
	if isElement(playerElement) then
		setElementHealth(playerElement, 100)
		setElementData(playerElement, "isPlayerDeath", false)
		setElementData(playerElement, "bulletDamages", false)
		--setElementData(playerElement, "boneDamages", false)
		setElementData(playerElement, "bloodLevel", 100)
		setElementData(playerElement, "deathReason", false)
		setElementData(playerElement, "customDeath", false)
	end
end

addEvent("reSpawnInJail", true)
addEventHandler("reSpawnInJail", getRootElement(),
	function ()
		if isElement(source) then
			local adminJail = getElementData(source, "acc.adminJailTime") or 0
			local inJail = getElementData(source, "char.arrested")

			if adminJail > 0 then
				triggerEvent("movePlayerBackToAdminJail", source)
			elseif inJail then
				triggerEvent("movePlayerBackToJail", source)
			end

			healPlayer(source)
			setPedAnimation(source)
		end
	end
)

addEvent("spawnToHospital", true)
addEventHandler("spawnToHospital", getRootElement(),
	function ()
		if isElement(source) then
			local playerSkin = getElementModel(source)

			spawnPlayer(source, 2038.4783935547, -1411.0344238281, 17.1640625, 130, playerSkin, 0, 0)
			healPlayer(source)

			setPedAnimation(source)
			setCameraTarget(source, source)
		end
	end
)

addEvent("killPlayerAnimTimer", true)
addEventHandler("killPlayerAnimTimer", getRootElement(),
	function ()
		if isElement(source) then
			local playerId = getElementData(source, "playerID")

			setElementHealth(source, 0)
			setPedAnimation(source)
		end
	end
)

addEvent("bringBackInjureAnim", true)
addEventHandler("bringBackInjureAnim", getRootElement(),
	function (state)
		if isElement(source) then
			if state then
				setPedAnimation(source)
			elseif isPedInVehicle(source) then
				setPedAnimation(source, "ped", "car_dead_lhs", -1, false, false, false)
			else
				setPedAnimation(source, "wuzi", "cs_dead_guy", -1, false, false, false)
			end
		end
	end
)