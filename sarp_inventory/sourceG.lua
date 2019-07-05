local weightLimits = {}

defaultSettings = {
	slotLimit = 50,
	width = 10,
	slotBoxWidth = 36,
	slotBoxHeight = 36,
	weightLimit = {
		player = 20,
		vehicle = 100,
		object = 60
	},
	trashModels = {
		[1359] = true,
		[1439] = true
	},
	safeModel = 2332
}

availableItems = {
	-- [ItemID] = {Név, Leírás, Súly, Stackelhető, Fegyver ID, Töltény item ID}
	[1] = {"Lakás kulcs", false, 0},
	[2] = {"Jármű kulcs", false, 0},

	[3] = {"5x9mm-es töltény", "Colt45, Desert 5x9mm-es töltény", 0.001, true},
	[4] = {"Kis gépfegyver töltények", "Kis gépfegyver töltények (UZI,TEC-9,MP5)", 0.001, true},
	[5] = {"AK47-es töltény", false, 0.001, true},
	[6] = {"M4-es gépfegyver töltény", false, 0.001, true},
	[7] = {"Vadászpuska töltény", "Hosszú Vadászpuska töltény", 0.001, true},
	[8] = {"Sörétes töltény", false, 0.001, true},

	[9] = {"CZ-75 pisztoly", "Egy CZ-75-ös.", 3, false, 22, 3},
	[10] = {"Hangtompítós CZ-75", "Egy CZ-75-ös hangtompítóval szerelve.", 3, false, 23, 3},
	[11] = {"H&K USP 45", false, 3, false, 24, 3},

	[12] = {"Micro UZI", "Egy Micro UZI pisztoly.", 3, false, 28, 4},
	[13] = {"TEC-9", "Egy TEC-9-es.", 3, false, 32, 4},
	[14] = {"MP5", "Egy MP5-ös.", 3, false, 29, 4},

	[15] = {"AK-47", "AK-47-es gépfegyver.", 3, false, 30, 5},
	[16] = {"M4", "M4-es gépfegyver.", 3, false, 31, 6},

	[17] = {"Springfield M-1903", "Vadász puska a pontos és határozott lövéshez.", 3, false, 33, 7},
	[18] = {"Távcsöves Springfield M-1903", "Mesterlövész puska a pontos és határozott lövéshez.", 3, false, 34, 7},

	[19] = {"Sörétes puska", "Nagy kaliberű sörétes puska.", 3, false, 25, 8},
	[20] = {"Rövid csövű sörétes puska", "Nagy kaliberű sörétes puska levágott csővel.", 3, false, 26, 8},
	[21] = {"SPAZ-12 taktikai sörétes puska", "SPAZ-12 taktikai sörétes puska elit fegyver.", 3, false, 27, 8},

	[22] = {"Molotov koktél", false, 1, false, 18, 22},
	[23] = {"Gránát", false, 1, false, 16, 23},
	[24] = {"Könnygázgránát", false, 1, false, 17, 24},

	[25] = {"Festékszóró", "Egy festékpatronnal működő festékszóró.", 1, false, 41, 42},
	[26] = {"Könnygáz spray", "Tömegoszlatásra, önvédelemre kitalált, hatásos spray.", 1, false, 41, 43},
	[27] = {"Porral oltó", "Egy porral oltó, mely hatásos védelmet nyújt kisebb tüzek ellen.", 1, false, 42},
	[28] = {"Fényképezőgép", "Egy fényképezőgép mellyel megörökítheted a pillanatokat.", 1, false, 43, 44},

	[29] = {"Gumibot", false, 1, false, 3, 29},
	[30] = {"Golfütő", false, 1, false, 2, 30},
	[31] = {"Kés", false, 1, false, 4, 31},
	[32] = {"Baseball ütő", false, 1, false, 5, 32},
	[33] = {"Csákány", false, 1, false, 6, 33},
	[34] = {"Biliárd ütő", false, 1, false, 7, 34},
	[35] = {"Katana", false, 1, false, 8, 35},
	[36] = {"Láncfűrész", false, 1, false, 9, 36},

	[37] = {"Balta", false, 1, false, 10, 37},
	[38] = {"Dildo", false, 1, false, 11, 38},
	[39] = {"Vibrator", false, 1, false, 12, 39},
	[40] = {"Virág", false, 1, false, 14, 40},
	[41] = {"Járó bot", false, 1, false, 15, 41},

	[42] = {"Festék patron", false, 0.05, true},
	[43] = {"Könnygáz patron", false, 0.05, true},
	[44] = {"SD Kártya", "Kamerába való SD kártya", 0.005, true},

	[45] = {"Hamburger", "Egy guszta, jól megpakolt hamburger.", 0.8},
	[46] = {"Hot-dog", false, 0.8},
	[47] = {"Szendvics", false, 0.8},
	[48] = {"Taco", false, 0.8},
	[49] = {"Fánk", false, 0.8},
	[50] = {"Süti", false, 0.8},
	[51] = {"Puding", false, 0.8},

	[52] = {"Fanta", "Üdítő.", 0.8},
	[53] = {"Coca Cola", "Üdítő.", 0.8},
	[54] = {"PEPSI Cola", "Üdítő.", 0.8},
	[55] = {"7up", "Üdítő.", 0.8},
	[56] = {"Dr Pepper", "Üdítő.", 0.8},

	[57] = {"Red Bull", "Energia ital.", 0.8},
	[58] = {"Monster", "Energia ital.", 0.8},
	[59] = {"Burn", "Energia ital.", 0.8},

	[60] = {"Indigo H2O", "Ásványvíz.", 0.8},
	[61] = {"FIJI Water", "Ásványvíz.", 0.8},

	[62] = {"Bud Light", "Sör.", 0.8},
	[63] = {"Budweiser", "Sör.", 0.8},

	[64] = {"Spring 44", "Vodka.", 0.8},
	[65] = {"Hangar One", "Vodka.", 0.8},
	[66] = {"Tito’s", "Vodka.", 0.8},

	[67] = {"Buffalo Trace", "Whisky.", 0.8},
	[68] = {"Jim Beam", "Whisky.", 0.8},
	[69] = {"Jack Daniel's", "Whisky.", 0.8},

	[70] = {"Kávé", false, 0.8},

	[71] = {"Telefon", false, 0.05},
	[72] = {"Unused slot", false, 0.8},
	[73] = {"Telefon könyv", false, 0.8},
	[74] = {"Gáz maszk", false, 0.8},
	[75] = {"Fény rúd", false, 0.005, true},
	[76] = {"Faltörő kos", false, 0.8},
	[77] = {"Bilincs", false, 0.025, true},
	[78] = {"Bilincs kulcs", false, 0.025, true},
	[79] = {"Rádió", false, 0.8},
	[80] = {"Kötél", false, 0.8},
	[81] = {"Szonda", false, 0.8},
	[82] = {"Hi-Fi", false, 0.8},
	[83] = {"Sí maszk", false, 0.8},
	[84] = {"Benzin kanna", false, 0.8},
	[85] = {"Széf", "A lerakáshoz kattints rá jobb klikkel.", 0.8},
	[86] = {"Jelvény", false, 0.05},
	[87] = {"Azonosító", false, 0.8},
	[88] = {"Kendő", false, 0.8},
	[89] = {"GPS", false, 0.8},
	[90] = {"Elsősegély doboz", false, 0.8},
	[91] = {"Rohampajzs", false, 0.8},
	[92] = {"Hűtőszekrény", false, 0.8},
	[93] = {"Sisak", false, 0.8},
	[94] = {"Ajándék", false, 0.8},
	[95] = {"Pénzes zsák", false, 0.8},
	[96] = {"Kapu kulcs", false, 0.8},
	[97] = {"Cigaretta", false, 0.8},
	[98] = {"Egy doboz cigi", false, 0.8},
	[99] = {"Öngyújtó", false, 0.01},
	[100] = {"Befizetési Csekk", false, 0},
	[101] = {"Csekk tömb", false, 0.01},
	[102] = {"Kifizetési utalvány", false, 0},
	[103] = {"Üres kifizetési utalvány", false, 0},
	[104] = {"Üres befizetési csekl", false, 0},
	[105] = {"Gyógyszer", false, 0.01},
	[106] = {"Vitamin", false, 0.8},
	[107] = {"Defiblirátor", false, 0.8},
	[108] = {"Orvosi táska", false, 0.8},
	[109] = {"GPS", false, 0.8},
	[110] = {"Sokkoló", "Sokkoló pisztoly", 0.25, false, 24, -1},
	[111] = {"Jogosítvány", "Jogosítvány", 0},
	[112] = {"Személyigazolvány", "Személyi", 0},
	[113] = {"Vizsga záradék", "Vizsgának az eredményei papírra írva", 0},
	[114] = {"Megafon", false, 0.01},

	[115] = {"Szén", false, 0.25, true},
	[116] = {"Aranyrög", false, 0.75, true},
	[117] = {"Gyémánt", false, 0.5, true},

	[118] = {"Parkolási bírság", false, 0},
	[119] = {"Bírság", false, 0},
	[120] = {"Bírság tömb", false, 0.01},
	[121] = {"Parkolási bírság tömb", false, 0.01},

	[122] = {"Kötszer", "Kötszer a vérzés lassítására", 0.001, true},
	
	[123] = {"Feldolgozatlan Marihuana", false, 0.01},
	[124] = {"Feldolgozatlan Kokacserje", false, 0.01},
	[125] = {"Marihuána", false, 0.01},
	[126] = {"Kokain", false, 0.01},

}

function isKeyItem(itemId)
	return itemId <= 2 or itemId == 96
end

function isPaperItem(itemId)
	return (itemId >= 100 and itemId <= 104) or (itemId >= 111 and itemId <= 113) or (itemId >= 118 and itemId <= 121)
end

function isSpecialItem(itemId)
	return (itemId >= 45 and itemId <= 70) or itemId == 97 or itemId == 98
end

function isFoodItem(itemId)
	return itemId >= 45 and itemId <= 51
end

function isDrinkItem(itemId)
	return itemId >= 52 and itemId <= 70
end

function getFoodItems()
	local items = {}

	for i = 1, #availableItems do
		if isFoodItem(i) then
			table.insert(items, i)
		end
	end

	return items
end

function getDrinkItems()
	local items = {}

	for i = 1, #availableItems do
		if isDrinkItem(i) then
			table.insert(items, i)
		end
	end

	return items
end

function isPhoneItem(itemId)
	return itemId == 71 or itemId == 72
end

specialItemUsage = {
	[97] = 5,
	[98] = 2
}

for i = 45, 70 do
	if i <= 51 then
		specialItemUsage[i] = 15
	else
		specialItemUsage[i] = 5
	end
end

perishableItems = {
    --[66] = 270 -- 4 és fél óra (270 perc)
    [45] = 300,
    [46] = 300,
    [47] = 300,
    [48] = 300,
    [49] = 300,
    [50] = 300,
    [51] = 300,
    [105] = 480, --8 óra, gyógyszer
    [106] = 480, --8 óra, vitamin
    [118] = 2880, -- parkolási bírság
    [119] = 2880, -- bírság
}

perishableEvent = {
	[118] = "ticketPerishableEvent",
	[119] = "ticketPerishableEvent2"
}

function getItemList()
	return availableItems
end

function getItemInfoForShop(itemId)
	return getItemName(itemId), getItemDescription(itemId), getItemWeight(itemId)
end

function getItemNameList()
	local nameList = {}

	for i = 1, #availableItems do
		nameList[i] = getItemName(i)
	end

	return nameList
end

function getItemDescriptionList()
	local descriptionList = {}

	for i = 1, #availableItems do
		descriptionList[i] = getItemDescription(i)
	end

	return descriptionList
end

function getItemName(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][1]
	end
	return false
end

function getItemDescription(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][2]
	end
	return false
end

function getItemWeight(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][3]
	end
	return false
end

function isItemStackable(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][4]
	end
	return false
end

function getItemWeaponID(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][5] or 0
	end
	return false
end

function getItemAmmoID(itemId)
	if availableItems[itemId] then
		return availableItems[itemId][6]
	end
	return false
end

function isWeaponItem(itemId)
	if availableItems[itemId] and getItemWeaponID(itemId) > 0 then
		return true
	end
	return false
end

function isAmmoItem(itemId)
	return (itemId >= 3 and itemId <= 8) or (itemId >= 42 and itemId <= 44)
end

local nonStackableItems = {}

for i = 1, #availableItems do
	if not isItemStackable(i) then
		nonStackableItems[i] = true
	end
end

function getNonStackableItems()
	return nonStackableItems
end

disabledVehicleTypes = {
	["BMX"] = true,
	["Train"] = true,
	["Trailer"] = true
}

function getWeightLimit(elementType, element)
	if element and getElementType(element) == "vehicle" and disabledVehicleTypes[getVehicleType(element)] then
		return 0
	end

	if element and getElementType(element) == "vehicle" then
		if getVehicleType(element) == "Bike" or getVehicleType(element) == "Quad" then
			return 15
		end
	end

	return weightLimits[getElementModel(element)] or defaultSettings.weightLimit[elementType]
end

function isTrashModel(model)
	if defaultSettings.trashModels[model] then
		return true
	end
	
	return false
end

function isSafeModel(model)
	if model == defaultSettings.safeModel then
		return true
	end
	
	return false
end

function getElementDatabaseId(element, elementType)
	local elementType = elementType or getElementType(element)
	
	if elementType == "player" then
		return getElementData(element, "char.ID")
	elseif elementType == "vehicle" then
		return getElementData(element, "vehicle.dbID")
	elseif elementType == "object" then
		if isSafeModel(getElementModel(element)) then
			return getElementData(element, "safeId")
		end
	end
end