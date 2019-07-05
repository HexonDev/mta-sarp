local wallObjects = {
    8425,
    8426,
    8427,
    8428,
    8429,
    8430,
    8431,
    8435,
    8436,
    8437,
    8460,
    8461,
    8462,
    8468,
    8480,
    8482,
    8483,
    8489,
    8491,
    8492,
    8493,
    8494,
    8495,
    8496,
    8497,
    8498,
    8499,
    8501,
    8503,
    8504,
    8505,
    8506,
    8507,
    8508,
    8509,
    8516,
    8526,
    8527,
    8528,
    8530,
    8532,
    8534,
    8535,
    8536,
    8537,
    8547,
    8548,
    8549,
    8551,
    8553,
    8554,
    8563,
    8564,
    8565,
    8565,
    8566,
    8567,
    8568,
    8589,
    8591,
    8593,
    8594,
    8595,
    8596,
    8607,
    8608,
    8618,
    8620,
    8639,
    8641,
    8643,
    8644,
    8654,
    8655,
    8663,
    8664,
    8666,
    8667,
    8668,
    8671,
    8676,
    8677,
    8678,
    8680,
    8681,
    8682,
    8683,
    8684,
    8685,
    8686,
    8687,
    8688,
    8689,
    8710,
    8833,
    8834,
    8840,
    8842,
    8845,
    8849,
    8881,
    8882,
    8969,
    8981,
    9037,
}

local signsObject = {
    9039, 9044, 9045, 9046, 9054, 9055, 9066, 9070, 9071, 9072, 
    9076, 9078, 9080, 9132, 9159, 9162, 9163, 9174, 9036, 8132,
    8034, 8079, 8675, 8424, 8423, 8422, 8421, 8419, 8416, 8412,
    8411, 8409, 8408, 8405, 8404, 8402, 8400, 8399, 8397, 9396,
    8394, 8393, 8392, 8391, 8371, 8370, 8333 
}

local planeObjects = {
    ["plane_grass_1"] = 11453, 
    ["plane_grass_2"] = 11462, 
    ["plane_grass_3"] = 11543
}

local TXDs = {}
local DFFs = {}
local COLs = {}

function loadSAMPPlanes()

    TXDs["planes"] = {}
    DFFs["planes"] = {}
    COLs["planes"] = {} 

    print("asdd")
    for k, v in pairs(planeObjects) do
        print( k .. " " .. v)
        COLs["planes"][k] = engineLoadCOL("plane/" .. k .. ".col")
        engineReplaceCOL(COLs["planes"][k], v)
        TXDs["planes"][k] = engineLoadTXD("plane/planes.txd")
        engineImportTXD(TXDs["planes"][k], v)
        DFFs["planes"][k] = engineLoadDFF("plane/" .. k .. ".dff") -- 
        engineReplaceModel(DFFs["planes"][k], v)
    end
end

function loadSAMPWalls()

    TXDs["walls"] = {}
    DFFs["walls"] = {}
    COLs["walls"] = {} 

    for k, v in ipairs(wallObjects) do
        if k < 10 then
            rk = "00" .. k
        end

        if k < 100 and k > 10 then
            rk = "0" .. k
        end

        if k > 99 then
            rk = k
        end

        COLs["walls"][k] = engineLoadCOL("walls/wall" .. rk .. ".col")
        engineReplaceCOL(COLs["walls"][k], v)
        TXDs["walls"][k] = engineLoadTXD("walls/all_walls.txd")
        engineImportTXD(TXDs["walls"][k], v)
        DFFs["walls"][k] = engineLoadDFF("walls/wall" .. rk .. ".dff") -- 
        engineReplaceModel(DFFs["walls"][k], v)
    end
end

function loadSAMPSigns()

    TXDs["signs"] = {}
    DFFs["signs"] = {}
    COLs["signs"] = {} 

    for k, v in ipairs(signsObject) do
        
        --if fileExists("roadsigns/SAMPRoadSign" .. k .. ".col") then
            COLs["signs"][k] = engineLoadCOL("roadsigns/SAMPRoadSign" .. k .. ".col")
            engineReplaceCOL(COLs["signs"][k], v)
        --end

        --if fileExists("roadsigns/SAMPRoadSigns.txd") then
            TXDs["signs"][k] = engineLoadTXD("roadsigns/SAMPRoadSigns.txd")
            engineImportTXD(TXDs["signs"][k], v)
        --end

        --if fileExists("roadsigns/SAMPRoadSign" .. k .. ".dff") then
            DFFs["signs"][k] = engineLoadDFF("roadsigns/SAMPRoadSign" .. k .. ".dff") -- 
            engineReplaceModel(DFFs["signs"][k], v)
        --end
        end
    
end

addEventHandler( "onClientResourceStart", getResourceRootElement(), function()
    loadSAMPWalls()
    loadSAMPSigns()
    loadSAMPPlanes()
end)

local screenX, screenY = guiGetScreenSize()

function showWallGUI()

    if isElement(wallW) then
        destroyElement(wallW)
        return
    end

    local width, height = 100, 400
    local x, y = (screenX / 2) - (width / 2), (screenY / 2) - (height / 2)

    local windowWidth, windowHeight = 300, 400
	wallW = guiCreateWindow(50, screenY - windowHeight - 20, windowWidth, windowHeight, "Fal object ID-k", false)
	wallList = guiCreateGridList(0.1, 0.05, 0.8, 0.9, true, wallW)
	
	local guiListColumn1 = guiGridListAddColumn(wallList, "Obj ID", 0.25 )
	local guiListColumn2 = guiGridListAddColumn(wallList, "Név", 0.65 )
	
	for	k, wall in ipairs(wallObjects) do
        
        if k < 10 then
            rk = "00" .. k
        end

        if k < 100 and k > 10 then
            rk = "0" .. k
        end

        if k > 99 then
            rk = k
        end
        
        local row = guiGridListAddRow(wallList)
		guiGridListSetItemText(wallList, row, guiListColumn1, wall, false, true)
		guiGridListSetItemText(wallList, row, guiListColumn2, "wall" .. rk, false, true)
		
	end
end
addCommandHandler("alwo", showWallGUI)

