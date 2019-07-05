availableModels = {
	["kmb_cratex"] = 2912,
	["megaphone"] = 3090,
	["safe"] = 2332,
	["medicalbag"] = 8669, -- RÉGI: 3089(ROSSZ)
	["transportcart"] = 8287, -- RÉGI: 8675(ROSSZ)
	["industshelves"] = 3761, 
	["eszaki_alap"] = 5853,
	["deli_alap"] = 5489,
	["fuelprices"] = 8246,
	["pumppistol"] = 330,
	["pump"] = 3465,
	["fuelstation"] = 16360,
	["platform"] = 8286, -- RÉGI: 3091(ROSSZ)
	["ce_farmland03"] = 13051,
	["wheelclamp"] = 8283,
	["hydrauliccutter"] = 8251,
}

function getModelIdFromName(name)
	if availableModels[name] then
		return availableModels[name]
	end
	return false
end

function splitEx(inputstr, sep)
	if not sep then
		sep = "%s"
	end

	local t = {}
	local i = 1

	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end

	return t
end