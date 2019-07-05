local util = exports["sarp_core"]
startTime = 0
endTime = startTime + 1500

local screenX, screenY = guiGetScreenSize()

local BebasNeue = dxCreateFont(":sarp_assets/fonts/BebasNeue.otf", util:resp(15))
local Century = dxCreateFont(":sarp_assets/fonts/CenturyGothicRegular.ttf", util:resp(12))

local fadeAlpha = 1

local fadeInTick = false
local fadeOutTick = false

local boxWidth1, boxHeight1 = 0, 0

local achievement = nil

function renderAchievementBox()

	currentTickCount = getTickCount()

	if fadeOutTick and currentTickCount >= fadeOutTick then
		fadeProgress = (currentTickCount - fadeOutTick) / 2000
		fadeAlpha = interpolateBetween(1, 0, 0, 0, 0, 0, fadeProgress, "Linear")
		if fadeAlpha <= 0 then
			if removeEventHandler("onClientRender", root, renderAchievementBox) then
				reset()
				return
			end
		end
	end	

	boxWidth, boxHeight, _ = util:resp(400), util:resp(90), 0
	imageWidth, imageHeight = util:resp(60), util:resp(60)
	
	startTime = startTime + 25
	progress = startTime / endTime
	
	boxWidth1, boxHeight1, _ = interpolateBetween(_, _, _, boxWidth, boxHeight, _, progress, "OutElastic")
    panelX, panelY = (screenX / 2) - (boxWidth1 / 2), screenY - boxHeight1 - util:resp(100)
    
    dxDrawRoundedRectangle(panelX, panelY, boxWidth1, boxHeight1, 5, tocolor(0, 0, 0, 150 * fadeAlpha), "inner", tocolor(50, 179, 239, 155 * fadeAlpha), false, false)
	dxDrawImage(panelX + util:resp(10), panelY + util:resp(15), imageWidth, imageHeight, ":sarp_assets/images/achievement/medal.png", 0, 0, 0, tocolor(255, 255, 255, 255 * fadeAlpha))
	
	dxDrawText(achievements[achievement][1], panelX, panelY + util:resp(10), panelX + boxWidth1 + imageWidth, panelY + boxHeight1, tocolor(255, 255, 255, 255 * fadeAlpha), 1, BebasNeue, "center", "top")
	dxDrawText("Gratulálunk! Elérétél egy új teljesítményt,\nezért #32B3EF" .. achievements[achievement][3] .. "#FFFFFF XP-vel lettél gazdagabb!", panelX, panelY + util:resp(35), panelX + boxWidth1 + imageWidth, panelY + boxHeight1, tocolor(255, 255, 255, 255 * fadeAlpha), 1, Century, "center", "top", false, false, false, true)
end

function showAchivementPanel(achievementID)	
	if not achievementID or type(achievementID) ~= "number" or not achievements[achievementID] then
		outputDebugString("Hibás achivement arg")
		return
	end

	fadeInTick = getTickCount()
	fadeOutTick = fadeInTick + 5000
	achievement = achievementID
    playSound(":sarp_assets/audio/achievements/newach.ogg")
    removeEventHandler("onClientRender", root, renderAchievementBox)
	addEventHandler("onClientRender", root, renderAchievementBox)
	outputConsole("[SARP - ÚJ TELJESÍTMÉNY] Elérted a " .. achievements[achievement][1] .. " nevű teljesítményt, " .. achievements[achievement][3] .. " XP-t kaptál érte")
end
addEvent("showAchivementPanel", true)
addEventHandler("showAchivementPanel", root, showAchivementPanel)

function reset()
	fadeInTick = false
	fadeOutTick = false
	fadeAlpha = 1
	boxWidth1, boxHeight1 = 0, 0
	startTime = 0
	endTime = startTime + 1500
	fadeProgress = 0
end

addCommandHandler( "ab", function()
    showAchivementPanel(1)
end)

local roundTexture = dxCreateTexture(":sarp_assets/images/alert/round.png", "argb", true, "clamp")

function dxDrawRoundedRectangle(x, y, w, h, radius, color, border, borderColor, postGUI, subPixelPositioning)
	radius = radius or 5
	
	if border == "outer" then
		dxDrawImage(x - radius, y - radius, radius, radius, roundTexture, 0, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w, y - radius, radius, radius, roundTexture, 90, 0, 0, borderColor, postGUI)
		dxDrawImage(x - radius, y + h, radius, radius, roundTexture, 270, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w, y + h, radius, radius, roundTexture, 180, 0, 0, borderColor, postGUI)
		
		dxDrawRectangle(x, y, w, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y - radius, w, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y + h, w, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x - radius, y, radius, h, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w, y, radius, h, borderColor, postGUI, subPixelPositioning)
	elseif border == "inner" then
		dxDrawImage(x, y, radius, radius, roundTexture, 0, 0, 0, borderColor, postGUI)
		dxDrawImage(x, y + h - radius, radius, radius, roundTexture, 270, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w - radius, y, radius, radius, roundTexture, 90, 0, 0, borderColor, postGUI)
		dxDrawImage(x + w - radius, y + h - radius, radius, radius, roundTexture, 180, 0, 0, borderColor, postGUI)
		
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, radius, borderColor, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y + h - radius, w - radius * 2, radius, borderColor, postGUI, subPixelPositioning)
	else
		dxDrawImage(x, y, radius, radius, roundTexture, 0, 0, 0, color, postGUI)
		dxDrawImage(x, y + h - radius, radius, radius, roundTexture, 270, 0, 0, color, postGUI)
		dxDrawImage(x + w - radius, y, radius, radius, roundTexture, 90, 0, 0, color, postGUI)
		dxDrawImage(x + w - radius, y + h - radius, radius, radius, roundTexture, 180, 0, 0, color, postGUI)
		
		dxDrawRectangle(x, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + radius, y, w - radius * 2, h, color, postGUI, subPixelPositioning)
		dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color, postGUI, subPixelPositioning)
	end
end

function getPlayerLevel(player)
    if player and isElement(player) then
        local XP = getElementData(player, "xp") or 0
        local level = 1
        for k, v in ipairs(levels) do
            if v <= XP then
                level = k
            end
        end

        return level
    end
end

function getAllAchievements()
	return achievements
end