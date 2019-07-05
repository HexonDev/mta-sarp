local vehicleHandlings = {
	[402] = {
		["maxVelocity"] = 320,
		["engineAccleration"] = 50,
		["driveType"] = "awd",
		["brakeDeceleration"] = 50,
		["steeringLock"] = 35.0,
		["suspensionLowerLimit"] = -0.15,
		["suspensionUpperLimit"] = -0.10,
	},
	[405] = {
		["maxVelocity"] = 250,
		["engineAccleration"] = 40,
		["driveType"] = "awd",
		["brakeDeceleration"] = 50,
		["steeringLock"] = 35.0,
		["suspensionLowerLimit"] = -0.32,
		["suspensionUpperLimit"] = -0.2,
		["suspensionDamping"] = 0,5,
		["numberOfGears"] = 5,
	},
}

addEventHandler("onResourceStart", resourceRoot, function() -- Csak akkor hajtsa végre, ha a resource elindul. a resourceRoot jelenti azt, hogy csak ez a resource indulásakor
    local vehicles = getElementsByType("vehicle") -- lekéri az össze szerveren létrehozott jármű típusú elementet, táblát ad vissza, így loopolhatunk rajta
    for _, vehicle in ipairs(vehicles) do -- a "vehicle" a for után visszaadja az elementet 
        local vehicleModel = getElementModel(vehicle) -- Ez lekéri az ID-ját a kocsinak (500, 599, 402, stb...)
        local vehicleHandling = vehicleHandlings[vehicleModel] -- Lekérjük, hogy van-e a táblában a bizonyos modelre handling, ha nincs false-t vagy nil-t fog visszaadni
        if vehicleHandling then -- csak akkor loopoljon rajta végig, ha van ilyen tábla (pl: [589] = {...}). Így elkerüljük a hiba üzeneteket
            for flag, value in pairs(vehicleHandling) do -- Ha van ilyen tábla, akkor végig loopolunk a tábla tartalmán. a flag = [Property], value = érték. (["maxVelocity"] = 400) szóval itt a flag a "maxVelocity" lesz és a value a 400.
                setVehicleHandling(vehicle, flag, value) -- Rárakjuk a járműre a handlinget.
            end
        end
    end
end)