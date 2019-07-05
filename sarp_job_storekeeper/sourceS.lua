addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		setElementData(resourceRoot, "donePackages", 0)
	end
)

addEvent("crateCarryAnimation", true)
addEventHandler("crateCarryAnimation", getRootElement(),
	function ()
		if isElement(source) then
			setPedAnimation(source, "carry", "crry_prtial", 0, true, true, false, true)
		end
	end
)

addEvent("cratePutDownAnimation", true)
addEventHandler("cratePutDownAnimation", getRootElement(),
	function (transportedCrate)
		if isElement(source) then
			setPedAnimation(source, "carry", "putdwn", 1000, true, true, false, false)

			if transportedCrate then
				local donePackages = getElementData(resourceRoot, "donePackages")
				setElementData(resourceRoot, "donePackages", donePackages + 1)
			end
		end
	end
)

addEvent("giveStorekeeperJobCash", true)
addEventHandler("giveStorekeeperJobCash", getRootElement(),
	function (amount)
		if isElement(source) and tonumber(amount) then
			local currentMoney = getElementData(source, "char.Money") or 0

			currentMoney = currentMoney + amount

			dbQuery(
				function (qh, sourcePlayer)
					setElementData(sourcePlayer, "char.Money", currentMoney)

					dbFree(qh)
				end, {source}, exports.sarp_database:getConnection(), "UPDATE characters SET money = ?", currentMoney
			)
		end
	end
)