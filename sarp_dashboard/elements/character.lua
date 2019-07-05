local Elements = Dashboard.Elements
local Handlers = Dashboard.Handlers

local characterData = {}

addCommandHandler("frakik", function()
    local frakik = exports.sarp_groups:getPlayerGroups(localPlayer) 
    outputConsole(inspect(frakik))

    for groupID, groupData in pairs(frakik) do
        --getGroupPrefix(groupId)
        local rankID, rankName = exports.sarp_groups:getPlayerRank(localPlayer, groupID)
        outputChatBox(groupID .. ":" .. exports.sarp_groups:getGroupPrefix(groupID) .. ":" .. groupData[1] .. ":" .. rankName .. ":" .. groupData[3])
    end
end)

Elements.Character = function(x, y, w, h)
    local alphaMul = tabPanelAlphas["Character"]

    -- Frakciók
    --characterData[#characterData][2] = processPlayerGroups():sub(3)

    dxDrawText(getPlayerName(localPlayer):gsub("_", " "), x + respc(40), y + respc(40), x + respc(40), y + respc(40), tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.RobotoL24)

    local dataTextX = x + respc(50)
    for k, v in ipairs(characterData) do
        local dataTextY = (y + respc(200)) + ((dxGetFontHeight(1, fonts.Roboto14) + respc(10)) * (k - 1))
        dxDrawText(tostring(v[1]) .. ": " .. tostring(v[2]) .. v[3], dataTextX, dataTextY, dataTextX, dataTextY, tocolor(255, 255, 255, 255 * alphaMul), 1, fonts.Roboto14, "left", "top", false, false, false, true)
    end

    local cursorX, cursorY = getCursorPosition()
    local absX, absY = -1, -1
    if isCursorShowing() then
        absX, absY = cursorX * screenX, cursorY * screenY
    elseif cursorIsMoving then
        cursorIsMoving = false
    end

    local charW, charH = h - respc(50), h - respc(50)
    local charX, charY = x + w - charW - respc(100), y
    exports["sarp_3dview"]:setSkinProjection(charX, charY, charW, charH, 255 * alphaMul)

    if cursorIsMoving then
        exports["sarp_3dview"]:rotateSkin(cursorX)
        setCursorPosition(screenX * 0.5, screenY * 0.5)
        
        if not getKeyState("mouse1") then
            cursorIsMoving = false
            setCursorAlpha(255)
        end
    elseif cursorInBox(charX, charY, charW, charH) and getKeyState("mouse1") then
        cursorIsMoving = true
        setCursorAlpha(0)
        setCursorPosition(screenX * 0.5, screenY * 0.5)
    end

    --dxDrawRectangle(charX, charY, charW, charH)

    activeButtonChecker()
end

Handlers.Character = {}

Handlers.Character.ProcessPlayerInfo = {function()
    characterData = {
        {"Karakter azonosító", "#32b3ef"..getElementData(localPlayer, "char.ID"), ""},
        {"Kor", "#32b3ef"..getElementData(localPlayer, "char.Age"), " életév"},
        {"Készpénz", "#32b3ef"..getElementData(localPlayer, "char.Money"), "$"},
        {"Banki egyenleg", "#32b3ef"..getElementData(localPlayer, "char.bankMoney"), "#ffffff$"},
        
       -- {"Munka", "#32b3ef".. exports.sarp_jobs:getJobInfo(getElementData(localPlayer, "char.Job"))[1], ""},
        {"Tartózkodási hely", "#32b3ef"..getZoneName(getElementPosition(localPlayer)), ""},
        {"Szervezet(ek)", "Betöltés...", ""}, -- Ez mindig legyen az utolsó a táblában!!!
    }
end, "function"}

Handlers.Character.ProcessPlayerGroups = {function()
    local playerGroups = exports.sarp_groups:getPlayerGroups(localPlayer)

    local dataInfo = ""
    if table.empty(playerGroups) and characterData[#characterData] then
        dataInfo = "Nincs"
        characterData[#characterData][2] = dataInfo
    end

    local i = 1
    for groupID, groupData in pairs(playerGroups) do
        local rankID, rankName, rankWage = exports.sarp_groups:getPlayerRank(localPlayer, groupID)
        local groupPrefix = exports.sarp_groups:getGroupPrefix(groupID)
        local isLeader = "Nem"
        if groupData[3] == "Y" then
            isLeader = "Igen"
        end
        
        dataInfo = dataInfo .. ", " .. groupPrefix .. "#ffffff (".. "#32b3ef" .. rankName .. "#ffffff)#32b3ef"
    end

    setTimer(function() 
        characterData[#characterData][2] = "#32b3ef".. dataInfo:sub(3)
    end, 500, 1)
end, "function"}

function showCharacter(skin, state)
    outputChatBox(skin .. " " .. tostring(state))
    if state then
        exports["sarp_3dview"]:processSkinPreview(skin, 0, 0, 0, 0)
    else
        exports["sarp_3dview"]:processSkinPreview()
    end
end

addEventHandler( "onClientResourceStart", resourceRoot,
	function( )
		
	end
)