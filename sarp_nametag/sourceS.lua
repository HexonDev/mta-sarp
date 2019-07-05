addEvent("getTickSync", true)
addEventHandler("getTickSync", getRootElement(),
	function ()
		triggerClientEvent(source, "getTickSync", source, getRealTime().timestamp)
	end
)

addEventHandler("onElementDataChange", getRootElement(),
	function (dataName)
		if getElementType(source) == "player" then
			if dataName == "afk" then
				local dataValue = getElementData(source, dataName)
				
				if dataValue then
					setElementData(source, "startAfk", getRealTime().timestamp)
				else
					setElementData(source, "startAfk", 0)
				end
			end
		end
	end
)