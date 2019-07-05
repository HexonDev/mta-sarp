restaurants = {
	[5] = { -- Well Stacked Pizza
		ID = {
			[2] = true,
		},
		managerPed = {155, 379.80978393555, -116.47602844238, 1001.4921875, 90},
		clothChange = {369.06573486328, -115.06607818604, 1001.4921875 - 1}, 
		skin = 155,
		peds = {
			{374.59915161133 - 0.1, -125.70389556885, 1001.4995117188, 90, "ped", "SEAT_idle"},
			{373.2014465332 + 0.2, -125.70389556885, 1001.4921875, 270, "ped", "SEAT_idle"},
			{374.59915161133 - 0.1, -122.03076721191, 1001.4921875, 90, "ped", "SEAT_idle"},
		},
		meals = { -- {objectID, Neve, Ára, Elékszítési idő (mp)}
			[1] = {2218, "Buster", 2, 10},
			[2] = {2219, "Double D-Luxe", 5, 15},
			[3] = {2220, "Full Rack", 10, 20},
			[4] = {2355, "Salad Meal", 10, 20},
		},
		pickupPoint = {379.09338378906, -114.38400268555, 1001.4921875},
		objects = {
			[2218] = {379.98321533203 - 0.3, -113.92658996582 - 0.3, 1002.643737793 - 1.12, 334, 22, -19}, -- Buster
			[2219] = {379.98321533203 - 0.3, -113.92658996582 - 1.1, 1002.643737793 - 1.12, 334, 22, -19}, -- Double D-Luxe
			[2220] = {379.98321533203 + 0.2, -113.92658996582 - 0.3, 1002.643737793 - 1.12, 334, 22, -19}, -- Full Rack
			[2355] = {379.98321533203 + 0.2, -113.92658996582 - 1.1, 1002.643737793 - 1.12, 334, 22, -19}, -- Salad Meal
		},
	}
}

function table.empty( a )
    if type( a ) ~= "table" then
        return false
    end
    
    return next(a) == nil
end

function table.size(tab)
    local length = 0
	for k, v in pairs(tab) do 
		if v then
			length = length + 1
		end
	end
    return length
end

function isValidInterior(currentInterior, currentDimension)
	if not currentInterior or not currentDimension then
		return false
	end

	if not restaurants[currentInterior] then
		return false
	end

	if not restaurants[currentInterior]["ID"][currentDimension] then
		return false
	end

	return restaurants[currentInterior]["ID"][currentDimension]
end