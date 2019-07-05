local objects = {
    {5681, 1000, 1921.4844, -1778.9141, 18.5781},
    {4215, 1000, 1777.5547, -1775.0391, 36.7500},
    {4715, 1000, 1567.7188, -1248.6953, 102.5234},
    {5661, 1000, 2050.0703, -1401.2109, 33.6797},
    {4218, 1000, 1497.7031, -1546.6172, 43.9922},
    {4220, 1000, 1370.6406, -1643.4453, 33.1797},
    {17886, 1000, 2264.0391, -1789.2578, 20.7734},
    {17887, 1000, 2343.6094, -1784.5078, 20.3125},
}

function removeObjects()
    for k, v in pairs(objects) do
        if v[6] then
            removeWorldModel(v[1], v[2], v[3], v[4], v[5], v[6])
        else
            removeWorldModel(v[1], v[2], v[3], v[4], v[5])
        end
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    removeObjects()
end)