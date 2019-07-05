screenX, screenY = guiGetScreenSize()
local UI = exports.sarp_ui
local responsiveMultipler = UI:getResponsiveMultiplier()

Dashboard = {}
Dashboard.Elements = {}
Dashboard.Handlers = {}
Dashboard.Arguments = {}

function resp(value)
    return value * responsiveMultipler
end

function respc(value)
    return math.ceil(value * responsiveMultipler)
end

function loadFonts()
    fonts = {
        Roboto11 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(11), false, "antialiased"),
        Roboto14 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(14), false, "antialiased"),
        Roboto16 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(16), false, "cleartype"),
        Roboto18 = exports.sarp_assets:loadFont("Roboto-Regular.ttf", respc(18), false, "cleartype"),
        RobotoL = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL14 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(14), false, "cleartype"),
        RobotoL16 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(16), false, "cleartype"),
        RobotoL18 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(18), false, "cleartype"),
        RobotoL24 = exports.sarp_assets:loadFont("Roboto-Light.ttf", respc(24), false, "cleartype"),
        RobotoLI16 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(16), false, "cleartype"),
        RobotoLI24 = exports.sarp_assets:loadFont("Roboto-Light-Italic.ttf", respc(24), false, "cleartype"),
        RobotoB18 = exports.sarp_assets:loadFont("Roboto-Bold.ttf", respc(18), false, "antialiased"),
    }
end

local registerEvent = function(eventName, element, func)
	addEvent(eventName, true)
	addEventHandler(eventName, element, func)
end

addEventHandler("onAssetsLoaded", root, function ()
	loadFonts()
end)

addEventHandler("onClientResourceStart", resourceRoot, function ()
	loadFonts()
end)

dashboardMenuItems = {
--  {"Menü név", "Kép elérhetősége", Menü ID}
    {"Áttekintés", "files/icons/home.png", "Overview"},
    {"Karakter", "files/icons/user.png", "Character"},
    {"Vagyon", "files/icons/money.png", "Property"},
--    {"Adminok", "files/icons/User.png", "Admin"},
--    {"Beállítások", "files/icons/settings.png", "Settings"},
--    {"Teljesítmények", "files/icons/award.png", "Achievements"},
}

activeMenu = 1
local showDashboard = false
activePage = "Overview"

local logoX, logoY = 0, 0
local logoW, logoH = respc(300), respc(150)

local menuX, menuY = 0, logoH
local menuW, menuH = respc(300), screenY - logoH

local barX, barY = logoW, 0
local barW, barH = screenX - logoW, respc(50)

local contentX, contentY = logoW, barH
local contentW, contentH = screenX - logoW, screenY - barH

local openedTime = 0
local moveAnim = false

local tabSwitchStartInterpolation = {}
local tabSwitchEndInterpolation = {}
local tabAfterInterpolation = "Overview"
tabPanelAlphas = {}

Dashboard.SwitchMenu = function(id)
    if id == activePage then
        return false
    end

    lastPage = activePage
    tabAfterInterpolation = id
    tabSwitchEndInterpolation[lastPage] = getTickCount()
    
    if Dashboard.Handlers[tabAfterInterpolation] then
        for k, v in pairs(Dashboard.Handlers[tabAfterInterpolation]) do
            if v[2] == "function" then
                v[1]()
            else
                addEventHandler(v[2], root, v[1]) 
            end
        end
    end

    if lastPage ~= tabAfterInterpolation then
        if Dashboard.Handlers[lastPage] then
            for k, v in pairs(Dashboard.Handlers[lastPage]) do
                if v[2] ~= "function" then
                    --outputChatBox(v[2] .. " event törlése => " .. lastPage)
                    removeEventHandler(v[2], root, v[1]) 
                end
            end
        end
    end

    --outputChatBox(lastPage .. " => " .. tabAfterInterpolation)

    return true
end


Dashboard.Interface = function()
    dashboardW, dashboardH = 0, 0

    if moveAnim and moveAnim[1] then
        if getTickCount() >= moveAnim[1] then
            local progress = (getTickCount() - moveAnim[1]) / 500

            if moveAnim[2] == "Y" then
                moveAnim[3] = interpolateBetween(0, 0, 0, screenY, 0, 0, progress, "Linear")
            elseif moveAnim[2] == "N" then
                moveAnim[3] = interpolateBetween(screenY, 0, 0, 0, 0, 0, progress, "Linear")
            end

            moveAnim[4] = progress

            if progress >= 1 then
                if moveAnim[2] == "N" then
                    removeEventHandler("onClientRender", root, Dashboard.Interface)
                    removeEventHandler("onClientClick", root, Dashboard.Handlers.SideMenu.ClickHandler[1])
                    showDashboard = false
                    exports["sarp_hud"]:toggleHUD(not currentState)
                    showChat(not currentState)
                    Dashboard.Reset()
                else
                    activePage = "Overview"
                    tabSwitchStartInterpolation[activePage] = getTickCount()
                end

                moveAnim[1] = false
                moveAnim[4] = 1
            end
        end
    end

    dashboardH = moveAnim[3]

    dxDrawRectangle(0, 0, screenX, dashboardH, tocolor(31, 31, 31, 240))

    for i = 1, #dashboardMenuItems do
        i = dashboardMenuItems[i][3]

        if not tabPanelAlphas[i] then
            tabPanelAlphas[i] = 0
        end

        if tonumber(tabSwitchStartInterpolation[i]) then
            local progress = (getTickCount() - tabSwitchStartInterpolation[i]) / 250

            tabPanelAlphas[i] = interpolateBetween(tabPanelAlphas[i], 0, 0, 1, 0, 0, progress, "Linear")

            if progress >= 1 then
                tabSwitchStartInterpolation[i] = false
            end
        elseif tonumber(tabSwitchEndInterpolation[i]) then
            local progress = (getTickCount() - tabSwitchEndInterpolation[i]) / 250

            tabPanelAlphas[i] = interpolateBetween(tabPanelAlphas[i], 0, 0, 0, 0, 0, progress, "Linear")

            if progress >= 1 then
                tabSwitchEndInterpolation[i] = false

                if tabAfterInterpolation ~= activePage then
                    activePage = tabAfterInterpolation
                    tabSwitchStartInterpolation[activePage] = getTickCount()
                end
            end
        end
    end

    if moveAnim[2] == "Y" and moveAnim[4] >= 1 then
        --dxDrawRectangle(contentX, contentY, contentW, contentH, tocolor(0, 0, 100, 255))
        --dxDrawRectangle(barX, barY, barW, barH, tocolor(0, 100, 0, 255)) -- BAR RÉSZE
        --dxDrawRectangle(logoX, logoY, logoW, logoH, tocolor(100, 0, 0, 255)) -- LOGÓ RÉSZE
        --dxDrawRectangle(menuX, menuY, menuW, menuH, tocolor(100, 100, 100, 255)) -- MENÜ RÉSZE
    
        Dashboard.Elements.Logo(logoX, logoY, logoW, logoH)
        Dashboard.Elements.SideMenu(menuX, menuY, menuW, menuH)
        if Dashboard.Elements[activePage] then
            Dashboard.Elements[activePage](contentX, contentY, contentW, contentH)
        end
    end
end

Dashboard.Reset = function()
    tabSwitchStartInterpolation = {}
    tabSwitchEndInterpolation = {}
    tabAfterInterpolation = "Overview"
    tabPanelAlphas = {}

    activeMenu = 1
    
    exports["sarp_3dview"]:processSkinPreview()
    exports["sarp_3dview"]:processVehiclePreview()

    for key, menu in pairs(dashboardMenuItems) do
        if Dashboard.Handlers[menu[3]] then
            for k, v in pairs(Dashboard.Handlers[menu[3]]) do
                if v[2] ~= "function" then
                    removeEventHandler(v[2], root, v[1]) 
                end
            end
        end
    end
end

Dashboard.Show = function()
    if moveAnim and moveAnim[4] < 1 then
        return
    end

    if showDashboard then
        moveAnim = {getTickCount(), "N", moveAnim[3]}
    elseif getTickCount() - openedTime >= 2000 then
        moveAnim = {getTickCount(), "Y", 0}

        addEventHandler("onClientRender", root, Dashboard.Interface)
        addEventHandler("onClientClick", root, Dashboard.Handlers.SideMenu.ClickHandler[1])

        Dashboard.Handlers.Overview.ProcessUserInfo[1]()

        showDashboard = true
        exports["sarp_hud"]:toggleHUD(not showDashboard)
        showChat(not showDashboard)

        openedTime = getTickCount()
    else
        exports.sarp_hud:showAlert(":sarp_assets/images/cross_x.png;error;215;89;89", "Maximum 2 másodpercenként nyithatod meg a dashboardot!")
    end
end
bindKey("F5", "down", Dashboard.Show)



--]]--



























