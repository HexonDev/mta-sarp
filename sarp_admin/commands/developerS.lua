addAdminCommand("gotopos", 6, "Pozícióra teleportálás")
addCommandHandler("gotopos", function(sourcePlayer, commandName, x, y, z)
	if havePermission(sourcePlayer, commandName, true) then
		if not (x and y and z) then
			outputUsageText(commandName, "[x] [y] [z]", sourcePlayer)
		else
			x = tonumber(x)
			y = tonumber(y)
			z = tonumber(z)

			setElementPosition(sourcePlayer, x, y, z)

			outputAdminText("Sikeresen elteleportáltál a kiválasztott koordinátákra.", sourcePlayer)
		end
	end
end)

-- **************************************************
-- ****************** HTTP CUCCOS *******************
-- **************************************************

function resourceAction(resourceName, theAction)
	if resourceName and theAction then
		local theResource = getResourceFromName(resourceName)

		if theResource then
			if theAction == "restart" then
				restartResource(theResource)
			elseif theAction == "start" then
				startResource(theResource)
			elseif theAction == "stop" then
				stopResource(theResource)
			end
		end
	end
end

function getResourceList(search, orderColumn, orderDirection, startLimit, stopLimit)
	local availableResources = getResources()
	local sortedResources = {}

	startLimit = startLimit or -1
	stopLimit = stopLimit or #availableResources

	startLimit = tonumber(startLimit)
	stopLimit = tonumber(stopLimit)

	for k = #availableResources, 1, -1 do
		local v = availableResources[k]

		if v then
			local resourceName = getResourceName(v)

			if string.find(resourceName, "sarp_") then
				table.insert(sortedResources, 1, v)
			else
				table.insert(sortedResources, v)
			end
		end
	end

	local array = {}
	local index = 0

	for k = 1, #sortedResources do
		local v = sortedResources[k]

		if v then
			local resourceName = getResourceName(v)
			local found = search and string.find(resourceName, search) or not search

			if k >= startLimit + 1 and k <= startLimit + stopLimit then
				if found then
					local loadTime = getResourceLoadTime(v)
					local startTime = getResourceLastStartTime(v)

					if loadTime == "never" then
						loadTime = "N/A"
					else
						loadTime = getRealTime(loadTime)
						loadTime = string.format("%04d/%02d/%02d - %02d:%02d:%02d", loadTime.year + 1900, loadTime.month + 1, loadTime.monthday, loadTime.hour, loadTime.minute, loadTime.second)
					end

					if startTime == "never" then
						startTime = "N/A"
					else
						startTime = getRealTime(startTime)
						startTime = string.format("%04d/%02d/%02d - %02d:%02d:%02d", startTime.year + 1900, startTime.month + 1, startTime.monthday, startTime.hour, startTime.minute, startTime.second)
					end

					table.insert(array, {
						name = resourceName,
						state = getResourceState(v),
						loadTime = loadTime,
						startTime = startTime,
						failureReason = getResourceLoadFailureReason(v)
					})
				end
			end

			if found then
				index = index + 1
			end
		end
	end

	if orderColumn then
		table.sort(array,
			function(a, b)
				if not a[orderColumn] or not b[orderColumn] then
					return false
				end

				if orderDirection == "asc" then
					return a[orderColumn] > b[orderColumn]
				else
					return a[orderColumn] < b[orderColumn]
				end				
			end)
	end

	return array, index, #sortedResources
end

function restartAllRes()
	restartResource(getResourceFromName("sarp_modstarter"))
end
