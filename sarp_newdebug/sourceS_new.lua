addEventHandler("onDebugMessage", getRootElement(),
	function (message, level, file, line, r, g, b)
		if level == 1 then
			level = "#d75959[fa-exclamation-circle] "
		elseif level == 2 then
			level = "#FF9600[fa-exclamation-triangle] "
		elseif level == 3 then
			level = "#32b3ef[fa-info-circle] "
		else
			level = string.format("#%02x%02x%02x", r, g, b) .. "[fa-terminal] "
		end

		level = "[caret-left]b style='color: inherit;'[caret-right]" .. level .. "[caret-left][per]b[caret-right]"
		
		if file and line then
			triggerLatentClientEvent("addDebugLine", getResourceRootElement(), level .. file .. ":" .. line .. ", " .. message)
		else
			triggerLatentClientEvent("addDebugLine", getResourceRootElement(), level .. message)
		end
	end
)