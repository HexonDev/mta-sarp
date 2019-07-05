addEvent("getServerPerformanceStats", true)
addEventHandler("getServerPerformanceStats", getRootElement(),
	function (category)
		triggerClientEvent(source, "getServerPerformanceStats", source, getPerformanceStats(category))
	end
)

addEvent("performanceFromAnotherClient", true)
addEventHandler("performanceFromAnotherClient", getRootElement(),
	function (anotherClient, category)
		triggerClientEvent(anotherClient, "clientFromAnotherClient", client, category)
	end
)

addEvent("sendToAnother", true)
addEventHandler("sendToAnother", getRootElement(),
	function (player, columns, rows)
		triggerClientEvent(source, "getServerPerformanceStats", player, columns, rows, getPlayerName(source))
	end
)

addCommandHandler("performance",
	function (player, command, target)
		if getElementData(player, "acc.adminLevel") >= 7 and target then
			local targetPlayer, targetPlayerName = exports.sarp_core:findPlayer(player, target)
			if targetPlayer then
				triggerClientEvent(player, "clientPerformance", targetPlayer)
			end
		end
	end
)

exports.sarp_admin:addAdminCommand("exports", 9, "Exportált funkciók listázása a konzolba")
addCommandHandler("exports",
	function (player)
		if getElementData(player, "acc.adminLevel") >= 9 then
			for k,v in ipairs(getResources()) do
				local resourceName = getResourceName(v)
				local functions = getResourceExportedFunctions(v)

				if #functions > 0 then
					outputConsole(resourceName .. " has #" .. #functions .. " exported functions: ")

					for i = 1, #functions do
						outputConsole(" - " .. functions[i])
					end
				end
			end
		end
	end
)