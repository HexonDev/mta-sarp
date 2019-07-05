addEvent("unauthorizedFunction", true)
addEventHandler("unauthorizedFunction", getRootElement(),
	function (resourceName, functionName, luaFilename, luaLineNumber, args)
		if not fileExists("anticheat.log") then
			fileCreate("anticheat.log")
		end
		
		local acFile = fileOpen("anticheat.log")
		if acFile then
			local buffer = ""
			
			while not fileIsEOF(acFile) do
				buffer = fileRead(acFile, 500)
			end
			
			buffer = buffer .. "resourceName: " .. resourceName .. ", functionName: " .. functionName .. ", luaFilename: " .. (luaFilename or "unknown") .. ", luaLineNumber: " .. (luaLineNumber or "-") .. ", args: " .. (args and table.concat(args, "|") or "-") .. "\n"
			
			fileWrite(acFile, buffer)
			fileClose(acFile)
		end

		--print(resourceName .. ": " .. functionName .. " (" .. (luaFilename or "unknown") .. " [" .. (luaLineNumber or "-") .. "]) // " .. (args and table.concat(args, "|") or "-"))
	end
)