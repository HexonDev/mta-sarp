mainCategories = {}
availableItems = {}
itemBasePrices = {}
itemCategories = {}

function addAnItem(itemId, basePrice)
	if type(itemId) == "string" then
		table.insert(mainCategories, itemId)
	else
		availableItems[itemId] = true
		itemBasePrices[itemId] = math.floor(basePrice)
		itemCategories[itemId] = #mainCategories
	end
end

addAnItem("Gyorsételek")
addAnItem(45, 35)
addAnItem(46, 25)
addAnItem(47, 15)
addAnItem(48, 25)
addAnItem(49, 20)
addAnItem(50, 20)
addAnItem(51, 15)
addAnItem("Üdítők")
addAnItem(52, 15)
addAnItem(53, 15)
addAnItem(54, 15)
addAnItem(55, 15)
addAnItem(56, 15)
addAnItem(57, 20)
addAnItem(58, 20)
addAnItem(59, 20)
addAnItem(60, 5)
addAnItem(61, 5)
addAnItem("Forró italok")
addAnItem(70, 20)
addAnItem("Alkohol/Cigaretta")
addAnItem(62, 40)
addAnItem(63, 40)
addAnItem(64, 45)
addAnItem(65, 45)
addAnItem(66, 45)
addAnItem(67, 45)
addAnItem(68, 45)
addAnItem(69, 45)
addAnItem(97, 5)
addAnItem(98, 55)
addAnItem("Műszaki")
addAnItem(28, 75)
addAnItem(44, 15)
addAnItem(71, 95)
addAnItem(79, 15)
addAnItem(82, 65)
addAnItem("Szerszámok")
addAnItem(33, 10)
addAnItem(37, 10)
addAnItem("Hobby")
addAnItem(32, 70)
addAnItem(25, 15)
addAnItem(42, 25)
addAnItem("Egészség")
addAnItem(105, 10)
addAnItem(106, 10)
addAnItem(90, 35)
addAnItem(122, 15)
addAnItem("Lőszerek")
addAnItem(3, 10)
addAnItem(4, 10)
addAnItem(5, 10)
addAnItem(6, 10)
addAnItem(7, 10)
addAnItem(8, 10)

function deepcopy(t)
	if type(t) ~= "table" then return t end
	local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = deepcopy(v)
		else
			target[k] = v
		end
	end
	setmetatable(target, meta)
	return target
end

function table_eq(table1, table2)
	local avoid_loops = {}
	local function recurse(t1, t2)
		-- compare value types
		if type(t1) ~= type(t2) then return false end
		-- Base case: compare simple values
		if type(t1) ~= "table" then return t1 == t2 end
		-- Now, on to tables.
		-- First, let's avoid looping forever.
		if avoid_loops[t1] then return avoid_loops[t1] == t2 end
		avoid_loops[t1] = t2
		-- Copy keys from t2
		local t2keys = {}
		local t2tablekeys = {}
		for k, _ in pairs(t2) do
			if type(k) == "table" then table.insert(t2tablekeys, k) end
			t2keys[k] = true
		end
		-- Let's iterate keys from t1
		for k1, v1 in pairs(t1) do
			local v2 = t2[k1]
			if type(k1) == "table" then
				-- if key is a table, we need to find an equivalent one.
				local ok = false
				for i, tk in ipairs(t2tablekeys) do
					if table_eq(k1, tk) and recurse(v1, t2[tk]) then
						table.remove(t2tablekeys, i)
						t2keys[tk] = nil
						ok = true
						break
					end
				end
				if not ok then return false end
			else
				-- t1 has a key which t2 doesn't have, fail.
				if v2 == nil then return false end
				t2keys[k1] = nil
				if not recurse(v1, v2) then return false end
			end
		end
		-- if t2 has a key which t1 doesn't have, fail.
		if next(t2keys) then return false end
		return true
	end
	return recurse(table1, table2)
end