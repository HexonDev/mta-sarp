availableMods = {
	-- [Fájl elérés] = {model id vagy model neve, jármű neve - ha nincs az alap model neve lesz, kikapcsolható-e}
	["job/boxville"] = {"boxville", "Boxville Freight"},
	["job/mrwhoop"] = {423, "Fagylaltos kocsi"},
	["job/sweeper"] = {"sweeper", "Úttisztító jármű", true},

	["pdsd/polmav"] = {497, "Rendőrségi helikopter"},
	["pdsd/copbike"] = {523, "Rendőrségi motor"},
	["pdsd/598"] = {598, "Dodge Charger (Law Enforcement)"},
	["pdsd/597"] = {597, "Ford Crown Victoria Slicktop (Law Enforcement)"},
	["pdsd/596"] = {596, "Ford Crown Victoria (Law Enforcement)"},
	["pdsd/enforcer"] = {427, "Lenco Bearcat (Law Enforcement)"},


	["lsfd/ambulan"] = {"ambulance", "Vapid Sadler Mentő"},
	["lsfd/firetruk"] = {407, "Pierce Arrow XT Tűzoltó"},
	["lsfd/firela"] = {544, "Pierce Arrow XT Létrás tűzoltó"},
	["lsfd/raindanc"] = {563, "Bell Huey UH-1 Tűzoltó-helikopter"},
	["lsfd/barracks"] = {433, "LSFD"},

	["lsc/towtruck"] = {525, "Vontató"},
	
	["civil/562"] = {562, "Nissan GTR R35", true},
	["civil/494"] = {494, "Nissan Skyline R32", true},
	["civil/504"] = {504, "Nissan 2000GTR", true},
	["civil/yosemite"] = {554, "Ford F-150", true},
	["civil/Bravura"] = {401, "Ford Mustang Mach 1 429 Cobra", true},
	["buffalo"] = {402, "Dodge Challenger SRT Hellcat", true},
	["civil/sentinel"] = {405, "BMW E3", true},
	["civil/esperant"] = {419, "Cadillac Fleetwood Eldorado ", true},
	["civil/washing"] = {421, "Lincoln Continental Sedan", true},
	["civil/premier"] = {426, "Ford Crown Victoria", true},
	["civil/bobcat"] = {422, "Chevrolet Blazer 93", true},
	["civil/stallion"] = {439, "Ford Mustang GT Fastback", true},
	["civil/hotknife"] = {434, "Ford Mustang Bullitt 1968", true},
	["civil/cheeta"] = {415, "Dodge Stealth R/T Twin Turbo", true},
	["civil/stafford"] = {580, "Mercedes-Benz 300 SEL 6.3", true},
	["civil/tornado"] = {576, "Plymouth GTX 426 HEMI", true},
	["civil/jester"] = {559, "Toyota Supra US-Spec", true},
	["civil/slamvan"] = {535, "1974 Chevrolet C-10", true},
	["civil/infernus"] = {411, "Lamborghini Murcielago 2005", true},
	["civil/voodoo"] = {412, "Lincoln Continental Sedan", true},
	["civil/sabre"] = {475, "Chevrolet Camaro ZL1 1LE '18", true},
	--["civil/zr350"] = {477, "1997 Mazda RX-7 Series III", true},
	["civil/admiral"] = {445, "2009 Audi RS6 Avant", true},
	["civil/glendale"] = {466, "BMW 7-Series 750iL e38 1995 ", true},
	["civil/club"] = {589, "BMW M635 CSi", true},
	["civil/manana"] = {410, "1974 Datsun 280Z", true},
	["civil/fortune"] = {526, "Nissan Skyline R33 Tunable", true},
	["civil/cadrona"] = {527, "2001 HONDA S2000", true},
	["civil/banshee"] = {429, "McLaren P1", true},
	["civil/blistac"] = {496, "Audi Sport quattro B2", true},
	["civil/supergt"] = {506, "Audi R8", true},
	["civil/solair"] = {458, "2003 Ford Taurus Sedan", true},
	["civil/quad"] = {471, "Snowmobile", false},

}

vehicleNames = {}

for k, v in pairs(availableMods) do
	local model = tonumber(v[1]) or getVehicleModelFromName(v[1])

	if model then
		vehicleNames[model] = v[2]
	end
end

_getVehicleNameFromModel = getVehicleNameFromModel
_getVehicleName = getVehicleName

function getVehicleNameFromModel(model)
	if vehicleNames[model] then
		return vehicleNames[model]
	end

	return _getVehicleNameFromModel(model)
end

function getVehicleName(vehicleElement)
	local model = getElementModel(vehicleElement)

	if vehicleNames[model] then
		return vehicleNames[model]
	end

	return _getVehicleName(vehicleElement)
end

function getVehicleNameList()
	local list = {}

	for k, v in pairs(availableMods) do
		table.insert(list, v[2])
	end

	return list
end