local damageTypes = {
	[19] = "robbanás",
	[37] = "égés",
	[49] = "autóbaleset",
	[50] = "autóbaleset",
	[51] = "robbanás",
	[52] = "jármű",
	[53] = "fulladás",
	[54] = "esés",
	[55] = "unknown",
	[56] = "verekedés",
	[57] = "fegyver",
	[59] = "tank",
	[63] = "robbanás"
}

local boneBodyPart = {
	[5] = "leftArm",
	[6] = "rightArm",
	[7] = "leftLeg",
	[8] = "rightLeg"
}

addEventHandler("onPlayerDamage", getRootElement(),
	function (attacker, weapon, bodyPart, loss)
		if attacker and bodyPart ~= 9 and weapon ~= 53 and (weapon < 16 or weapon > 18) then
			local currentDamages = getElementData(source, "bulletDamages") or {}
			local damageType = false

			if weapon == 0 then
				damageType = "punch"
			elseif weapon == 4 or weapon == 8 then
				damageType = "cut"
			elseif weapon >= 22 and weapon <= 34 then
				damageType = weapon
			end

			if damageType then
				local k = damageType .. ";" .. bodyPart

				currentDamages[k] = (currentDamages[k] or 0) + 1

				setElementData(source, "bulletDamages", currentDamages)
			end
		elseif damageTypes[weapon] then
			--[[
			local damageType = damageTypes[weapon]

			if damageType == "robbanás" or damageType == "esés" or damageType == "jármű" then
				local chance = 20

				if damageType == "verekedés" then
					chance = 60
				end

				if math.random(chance) <= 7 then
					local boneName = boneBodyPart[math.random(5, 8)]
					local boneDamages = getElementData(source, "boneDamages") or {}

					if not boneDamages[boneName] then
						boneDamages[boneName] = true

						setElementData(source, "boneDamages", boneDamages)

						if boneName == "leftArm" then
							exports.sarp_hud:showInfobox(source, "warning", "Eltört a bal karod!")
						elseif boneName == "rightArm" then
							exports.sarp_hud:showInfobox(source, "warning", "Eltört a jobb karod!")
						elseif boneName == "leftLeg" then
							exports.sarp_hud:showInfobox(source, "warning", "Eltört a bal lábad!")
						elseif boneName == "rightLeg" then
							exports.sarp_hud:showInfobox(source, "warning", "Eltört a jobb lábad!")
						end
					end
				end
			end
			]]
		end
	end
)

addEvent("processHeadShot", true)
addEventHandler("processHeadShot", getRootElement(),
	function (attacker, weapon)
		if isElement(attacker) and weapon then
			killPed(source, attacker, weapon, 9)
			setPedHeadless(source, true)
		end
	end
)

addEventHandler("onPlayerSpawn", getRootElement(),
	function ()
		setPedHeadless(source, false)
		setElementData(source, "player.seatBelt", false)
	end
)

addEvent("vehicleDamage", true)
addEventHandler("vehicleDamage", getRootElement(),
	function (damagedPlayers)
		if type(damagedPlayers) == "table" then
			for k, v in pairs(damagedPlayers) do
				if isElement(k) and not isPedDead(k) then
					local health = getElementHealth(k) - v

					setElementHealth(k, health)

					if health <= 0 then
						setElementData(k, "customDeath", "autóbaleset")
					elseif math.random(100) <= 35 then
						local currentDamages = getElementData(k, "bulletDamages") or {}

						if math.random(100) <= 50 then
							currentDamages["cut;3"] = (currentDamages["cut;3"] or 0) + 1
						else
							currentDamages["punch;3"] = (currentDamages["punch;3"] or 0) + 1
						end

						setElementData(k, "bulletDamages", currentDamages)
					end

					triggerClientEvent(k, "addBloodToScreenByCarDamage", k, damagedPlayers)
				end
			end
		end
	end
)