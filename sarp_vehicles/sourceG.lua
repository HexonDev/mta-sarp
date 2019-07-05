function processLicensePlate(dbID)
	local number_1 = dbID % 10
	dbID = (dbID - number_1) / 10

	local number_2 = dbID % 10
	dbID = (dbID - number_2) / 10

	local number_3 = dbID % 10
	dbID = (dbID - number_3) / 10

	local character_1 = dbID % 14
	dbID = (dbID - character_1) / 14

	local character_2 = dbID % 14
	dbID = (dbID - character_2) / 14

	return string.format("%c%c%c%c-%c%c%c",
		math.random(1, 9) + string.byte("0"),

		dbID + string.byte("A"),
		character_2 + string.byte("A"),
		character_1 + string.byte("A"),

		number_3 + string.byte("0"),
		number_2 + string.byte("0"),
		number_1 + string.byte("0")
	)
end