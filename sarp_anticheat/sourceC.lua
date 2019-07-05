addDebugHook("preFunction",
	function (sourceResource, functionName, isAllowedByACL, luaFilename, luaLineNumber, ...)
		local args = {...}
		local isSafeFunction = true
		
		for k,v in pairs(args) do
			args[k] = tostring(v)
		end
		
		if not (sourceResource and getResourceName(sourceResource)) then
			isSafeFunction = false
		end
		
		if not isSafeFunction then
			triggerServerEvent("unauthorizedFunction", localPlayer, sourceResource and getResourceName(sourceResource), functionName, luaFilename, luaLineNumber, args)
			return "skip"
		end
	end, {"loadstring", "setElementData", "triggerServerEvent"}
)