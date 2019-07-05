local breakableObjects = {
	[3465] = true,
	[1686] = true,
	[1244] = true,
	[1676] = true,
	[1215] = true,
	[1214] = true,
	[1257] = true,
	[2942] = true,
	[1319] = true
}

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for k,v in ipairs(getElementsByType("object")) do
			if breakableObjects[getElementModel(v)] then
				setObjectBreakable(v, false)
				setElementFrozen(v, true)
			end
		end
	end
)

addEventHandler("onClientElementStreamIn", getRootElement(),
	function ()
		if getElementType(source) == "object" and breakableObjects[getElementModel(source)] then
			setObjectBreakable(source, false)
			setElementFrozen(source, true)
		end
	end
)